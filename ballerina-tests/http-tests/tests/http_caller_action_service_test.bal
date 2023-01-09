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

import ballerina/test;
import ballerina/http;
import ballerina/lang.runtime as runtime;
import ballerina/http_test_common as common;

listener http:Listener callerActionListener = new (callerActionTestPort, httpVersion = http:HTTP_1_1);
final http:Client callerActionTestClient = check new ("http://localhost:" + callerActionTestPort.toString(), httpVersion = http:HTTP_1_1);

isolated string globalLvlStr = "sample value";

service /'listener on callerActionListener {

    resource function get respond(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        string value = "";
        lock {
            value = globalLvlStr;
        }
        res.setTextPayload(value);
        check caller->respond(res);
        lock {
            globalLvlStr = "respond";
        }
    }

    resource function get redirect(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_PERMANENT_REDIRECT_308, ["/redirect1/round2"]);
        lock {
            globalLvlStr = "redirect";
        }
    }

    // @http:ResourceConfig {
    //     methods:["GET"]
    // }
    // resource function getChangedValue(http:Caller caller, http:Request req) {
    //     check caller->respond(globalLvlStr);
    // }
}

@test:Config {}
function testNonBlockingRespondAction() returns error? {
    http:Response|error response = callerActionTestClient->get("/listener/respond");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "sample value");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn: [testNonBlockingRespondAction]}
function testExecutionAfterRespondAction() {
    runtime:sleep(3);
    lock {
        test:assertEquals(globalLvlStr, "respond");
    }
    // http:Response|error response = callerActionTestClient->get("/listener/getChangedValue");
    // if response is http:Response {
    //     test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    //     common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
    //     common:assertTextPayload(response.getTextPayload(), "respond");
    // } else {
    //     test:assertFail(msg = "Found unexpected output type: " + response.message());
    // }
}

@test:Config {dependsOn: [testExecutionAfterRespondAction]}
function testNonBlockingRedirectAction() {
    http:Response|error response = callerActionTestClient->get("/listener/redirect");
    if response is http:Response {
        test:assertEquals(response.statusCode, 308, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn: [testNonBlockingRedirectAction]}
function testExecutionAfterRedirectAction() {
    runtime:sleep(3);
    lock {
        test:assertEquals(globalLvlStr, "redirect");
    }
    // http:Response|error response = callerActionTestClient->get("/listener/getChangedValue");
    // if response is http:Response {
    //     test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    //     common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
    //     common:assertTextPayload(response.getTextPayload(), "redirect");
    // } else {
    //     test:assertFail(msg = "Found unexpected output type: " + response.message());
    // }
}
