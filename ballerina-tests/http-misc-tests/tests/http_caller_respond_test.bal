// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/http_test_common as common;

final http:Client callerRespondTestClientEP = check new ("http://localhost:" + callerRespondTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener callerRespondTestServerEP = new (callerRespondTestPort, httpVersion = http:HTTP_1_1);

service / on callerRespondTestServerEP {

    resource function get accepted(http:Caller caller) returns error? {
        check caller->respond(http:ACCEPTED);
    }

    resource function post status(http:Caller caller, http:Request req) returns error? {
        http:StatusCodeResponse res;
        string|error header = req.getHeader("x-header");
        json|error payload = req.getJsonPayload();
        if header is error {
            res = <http:NotFound>{body: {message: "header not found"}};
        } else if payload is error {
            res = <http:BadRequest>{body: {message: "payload type is not supported"}};
        } else {
            res = <http:Ok>{body: {message: "hello world"}};
        }
        check caller->respond(res);
    }
}

@test:Config {}
function testCallerRespondAccepted() returns error? {
    http:Response res = check callerRespondTestClientEP->get("/accepted");
    test:assertEquals(res.statusCode, 202);
}

@test:Config {}
function testCallerRespondNotFound() returns error? {
    http:Request req = new;
    req.setJsonPayload({message: "hello world"});
    http:Response res = check callerRespondTestClientEP->post("/status", req);
    test:assertEquals(res.statusCode, 404);
    common:assertJsonPayload(res.getJsonPayload(), {message: "header not found"});
}

@test:Config {}
function testCallerRespondBadRequest() returns error? {
    http:Request req = new;
    req.setHeader("x-header", "x-value");
    req.setXmlPayload(xml `<message> hello world </message>`);
    http:Response res = check callerRespondTestClientEP->post("/status", req);
    test:assertEquals(res.statusCode, 400);
    common:assertJsonPayload(res.getJsonPayload(), {message: "payload type is not supported"});
}

@test:Config {}
function testCallerRespondOk() returns error? {
    http:Request req = new;
    req.setHeader("x-header", "x-value");
    req.setJsonPayload({message: "hello world"});
    http:Response res = check callerRespondTestClientEP->post("/status", req);
    test:assertEquals(res.statusCode, 200);
    common:assertJsonPayload(res.getJsonPayload(), {message: "hello world"});
}
