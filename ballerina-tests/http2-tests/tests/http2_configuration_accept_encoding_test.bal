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

import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

int http2AcceptEncodingHeaderTestPort = common:getHttp2Port(acceptEncodingHeaderTestPort);

listener http:Listener http2AcceptEncodingListenerEP = new (http2AcceptEncodingHeaderTestPort, server = "Mysql");

final http:Client http2AcceptEncodingAutoEP = check new ("http://localhost:" + http2AcceptEncodingHeaderTestPort.toString() + "/hello",
    http2Settings = {http2PriorKnowledge: true}, compression = http:COMPRESSION_AUTO);

final http:Client http2AcceptEncodingEnableEP = check new ("http://localhost:" + http2AcceptEncodingHeaderTestPort.toString() + "/hello",
    http2Settings = {http2PriorKnowledge: true}, compression = http:COMPRESSION_ALWAYS);

final http:Client http2AcceptEncodingDisableEP = check new ("http://localhost:" + http2AcceptEncodingHeaderTestPort.toString() + "/hello",
    http2Settings = {http2PriorKnowledge: true}, compression = http:COMPRESSION_NEVER);

service /hello on http2AcceptEncodingListenerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json payload = {};
        boolean hasHeader = req.hasHeader(common:ACCEPT_ENCODING);
        if hasHeader {
            payload = {acceptEncoding: check req.getHeader(common:ACCEPT_ENCODING)};
        } else {
            payload = {acceptEncoding: "Accept-Encoding header not present."};
        }
        res.setJsonPayload(payload);
        check caller->respond(res);
    }
}

//Tests the behaviour when Accept Encoding option is enable.
@test:Config {}
function testHttp2AcceptEncodingEnabled() {
    http:Request req = new;
    req.setTextPayload("accept encoding test");
    http:Response|error response = http2AcceptEncodingEnableEP->post("/", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertJsonValue(response.getJsonPayload(), "acceptEncoding", "deflate, gzip, br");
        common:assertHeaderValue(response.server, "Mysql");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Tests the behaviour when Accept Encoding option is disable.
@test:Config {}
function testHttp2AcceptEncodingDisabled() returns error? {
    http:Request req = new;
    req.setTextPayload("accept encoding test");
    http:Response response = check http2AcceptEncodingDisableEP->post("/", req);
    test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    common:assertJsonValue(response.getJsonPayload(), "acceptEncoding", "Accept-Encoding header not present.");
}

//Tests the behaviour when Accept Encoding option is auto.
@test:Config {}
function testHttp2AcceptEncodingAuto() {
    http:Request req = new;
    req.setTextPayload("accept encoding test");
    http:Response|error response = http2AcceptEncodingAutoEP->post("/", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertJsonValue(response.getJsonPayload(), "acceptEncoding", "Accept-Encoding header not present.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
