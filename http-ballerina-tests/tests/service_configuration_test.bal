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

configurable int backendEP_port = ?;
configurable string basePath = ?;

listener http:Listener backendEP = new(backendEP_port);
http:Client scClient = check new("http://localhost:" + serviceConfigTest.toString());

service /schello on backendEP {
    resource function get sayHello(http:Caller caller, http:Request request) {
        checkpanic backendEP.attach(testingService, basePath);
        checkpanic backendEP.start();
        checkpanic caller->respond("Service started!");
    }
}

http:Service testingService = service object {
    resource function get .(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setTextPayload("Hello World!!!");
        checkpanic caller->respond(response);
    }
};


//Test for configuring a service via config API
@test:Config {}
function testConfiguringAService() {
    var response = scClient->get("/schello/sayHello");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Service started!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = scClient->get("/hello");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
