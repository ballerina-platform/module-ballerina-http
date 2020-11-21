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
import ballerina/runtime;
import ballerina/test;
import ballerina/http;

listener http:Listener listenerMethodListener = new(listenerMethodTestPort1);
http:Client listenerMethodTestClient = new("http://localhost:" + listenerMethodTestPort1.toString());
http:Client backendTestClient = new("http://localhost:" + listenerMethodTestPort2.toString());

http:Listener listenerMethodbackendEP = new(listenerMethodTestPort2);

boolean listenerIdle = true;
boolean listenerStopped = false;

service startService on listenerMethodListener {
    resource function test(http:Caller caller, http:Request req) {
        checkpanic listenerMethodbackendEP.__attach(listenerMethodMock1);
        checkpanic listenerMethodbackendEP.__attach(listenerMethodMock2);
        checkpanic listenerMethodbackendEP.__start();
        var result = caller->respond("Backend service started!");
        if (result is error) {
            log:printError("Error sending response", result);
        }
    }
}

service listenerMethodMock1 =
@http:ServiceConfig {
    basePath: "/mock1"
} service {
    @http:ResourceConfig {
        path: "/"
    }
    resource function mock1(http:Caller caller, http:Request req) {
        var responseToCaller = caller->respond("Mock1 invoked!");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
};

service listenerMethodMock2 =
@http:ServiceConfig {
    basePath: "/mock2"
} service {
    @http:ResourceConfig {
        path: "/"
    }
    resource function mock2(http:Caller caller, http:Request req) {
        checkpanic listenerMethodbackendEP.__gracefulStop();
        runtime:sleep(2000);
        var responseToCaller = caller->respond("Mock2 invoked!");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
};

@test:Config {}
function testServiceAttachAndStart() {
    var response = listenerMethodTestClient->get("/startService/test");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Backend service started!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn:["testServiceAttachAndStart"]}
function testAvailabilityOfAttachedService() {
    var response = backendTestClient->get("/mock1");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Mock1 invoked!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn:["testAvailabilityOfAttachedService"]}
function testGracefulStopMethod() {
    var response = backendTestClient->get("/mock2");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Mock2 invoked!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25675
@test:Config {dependsOn:["testGracefulStopMethod"], enable:false}
function testInvokingStoppedService() {
    runtime:sleep(10000);
    var response = backendTestClient->get("/mock1");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Mock2 invoked!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
