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

import ballerina/lang.runtime as runtime;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

final http:Client cachingEP3 = check new ("http://localhost:" + cachingTestPort4.toString(),
    httpVersion = http:HTTP_1_1, cache = {isShared: true});
int numberOfProxyHits = 0;

service /mustRevalidate on cachingProxyListener {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        lock {
            numberOfProxyHits += 1;
        }
        http:Response|error response = cachingEP3->forward("/mustRevalidateBE", req);
        if response is http:Response {
            string value = "";
            lock {
                value = numberOfProxyHits.toString();
            }
            response.setHeader("x-proxy-hit-count", value);
            check caller->respond(response);
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(response.message());
            check caller->respond(res);
        }
    }
}

int numberOfHits = 0;

service /mustRevalidateBE on cachingBackendListener {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        json payload = {};
        http:Response res = new;
        http:ResponseCacheControl resCC = new;
        payload = {"message": "Hello, World!"};
        resCC.mustRevalidate = true;
        resCC.maxAge = 5;
        res.cacheControl = resCC;
        res.setETag(payload);
        lock {
            numberOfHits += 1;
        }
        res.setPayload(payload);
        string value = "";
        lock {
            value = numberOfHits.toString();
        }
        res.setHeader("x-service-hit-count", value);

        check caller->respond(res);
    }
}

//Test must-revalidate cache control
@test:Config {}
function testMustRevalidateCacheControl() returns error? {
    http:Response|error response = cachingProxyTestClient->get("/mustRevalidate");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(serviceHitCount), "1");
        common:assertHeaderValue(check response.getHeader(proxyHitCount), "1");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cachingProxyTestClient->get("/mustRevalidate");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(serviceHitCount), "1");
        common:assertHeaderValue(check response.getHeader(proxyHitCount), "2");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    // Wait for a while before sending the next request
    runtime:sleep(5);

    response = cachingProxyTestClient->get("/mustRevalidate");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(serviceHitCount), "2");
        common:assertHeaderValue(check response.getHeader(proxyHitCount), "3");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

