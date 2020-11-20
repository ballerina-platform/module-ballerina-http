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

import ballerina/runtime;
import ballerina/test;
import ballerina/http;

http:Client cachingEP4 = new("http://localhost:" + cachingTestPort4.toString(), { cache: { isShared: true } });

@http:ServiceConfig {
    basePath: "/validation-request"
}
service cachingProxy2 on cachingProxyListener {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function cacheableProxyResource(http:Caller caller, http:Request req) {
        var response = cachingEP4->forward("/validation-req-be", req);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else if (response is error) {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(<@untainted> response.message());
            checkpanic caller->respond(<@untainted> res);
        }
    }
}

@http:ServiceConfig {
    basePath: "/validation-req-be"
}
service cachingBackEnd2 on cachingBackendListener {

    @http:ResourceConfig { path: "/" }
    resource function mustRevalidate(http:Caller caller, http:Request req) {
        json payload = {"message":"Hello, World!"};
        http:Response res = new;
        http:ResponseCacheControl resCC = new;
        resCC.mustRevalidate = true;
        resCC.maxAge = 3;
        res.cacheControl = resCC;
        res.setETag(payload);
        res.setPayload(payload);
        res.setHeader("x-caller-req-header", req.getHeader("x-caller-req-header"));

        checkpanic caller->respond(<@untainted>res);
    }
}

//Test preservation of caller request headers in the validation request
@test:Config {}
function testCallerRequestHeaderPreservation() {
    string callerReqHeader = "x-caller-req-header";    

    http:Request req = new;
    req.setHeader(callerReqHeader, "First Request");
    var response = cachingProxyTestClient->get("/validation-request", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(callerReqHeader), "First Request");
        test:assertFalse(response.hasHeader(IF_NONE_MATCH));
        test:assertFalse(response.hasHeader(IF_MODIFIED_SINCE));
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

// Since this request gets served straight from the cache, the value of 'x-caller-req-header' doesn't change.
    req = new;
    req.setHeader(callerReqHeader, "Second Request");
    response = cachingProxyTestClient->get("/validation-request", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(callerReqHeader), "First Request");
        test:assertFalse(response.hasHeader(IF_NONE_MATCH));
        test:assertFalse(response.hasHeader(IF_MODIFIED_SINCE));
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    // Wait for a while before sending the next request
    runtime:sleep(3000);

    req = new;
    req.setHeader(callerReqHeader, "Third Request");
    response = cachingProxyTestClient->get("/validation-request", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(callerReqHeader), "Third Request");
        test:assertFalse(response.hasHeader(IF_NONE_MATCH));
        test:assertFalse(response.hasHeader(IF_MODIFIED_SINCE));
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preservation of caller request headers in the validation request
@test:Config {enable: false}
function testCallerRequestHeaderPreservation2() {
    http:Request req = new;
    req.setHeader(IF_NONE_MATCH, "c854ce2c");
    var response = cachingProxyTestClient->get("/validation-request", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 304, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Hello from POST!Hello from POST!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
