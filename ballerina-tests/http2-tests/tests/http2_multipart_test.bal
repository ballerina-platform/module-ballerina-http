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
// import ballerina/log;
import ballerina/mime;
import ballerina/test;
import ballerina/http_test_common as common;

final http:Client mimeClientEP1 = check new ("http://localhost:9100");
final http:Client mimeClientEP2 = check new ("http://localhost:9100");
final http:Client priorKnowclientEP1 = check new ("http://localhost:9100", http2Settings = {http2PriorKnowledge: true});
final http:Client priorKnowclientEP2 = check new ("http://localhost:9100", http2Settings = {http2PriorKnowledge: true});

service /multiparts on generalHTTP2Listener {

    resource function post decode(http:Caller caller, http:Request request) {
        http:Response response = new;
        mime:Entity[] respBodyParts = [];
        var bodyParts = request.getBodyParts();
        int i = 0;
        if bodyParts is mime:Entity[] {
            foreach var part in bodyParts {
                respBodyParts[i] = handleRespContent(part);
                i = i + 1;
            }
            response.setBodyParts(respBodyParts);
        } else {
            // log:printError(bodyParts.message());
            response.setPayload("Error in decoding multiparts!");
            response.statusCode = 500;
        }
        error? result = caller->respond(response);
        if result is error {
            // log:printError("Error sending response", 'error = result);
        }
    }

    resource function get initial(http:Caller caller, http:Request request) returns error? {
        http:Response|error finalResponse;
        if check request.getHeader("priorKnowledge") == "true" {
            finalResponse = priorKnowclientEP2->get("/multiparts/encode", {"priorKnowledge": "true"});
        } else {
            finalResponse = mimeClientEP2->get("/multiparts/encode", {"priorKnowledge": "false"});
        }
        if finalResponse is http:Response {
            var respBodyParts = finalResponse.getBodyParts();
            string finalMessage = "";
            if respBodyParts is mime:Entity[] {
                foreach var part in respBodyParts {
                    finalMessage = finalMessage + handleResponseBodyParts(part);
                }
            }
            check caller->respond(finalMessage);
        } else {
            // log:printError("Error sending response", 'error = finalResponse);
        }
    }

    resource function get encode(http:Caller caller, http:Request req) returns error? {
        mime:Entity jsonBodyPart = new;
        jsonBodyPart.setContentDisposition(getContDisposition("json part"));
        jsonBodyPart.setJson({"name": "wso2"});
        mime:Entity xmlFilePart = new;
        xmlFilePart.setContentDisposition(getContDisposition("xml file part"));
        xmlFilePart.setFileAsEntityBody(common:HTTP2_XML_FILE,
                                        contentType = mime:APPLICATION_XML);
        mime:Entity textPart = new;
        textPart.setText("text content", contentType = "text/plain");
        mime:Entity[] bodyParts = [jsonBodyPart, xmlFilePart, textPart];
        http:Request request = new;
        request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
        http:Response|error returnResponse;
        if check req.getHeader("priorKnowledge") == "true" {
            returnResponse = priorKnowclientEP1->post("/multiparts/decode", request);
        } else {
            returnResponse = mimeClientEP1->post("/multiparts/decode", request);
        }
        if returnResponse is http:Response {
            error? result = caller->respond(returnResponse);
            if result is error {
                // log:printError("Error sending response", 'error = result);
            }
        } else {
            http:Response response = new;
            response.setPayload("Error occurred while sending multipart request!");
            response.statusCode = 500;
            error? result = caller->respond(response);
            if result is error {
                // log:printError("Error sending response", 'error = result);
            }
        }
    }
}

isolated function handleRespContent(mime:Entity bodyPart) returns mime:Entity {
    mime:Entity jsonPart = new;
    mime:Entity xmlPart = new;
    mime:Entity textPart = new;
    var mediaType = mime:getMediaType(bodyPart.getContentType());
    if mediaType is mime:MediaType {
        string baseType = mediaType.getBaseType();
        if mime:APPLICATION_XML == baseType || mime:TEXT_XML == baseType {
            var payload = bodyPart.getXml();
            if payload is xml {
                xmlPart.setXml(payload, contentType = "application/xml");
                return xmlPart;
            } else {
                xmlPart.setXml(xml `<message>error</message>`, contentType = "application/xml");
                return xmlPart;
            }
        } else if mime:APPLICATION_JSON == baseType {
            var payload = bodyPart.getJson();
            if payload is json {
                jsonPart.setJson(payload, contentType = "application/json");
                return jsonPart;
            } else {
                jsonPart.setJson("error", contentType = "application/json");
                return jsonPart;
            }
        } else if mime:TEXT_PLAIN == baseType {
            var payload = bodyPart.getText();
            if payload is string {
                textPart.setText(payload, contentType = "text/plain");
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

isolated function handleResponseBodyParts(mime:Entity bodyPart) returns string {
    var mediaType = mime:getMediaType(bodyPart.getContentType());
    if mediaType is mime:MediaType {
        string baseType = mediaType.getBaseType();
        if mime:APPLICATION_XML == baseType || mime:TEXT_XML == baseType {
            var payload = bodyPart.getXml();
            if payload is xml {
                return payload.toString();
            } else {
                return "error";
            }
        } else if mime:APPLICATION_JSON == baseType {
            var payload = bodyPart.getJson();
            if payload is json {
                return payload.toJsonString();
            } else {
                return "error";
            }
        } else if mime:TEXT_PLAIN == baseType {
            var payload = bodyPart.getText();
            if payload is string {
                return payload;
            } else {
                return "error";
            }
        }
    }
    return "error";
}

isolated function getContDisposition(string partName) returns (mime:ContentDisposition) {
    mime:ContentDisposition contentDisposition = new;
    contentDisposition.name = partName;
    contentDisposition.disposition = "form-data";
    return contentDisposition;
}

@test:Config {}
public function testMultipart() returns error? {
    http:Client clientEP = check new ("http://localhost:9100");
    http:Response|error resp = clientEP->get("/multiparts/initial", {"priorKnowledge": "false"});
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "{\"name\":\"wso2\"}<message>Hello world</message>text content");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testMultipartsWithPriorKnowledge() returns error? {
    http:Client clientEP = check new ("http://localhost:9100");
    http:Response|error resp = clientEP->get("/multiparts/initial", {"priorKnowledge": "true"});
    if resp is http:Response {
        common:assertTextPayload(resp.getTextPayload(), "{\"name\":\"wso2\"}<message>Hello world</message>text content");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}
