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
import ballerina/log;
import ballerina/test;

const string X_TEST_TYPE = "x-test-type";
const string X_HEADER = "x-header";
const string ERROR = "error";
const string SUCCESS = "success";

http:ClientConfiguration statusLineLimitConfig = {
    responseLimits: {
        maxStatusLineLength: 1024
    }
};

http:ClientConfiguration headerLimitConfig = {
    responseLimits: {
        maxHeaderSize: 1024
    }
};

http:ClientConfiguration  entityBodyLimitConfig = {
    responseLimits: {
        maxEntityBodySize: 1024
    }
};

http:ClientConfiguration http2headerLimitConfig = {
    httpVersion: "2.0",
    responseLimits: {
        maxHeaderSize: 1024
    }
};

listener http:Listener statusLineEP = new(responseLimitsTestPort1);
listener http:Listener statusBackendEP = new(responseLimitsTestPort2);
listener http:Listener headertBackendEP = new(responseLimitsTestPort3);
listener http:Listener entitybodyBackendEP = new(responseLimitsTestPort4);
listener http:Listener headerTestEP = new(responseLimitsTestPort5);

http:Client limitTestClient = check new("http://localhost:" + responseLimitsTestPort1.toString());
http:Client statusLimitClient = check new("http://localhost:" + responseLimitsTestPort2.toString()
        + "/backend/statustest", statusLineLimitConfig);
http:Client headerLimitClient = check new("http://localhost:" + responseLimitsTestPort3.toString()
        + "/backend/headertest", headerLimitConfig);
http:Client entityBodyLimitClient = check new("http://localhost:" + responseLimitsTestPort4.toString()
        + "/backend/entitybodytest", entityBodyLimitConfig);
http:Client http2headerLimitClient = check new("http://localhost:" + responseLimitsTestPort5.toString()
        + "/backend/headertest", http2headerLimitConfig);

service /responseLimit on statusLineEP {

    resource function get [string clientType](http:Caller caller, http:Request req) {
        http:Client clientEP = entityBodyLimitClient;
        if (clientType == "statusline") {
            clientEP = statusLimitClient;
        } else if (clientType == "header") {
            clientEP = headerLimitClient;
        } else if (clientType == "http2") {
            clientEP = http2headerLimitClient;
        }

        var clientResponse = clientEP->forward("/", <@untainted>req);
        if (clientResponse is http:Response) {
            var result = caller->respond(<@untainted>clientResponse);
            if (result is error) {
                log:printError("Error sending passthru response", err = result);
            }
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(<@untainted>clientResponse.toString());
            var result = caller->respond(<@untainted>res);
            if (result is error) {
                log:printError("Error sending error response", err = result);
            }
        }
    }
}

service /backend on statusBackendEP {
    resource function get statustest(http:Caller caller, http:Request req) {
        http:Response res = new;
        string testType = checkpanic req.getHeader("x-test-type");
        if (testType == "error") {
            res.reasonPhrase = getStringLengthOf(1200);
        } else {
            res.reasonPhrase = "HELLO";
        }
        res.setTextPayload("Hello World!!!");
        sendResponse(caller, res);
    }
}

service /backend on headertBackendEP {
    resource function get headertest(http:Caller caller, http:Request req) {
        http:Response res = new;
        string testType = checkpanic req.getHeader("x-test-type");
        if (testType == "error") {
            res.setHeader("x-header", getStringLengthOf(2048));
        } else {
            res.setHeader("x-header", "Validated");
        }
        res.setTextPayload("Hello World!!!");
        sendResponse(caller, res);
    }
}

service /backend on entitybodyBackendEP {
    resource function get entitybodytest(http:Caller caller, http:Request req) {
        http:Response res = new;
        string testType = checkpanic req.getHeader("x-test-type");
        if (testType == "error") {
            res.setTextPayload(getStringLengthOf(2048));
        } else {
            res.setTextPayload("Small payload");
        }
        sendResponse(caller, res);
    }
}

service /backend on headerTestEP {
    resource function get headertest(http:Caller caller, http:Request req) {
        http:Response res = new;
        string testType = checkpanic req.getHeader("x-test-type");
        if (testType == "error") {
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
    var result = caller->respond(res);
    if (result is error) {
        log:printError("Error sending backend response", err = result);
    }
}

//Test when status line length is less than the configured maxStatusLineLength threshold
@test:Config {}
function testValidStatusLineLength() {
    http:Request req = new;
    req.setHeader(X_TEST_TYPE, SUCCESS);
    var response = limitTestClient->get("/responseLimit/statusline", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(response.reasonPhrase, "HELLO", msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when status line length is greater than the configured maxStatusLineLength threshold
@test:Config {}
function testInvalidStatusLineLength() {
    http:Request req = new;
    req.setHeader(X_TEST_TYPE, ERROR);
    var response = limitTestClient->get("/responseLimit/statusline", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "error(\"Response max " +
                "status line length exceeds: An HTTP line is larger than 1024 bytes.\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when header size is less than the configured maxHeaderSize threshold
@test:Config {}
function testValidHeaderLengthOfResponse() {
    http:Request req = new;
    req.setHeader(X_TEST_TYPE, SUCCESS);
    var response = limitTestClient->get("/responseLimit/header", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(X_HEADER), "Validated");
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when header size is greater than the configured maxHeaderSize threshold
@test:Config {}
function testInvalidHeaderLengthOfResponse() {
    http:Request req = new;
    req.setHeader(X_TEST_TYPE, ERROR);
    var response = limitTestClient->get("/responseLimit/header", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "error(\"Response max " +
                "header size exceeds: HTTP header is larger than 1024 bytes.\")");
        var header = response.getHeader(X_HEADER);
        if (header is error) {
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
    http:Request req = new;
    req.setHeader(X_TEST_TYPE, SUCCESS);
    var response = limitTestClient->get("/responseLimit/entitybody", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Small payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when entityBody size is greater than the configured maxEntityBodySize threshold
@test:Config {}
function testInvalidEntityBodyLength() {
    http:Request req = new;
    req.setHeader(X_TEST_TYPE, ERROR);
    var response = limitTestClient->get("/responseLimit/statusline", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "error(\"Response max status line length exceeds: An HTTP line " +
                "is larger than 1024 bytes.\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when header size is less than the configured maxHeaderSize threshold in http2 client but the backend sends http 1.1 response
@test:Config {}
function testValidHeaderLengthWithHttp2Client() {
    http:Request req = new;
    req.setHeader(X_TEST_TYPE, SUCCESS);
    var response = limitTestClient->get("/responseLimit/http2", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(X_HEADER), "Validated");
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test when header size is greater than the configured maxHeaderSize threshold in http2 client but the backend sends http 1.1 response
@test:Config {}
function testInvalidHeaderLengthWithHttp2Client() {
    http:Request req = new;
    req.setHeader(X_TEST_TYPE, ERROR);
    var response = limitTestClient->get("/responseLimit/header", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "error(\"Response max " +
                "header size exceeds: HTTP header is larger than 1024 bytes.\")");
        var header = response.getHeader(X_HEADER);
        if (header is error) {
            test:assertEquals(header.message(), "Http header does not exist", msg = "Found unexpected output");
        } else {
            test:assertFail(msg = "Found unexpected output type");
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
