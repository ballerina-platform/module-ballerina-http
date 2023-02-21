// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/io;
import ballerina/mime;
import ballerina/test;
import ballerina/http_test_common as common;

listener http:Listener mockEP2 = new (9091, httpVersion = http:HTTP_1_1);
final http:Client multipartRespClient = check new ("http://localhost:9091", httpVersion = http:HTTP_1_1);

service /multipart on mockEP2 {
    resource function get encode_out_response(http:Caller caller, http:Request request) returns error? {

        //Create a body part with json content.
        mime:Entity bodyPart1 = new;
        bodyPart1.setJson({"bodyPart": "jsonPart"});

        //Create another body part with a xml file.
        mime:Entity bodyPart2 = new;
        bodyPart2.setFileAsEntityBody(common:XML_FILE, mime:TEXT_XML);

        //Create a text body part.
        mime:Entity bodyPart3 = new;
        bodyPart3.setText("Ballerina text body part");

        //Create another body part with a text file.
        mime:Entity bodyPart4 = new;
        bodyPart4.setFileAsEntityBody(common:TMP_FILE);

        //Create an array to hold all the body parts.
        mime:Entity[] bodyParts = [bodyPart1, bodyPart2, bodyPart3, bodyPart4];

        //Set the body parts to outbound response.
        http:Response outResponse = new;
        string contentType = mime:MULTIPART_MIXED + "; boundary=e3a0b9ad7b4e7cdb";
        outResponse.setBodyParts(bodyParts, contentType);

        check caller->respond(outResponse);
    }

    resource function post nested_parts_in_outresponse(http:Caller caller, http:Request request) returns error? {
        string contentType = check request.getHeader("content-type");
        http:Response outResponse = new;
        var bodyParts = request.getBodyParts();

        if bodyParts is mime:Entity[] {
            outResponse.setBodyParts(bodyParts, contentType);
        } else {
            outResponse.setPayload(bodyParts.message());
        }
        check caller->respond(outResponse);
    }

    resource function get boundaryCheck(http:Caller caller) returns error? {
        mime:Entity bodyPart1 = new;
        bodyPart1.setJson({"bodyPart": "jsonPart"});
        mime:Entity[] bodyParts = [bodyPart1];

        //Set the body parts to outbound response.
        http:Response outResponse = new;
        string contentType = mime:MULTIPART_MIXED + "; boundary=\"------=_Part_0_814051860.1675096572056\"";
        outResponse.setBodyParts(bodyParts, contentType);
        check caller->respond(outResponse);
    }
}

@test:Config {}
function testMultipartsInOutResponse() {
    http:Response|error response = multipartRespClient->get("/multipart/encode_out_response");
    if response is http:Response {
        mime:Entity[]|error bodyParts = response.getBodyParts();
        if bodyParts is mime:Entity[] {
            test:assertEquals(bodyParts.length(), 4, msg = common:errorMessage);
            json|error jsonPart = bodyParts[0].getJson();
            if jsonPart is json {
                test:assertEquals(jsonPart.toJsonString(), "{\"" + "bodyPart" + "\":\"" + "jsonPart" + "\"}");
            } else {
                test:assertFail(msg = common:errorMessage + jsonPart.message());
            }
            xml|error xmlPart = bodyParts[1].getXml();
            if xmlPart is xml {
                test:assertEquals(xmlPart.toString(), "<name>Ballerina xml file part</name>");
            } else {
                test:assertFail(msg = common:errorMessage + xmlPart.message());
            }
            string|error textPart = bodyParts[2].getText();
            if textPart is string {
                test:assertEquals(textPart, "Ballerina text body part");
            } else {
                test:assertFail(msg = common:errorMessage + textPart.message());
            }
            stream<byte[], io:Error?>|error filePart = bodyParts[3].getByteStream();
            if filePart is error {
                test:assertFail(msg = common:errorMessage + filePart.message());
            }
        } else {
            test:assertFail(msg = common:errorMessage + bodyParts.message());
        }
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testNestedPartsInOutResponse() {
    http:Request request = new;
    request.setBodyParts(createNestedPartRequest(), contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error response = multipartRespClient->post("/multipart/nested_parts_in_outresponse", request);
    if response is http:Response {
        mime:Entity[]|error bodyParts = response.getBodyParts();
        if bodyParts is mime:Entity[] {
            test:assertEquals(bodyParts.length(), 1, msg = common:errorMessage);
            string payload = "";
            int i = 0;
            while (i < bodyParts.length()) {
                mime:Entity part = bodyParts[i];
                payload = handleNestedParts(part);
                i = i + 1;
            }
            test:assertEquals(payload, "Child Part 1Child Part 2", msg = common:errorMessage);
        } else {
            test:assertFail(msg = common:errorMessage + bodyParts.message());
        }
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}

@test:Config {}
function testMultipartsOutResponseWithDoubleQuotes() {
    http:Response|error response = multipartRespClient->get("/multipart/boundaryCheck");
    if response is http:Response {
        mime:Entity[]|error bodyParts = response.getBodyParts();
        if bodyParts is mime:Entity[] {
            test:assertEquals(bodyParts.length(), 1, msg = common:errorMessage);
            json|error jsonPart = bodyParts[0].getJson();
            if jsonPart is json {
                test:assertEquals(jsonPart.toJsonString(), "{\"" + "bodyPart" + "\":\"" + "jsonPart" + "\"}");
            } else {
                test:assertFail(msg = common:errorMessage + jsonPart.message());
            }
        } else {
            test:assertFail(msg = common:errorMessage + bodyParts.message());
        }
    } else {
        test:assertFail(msg = common:errorMessage + response.message());
    }
}
