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

import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener cachingProxyListener = new (cachingTestPort3, httpVersion = http:HTTP_1_1);
listener http:Listener cachingBackendListener = new (cachingTestPort4, httpVersion = http:HTTP_1_1);

final http:Client cachingProxyTestClient = check new ("http://localhost:" + cachingTestPort3.toString(),
    httpVersion = http:HTTP_1_1, cache = {enabled: false});

final http:Client cachingEP1 = check new ("http://localhost:" + cachingTestPort4.toString(),
    httpVersion = http:HTTP_1_1, cache = {isShared: true});

service /cachingProxyService on cachingProxyListener {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = cachingEP1->forward("/nocacheBackend", req);
        if response is http:Response {
            check caller->respond(response);
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(response.message());
            check caller->respond(res);
        }
    }
}

int nocachehitcount = 0;

service /nocacheBackend on cachingBackendListener {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        json nocachePayload = {};
        int count = 0;
        lock {
            count = nocachehitcount;
        }
        if count < 1 {
            nocachePayload = {"message": "1st response"};
        } else {
            nocachePayload = {"message": "2nd response"};
        }
        http:Response res = new;
        http:ResponseCacheControl resCC = new;
        res.cacheControl = resCC;
        resCC.noCache = true;
        res.setETag(nocachePayload);
        lock {
            nocachehitcount += 1;
        }
        string value = "";
        lock {
            value = nocachehitcount.toString();
        }
        res.setHeader("x-service-hit-count", value);
        res.setPayload(nocachePayload);

        check caller->respond(res);
    }
}

//Test no-cache cache control
@test:Config {}
function testNoCacheCacheControl() returns error? {
    http:Response|error response = cachingProxyTestClient->get("/cachingProxyService");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(serviceHitCount), "1");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {message: "1st response"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cachingProxyTestClient->get("/cachingProxyService");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(serviceHitCount), "2");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {message: "2nd response"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cachingProxyTestClient->get("/cachingProxyService");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(serviceHitCount), "3");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {message: "2nd response"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
