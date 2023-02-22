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

import ballerina/mime;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

http:ListenerConfiguration urlLimitConfig = {
    httpVersion: http:HTTP_1_1,
    requestLimits: {
        maxUriLength: 1024
    }
};

http:ListenerConfiguration lowUrlLimitConfig = {
    httpVersion: http:HTTP_1_1,
    requestLimits: {
        maxUriLength: 2
    }
};

http:ListenerConfiguration lowHeaderConfig = {
    httpVersion: http:HTTP_1_1,
    requestLimits: {
        maxHeaderSize: 30
    }
};

http:ListenerConfiguration midSizeHeaderConfig = {
    httpVersion: http:HTTP_1_1,
    requestLimits: {
        maxHeaderSize: 100
    }
};

http:ListenerConfiguration http2lowHeaderConfig = {
    requestLimits: {
        maxHeaderSize: 30
    }
};

http:ListenerConfiguration lowPayloadConfig = {
    httpVersion: http:HTTP_1_1,
    requestLimits: {
        maxEntityBodySize: 10
    }
};

listener http:Listener normalRequestLimitEP = new (requestLimitsTestPort1, urlLimitConfig);
listener http:Listener lowRequestLimitEP = new (requestLimitsTestPort2, lowUrlLimitConfig);
listener http:Listener lowHeaderLimitEP = new (requestLimitsTestPort3, lowHeaderConfig);
listener http:Listener midHeaderLimitEP = new (requestLimitsTestPort4, midSizeHeaderConfig);
listener http:Listener http2HeaderLimitEP = new (requestLimitsTestPort5, http2lowHeaderConfig);
listener http:Listener lowPayloadLimitEP = new (requestLimitsTestPort6, lowPayloadConfig);

service /requestUriLimit on normalRequestLimitEP {

    resource function get validUrl(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

service /lowRequestUriLimit on lowRequestLimitEP {

    resource function get invalidUrl(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

service /lowRequestHeaderLimit on lowHeaderLimitEP {

    resource function get invalidHeaderSize(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

service /requestHeaderLimit on midHeaderLimitEP {

    resource function get validHeaderSize(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

service /requestPayloadLimit on lowPayloadLimitEP {

    resource function post test(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

service /http2service on http2HeaderLimitEP {

    resource function get invalidHeaderSize(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

//Tests the behaviour when url length is less than the configured threshold
@test:Config {}
function testValidUrlLength() returns error? {
    http:Client limitClient = check new ("http://localhost:" + requestLimitsTestPort1.toString(), httpVersion = http:HTTP_1_1);
    http:Response|error response = limitClient->get("/requestUriLimit/validUrl");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(mime:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests the behaviour when url length is greater than the configured threshold
@test:Config {}
function testInvalidUrlLength() returns error? {
    http:Client limitClient = check new ("http://localhost:" + requestLimitsTestPort2.toString(), httpVersion = http:HTTP_1_1);
    http:Response|error response = limitClient->get("/lowRequestUriLimit/invalidUrl");
    if response is http:Response {
        //414 Request-URI Too Long
        test:assertEquals(response.statusCode, 414, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests the behaviour when header size is less than the configured threshold
@test:Config {}
function testValidHeaderLength() returns error? {
    http:Client limitClient = check new ("http://localhost:" + requestLimitsTestPort4.toString(), httpVersion = http:HTTP_1_1);
    http:Response|error response = limitClient->get("/requestHeaderLimit/validHeaderSize");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(mime:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests the behaviour when header size is greater than the configured threshold
@test:Config {}
function testInvalidHeaderLength() returns error? {
    http:Client limitClient = check new ("http://localhost:" + requestLimitsTestPort3.toString(), httpVersion = http:HTTP_1_1);
    http:Response|error response = limitClient->get("/lowRequestHeaderLimit/invalidHeaderSize", {"X-Test": getLargeHeader()});
    if response is http:Response {
        //431 Request Header Fields Too Large
        test:assertEquals(response.statusCode, 431, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function getLargeHeader() returns string {
    string header = "x";
    int i = 0;
    while (i < 9000) {
        header = header + "x";
        i = i + 1;
    }
    return header.toString();
}

//Tests the behaviour when payload size is greater than the configured threshold
@test:Config {}
function testInvalidPayloadSize() returns error? {
    http:Request req = new;
    req.setTextPayload("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    http:Client limitClient = check new ("http://localhost:" + requestLimitsTestPort6.toString(), httpVersion = http:HTTP_1_1);
    http:Response|error response = limitClient->post("/requestPayloadLimit/test", req);
    if response is http:Response {
        //413 Payload Too Large
        test:assertEquals(response.statusCode, 413, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

