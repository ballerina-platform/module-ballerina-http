// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

http:ClientConfiguration http2StatusLineLimitConfig = {
    http2Settings: {
        http2PriorKnowledge: true
    },
    responseLimits: {
        maxStatusLineLength: 1024
    }
};

http:ClientConfiguration http2HeaderLimitConfig = {
    http2Settings: {
        http2PriorKnowledge: true
    },
    responseLimits: {
        maxHeaderSize: 1024
    }
};

http:ClientConfiguration http2EntityBodyLimitConfig = {
    http2Settings: {
        http2PriorKnowledge: true
    },
    responseLimits: {
        maxEntityBodySize: 1024
    }
};

int http2ResponseLimitsTestPort1 = common:getHttp2Port(responseLimitsTestPort1);
int http2ResponseLimitsTestPort2 = common:getHttp2Port(responseLimitsTestPort2);

listener http:Listener http2StatusLineEP = new (http2ResponseLimitsTestPort1);
listener http:Listener http2ResponseLimitBackendEP = new (http2ResponseLimitsTestPort2);

final http:Client http2LimitTestClient = check new ("http://localhost:" + http2ResponseLimitsTestPort1.toString());
final http:Client http2StatusLimitClient = check new ("http://localhost:" + http2ResponseLimitsTestPort2.toString()
        + "/backend/statustest", http2StatusLineLimitConfig);
final http:Client http2HeaderLimitClient = check new ("http://localhost:" + http2ResponseLimitsTestPort2.toString()
        + "/backend/headertest", http2HeaderLimitConfig);
final http:Client http2EntityBodyLimitClient = check new ("http://localhost:" + http2ResponseLimitsTestPort2.toString()
        + "/backend/entitybodytest", http2EntityBodyLimitConfig);

service /responseLimit on http2StatusLineEP {

    resource function get [string clientType](http:Caller caller, http:Request req) {
        http:Client clientEP = http2EntityBodyLimitClient;
        if clientType == "statusline" {
            clientEP = http2StatusLimitClient;
        } else if clientType == "header" {
            clientEP = http2HeaderLimitClient;
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

service /backend on http2ResponseLimitBackendEP {
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

//Test when status line length is less than the configured maxStatusLineLength threshold
// todo: disabled due to missing feature
// @test:Config {}
function testHttp2ValidStatusLineLength() returns error? {
    http:Response response = check http2LimitTestClient->get("/responseLimit/statusline", {[X_TEST_TYPE] : [SUCCESS]});
    test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    test:assertEquals(response.reasonPhrase, "HELLO", msg = "Found unexpected output");
    common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
}

//Test when status line length is greater than the configured maxStatusLineLength threshold
// todo: disabled due to missing feature
// @test:Config {}
function testHttp2InvalidStatusLineLength() returns error? {
    http:Response response = check http2LimitTestClient->get("/responseLimit/statusline", {[X_TEST_TYPE] : [ERROR]});
    test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
    common:assertTextPayload(response.getTextPayload(), "error ClientError (\"Response max " +
                "status line length exceeds: An HTTP line is larger than 1024 bytes.\")");
}

//Test when header size is less than the configured maxHeaderSize threshold
@test:Config {}
function testHttp2ValidHeaderLengthOfResponse() returns error? {
    http:Response response = check http2LimitTestClient->get("/responseLimit/header", {[X_TEST_TYPE] : [SUCCESS]});
    test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check response.getHeader(X_HEADER), "Validated");
    common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
}

//Test when header size is greater than the configured maxHeaderSize threshold
// todo: disabled due to missing feature
// @test:Config {}
function testHttp2InvalidHeaderLengthOfResponse() returns error? {
    http:Response response = check http2LimitTestClient->get("/responseLimit/header", {[X_TEST_TYPE] : [ERROR]});
    test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
    common:assertTextPayload(response.getTextPayload(), "error ClientError (\"Response max " +
                "header size exceeds: HTTP header is larger than 1024 bytes.\")");
    var header = response.getHeader(X_HEADER);
    if header is error {
        test:assertEquals(header.message(), "Http header does not exist", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

//Test when entityBody size is less than the configured maxEntityBodySize threshold
@test:Config {}
function testHttp2ValidEntityBodyLength() returns error? {
    http:Response response = check http2LimitTestClient->get("/responseLimit/entitybody", {[X_TEST_TYPE] : [SUCCESS]});
    test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    common:assertTextPayload(response.getTextPayload(), "Small payload");
}

//Test when entityBody size is greater than the configured maxEntityBodySize threshold
// todo: disabled due to missing feature
// @test:Config {}
function testHttp2InvalidEntityBodyLength() returns error? {
    http:Response response = check http2LimitTestClient->get("/responseLimit/statusline", {[X_TEST_TYPE] : [ERROR]});
    test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
    common:assertTextPayload(response.getTextPayload(), "error ClientError (\"Response max " +
                "status line length exceeds: An HTTP line is larger than 1024 bytes.\")");
}
