// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/lang.runtime as runtime;
import ballerina/http;
import ballerina/log;

http:Client cacheClientEP = check new("http://localhost:" + cacheAnnotationTestPort1.toString(), { cache: { enabled: false }});

http:Client cacheBackendEP = check new("http://localhost:" + cacheAnnotationTestPort2.toString(), { cache: { isShared: true } });

int numberOfProxyHitsNew = 0;

service / on new http:Listener(cacheAnnotationTestPort1) {

    resource function get noCache(http:Caller caller, http:Request req) {
        http:Response|error response = cacheBackendEP->forward("/nocacheBE", req);
        if (response is http:Response) {
            checkpanic caller->respond(response);
        } else {
            log:printError(response.message());
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(response.message());
            checkpanic caller->respond(res);
        }
    }

    resource function get maxAge(http:Caller caller, http:Request req) {
        http:Response|error response = cacheBackendEP->forward("/maxAgeBE", req);
        if (response is http:Response) {
            checkpanic caller->respond(response);
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(response.message());
            checkpanic caller->respond(res);
        }
    }

    resource function get mustRevalidate(http:Caller caller, http:Request req) {
        numberOfProxyHitsNew += 1;
        http:Response|error response = cacheBackendEP->forward("/mustRevalidateBE", req);
        if (response is http:Response) {
            response.setHeader("x-proxy-hit-count", numberOfProxyHitsNew.toString());
            checkpanic caller->respond(response);
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(response.message());
            checkpanic caller->respond(res);
        }
    }
}

int noCacheHitCountNew = 0;
int maxAgeHitCountNew = 0;
int numberOfHitsNew = 0;

service / on new http:Listener(cacheAnnotationTestPort2) {

    resource function default nocacheBE(http:Request req) returns @http:CacheConfig{noCache : true, setETag : true}
            http:Response {
        json nocachePayload = {};
        http:Response res = new;
        if (noCacheHitCountNew < 1) {
            nocachePayload = { "message": "1st response" };
        } else {
            nocachePayload = { "message": "2nd response" };
        }
        noCacheHitCountNew += 1;
        res.setHeader("x-service-hit-count", noCacheHitCountNew.toString());
        res.setPayload(nocachePayload);

        return res;
    }

    resource function default maxAgeBE(http:Request req) returns @http:CacheConfig{maxAge : 5, setETag : true}
            http:Response {
        http:Response res = new;
        if (maxAgeHitCountNew < 1) {
            maxAgePayload = { "message": "before cache expiration" };
        } else {
            maxAgePayload = { "message": "after cache expiration" };
        }
        maxAgeHitCountNew += 1;
        res.setPayload(maxAgePayload);

        return res;
    }

    resource function get mustRevalidateBE(http:Caller caller, http:Request req) returns
            @http:CacheConfig{mustRevalidate : true, maxAge : 5, setETag : true} http:Response {
        http:Response res = new;
        json payload = {"message" : "Hello, World!"};
        numberOfHitsNew += 1;
        res.setPayload(payload);
        res.setHeader("x-service-hit-count", numberOfHitsNew.toString());

        return res;
    }
}

@test:Config {}
function testNoCacheCacheControlWithAnnotation() {
    http:Response|error response = cacheClientEP->get("/noCache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(serviceHitCount), "1");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {message:"1st response"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cacheClientEP->get("/noCache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(serviceHitCount), "2");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {message:"2nd response"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cacheClientEP->get("/noCache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(serviceHitCount), "3");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {message:"2nd response"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMaxAgeCacheControlWithAnnotation() {
    http:Response|error response = cacheClientEP->get("/maxAge");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), { "message": "before cache expiration" });
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cacheClientEP->get("/maxAge");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), { "message": "before cache expiration" });
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    // Wait for a while before sending the next request
    runtime:sleep(5);

    response = cacheClientEP->get("/maxAge");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {message:"after cache expiration"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMustRevalidateCacheControlWithAnnotation() {
    http:Response|error response = cacheClientEP->get("/mustRevalidate");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(serviceHitCount), "1");
        assertHeaderValue(checkpanic response.getHeader(proxyHitCount), "1");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cacheClientEP->get("/mustRevalidate");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(serviceHitCount), "1");
        assertHeaderValue(checkpanic response.getHeader(proxyHitCount), "2");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    // Wait for a while before sending the next request
    runtime:sleep(5);

    response = cacheClientEP->get("/mustRevalidate");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(serviceHitCount), "2");
        assertHeaderValue(checkpanic response.getHeader(proxyHitCount), "3");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
