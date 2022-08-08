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

// import ballerina/log;
import ballerina/test;
import ballerina/http;

listener http:Listener httpClientContinueListenerEP1 = new(httpClientContinueTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener httpClientContinueListenerEP2 = new(httpClientContinueTestPort2, httpVersion = http:HTTP_1_1);
final http:Client httpClientContinueClient = check new("http://localhost:" + httpClientContinueTestPort2.toString(), 
    httpVersion = http:HTTP_1_1);

final http:Client continueClient = check new("http://localhost:" + httpClientContinueTestPort1.toString(), 
    httpVersion = http:HTTP_1_1, cache = { enabled: false });

service /'continue on httpClientContinueListenerEP1 {

    resource function 'default .(http:Caller caller, http:Request request) returns error? {
        if request.expects100Continue() {
            string mediaType = check request.getHeader("Content-Type");
            if mediaType.toLowerAscii() == "text/plain" {
                error? result = caller->continue();
                if result is error {
                    // log:printError("Error sending response", 'error = result);
                }
            } else {
                http:Response res = new;
                res.statusCode = 417;
                res.setPayload("Unprocessable Entity");
                error? result = caller->respond(res);
                if result is error {
                    // log:printError("Error sending response", 'error = result);
                }
                return;
            }
        }
        http:Response res = new;
        var payload = request.getTextPayload();
        if payload is string {
            res.statusCode = 200;
            res.setPayload("Hello World!\n");
            error? result = caller->respond(res);
            if result is error {
                // log:printError("Error sending response", 'error = result);
            }
        } else {
            res.statusCode = 500;
            res.setPayload(payload.message());
            error? result = caller->respond(res);
            if result is error {
                // log:printError("Error sending response", 'error = result);
            }
        }
    }
}

service /'continue on httpClientContinueListenerEP2  {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        req.addHeader("content-type", "text/plain");
        req.addHeader("Expect", "100-continue");
        req.setPayload("Hi");
        http:Response|error response = continueClient->post("/continue", req);
        if response is http:Response {
            check caller->respond(response);
        } else {
            check caller->respond("Error: " + response.toString());
        }
    }

    resource function get failure(http:Caller caller, http:Request req) returns error? {
        req.addHeader("Expect", "100-continue");
        req.addHeader("content-type", "application/json");
        req.setPayload({ name: "apple", color: "red" });
        http:Response|error response = continueClient->post("/continue", req);
        if response is http:Response {
            check caller->respond(response);
        } else {
            check caller->respond("Error: " + response.toString());
        }
    }
}
@test:Config {}
function testContinueActionWithMain() returns error? {
    http:Client clientEP = check new("http://localhost:" + httpClientContinueTestPort1.toString(), httpVersion = http:HTTP_1_1);
    http:Request req = new();
    req.addHeader("content-type", "text/plain");
    req.addHeader("Expect", "100-continue");
    req.setPayload("Hello World!");
    http:Response|error response = clientEP->post("/continue", req);
    if response is http:Response {
        var payload = response.getTextPayload();
        if payload is string {
            test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
            assertTextPayload(response.getTextPayload(), "Hello World!\n");
        } else {
            test:assertFail(msg = "Found unexpected output type: " + payload.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test 100 continue for http client
@test:Config {dependsOn:[testContinueActionWithMain]}
function testContinueAction() returns error? {
    http:Response|error response = httpClientContinueClient->get("/continue");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!\n");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Negative test case for 100 continue of http client
@test:Config {dependsOn:[testContinueAction]}
function testNegativeContinueAction() returns error? {
    http:Response|error response = httpClientContinueClient->get("/continue/failure");
    if response is http:Response {
        test:assertEquals(response.statusCode, 417, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
