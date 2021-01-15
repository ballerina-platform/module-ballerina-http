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
import ballerina/lang.runtime as runtime;
import ballerina/test;
import ballerina/http;

listener http:Listener listenerMethodListener = checkpanic new(listenerMethodTestPort1);
http:Client listenerMethodTestClient = checkpanic new("http://localhost:" + listenerMethodTestPort1.toString());
http:Client backendTestClient = checkpanic new("http://localhost:" + listenerMethodTestPort2.toString());

http:Listener listenerMethodbackendEP = checkpanic new(listenerMethodTestPort2);

boolean listenerIdle = true;
boolean listenerStopped = false;

service /startService on listenerMethodListener {
    resource function get test(http:Caller caller, http:Request req) {
        checkpanic listenerMethodbackendEP.attach(listenerMethodMock1, "mock1");
        checkpanic listenerMethodbackendEP.attach(listenerMethodMock2, "mock2");
        checkpanic listenerMethodbackendEP.start();
        var result = caller->respond("Backend service started!");
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
}

http:Service listenerMethodMock1 = service object {
    resource function get .(http:Caller caller, http:Request req) {
        var responseToCaller = caller->respond("Mock1 invoked!");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
};

http:Service listenerMethodMock2 = service object {
    resource function get .(http:Caller caller, http:Request req) {
        checkpanic listenerMethodbackendEP.gracefulStop();
        runtime:sleep(2);
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

@test:Config {dependsOn:[testServiceAttachAndStart]}
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

@test:Config {dependsOn:[testAvailabilityOfAttachedService]}
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
@test:Config {dependsOn:[testGracefulStopMethod], enable:false}
function testInvokingStoppedService() {
    runtime:sleep(10);
    var response = backendTestClient->get("/mock1");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Mock2 invoked!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
