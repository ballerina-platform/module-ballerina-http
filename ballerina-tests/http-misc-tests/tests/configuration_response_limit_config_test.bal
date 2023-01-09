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

import ballerina/http;
// import ballerina/log;
import ballerina/test;
import ballerina/http_test_common as common;

const string X_TEST_TYPE = "x-test-type";
const string X_HEADER = "x-header";
const string ERROR = "error";
const string SUCCESS = "success";

http:ClientConfiguration statusLineLimitConfig = {
    httpVersion: http:HTTP_1_1,
    responseLimits: {
        maxStatusLineLength: 1024
    }
};

http:ClientConfiguration headerLimitConfig = {
    httpVersion: http:HTTP_1_1,
    responseLimits: {
        maxHeaderSize: 1024
    }
};

http:ClientConfiguration entityBodyLimitConfig = {
    httpVersion: http:HTTP_1_1,
    responseLimits: {
        maxEntityBodySize: 1024
    }
};

http:ClientConfiguration http2headerLimitConfig = {
    responseLimits: {
        maxHeaderSize: 1024
    }
};

listener http:Listener statusLineEP = new (responseLimitsTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener responseLimitBackendEP = new (responseLimitsTestPort2, httpVersion = http:HTTP_1_1);

final http:Client limitTestClient = check new ("http://localhost:" + responseLimitsTestPort1.toString(), httpVersion = http:HTTP_1_1);
final http:Client statusLimitClient = check new ("http://localhost:" + responseLimitsTestPort2.toString()
        + "/backend/statustest", statusLineLimitConfig);
final http:Client headerLimitClient = check new ("http://localhost:" + responseLimitsTestPort2.toString()
        + "/backend/headertest", headerLimitConfig);
final http:Client entityBodyLimitClient = check new ("http://localhost:" + responseLimitsTestPort2.toString()
        + "/backend/entitybodytest", entityBodyLimitConfig);
final http:Client http2headerLimitClient = check new ("http://localhost:" + responseLimitsTestPort2.toString()
        + "/backend/headertest2", http2headerLimitConfig);

service /responseLimit on statusLineEP {

    resource function get [string clientType](http:Caller caller, http:Request req) {
        http:Client clientEP = entityBodyLimitClient;
        if clientType == "statusline" {
            clientEP = statusLimitClient;
        } else if clientType == "header" {
            clientEP = headerLimitClient;
        } else if clientType == "http2" {
            clientEP = http2headerLimitClient;
        }

        http:Response|error clientResponse = clientEP->forward("/", req);
        if clientResponse is http:Response {
            error? result = caller->respond(clientResponse);
            if result is error {
                // log:printError("Error sending passthru response", 'error = result);
            }
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(clientResponse.toString());
            error? result = caller->respond(res);
            if result is error {
                // log:printError("Error sending error response", 'error = result);
            }
        }
    }
}

service /backend on responseLimitBackendEP {
    resource function get statustest(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        string testType = check req.getHeader("x-test-type");
        if testType == "error" {
            res.reasonPhrase = getStringLengthOf(1200);
        } else {
            res.reasonPhrase = "HELLO";
        }
        res.setTextPayload("Hello World!!!");
        sendResponse(caller, res);
    }

    resource function get headertest(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        string testType = check req.getHeader("x-test-type");
        if testType == "error" {
            res.setHeader("x-header", getStringLengthOf(2048));
        } else {
            res.setHeader("x-header", "Validated");
        }
        res.setTextPayload("Hello World!!!");
        sendResponse(caller, res);
    }

    resource function get entitybodytest(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        string testType = check req.getHeader("x-test-type");
        if testType == "error" {
            res.setTextPayload(getStringLengthOf(2048));
        } else {
            res.setTextPayload("Small payload");
        }
        sendResponse(caller, res);
    }

    resource function get headertest2(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        string testType = check req.getHeader("x-test-type");
        if testType == "error" {
            res.setHeader("x-header", getStringLengthOf(2048));
        } else {
            res.setHeader("x-header", "Validated");
        }
        res.setTextPayload("Hello World!!!");
        sendResponse(caller, res);
    }
}

function getStringLengthOf(int length) returns string {
    string builder = "";
    int i = 0;
    while (i < length) {
        builder = builder + "a";
        i = i + 1;
    }
    return builder;
}

function sendResponse(http:Caller caller, http:Response res) {
    error? result = caller->respond(res);
    if result is error {
        // log:printError("Error sending backend response", 'error = result);
    }
}

//Test when status line length is less than the configured maxStatusLineLength threshold
@test:Config {}
function testValidStatusLineLength() {
    http:Response|error response = limitTestClient->get("/responseLimit/statusline", {[X_TEST_TYPE] : [SUCCESS]});
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "HELLO", msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when status line length is greater than the configured maxStatusLineLength threshold
@test:Config {}
function testInvalidStatusLineLength() {
    http:Response|error response = limitTestClient->get("/responseLimit/statusline", {[X_TEST_TYPE] : [ERROR]});
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "error ClientError (\"Response max " +
                "status line length exceeds: An HTTP line is larger than 1024 bytes.\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when header size is less than the configured maxHeaderSize threshold
@test:Config {}
function testValidHeaderLengthOfResponse() returns error? {
    http:Response|error response = limitTestClient->get("/responseLimit/header", {[X_TEST_TYPE] : [SUCCESS]});
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(X_HEADER), "Validated");
        common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when header size is greater than the configured maxHeaderSize threshold
@test:Config {}
function testInvalidHeaderLengthOfResponse() {
    http:Response|error response = limitTestClient->get("/responseLimit/header", {[X_TEST_TYPE] : [ERROR]});
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "error ClientError (\"Response max " +
                "header size exceeds: HTTP header is larger than 1024 bytes.\")");
        var header = response.getHeader(X_HEADER);
        if header is error {
            test:assertEquals(header.message(), "Http header does not exist", msg = "Found unexpected output");
        } else {
            test:assertFail(msg = "Found unexpected output type");
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when entityBody size is less than the configured maxEntityBodySize threshold
@test:Config {}
function testValidEntityBodyLength() {
    http:Response|error response = limitTestClient->get("/responseLimit/entitybody", {[X_TEST_TYPE] : [SUCCESS]});
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "Small payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when entityBody size is greater than the configured maxEntityBodySize threshold
@test:Config {}
function testInvalidEntityBodyLength() {
    http:Response|error response = limitTestClient->get("/responseLimit/statusline", {[X_TEST_TYPE] : [ERROR]});
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "error ClientError (\"Response max " +
                "status line length exceeds: An HTTP line is larger than 1024 bytes.\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when header size is less than the configured maxHeaderSize threshold in http2 client but the backend sends http 1.1 response
@test:Config {}
function testValidHeaderLengthWithHttp2Client() returns error? {
    http:Response|error response = limitTestClient->get("/responseLimit/http2", {[X_TEST_TYPE] : [SUCCESS]});
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(X_HEADER), "Validated");
        common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when header size is greater than the configured maxHeaderSize threshold in http2 client but the backend sends http 1.1 response
@test:Config {}
function testInvalidHeaderLengthWithHttp2Client() {
    http:Response|error response = limitTestClient->get("/responseLimit/header", {[X_TEST_TYPE] : [ERROR]});
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "error ClientError (\"Response max " +
                "header size exceeds: HTTP header is larger than 1024 bytes.\")");
        var header = response.getHeader(X_HEADER);
        if header is error {
            test:assertEquals(header.message(), "Http header does not exist", msg = "Found unexpected output");
        } else {
            test:assertFail(msg = "Found unexpected output type");
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
