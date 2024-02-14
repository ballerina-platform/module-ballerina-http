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

import ballerina/mime;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener http2HeaderLimitEP = new(requestLimitsTestPort5, http2lowHeaderConfig);

service /http2service on http2HeaderLimitEP {

    resource function get invalidHeaderSize(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

http:ListenerConfiguration http2UrlLimitConfig = {
    requestLimits: {
        maxUriLength: 1024
    }
};

http:ListenerConfiguration http2LowUrlLimitConfig = {
    requestLimits: {
        maxUriLength: 2
    }
};

http:ListenerConfiguration http2lowHeaderConfig = {
    requestLimits: {
        maxHeaderSize: 850
    }
};

http:ListenerConfiguration http2LowHeaderConfig = {
    requestLimits: {
        maxHeaderSize: 850
    }
};

http:ListenerConfiguration http2MidSizeHeaderConfig = {
    requestLimits: {
        maxHeaderSize: 400
    }
};

http:ListenerConfiguration http2LowPayloadConfig = {
    requestLimits: {
        maxEntityBodySize: 10
    }
};

int http2RequestLimitsTestPort1 = common:getHttp2Port(requestLimitsTestPort1);
int http2RequestLimitsTestPort2 = common:getHttp2Port(requestLimitsTestPort2);
int http2RequestLimitsTestPort3 = common:getHttp2Port(requestLimitsTestPort3);
int http2RequestLimitsTestPort4 = common:getHttp2Port(requestLimitsTestPort4);
int http2RequestLimitsTestPort6 = common:getHttp2Port(requestLimitsTestPort6);

listener http:Listener http2NormalRequestLimitEP = new (http2RequestLimitsTestPort1, http2UrlLimitConfig);
listener http:Listener http2LowRequestLimitEP = new (http2RequestLimitsTestPort2, http2LowUrlLimitConfig);
listener http:Listener http2LowHeaderLimitEP = new (http2RequestLimitsTestPort3, http2LowHeaderConfig);
listener http:Listener http2MidHeaderLimitEP = new (http2RequestLimitsTestPort4, http2MidSizeHeaderConfig);
listener http:Listener http2LowPayloadLimitEP = new (http2RequestLimitsTestPort6, http2LowPayloadConfig);

service /requestUriLimit on http2NormalRequestLimitEP {

    resource function get validUrl(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

service /lowRequestUriLimit on http2LowRequestLimitEP {

    resource function get invalidUrl(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

service /lowRequestHeaderLimit on http2LowHeaderLimitEP {

    resource function get invalidHeaderSize(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

service /requestHeaderLimit on http2MidHeaderLimitEP {

    resource function get validHeaderSize(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

service /requestPayloadLimit on http2LowPayloadLimitEP {

    resource function post test(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello World!!!");
    }
}

//Tests the behaviour when url length is less than the configured threshold
@test:Config {}
function testHttp2ValidUrlLength() returns error? {
    http:Client limitClient = check new ("http://localhost:" + http2RequestLimitsTestPort1.toString(),
        http2Settings = {http2PriorKnowledge: true});
    http:Response response = check limitClient->get("/requestUriLimit/validUrl");
    test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check response.getHeader(mime:CONTENT_TYPE), common:TEXT_PLAIN);
    common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
}

//Tests the behaviour when url length is greater than the configured threshold
// todo: disabled due to missing feature
// @test:Config {}
function testHttp2InvalidUrlLength() returns error? {
    http:Client limitClient = check new ("http://localhost:" + http2RequestLimitsTestPort2.toString(),
        http2Settings = {http2PriorKnowledge: true});
    http:Response response = check limitClient->get("/lowRequestUriLimit/invalidUrl");
    //414 Request-URI Too Long
    test:assertEquals(response.statusCode, 414, msg = "Found unexpected output");
}

//Tests the behaviour when header size is less than the configured threshold
@test:Config {}
function testHttp2ValidHeaderLength() returns error? {
    http:Client limitClient = check new ("http://localhost:" + http2RequestLimitsTestPort4.toString(),
        http2Settings = {http2PriorKnowledge: true});
    http:Response response = check limitClient->get("/requestHeaderLimit/validHeaderSize");
    test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check response.getHeader(mime:CONTENT_TYPE), common:TEXT_PLAIN);
    common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
}

//Tests the behaviour when header size is greater than the configured threshold
// TODO: Enable after fixing this issue : https://github.com/ballerina-platform/ballerina-library/issues/4461
@test:Config {enable: false}
function testHttp2InvalidHeaderLength() returns error? {
    http:Client limitClient = check new ("http://localhost:" + http2RequestLimitsTestPort3.toString(),
        http2Settings = {http2PriorKnowledge: true});
    http:Response|http:Error response = limitClient->get("/lowRequestHeaderLimit/invalidHeaderSize", {"X-Test": getLargeHeader()});
    //431 Request Header Fields Too Large
    if response is http:Error {
        test:assertTrue(response is http:ClientError);
        test:assertEquals(response.message(), "Header size exceeded max allowed size (600)");
    } else {
        test:assertEquals(response.statusCode, 431, msg = "Found unexpected output");
    }
}

// Tests the fallback behaviour when header size is greater than the configured http2 service
// TODO: Enable after fixing this issue : https://github.com/ballerina-platform/ballerina-standard-library/issues/3963
@test:Config {}
function testHttp2Http2ServiceInvalidHeaderLength() returns error? {
    http:Client limitClient = check new ("http://localhost:" + requestLimitsTestPort5.toString(),
        http2Settings = {http2PriorKnowledge: true});
    http:Response|http:Error response = limitClient->get("/http2service/invalidHeaderSize", {"X-Test": getLargeHeader()});
    if response is http:Error {
        test:assertTrue(response is http:ClientError);
        test:assertEquals(response.message(), "Header size exceeded max allowed size (850)");
    } else {
        test:assertEquals(response.statusCode, 431, msg = "Found unexpected output");
    }
}

//Tests the behaviour when payload size is greater than the configured threshold
// todo: disabled due to missing feature
// @test:Config {}
function testHttp2InvalidPayloadSize() returns error? {
    http:Request req = new;
    req.setTextPayload("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    http:Client limitClient = check new ("http://localhost:" + http2RequestLimitsTestPort6.toString(),
        http2Settings = {http2PriorKnowledge: true});
    http:Response response = check limitClient->post("/requestPayloadLimit/test", req);
    //413 Payload Too Large
    test:assertEquals(response.statusCode, 413, msg = "Found unexpected output");
}

