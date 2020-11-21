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

listener http:Listener mockEP2 = new(9091);
http:Client multipartRespClient = new("http://localhost:9091");

@http:ServiceConfig {basePath:"/multipart"}
service test2 on mockEP2 {
    @http:ResourceConfig {
        methods:["GET"],
        path:"/encode_out_response"
    }
    resource function multipartOutResponse(http:Caller caller, http:Request request) {

        //Create a body part with json content.
        mime:Entity bodyPart1 = new;
        bodyPart1.setJson({"bodyPart":"jsonPart"});

        //Create another body part with a xml file.
        mime:Entity bodyPart2 = new;
        bodyPart2.setFileAsEntityBody("tests/datafiles/file.xml", mime:TEXT_XML);

        //Create a text body part.
        mime:Entity bodyPart3 = new;
        bodyPart3.setText("Ballerina text body part");

        //Create another body part with a text file.
        mime:Entity bodyPart4 = new;
        bodyPart4.setFileAsEntityBody("tests/datafiles/test.tmp");

        //Create an array to hold all the body parts.
        mime:Entity[] bodyParts = [bodyPart1, bodyPart2, bodyPart3, bodyPart4];

        //Set the body parts to outbound response.
        http:Response outResponse = new;
        string contentType = mime:MULTIPART_MIXED + "; boundary=e3a0b9ad7b4e7cdb";
        outResponse.setBodyParts(bodyParts, contentType);

        checkpanic caller->respond(outResponse);
    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/nested_parts_in_outresponse"
    }
    resource function nestedPartsInOutResponse(http:Caller caller, http:Request request) {
        string contentType = <@untainted string> request.getHeader("content-type");
        http:Response outResponse = new;
        var bodyParts = request.getBodyParts();

        if (bodyParts is mime:Entity[]) {
            outResponse.setBodyParts(<@untainted mime:Entity[]> bodyParts, contentType);
        } else {
            outResponse.setPayload(<@untainted> bodyParts.message());
        }
        checkpanic caller->respond(outResponse);
    }
}

@test:Config {}
function testMultipartsInOutResponse() {
    var response = multipartRespClient->get("/multipart/encode_out_response");
    if (response is http:Response) {
        mime:Entity[]|error bodyParts = response.getBodyParts();
        if (bodyParts is mime:Entity[]) {
            test:assertEquals(bodyParts.length(), 4, msg = errorMessage);
            json|error jsonPart = bodyParts[0].getJson();
            if (jsonPart is json) {
               test:assertEquals(jsonPart.toJsonString(), "{\"" + "bodyPart" + "\":\"" + "jsonPart" + "\"}");
            } else {
               test:assertFail(msg = errorMessage + jsonPart.message());
            }
            xml|error xmlPart = bodyParts[1].getXml();
            if (xmlPart is xml) {
               test:assertEquals(xmlPart.toString(), "<name>Ballerina xml file part</name>");
            } else {
               test:assertFail(msg = errorMessage + xmlPart.message());
            }
            string|error textPart = bodyParts[2].getText();
            if (textPart is string) {
               test:assertEquals(textPart, "Ballerina text body part");
            } else {
               test:assertFail(msg = errorMessage + textPart.message());
            }
            io:ReadableByteChannel|error filePart = bodyParts[3].getByteChannel();
            if (filePart is error) {
               test:assertFail(msg = errorMessage + filePart.message());
            }
        } else {
            test:assertFail(msg = errorMessage + bodyParts.message());
        }
    } else if (response is error) {
        test:assertFail(msg = errorMessage + response.message());
    }
}

@test:Config {}
function testNestedPartsInOutResponse() {
    http:Request request = new;
    request.setBodyParts(createNestedPartRequest(), contentType = mime:MULTIPART_FORM_DATA);
    var response = multipartRespClient->post("/multipart/nested_parts_in_outresponse", request);
    if (response is http:Response) {
        mime:Entity[]|error bodyParts = response.getBodyParts();
        if (bodyParts is mime:Entity[]) {
            test:assertEquals(bodyParts.length(), 1, msg = errorMessage);
            string payload = "";
            int i = 0;
            while (i < bodyParts.length()) {
                mime:Entity part = bodyParts[i];
                payload = handleNestedParts(part);
                i = i + 1;
            }
            test:assertEquals(payload, "Child Part 1Child Part 2", msg = errorMessage);
        } else {
            test:assertFail(msg = errorMessage + bodyParts.message());
        }
    } else if (response is error) {
        test:assertFail(msg = errorMessage + response.message());
    }
}
