// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerina/test;

http:Client mimeClientEP1 = new("http://localhost:9100", { httpVersion: "2.0" });
http:Client mimeClientEP2 = new("http://localhost:9100", { httpVersion: "2.0" });
http:Client priorKnowclientEP1 = new("http://localhost:9100", { httpVersion: "2.0",
                                    http2Settings: { http2PriorKnowledge: true } });
http:Client priorKnowclientEP2 = new("http://localhost:9100", { httpVersion: "2.0",
                                    http2Settings: { http2PriorKnowledge: true } });

@http:ServiceConfig {
    basePath: "/multiparts"
}
service multipartDemoService on new http:Listener(9100, { httpVersion: "2.0" }) {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/decode"
    }
    resource function multipartReceiver(http:Caller caller, http:Request request) {
        http:Response response = new;
        string respPayload = "";
        mime:Entity[] respBodyParts = [];
        var bodyParts = request.getBodyParts();
        int i = 0;
        if (bodyParts is mime:Entity[]) {
            foreach var part in bodyParts {
                respBodyParts[i] = handleRespContent(part);
                i = i+1;
            }
            response.setBodyParts(respBodyParts);
        } else {
            log:printError(<string> bodyParts.detail()["message"]);
            response.setPayload("Error in decoding multiparts!");
            response.statusCode = 500;
        }
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", result);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/initial"
    }
    resource function requestInitializer(http:Caller caller, http:Request request) {
        http:Response|http:Payload|error finalResponse;
        http:Request req = new;
        if (request.getHeader("priorKnowledge") == "true") {
            req.setHeader("priorKnowledge", "true");
            finalResponse = priorKnowclientEP2->get("/multiparts/encode", req);
        } else {
            req.setHeader("priorKnowledge", "false");
            finalResponse = mimeClientEP2->get("/multiparts/encode", req);
        }
        if (finalResponse is error) {
            log:printError("Error sending response", finalResponse);
        } else if (finalResponse is http:Response) {
            var respBodyParts = finalResponse.getBodyParts();
            string finalMessage = "";
            if (respBodyParts is mime:Entity[]) {
                foreach var part in respBodyParts {
                    finalMessage = finalMessage + handleResponseBodyParts(part);
                }
            }
            var result = caller->respond(finalMessage);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/encode"
    }
    resource function multipartSender(http:Caller caller, http:Request req) {
        mime:Entity jsonBodyPart = new;
        jsonBodyPart.setContentDisposition(getContDisposition("json part"));
        jsonBodyPart.setJson({"name": "wso2"});
        mime:Entity xmlFilePart = new;
        xmlFilePart.setContentDisposition(getContDisposition("xml file part"));
        xmlFilePart.setFileAsEntityBody("tests/datafiles/http2_test.xml",
                                        contentType = mime:APPLICATION_XML);
        mime:Entity textPart = new;
        textPart.setText("text content", contentType = "text/plain");
        mime:Entity[] bodyParts = [jsonBodyPart, xmlFilePart, textPart];
        http:Request request = new;
        request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
        http:Response|http:Payload|error returnResponse;
        if (req.getHeader("priorKnowledge") == "true") {
            returnResponse = priorKnowclientEP1->post("/multiparts/decode", request);
        } else {
            returnResponse = mimeClientEP1->post("/multiparts/decode", request);
        }
        if (returnResponse is http:Response) {
            var result = caller->respond(<@untainted> returnResponse);
            if (result is error) {
                log:printError("Error sending response", result);
            }
        } else {
            http:Response response = new;
            response.setPayload("Error occurred while sending multipart request!");
            response.statusCode = 500;
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", result);
            }
        }
    }
}

function handleRespContent(mime:Entity bodyPart) returns @untainted mime:Entity {
    mime:Entity jsonPart = new;
    mime:Entity xmlPart = new;
    mime:Entity textPart = new;
    var mediaType = mime:getMediaType(bodyPart.getContentType());
    if (mediaType is mime:MediaType) {
        string baseType = mediaType.getBaseType();
        if (mime:APPLICATION_XML == baseType || mime:TEXT_XML == baseType) {
            var payload = bodyPart.getXml();
            if (payload is xml) {
                xmlPart.setXml(<@untainted>payload, contentType = "application/xml");
                return xmlPart;
            } else {
                xmlPart.setXml(xml `<message>error</message>`, contentType = "application/xml");
                return xmlPart;
            }
        } else if (mime:APPLICATION_JSON == baseType) {
            var payload = bodyPart.getJson();
            if (payload is json) {
                jsonPart.setJson(<@untainted>payload, contentType = "application/json");
                return jsonPart;
            } else {
                jsonPart.setJson("error", contentType = "application/json");
                return jsonPart;
            }
        } else if (mime:TEXT_PLAIN == baseType) {
            var payload = bodyPart.getText();
            if (payload is string) {
                textPart.setText(<@untainted>payload, contentType = "text/plain");
                return textPart;
            } else {
                textPart.setText("error", contentType = "text/plain");
                return textPart;
            }
        }
    }
    textPart.setText("error", contentType = "text/plain");
    return textPart;
}

function handleResponseBodyParts(mime:Entity bodyPart) returns @untainted string {
    var mediaType = mime:getMediaType(bodyPart.getContentType());
    if (mediaType is mime:MediaType) {
        string baseType = mediaType.getBaseType();
        if (mime:APPLICATION_XML == baseType || mime:TEXT_XML == baseType) {
            var payload = bodyPart.getXml();
            if (payload is xml) {
                return payload.toString();
            } else {
                return "error";
            }
        } else if (mime:APPLICATION_JSON == baseType) {
            var payload = bodyPart.getJson();
            if (payload is json) {
                return payload.toJsonString();
            } else {
                return "error";
            }
        } else if (mime:TEXT_PLAIN == baseType) {
            var payload = bodyPart.getText();
            if (payload is string) {
                return payload;
            } else {
                return "error";
            }
        }
    }
    return "error";
}

function getContDisposition(string partName) returns (mime:ContentDisposition) {
    mime:ContentDisposition contentDisposition = new;
    contentDisposition.name = partName;
    contentDisposition.disposition = "form-data";
    return contentDisposition;
}

@test:Config {}
public function testMultipart() {
    http:Client clientEP = new("http://localhost:9100");
    http:Request req = new;
    req.setHeader("priorKnowledge", "false");
    var resp = clientEP->get("/multiparts/initial", req);
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "{\"name\":\"wso2\"}<message>Hello world</message>text content");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testMultipartsWithPriorKnowledge() {
    http:Client clientEP = new("http://localhost:9100");
    http:Request req = new;
    req.setHeader("priorKnowledge", "true");
    var resp = clientEP->get("/multiparts/initial", req);
    if (resp is http:Response) {
        assertTextPayload(resp.getTextPayload(), "{\"name\":\"wso2\"}<message>Hello world</message>text content");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
