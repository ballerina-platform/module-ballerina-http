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

import ballerina/io;
import ballerina/test;
import ballerina/http;

listener http:Listener callerActionListener = new(callerActionTestPort);
http:Client callerActionTestClient = new("http://localhost:" + callerActionTestPort.toString());

string globalLvlStr = "sample value";

@http:ServiceConfig {basePath:"/listener"}
service callerActionEcho on callerActionListener {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/respond"
    }
    resource function echo(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload(<@untainted> globalLvlStr);
        checkpanic caller->respond(res);
        globalLvlStr = "respond";
        io:println("Service Level Variable : " + globalLvlStr);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/redirect"
    }
    resource function round1(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->redirect(res, http:REDIRECT_PERMANENT_REDIRECT_308, ["/redirect1/round2"]);
        globalLvlStr = "redirect";
        io:println("Service Level Variable : " + globalLvlStr);
    }

    // @http:ResourceConfig {
    //     methods:["GET"]
    // }
    // resource function getChangedValue(http:Caller caller, http:Request req) {
    //     checkpanic caller->respond(globalLvlStr);
    // }
}

@test:Config {}
function testNonBlockingRespondAction() {
    var response = callerActionTestClient->get("/listener/respond");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "sample value");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn:["testNonBlockingRespondAction"]}
function testExecutionAfterRespondAction() {
    test:assertEquals(globalLvlStr, "respond");
    // var response = callerActionTestClient->get("/listener/getChangedValue");
    // if (response is http:Response) {
    //     test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    //     assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
    //     assertTextPayload(response.getTextPayload(), "respond");
    // } else if (response is error) {
    //     test:assertFail(msg = "Found unexpected output type: " + response.message());
    // }
}

@test:Config {dependsOn:["testExecutionAfterRespondAction"]}
function testNonBlockingRedirectAction() {
    var response = callerActionTestClient->get("/listener/redirect");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 308, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn:["testNonBlockingRedirectAction"]}
function testExecutionAfterRedirectAction() {
    test:assertEquals(globalLvlStr, "redirect");
    // var response = callerActionTestClient->get("/listener/getChangedValue");
    // if (response is http:Response) {
    //     test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    //     assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
    //     assertTextPayload(response.getTextPayload(), "redirect");
    // } else if (response is error) {
    //     test:assertFail(msg = "Found unexpected output type: " + response.message());
    // }
}
