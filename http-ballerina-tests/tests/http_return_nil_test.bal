// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

listener http:Listener httpReturnNilListener = new(httpReturnNilTestPort);
http:Client httpReturnNilClient = check new("http://localhost:" + httpReturnNilTestPort.toString());

service "/url" on httpReturnNilListener  {

    resource function get nil() {
        return; // 202 response
    }

    resource function get empty() {
        // 202 response
    }

    resource function get end(http:Caller caller) {
        error? err = caller->respond("hi"); // 200 response
        return; // consider as exec end
    }

    resource function get double(http:Caller caller) returns string {
        error? err = caller->respond("Hello"); // 200 response
        return "hi"; // exception
    }

    resource function get errorCaller(http:Caller caller, boolean err) returns error? {
        if err {
            return; //500 response
        }
        check caller->respond("success");
    }
}

@test:Config {}
function testNilReturn() {
    http:Response|error response = httpReturnNilClient->get("/url/nil");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testEmptyResource() {
    http:Response|error response = httpReturnNilClient->get("/url/empty");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilReturnAsEndExec() {
    http:Response|error response = httpReturnNilClient->get("/url/end");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "hi");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDoubleResponseWithExecption() {
    http:Response|error response = httpReturnNilClient->get("/url/double");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilReturnWithCaller() {
    http:Response|error response = httpReturnNilClient->get("/url/errorCaller?err=true");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        string|error payload = response.getTextPayload();
        if payload is error {
            test:assertEquals(payload.message(), "No content", msg = "Found unexpected output");
        } else {
            test:assertFail(msg = "Found unexpected payload type: string");
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpReturnNilClient->get("/url/errorCaller?err=false");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "success");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
