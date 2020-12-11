// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

listener http:Listener serviceDetachTestEP = new(serviceDetachTest);
http:Client serviceDetachClient = new("http://localhost:" + serviceDetachTest.toString());

service /mock1 on serviceDetachTestEP {
    resource function get .(http:Caller caller, http:Request req) {
        checkpanic serviceDetachTestEP.attach(mock2, "/mock2");
        checkpanic serviceDetachTestEP.attach(mock3, "/mock3");
        var responseToCaller = caller->respond("Mock1 invoked. Mock2 attached. Mock3 attached");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
}

http:Service mock2 = service object {
    resource function get mock2Resource(http:Caller caller, http:Request req) {
        checkpanic serviceDetachTestEP.detach(mock3);
        checkpanic serviceDetachTestEP.attach(mock3, "/mock3");
        var responseToCaller = caller->respond("Mock2 resource was invoked");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
};

http:Service mock3 = service object {
    resource function get mock3Resource(http:Caller caller, http:Request req) {
        checkpanic serviceDetachTestEP.detach(mock2);
        checkpanic serviceDetachTestEP.attach(mock4, "/mock4");
        var responseToCaller = caller->respond("Mock3 invoked. Mock2 detached. Mock4 attached");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
};

http:Service mock4 = service object {
    resource function get mock4Resource(http:Caller caller, http:Request req) {
        checkpanic serviceDetachTestEP.attach(mock2, "/mock2");
        checkpanic serviceDetachTestEP.detach(mock5);
        var responseToCaller = caller->respond("Mock4 invoked. Mock2 attached");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
};

http:Service mock5 = service object {
    resource function get mock5Resource(http:Caller caller, http:Request req) {
        var responseToCaller = caller->respond("Mock5 invoked");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
};

//Test the detach method with multiple services attachments
@test:Config {}
function testServiceDetach() {
    var response = serviceDetachClient->get("/mock1");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Mock1 invoked. Mock2 attached. Mock3 attached");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke recently attached mock2 services. Test detaching and re attaching mock3 service
    response = serviceDetachClient->get("/mock2/mock2Resource");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Mock2 resource was invoked");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke recently attached mock3 service. That detached the mock2 service and attach mock3
    response = serviceDetachClient->get("/mock3/mock3Resource");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Mock3 invoked. Mock2 detached. Mock4 attached");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke detached mock2 services expecting a 404
    response = serviceDetachClient->get("/mock2/mock2Resource");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "no matching service found for path : /mock2/mock2Resource");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke mock3 services again expecting a error for re-attaching already available service
    response = serviceDetachClient->get("/mock3/mock3Resource");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "service registration failed: two services have the same basePath : '/mock4'");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke mock4 service. mock2 service is re attached
    response = serviceDetachClient->get("/mock4/mock4Resource");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Mock4 invoked. Mock2 attached");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    //Invoke recently re-attached mock2 services
    response = serviceDetachClient->get("/mock2/mock2Resource");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Mock2 resource was invoked");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
