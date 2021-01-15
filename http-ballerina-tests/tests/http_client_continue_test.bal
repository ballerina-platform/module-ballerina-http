// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/log;
import ballerina/test;
import ballerina/http;

listener http:Listener httpClientContinueListenerEP1 = checkpanic new(httpClientContinueTestPort1);
listener http:Listener httpClientContinueListenerEP2 = checkpanic new(httpClientContinueTestPort2);
http:Client httpClientContinueClient = checkpanic new("http://localhost:" + httpClientContinueTestPort2.toString());

http:Client continueClient = checkpanic new("http://localhost:" + httpClientContinueTestPort1.toString(), { cache: { enabled: false }});

service /'continue on httpClientContinueListenerEP1 {

    resource function 'default .(http:Caller caller, http:Request request) {
        if (request.expects100Continue()) {
            string mediaType = request.getHeader("Content-Type");
            if (mediaType.toLowerAscii() == "text/plain") {
                var result = caller->continue();
                if (result is error) {
                    log:printError("Error sending response", err = result);
                }
            } else {
                http:Response res = new;
                res.statusCode = 417;
                res.setPayload("Unprocessable Entity");
                var result = caller->respond(res);
                if (result is error) {
                    log:printError("Error sending response", err = result);
                }
                return;
            }
        }
        http:Response res = new;
        var payload = request.getTextPayload();
        if (payload is string) {
            log:print(payload);
            res.statusCode = 200;
            res.setPayload("Hello World!\n");
            var result = caller->respond(res);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        } else {
            res.statusCode = 500;
            res.setPayload(<@untainted> payload.message());
            var result = caller->respond(res);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        }
    }
}

service /'continue on httpClientContinueListenerEP2  {

    resource function get .(http:Caller caller, http:Request req) {
        req.addHeader("content-type", "text/plain");
        req.addHeader("Expect", "100-continue");
        req.setPayload("Hi");
        var response = continueClient->post("/continue", <@untainted> req);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            checkpanic caller->respond("Error: " + <@untainted> (<error>response).toString());
        }
    }

    resource function get failure(http:Caller caller, http:Request req) {
        req.addHeader("Expect", "100-continue");
        req.addHeader("content-type", "application/json");
        req.setPayload({ name: "apple", color: "red" });
        var response = continueClient->post("/continue", <@untainted> req);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            checkpanic caller->respond("Error: " + <@untainted> (<error>response).toString());
        }
    }
}

//Test 100 continue for http client
@test:Config {}
function testContinueAction() {
    var response = httpClientContinueClient->get("/continue");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!\n");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Negative test case for 100 continue of http client
@test:Config {dependsOn:["testContinueAction"]}
function testNegativeContinueAction() {
    var response = httpClientContinueClient->get("/continue/failure");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 417, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn:["testNegativeContinueAction"]}
function testContinueActionWithMain() {
    http:Client clientEP = checkpanic new("http://localhost:" + httpClientContinueTestPort1.toString());
    http:Request req = new();
    req.addHeader("content-type", "text/plain");
    req.addHeader("Expect", "100-continue");
    req.setPayload("Hello World!");
    var response = clientEP->post("/continue", req);
    if (response is http:Response) {
        var payload = response.getTextPayload();
        if (payload is string) {
            test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
            assertTextPayload(response.getTextPayload(), "Hello World!\n");
        } else {
            test:assertFail(msg = "Found unexpected output type: " + payload.message());
        }
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
