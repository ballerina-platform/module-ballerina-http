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

listener http:Listener httpUrlListenerEP1 = new(httpUrlTestPort1);
listener http:Listener httpUrlListenerEP2 = new(httpUrlTestPort2);
http:Client httpUrlClient = check new("http://localhost:" + httpUrlTestPort1.toString());

http:Client urlClient = check new("http://localhost:" + httpUrlTestPort2.toString() + "//url", { cache: { enabled: false }});

service "/url//test" on httpUrlListenerEP2 {

    resource function get .(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Hello");
    }
}

service "//url" on httpUrlListenerEP1  {

    resource function get .(http:Caller caller, http:Request request) {
        string value = "";
        http:Response|error response = urlClient->get("//test");
        if (response is http:Response) {
            var result = response.getTextPayload();
            if (result is string) {
                value = result;
            } else {
                value = result.message();
            }
        }
        checkpanic caller->respond(<@untainted> value);
    }
}

//Test for handling double slashes
@test:Config {}
function testUrlDoubleSlash() {
    http:Response|error response = httpUrlClient->get("/url");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testResourcePathWithoutStartingSlash() returns error? {
    http:Client httpUrlClient = check new("http://localhost:" + httpUrlTestPort1.toString() + "/");
    http:Response|error response = httpUrlClient->get("url");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testResourcePathWithEmptyPath() returns error? {
    http:Client httpUrlClient = check new("http://localhost:" + httpUrlTestPort1.toString() + "/url/");
    http:Response|error response = httpUrlClient->get("");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}


@test:Config {}
function testResourcePathWithQueryParam() returns error? {
    http:Client httpUrlClient = check new("http://localhost:" + httpUrlTestPort1.toString() + "/url");
    http:Response|error response = httpUrlClient->get("?abc=go&xyz=no");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testResourcePathWithFragmentParam() returns error? {
    http:Client httpUrlClient = check new("http://localhost:" + httpUrlTestPort1.toString() + "/url");
    http:Response|error response = httpUrlClient->get("#foo");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testResourcePathNegative() returns error? {
    http:Client httpUrlClient = check new("http://localhost:" + httpUrlTestPort1.toString());
    http:Response|error response = httpUrlClient->get("url");
    if (response is error) {
        test:assertEquals(response.message(),
            "client method invocation failed: malformed URL specified. Error at index 4 in: \"9521url\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: http:Response");
    }
}

@test:Config {}
function testResourcePath404Negative() returns error? {
    http:Response|error response = urlClient->get("test");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "no matching service found for path : /urltest");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
