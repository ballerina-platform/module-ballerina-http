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

// import ballerina/log;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

// listener http:Listener echoEP1 = new(9094, {server: "Mysql"});

listener http:Listener httpServerFieldListenerEP1 = new (httpServerFieldTestPort1, server = "Mysql", httpVersion = http:HTTP_1_1);
final http:Client httpServerFieldClient = check new ("http://localhost:" + httpServerFieldTestPort1.toString(), httpVersion = http:HTTP_1_1);

service /httpServerFieldEcho1 on httpServerFieldListenerEP1 {

    resource function post .(http:Caller caller, http:Request req) returns error? {
        var payload = req.getTextPayload();
        http:Response resp = new;
        if payload is string {
            check caller->respond(payload);
        } else {
            resp.statusCode = 500;
            resp.setPayload(payload.message());
            // log:printError("Failed to retrieve payload from request: " + payload.message());
            var responseError = caller->respond(resp);
            if (responseError is error) {
                // log:printError("Error sending response", 'error = responseError);
            }
        }
    }
}

//Test server name in the successful response
@test:Config {}
function testHeaderServerFromSuccessResponse() {
    http:Response|error response = httpServerFieldClient->post("/httpServerFieldEcho1", "{\"exchange\":\"nyse\",\"name\":\"WSO2\",\"value\":\"127.50\"}");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        test:assertEquals(response.server, "Mysql");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test server name in the successful response
@test:Config {}
function testSetServerHeaderManuallyFromSuccessResponse() {
    http:Request req = new;
    req.setHeader(common:SERVER, "JMS");
    req.setTextPayload("{\"exchange\":\"nyse\",\"name\":\"WSO2\",\"value\":\"127.50\"}");
    http:Response|error response = httpServerFieldClient->post("/httpServerFieldEcho1", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        test:assertEquals(response.server, "Mysql");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test header server name in the unsuccessful response
@test:Config {}
function testHeaderServerFromUnSuccessResponse() {
    http:Response|error response = httpServerFieldClient->get("/httpServerFieldEcho1");
    if response is http:Response {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
        test:assertEquals(response.server, "Mysql");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test header server name in the unsuccessful response
@test:Config {}
function testHeaderServerFromUnSuccessResponse1() {
    http:Request req = new;
    req.setTextPayload("{\"exchange\":\"nyse\",\"name\":\"WSO2\",\"value\":\"127.50\"}");
    http:Response|error response = httpServerFieldClient->post("/ec/ho", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        test:assertEquals(response.server, "Mysql");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test header server name in the successful response calling echoServiceTest1 service in echo-service-sample-test.bal
@test:Config {}
function testDefaultHeaderServerFromSuccessResponse() {
    http:Request req = new;
    string requestMessage = "{\"exchange\":\"nyse\",\"name\":\"WSO2\",\"value\":\"127.50\"}";
    req.setTextPayload(requestMessage);
    http:Response|error response = echoServiceClient->post("/echoServiceTest1", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        test:assertEquals(response.server, "ballerina");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test header server name in the unsuccessful response calling echoServiceTest1 service in echo-service-sample-test.bal
@test:Config {}
function testDefaultHeaderServerFromUnSuccessResponse() {
    http:Response|error response = echoServiceClient->get("/echoServiceTest1");
    if response is http:Response {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
        test:assertEquals(response.server, "ballerina");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test header server name in the unsuccessful response calling echoServiceTest1 service in echo-service-sample-test.bal
@test:Config {}
function testDefaultHeaderServerFromUnSuccessResponse1() {
    http:Request req = new;
    string requestMessage = "{\"exchange\":\"nyse\",\"name\":\"WSO2\",\"value\":\"127.50\"}";
    req.setTextPayload(requestMessage);
    http:Response|error response = echoServiceClient->post("/ec/ho", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        test:assertEquals(response.server, "ballerina");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
