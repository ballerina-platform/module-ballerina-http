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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

configurable int backendPort = ?;
configurable string basePath = ?;

listener http:Listener backendEP = new (backendPort, httpVersion = http:HTTP_1_1);
final http:Client scClient = check new ("http://localhost:" + serviceConfigTestPort.toString(), httpVersion = http:HTTP_1_1);

service /schello on backendEP {
    resource function get sayHello(http:Caller caller, http:Request request) returns error? {
        lock {
            check backendEP.attach(testingService, basePath);
        }
        check backendEP.start();
        check caller->respond("Service started!");
    }
}

isolated http:Service testingService = service object {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setTextPayload("Hello World!!!");
        check caller->respond(response);
    }
};

//Test for configuring a service via config API
@test:Config {}
function testConfiguringAService() {
    http:Response|error response = scClient->get("/schello/sayHello");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Service started!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = scClient->get("/hello");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
