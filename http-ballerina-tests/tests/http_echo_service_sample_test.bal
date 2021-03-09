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

import ballerina/log;
import ballerina/test;
import ballerina/http;

configurable string keystore = ?;
configurable string truststore = ?;

listener http:Listener echoServiceTestListenerEP = new(echoServiceTestPort);
http:Client echoServiceClient = check new("http://localhost:" + echoServiceTestPort.toString());

http:ListenerConfiguration echoHttpsServiceTestListenerEPConfig = {
    secureSocket: {
        key: {
            path: keystore,
            password: "ballerina"
        }
    }
};

listener http:Listener echoHttpsServiceTestListenerEP = new(echoHttpsServiceTestPort, echoHttpsServiceTestListenerEPConfig);

http:ClientConfiguration echoHttpsServiceClientConfig = {
    secureSocket: {
        cert: {
            path: truststore,
            password: "ballerina"
        }
    }
};
http:Client echoHttpsServiceClient = check new("https://localhost:" + echoHttpsServiceTestPort.toString(), echoHttpsServiceClientConfig);

service /echoServiceTest1 on echoServiceTestListenerEP {

    resource function post .(http:Caller caller, http:Request req) {
        var payload = req.getTextPayload();
        http:Response resp = new;
        if (payload is string) {
            checkpanic caller->respond(<@untainted> payload);
        } else {
            resp.statusCode = 500;
            resp.setPayload(<@untainted> payload.message());
            log:printError("Failed to retrieve payload from request: " + payload.message());
            var responseError = caller->respond(resp);
            if (responseError is error) {
                log:printError("Error sending response", err = responseError);
            }
        }
    }
}

service /echoServiceTest1One on echoServiceTestListenerEP, echoHttpsServiceTestListenerEP {

    resource function post abc(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("hello world");
        checkpanic caller->respond(res);
    }
}

service /echoServiceTest1 on echoHttpsServiceTestListenerEP {

    resource function post .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("hello world");
        checkpanic caller->respond(res);
    }
}

//Test echo service sample test case invoking base path
@test:Config {}
function testEchoServiceByBasePath() {
    http:Request req = new;
    string requestMessage = "{\"exchange\":\"nyse\",\"name\":\"WSO2\",\"value\":\"127.50\"}";
    req.setTextPayload(requestMessage);
    var response = echoServiceClient->post("/echoServiceTest1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), requestMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test echo service sample test case invoking base path
@test:Config {}
function testEchoServiceWithDynamicPortShared() {
    http:Request req = new;
    req.setJsonPayload({key:"value"});
    var response = echoServiceClient->post("/echoServiceTest1One/abc", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hello world");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test echo service with dynamic port and scheme https
@test:Config {}
function testEchoServiceWithDynamicPortHttpsByBasePath() {
    http:Request req = new;
    req.setJsonPayload({key:"value"});
    var response = echoHttpsServiceClient->post("/echoServiceTest1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hello world");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test echo service with dynamic port and scheme https with port shared
@test:Config {}
function testEchoServiceWithDynamicPortHttpsShared() {
    http:Request req = new;
    req.setJsonPayload({key:"value"});
    var response = echoHttpsServiceClient->post("/echoServiceTest1One/abc", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hello world");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
