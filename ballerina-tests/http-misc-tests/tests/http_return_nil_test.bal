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
// import ballerina/log;
import ballerina/http_test_common as common;

listener http:Listener httpReturnNilListener = new (httpReturnNilTestPort, httpVersion = http:HTTP_1_1);
final http:Client httpReturnNilClient = check new ("http://localhost:" + httpReturnNilTestPort.toString(), httpVersion = http:HTTP_1_1);

service "/url" on httpReturnNilListener {

    resource function get nil() {
        return; // 202 response
    }

    resource function post nil() {
        return; // 202 response
    }

    resource function get empty() {
        // 202 response
    }

    resource function get end(http:Caller caller) {
        error? err = caller->respond("hi"); // 200 response
        if err is error {
            // log:printError("Error occurred while sending response", 'error = err);
        }
        return; // consider as exec end
    }

    resource function get errorCaller(http:Caller caller, boolean err) returns error? {
        if err {
            return; //500 response
        }
        check caller->respond("success");
        return;
    }

    resource function get nonReturn(boolean success, http:Caller caller) {
        if success {
            error? err = caller->respond("success");
            if err is error {
                // log:printError("Error occurred while sending response", 'error = err);
            }
            return;
        }
        return; //500 response
    }
}

@test:Config {}
function testNilReturn() {
    http:Response|error response = httpReturnNilClient->get("/url/nil");
    if response is http:Response {
        test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilReturnWithPost() {
    http:Response|error response = httpReturnNilClient->post("/url/nil", new http:Request());
    if response is http:Response {
        test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testEmptyResource() {
    http:Response|error response = httpReturnNilClient->get("/url/empty");
    if response is http:Response {
        test:assertEquals(response.statusCode, 202, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilReturnAsEndExec() returns error? {
    http:Response|error response = httpReturnNilClient->get("/url/end");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "hi");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilReturnWithCaller() returns error? {
    http:Response|error response = httpReturnNilClient->get("/url/errorCaller?err=true");
    if response is http:Response {
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
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "success");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilReturnWithCallerNoReturnType() {
    http:Response|error response = httpReturnNilClient->get("/url/nonReturn?success=false");
    if response is http:Response {
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
}
