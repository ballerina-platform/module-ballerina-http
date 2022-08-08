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

import ballerina/lang.runtime as runtime;
import ballerina/test;
import ballerina/http;

final http:Client cachingEP4 = check new("http://localhost:" + cachingTestPort4.toString(), 
    httpVersion = http:HTTP_1_1, cache = { isShared: true });

service /validation\-request on cachingProxyListener {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = cachingEP4->forward("/validation-req-be", req);
        if response is http:Response {
            check caller->respond( response);
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload( response.message());
            check caller->respond( res);
        }
    }
}

service /validation\-req\-be on cachingBackendListener {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        json payload = {"message":"Hello, World!"};
        http:Response res = new;
        http:ResponseCacheControl resCC = new;
        resCC.mustRevalidate = true;
        resCC.maxAge = 3;
        res.cacheControl = resCC;
        res.setETag(payload);
        res.setPayload(payload);
        res.setHeader("x-caller-req-header", check req.getHeader("x-caller-req-header"));

        check caller->respond(res);
    }
}

//Test preservation of caller request headers in the validation request
@test:Config {}
function testCallerRequestHeaderPreservation() returns error? {
    string callerReqHeader = "x-caller-req-header";    

    http:Response|error response = cachingProxyTestClient->get("/validation-request", {[callerReqHeader]:"First Request"});
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(callerReqHeader), "First Request");
        test:assertFalse(response.hasHeader(IF_NONE_MATCH));
        test:assertFalse(response.hasHeader(IF_MODIFIED_SINCE));
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

// Since this request gets served straight from the cache, the value of 'x-caller-req-header' doesn't change.
    response = cachingProxyTestClient->get("/validation-request", {[callerReqHeader]:"Second Request"});
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(callerReqHeader), "First Request");
        test:assertFalse(response.hasHeader(IF_NONE_MATCH));
        test:assertFalse(response.hasHeader(IF_MODIFIED_SINCE));
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    // Wait for a while before sending the next request
    runtime:sleep(3);

    response = cachingProxyTestClient->get("/validation-request", {[callerReqHeader]:"Third Request"});
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(callerReqHeader), "Third Request");
        test:assertFalse(response.hasHeader(IF_NONE_MATCH));
        test:assertFalse(response.hasHeader(IF_MODIFIED_SINCE));
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preservation of caller request headers in the validation request
@test:Config {enable: false}
function testCallerRequestHeaderPreservation2() {
    http:Response|error response = cachingProxyTestClient->get("/validation-request", {[IF_NONE_MATCH]:"c854ce2c"});
    if response is http:Response {
        test:assertEquals(response.statusCode, 304, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Hello from POST!Hello from POST!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
