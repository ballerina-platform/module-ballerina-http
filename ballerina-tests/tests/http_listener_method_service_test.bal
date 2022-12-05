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

import ballerina/http;
import ballerina/test;

listener http:Listener listenerMethodListener = new(listenerMethodTestPort1, httpVersion = http:HTTP_1_1);
final http:Client listenerMethodTestClient = check new("http://localhost:" + listenerMethodTestPort1.toString(), httpVersion = http:HTTP_1_1);
final http:Client backendGraceStopTestClient = check new("http://localhost:" + listenerMethodTestPort2.toString(), httpVersion = http:HTTP_1_1);
final http:Client backendImmediateStopTestClient = check new("http://localhost:" + listenerMethodTestPort3.toString(), httpVersion = http:HTTP_1_1);

isolated http:Listener listenerMethodGracebackendEP = check new(listenerMethodTestPort2, httpVersion = http:HTTP_1_1);
isolated http:Listener listenerMethodImmediatebackendEP = check new(listenerMethodTestPort3, httpVersion = http:HTTP_1_1);

service /startService on listenerMethodListener {
    resource function get health() {}

    resource function get testGrace() returns string|error? {
        lock {
            http:Service listenerMethodMock1 = service object {
                resource function get .() returns string {
                    return "Mock1 invoked!";
                }
            };
            check listenerMethodGracebackendEP.attach(listenerMethodMock1, "mock1");
        }
        lock {
            http:Service listenerMethodMock2 = service object {
                resource function get .(http:Caller caller) returns error? {
                    // gracefulStop will unbind the listener port and stop accepting new connections.
                    // But already connection created clients can communicate until client close.
                    check caller->respond("Mock2 invoked!");
                    lock {
                        check listenerMethodGracebackendEP.gracefulStop();
                    }
                }
            };
            check listenerMethodGracebackendEP.attach(listenerMethodMock2, "mock2");
        }
        lock {
            check listenerMethodGracebackendEP.start();
        }
        return "testGrace backend service started!";
    }

    resource function get testImmediate() returns string|error? {
        lock {
            http:Service listenerMethodMock1 = service object {
                resource function get .() returns string {
                    return "Mock1 invoked!";
                }
            };
            check listenerMethodImmediatebackendEP.attach(listenerMethodMock1, "mock1");
        }
        lock {
            http:Service listenerMethodMock3 = service object {
                resource function get .() returns string|error? {
                    lock {
                        check listenerMethodImmediatebackendEP.immediateStop();
                    }
                    return "Mock3 invoked!";
                }
            };
            check listenerMethodImmediatebackendEP.attach(listenerMethodMock3, "mock3");
        }
        lock {
            check listenerMethodImmediatebackendEP.start();
        }
        return "testImmediate backend service started!";
    }
}

@test:Config {}
function testServiceAttachAndStart() returns error? {
    string response = check listenerMethodTestClient->get("/startService/testGrace");
    test:assertEquals(response, "testGrace backend service started!", msg = "Found unexpected output");
}

@test:Config {dependsOn:[testServiceAttachAndStart]}
function testAvailabilityOfAttachedService() returns error? {
    string response = check backendGraceStopTestClient->get("/mock1");
    test:assertEquals(response, "Mock1 invoked!", msg = "Found unexpected output");
}

@test:Config {dependsOn:[testAvailabilityOfAttachedService]}
function testGracefulStopMethod() returns error? {
    string response = check backendGraceStopTestClient->get("/mock2");
    test:assertEquals(response, "Mock2 invoked!", msg = "Found unexpected output");
}

@test:Config {dependsOn:[testGracefulStopMethod]}
function testInvokingStoppedService() returns error? {
    final http:Client backendGraceStopTestClient = check new("http://localhost:" + listenerMethodTestPort2.toString(),
        httpVersion = http:HTTP_1_1, http1Settings = { keepAlive: http:KEEPALIVE_NEVER });
    http:Response|error response = backendGraceStopTestClient->get("/mock1");
    if response is error {
        // Output depends on the closure time. The error implies that the listener has stopped.
        test:assertTrue(true, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: http:Response");
    }
}

@test:Config {dependsOn:[testInvokingStoppedService]}
function testServiceHealthAttempt1() returns error? {
    http:Response response = check listenerMethodTestClient->get("/startService/health");
    test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
}

@test:Config {dependsOn:[testServiceHealthAttempt1]}
function testImmediateServiceAttachAndStart() returns error? {
    string response = check listenerMethodTestClient->get("/startService/testImmediate");
    test:assertEquals(response, "testImmediate backend service started!", msg = "Found unexpected output");
}

@test:Config {dependsOn:[testImmediateServiceAttachAndStart]}
function testAvailabilityOfAttachedImmediateService() returns error? {
    string response = check backendImmediateStopTestClient->get("/mock1");
    test:assertEquals(response, "Mock1 invoked!", msg = "Found unexpected output");
}

@test:Config {dependsOn:[testAvailabilityOfAttachedImmediateService]}
function testImmediateStopMethod() returns error? {
    http:Response|error response = backendImmediateStopTestClient->get("/mock3");
    if response is error {
        test:assertEquals(response.message(), "Remote host closed the connection before initiating inbound response");
    } else {
        test:assertFail(msg = "Found unexpected output type: http:Response");
    }
}

@test:Config {dependsOn:[testImmediateStopMethod]}
function testInvokingStoppedImmediateService() returns error? {
    final http:Client backendImmediateStopTestClient = check new("http://localhost:" + listenerMethodTestPort2.toString(), 
        httpVersion = http:HTTP_1_1, http1Settings = { keepAlive: http:KEEPALIVE_NEVER });
    http:Response|error response = backendImmediateStopTestClient->get("/mock1");
    if response is error {
        // Output depends on the closure time. The error implies that the listener has stopped.
        test:assertTrue(true, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: http:Response");
    }
}

@test:Config {dependsOn:[testInvokingStoppedImmediateService]}
function testServiceHealthAttempt2() returns error? {
    http:Response response = check listenerMethodTestClient->get("/startService/health");
    test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
}
