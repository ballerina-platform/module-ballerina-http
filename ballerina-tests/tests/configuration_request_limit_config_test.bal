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

http:ListenerConfiguration urlLimitConfig = {
    requestLimits: {
        maxUriLength: 1024
    }
};

http:ListenerConfiguration lowUrlLimitConfig = {
    requestLimits: {
        maxUriLength: 2
    }
};

http:ListenerConfiguration lowHeaderConfig = {
    requestLimits: {
        maxHeaderSize: 30
    }
};

http:ListenerConfiguration midSizeHeaderConfig = {
    requestLimits: {
        maxHeaderSize: 100
    }
};

http:ListenerConfiguration http2lowHeaderConfig = {
    httpVersion: "2.0",
    requestLimits: {
        maxHeaderSize: 30
    }
};

http:ListenerConfiguration lowPayloadConfig = {
    requestLimits: {
        maxEntityBodySize: 10
    }
};

listener http:Listener normalRequestLimitEP = new(requestLimitsTestPort1, urlLimitConfig);
listener http:Listener lowRequestLimitEP = new(requestLimitsTestPort2, lowUrlLimitConfig);
listener http:Listener lowHeaderLimitEP = new(requestLimitsTestPort3, lowHeaderConfig);
listener http:Listener midHeaderLimitEP = new(requestLimitsTestPort4, midSizeHeaderConfig);
listener http:Listener http2HeaderLimitEP = new(requestLimitsTestPort5, http2lowHeaderConfig);
listener http:Listener lowPayloadLimitEP = new(requestLimitsTestPort6, lowPayloadConfig);

service /requestUriLimit on normalRequestLimitEP {

    resource function get validUrl(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Hello World!!!");
    }
}

service /lowRequestUriLimit on lowRequestLimitEP {

    resource function get invalidUrl(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Hello World!!!");
    }
}

service /lowRequestHeaderLimit on lowHeaderLimitEP {

    resource function get invalidHeaderSize(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Hello World!!!");
    }
}

service /requestHeaderLimit on midHeaderLimitEP {

    resource function get validHeaderSize(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Hello World!!!");
    }
}

service /http2service on http2HeaderLimitEP {

    resource function get invalidHeaderSize(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Hello World!!!");
    }
}

service /requestPayloadLimit on lowPayloadLimitEP {

    resource function post test(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Hello World!!!");
    }
}

//Tests the behaviour when url length is less than the configured threshold
@test:Config {}
function testValidUrlLength() {
    http:Client limitClient = checkpanic new("http://localhost:" + requestLimitsTestPort1.toString());
    http:Response|error response = limitClient->get("/requestUriLimit/validUrl");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(mime:CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests the behaviour when url length is greater than the configured threshold
@test:Config {}
function testInvalidUrlLength() {
    http:Client limitClient = checkpanic new("http://localhost:" + requestLimitsTestPort2.toString());
    http:Response|error response = limitClient->get("/lowRequestUriLimit/invalidUrl");
    if (response is http:Response) {
        //414 Request-URI Too Long
        test:assertEquals(response.statusCode, 414, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests the behaviour when header size is less than the configured threshold
@test:Config {}
function testValidHeaderLength() {
    http:Client limitClient = checkpanic new("http://localhost:" + requestLimitsTestPort4.toString());
    http:Response|error response = limitClient->get("/requestHeaderLimit/validHeaderSize");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(mime:CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests the behaviour when header size is greater than the configured threshold
@test:Config {}
function testInvalidHeaderLength() {
    http:Client limitClient = checkpanic new("http://localhost:" + requestLimitsTestPort3.toString());
    http:Response|error response = limitClient->get("/lowRequestHeaderLimit/invalidHeaderSize", {"X-Test":getLargeHeader()});
    if (response is http:Response) {
        //431 Request Header Fields Too Large
        test:assertEquals(response.statusCode, 431, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function getLargeHeader() returns string {
    string header = "x";
    int i = 0;
    while(i < 9000) {
        header = header + "x";
        i = i + 1;
    }
    return header.toString();
}

// Tests the fallback behaviour when header size is greater than the configured http2 service
@test:Config {}
function testHttp2ServiceInvalidHeaderLength() {
    http:Client limitClient = checkpanic new("http://localhost:" + requestLimitsTestPort5.toString());
    http:Response|error response = limitClient->get("/http2service/invalidHeaderSize", {"X-Test":getLargeHeader()});
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 431, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests the behaviour when payload size is greater than the configured threshold
@test:Config {}
function testInvalidPayloadSize() {
    http:Request req = new;
    req.setTextPayload("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    http:Client limitClient = checkpanic new("http://localhost:" + requestLimitsTestPort6.toString());
    http:Response|error response = limitClient->post("/requestPayloadLimit/test", req);
    if (response is http:Response) {
        //413 Payload Too Large
        test:assertEquals(response.statusCode, 413, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}


