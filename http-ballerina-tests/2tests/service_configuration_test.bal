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

import ballerina/config;
import ballerina/test;
import ballerina/http;

listener http:Listener backendEP = new(config:getAsInt("\"backendEP.port\""));
http:Client scClient = new("http://localhost:" + serviceConfigTest.toString());

@http:ServiceConfig {
    basePath: config:getAsString("hello.basePath")
}
service schello on backendEP{

    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource function sayHello (http:Caller caller, http:Request request) {
        http:Response response = new;
        response.setTextPayload("Hello World!!!");
        checkpanic caller->respond(response);
    }
}


//Test for configuring a service via config API
@test:Config {}
function testConfiguringAService() {
    var response = scClient->get("/hello");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
