// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

int http2ServiceDetachTest = common:getHttp2Port(serviceDetachTestPort);

listener http:Listener http2ServiceDetachTestEP = new (http2ServiceDetachTest);
final http:Client http2ServiceDetachClient = check new ("http://localhost:" + http2ServiceDetachTest.toString(),
    http2Settings = {http2PriorKnowledge: true});

service /mock1 on http2ServiceDetachTestEP {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        lock {
            check http2ServiceDetachTestEP.attach(http2Mock2, "/mock2");
        }
        lock {
            check http2ServiceDetachTestEP.attach(http2Mock3, "/mock3");
        }
        error? responseToCaller = caller->respond("Mock1 invoked. Mock2 attached. Mock3 attached");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

isolated http:Service http2Mock2 = service object {
    resource function get mock2Resource(http:Caller caller, http:Request req) returns error? {
        lock {
            check http2ServiceDetachTestEP.detach(http2Mock3);
        }
        lock {
            check http2ServiceDetachTestEP.attach(http2Mock3, "/mock3");
        }
        error? responseToCaller = caller->respond("Mock2 resource was invoked");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
};

isolated http:Service http2Mock3 = service object {
    resource function get mock3Resource(http:Caller caller, http:Request req) returns error? {
        lock {
            check http2ServiceDetachTestEP.detach(http2Mock2);
        }
        lock {
            check http2ServiceDetachTestEP.attach(http2Mock4, "/mock4");
        }
        error? responseToCaller = caller->respond("Mock3 invoked. Mock2 detached. Mock4 attached");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
};

isolated http:Service http2Mock4 = service object {
    resource function get mock4Resource(http:Caller caller, http:Request req) returns error? {
        lock {
            check http2ServiceDetachTestEP.attach(http2Mock2, "/mock2");
        }
        lock {
            check http2ServiceDetachTestEP.detach(http2Mock5);
        }
        error? responseToCaller = caller->respond("Mock4 invoked. Mock2 attached");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
};

isolated http:Service http2Mock5 = service object {
    resource function get mock5Resource(http:Caller caller, http:Request req) {
        error? responseToCaller = caller->respond("Mock5 invoked");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
};

//Test the detach method with multiple services attachments
@test:Config {}
function testHttp2ServiceDetach() {
    http:Response|error response = http2ServiceDetachClient->get("/mock1");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Mock1 invoked. Mock2 attached. Mock3 attached");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke recently attached mock2 services. Test detaching and re attaching mock3 service
    response = http2ServiceDetachClient->get("/mock2/mock2Resource");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Mock2 resource was invoked");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke recently attached mock3 service. That detached the mock2 service and attach mock3
    response = http2ServiceDetachClient->get("/mock3/mock3Resource");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Mock3 invoked. Mock2 detached. Mock4 attached");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke detached mock2 services expecting a 404
    response = http2ServiceDetachClient->get("/mock2/mock2Resource");
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "no matching service found for path : /mock2/mock2Resource");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke mock3 services again expecting a error for re-attaching already available service
    response = http2ServiceDetachClient->get("/mock3/mock3Resource");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(),
            "Service registration failed: two services have the same basePath : '/mock4'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke mock4 service. mock2 service is re attached
    response = http2ServiceDetachClient->get("/mock4/mock4Resource");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Mock4 invoked. Mock2 attached");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke recently re-attached mock2 services
    response = http2ServiceDetachClient->get("/mock2/mock2Resource");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Mock2 resource was invoked");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
