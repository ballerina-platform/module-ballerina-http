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

listener http:Listener listenerMethodListener = new(listenerMethodTestPort1);
final http:Client listenerMethodTestClient = check new("http://localhost:" + listenerMethodTestPort1.toString());
final http:Client backendTestClient = check new("http://localhost:" + listenerMethodTestPort2.toString());

isolated http:Listener listenerMethodbackendEP = check new(listenerMethodTestPort2);

boolean listenerIdle = true;
boolean listenerStopped = false;

service /startService on listenerMethodListener {
    resource function get test(http:Caller remoteCaller) {
        lock {
            http:Service listenerMethodMock1 = service object {
                resource function get .(http:Caller caller, http:Request req) {
                    error? responseToCaller = caller->respond("Mock1 invoked!");
                    if (responseToCaller is error) {
                        log:printError("Error sending response from mock service", 'error = responseToCaller);
                    }
                }
            };
            checkpanic listenerMethodbackendEP.attach(listenerMethodMock1, "mock1");
        }

        lock {
            http:Service listenerMethodMock2 = service object {
                resource function get .(http:Caller caller, http:Request req) {
                    // gracefulStop will unbind the listener port and stop accepting new connections.
                    // But already connection created clients can communicate until client close.
                    lock {
                        checkpanic listenerMethodbackendEP.gracefulStop();
                    }
                    error? responseToCaller = caller->respond("Mock2 invoked!");
                    if (responseToCaller is error) {
                        log:printError("Error sending response from mock service", 'error = responseToCaller);
                    }
                }
            };
            checkpanic listenerMethodbackendEP.attach(listenerMethodMock2, "mock2");
        }
        lock {
            checkpanic listenerMethodbackendEP.start();
        }
        error? result = remoteCaller->respond("Backend service started!");
        if (result is error) {
            log:printError("Error sending response", 'error = result);
        }
    }
}

@test:Config {}
function testServiceAttachAndStart() {
    http:Response|error response = listenerMethodTestClient->get("/startService/test");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Backend service started!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn:[testServiceAttachAndStart]}
function testAvailabilityOfAttachedService() {
    http:Response|error response = backendTestClient->get("/mock1");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Mock1 invoked!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn:[testAvailabilityOfAttachedService]}
function testGracefulStopMethod() {
    http:Response|error response = backendTestClient->get("/mock2");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Mock2 invoked!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn:[testGracefulStopMethod]}
function testInvokingStoppedService() returns error? {
    final http:Client backendTestClient = check new("http://localhost:" + listenerMethodTestPort2.toString(),
                                                http1Settings = { keepAlive: http:KEEPALIVE_NEVER });
    http:Response|error response = backendTestClient->get("/mock1");
    if (response is error) {
        // Output depends on the closure time. The error implies that the listener has stopped.
        test:assertTrue(true, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: http:Response");
    }
    return;
}
