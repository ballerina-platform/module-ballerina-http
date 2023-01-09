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

configurable string keystore = ?;
configurable string truststore = ?;

listener http:Listener echoServiceTestListenerEP = new (echoServiceTestPort, httpVersion = http:HTTP_1_1);
final http:Client echoServiceClient = check new ("http://localhost:" + echoServiceTestPort.toString(), httpVersion = http:HTTP_1_1);

http:ListenerConfiguration echoHttpsServiceTestListenerEPConfig = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: keystore,
            password: "ballerina"
        }
    }
};

listener http:Listener echoHttpsServiceTestListenerEP = new (echoHttpsServiceTestPort, echoHttpsServiceTestListenerEPConfig);

http:ClientConfiguration echoHttpsServiceClientConfig = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        cert: {
            path: truststore,
            password: "ballerina"
        }
    }
};
final http:Client echoHttpsServiceClient = check new ("https://localhost:" + echoHttpsServiceTestPort.toString(), echoHttpsServiceClientConfig);

service /echoServiceTest1 on echoServiceTestListenerEP {

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
            if responseError is error {
                // log:printError("Error sending response", 'error = responseError);
            }
        }
    }
}

service /echoServiceTest1One on echoServiceTestListenerEP, echoHttpsServiceTestListenerEP {

    resource function post abc(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("hello world");
        check caller->respond(res);
    }
}

service /echoServiceTest1 on echoHttpsServiceTestListenerEP {

    resource function post .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("hello world");
        check caller->respond(res);
    }
}

//Test echo service sample test case invoking base path
@test:Config {}
function testEchoServiceByBasePath() returns error? {
    http:Request req = new;
    string requestMessage = "{\"exchange\":\"nyse\",\"name\":\"WSO2\",\"value\":\"127.50\"}";
    req.setTextPayload(requestMessage);
    http:Response|error response = echoServiceClient->post("/echoServiceTest1", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), requestMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test echo service sample test case invoking base path
@test:Config {}
function testEchoServiceWithDynamicPortShared() returns error? {
    http:Request req = new;
    req.setJsonPayload({key: "value"});
    http:Response|error response = echoServiceClient->post("/echoServiceTest1One/abc", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "hello world");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test echo service with dynamic port and scheme https
@test:Config {}
function testEchoServiceWithDynamicPortHttpsByBasePath() returns error? {
    http:Request req = new;
    req.setJsonPayload({key: "value"});
    http:Response|error response = echoHttpsServiceClient->post("/echoServiceTest1", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "hello world");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test echo service with dynamic port and scheme https with port shared
@test:Config {}
function testEchoServiceWithDynamicPortHttpsShared() returns error? {
    http:Request req = new;
    req.setJsonPayload({key: "value"});
    http:Response|error response = echoHttpsServiceClient->post("/echoServiceTest1One/abc", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "hello world");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
