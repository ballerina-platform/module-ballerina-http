// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/lang.'string as strings;
import ballerina/mime;
import ballerina/test;
import ballerina/http_test_common as common;

listener http:Listener passthroughEP1 = new (9113, httpVersion = http:HTTP_1_1);

service /passthrough on passthroughEP1 {

    resource function get .(http:Caller caller, http:Request clientRequest) returns error? {
        http:Client nyseEP1 = check new ("http://localhost:9113", httpVersion = http:HTTP_1_1);
        http:Response|error response = nyseEP1->post("/nyseStock/stocks", clientRequest);
        if response is http:Response {
            check caller->respond(response);
        } else {
            check caller->respond({"error": "error occurred while invoking the service"});
        }
    }

    resource function post forwardMultipart(http:Caller caller, http:Request clientRequest) returns error? {
        http:Client nyseEP1 = check new ("http://localhost:9113", httpVersion = http:HTTP_1_1);
        http:Response|error response = nyseEP1->forward("/nyseStock/stocksAsMultiparts", clientRequest);
        if response is http:Response {
            check caller->respond(response);
        } else {
            check caller->respond({"error": "error occurred while invoking the service"});
        }
    }

    resource function post forward(http:Request clientRequest) returns http:Ok|http:InternalServerError|error {
        http:Client nyseEP1 = check new ("http://localhost:9113", httpVersion = http:HTTP_1_1);
        http:Response|error response = nyseEP1->forward("/nyseStock/entityCheck", clientRequest);
        if response is http:Response {
            var entity = response.getEntity();
            if entity is mime:Entity {
                string|error payload = entity.getText();
                if payload is string {
                    http:Ok ok = {body: payload + ", " + check entity.getHeader("X-check-header")};
                    return ok;
                } else {
                    http:InternalServerError err = {body: payload.toString()};
                    return err;
                }
            } else {
                http:InternalServerError err = {body: entity.toString()};
                return err;
            }
        } else {
            http:InternalServerError err = {body: response.toString()};
            return err;
        }
    }
}

service /nyseStock on passthroughEP1 {

    resource function post stocks(http:Caller caller, http:Request clientRequest) returns error? {
        check caller->respond({"exchange": "nyse", "name": "IBM", "value": "127.50"});
    }

    resource function post stocksAsMultiparts(http:Caller caller, http:Request clientRequest) returns error? {
        var bodyParts = clientRequest.getBodyParts();
        if bodyParts is mime:Entity[] {
            check caller->respond(bodyParts);
        } else {
            check caller->respond(bodyParts.message());
        }
    }

    resource function post entityCheck(http:Request clientRequest)
            returns http:InternalServerError|http:Response|error {
        http:Response res = new;
        var entity = clientRequest.getEntity();
        if entity is mime:Entity {
            json|error textPayload = entity.getText();
            if textPayload is string {
                mime:Entity ent = new;
                ent.setText("payload :" + textPayload + ", header: " + check entity.getHeader("Content-type"));
                ent.setHeader("X-check-header", "entity-check-header");
                res.setEntity(ent);
                return res;
            } else {
                return {body: "Error while retrieving from entity"};
            }
        } else {
            return {body: "Error while retrieving from request"};
        }
    }
}

@test:Config {}
public function testPassthroughServiceByBasePath() returns error? {
    http:Client httpClient = check new ("http://localhost:9113", httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->get("/passthrough");
    if resp is http:Response {
        string contentType = check resp.getHeader("content-type");
        test:assertEquals(contentType, "application/json");
        var body = resp.getJsonPayload();
        if body is json {
            test:assertEquals(body.toJsonString(), "{\"exchange\":\"nyse\", \"name\":\"IBM\", \"value\":\"127.50\"}");
        } else {
            test:assertFail(msg = "Found unexpected output: " + body.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testPassthroughServiceWithMimeEntity() returns error? {
    http:Client httpClient = check new ("http://localhost:9113", httpVersion = http:HTTP_1_1);
    http:Response|error resp = httpClient->post("/passthrough/forward", "Hello from POST!");
    if resp is http:Response {
        string contentType = check resp.getHeader("content-type");
        test:assertEquals(contentType, "text/plain");
        var body = resp.getTextPayload();
        if body is string {
            test:assertEquals(body, "payload :Hello from POST!, header: text/plain, entity-check-header");
        } else {
            test:assertFail(msg = "Found unexpected output: " + body.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testPassthroughWithMultiparts() returns error? {
    http:Client httpClient = check new ("http://localhost:9113", httpVersion = http:HTTP_1_1);
    mime:Entity textPart1 = new;
    textPart1.setText("Part1");
    textPart1.setHeader("Content-Type", "text/plain; charset=UTF-8");

    mime:Entity textPart2 = new;
    textPart2.setText("Part2");
    textPart2.setHeader("Content-Type", "text/plain");

    mime:Entity[] bodyParts = [textPart1, textPart2];
    http:Request request = new;
    request.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
    http:Response|error resp = httpClient->post("/passthrough/forwardMultipart", request);
    if resp is http:Response {
        string contentType = check resp.getHeader("content-type");
        test:assertTrue(strings:includes(contentType, "multipart/form-data"));
        var respBodyParts = resp.getBodyParts();
        if respBodyParts is mime:Entity[] {
            test:assertEquals(respBodyParts.length(), 2);
            string|error textPart = respBodyParts[0].getText();
            if textPart is string {
                test:assertEquals(textPart, "Part1");
            } else {
                test:assertFail(msg = common:errorMessage + textPart.message());
            }
            string|error txtPart2 = respBodyParts[1].getText();
            if txtPart2 is string {
                test:assertEquals(txtPart2, "Part2");
            } else {
                test:assertFail(msg = common:errorMessage + txtPart2.message());
            }
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}
