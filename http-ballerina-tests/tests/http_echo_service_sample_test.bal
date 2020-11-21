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

import ballerina/config;
import ballerina/log;
import ballerina/test;
import ballerina/http;

listener http:Listener echoServiceTestListenerEP = new(echoServiceTestPort);
http:Client echoServiceClient = new("http://localhost:" + echoServiceTestPort.toString());

http:ListenerConfiguration echoHttpsServiceTestListenerEPConfig = {
    secureSocket: {
        keyStore: {
            path: config:getAsString("keystore"),
            password: "ballerina"
        }
    }
};

listener http:Listener echoHttpsServiceTestListenerEP = new(echoHttpsServiceTestPort, echoHttpsServiceTestListenerEPConfig);

http:ClientConfiguration echoHttpsServiceClientConfig = {
    secureSocket: {
        trustStore: {
            path: config:getAsString("truststore"),
            password: "ballerina"
        }
    }
};
http:Client echoHttpsServiceClient = new("https://localhost:" + echoHttpsServiceTestPort.toString(), echoHttpsServiceClientConfig);

@http:ServiceConfig {
    basePath:"/echo"
}
service echoServiceTest1 on echoServiceTestListenerEP {

    @http:ResourceConfig {
        methods:["POST"],
        path:"/"
    }
    resource function echo1 (http:Caller caller, http:Request req) {
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
                log:printError("Error sending response", <error> responseError);
            }
        }
    }
}

@http:ServiceConfig {
    basePath:"/echoOne"
}
service echoServiceTest2 on echoServiceTestListenerEP, echoHttpsServiceTestListenerEP {
    @http:ResourceConfig {
        methods:["POST"],
        path:"/abc"
    }
    resource function echoAbc (http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("hello world");
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {
    basePath:"/echo"
}

service echo2 on echoHttpsServiceTestListenerEP {
    @http:ResourceConfig {
        methods:["POST"],
        path:"/"
    }
    resource function echo2(http:Caller caller, http:Request req) {
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
    var response = echoServiceClient->post("/echo", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), requestMessage);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test echo service sample test case invoking base path
@test:Config {}
function testEchoServiceWithDynamicPortShared() {
    http:Request req = new;
    req.setJsonPayload({key:"value"});
    var response = echoServiceClient->post("/echoOne/abc", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hello world");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test echo service with dynamic port and scheme https
@test:Config {}
function testEchoServiceWithDynamicPortHttpsByBasePath() {
    http:Request req = new;
    req.setJsonPayload({key:"value"});
    var response = echoHttpsServiceClient->post("/echo", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hello world");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test echo service with dynamic port and scheme https with port shared
@test:Config {}
function testEchoServiceWithDynamicPortHttpsShared() {
    http:Request req = new;
    req.setJsonPayload({key:"value"});
    var response = echoHttpsServiceClient->post("/echoOne/abc", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hello world");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
