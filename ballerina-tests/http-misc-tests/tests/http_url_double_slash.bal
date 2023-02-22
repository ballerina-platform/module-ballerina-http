// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

listener http:Listener httpUrlListenerEP1 = new (httpUrlTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener httpUrlListenerEP2 = new (httpUrlTestPort2, httpVersion = http:HTTP_1_1);
final http:Client httpUrlClient = check new ("http://localhost:" + httpUrlTestPort1.toString(), httpVersion = http:HTTP_1_1);

final http:Client urlClient = check new ("http://localhost:" + httpUrlTestPort2.toString() + "//url", httpVersion = http:HTTP_1_1, cache = {enabled: false});

service "/url//test" on httpUrlListenerEP2 {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello");
    }
}

service "//url" on httpUrlListenerEP1 {

    resource function get .(http:Caller caller, http:Request request) returns error? {
        string value = "";
        http:Response|error response = urlClient->get("//test");
        if response is http:Response {
            var result = response.getTextPayload();
            if result is string {
                value = result;
            } else {
                value = result.message();
            }
        }
        check caller->respond(value);
    }
}

service / on httpUrlListenerEP1 {

    resource function get foo() returns http:Ok {
        return {body: {name: "foo"}};
    }
}

//Test for handling double slashes
@test:Config {}
function testUrlDoubleSlash() returns error? {
    http:Response|error response = httpUrlClient->get("/url");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testResourcePathWithoutStartingSlash() returns error? {
    http:Client httpUrlClient = check new ("http://localhost:" + httpUrlTestPort1.toString() + "/", httpVersion = http:HTTP_1_1);
    http:Response|error response = httpUrlClient->get("url");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {}
function testResourcePathWithEmptyPath() returns error? {
    http:Client httpUrlClient = check new ("http://localhost:" + httpUrlTestPort1.toString() + "/url/", httpVersion = http:HTTP_1_1);
    http:Response|error response = httpUrlClient->get("");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {}
function testResourcePathWithQueryParam() returns error? {
    http:Client httpUrlClient = check new ("http://localhost:" + httpUrlTestPort1.toString() + "/url", httpVersion = http:HTTP_1_1);
    http:Response|error response = httpUrlClient->get("?abc=go&xyz=no");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {}
function testResourcePathWithFragmentParam() returns error? {
    http:Client httpUrlClient = check new ("http://localhost:" + httpUrlTestPort1.toString() + "/url", httpVersion = http:HTTP_1_1);
    http:Response|error response = httpUrlClient->get("#foo");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {}
function testResourcePathNegative() returns error? {
    http:Client httpUrlClient = check new ("http://localhost:" + httpUrlTestPort1.toString(), httpVersion = http:HTTP_1_1);
    http:Response|error response = httpUrlClient->get("url");
    if response is error {
        test:assertEquals(response.message(),
            "client method invocation failed: malformed URL specified. Error at index 4 in: \"9521url\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: http:Response");
    }
    return;
}

@test:Config {}
function testResourcePath404Negative() returns error? {
    http:Response|error response = urlClient->get("test");
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "no matching service found for path : /urltest");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {}
public function testClientWithDoubleURLs() returns error? {
    json response = check httpUrlClient->get("/foo");
    test:assertEquals(response, {name: "foo"});
}
