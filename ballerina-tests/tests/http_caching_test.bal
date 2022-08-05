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

listener http:Listener cachingListener1 = new(cachingTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener cachingListener2 = new(cachingTestPort2, httpVersion = http:HTTP_1_1);

final http:Client cachingTestClient = check new("http://localhost:" + cachingTestPort1.toString(), 
    httpVersion = http:HTTP_1_1, cache = { enabled: false });

final http:Client cachingEP = check new("http://localhost:" + cachingTestPort2.toString(), 
    httpVersion = http:HTTP_1_1, cache = { isShared: true });
int cachingProxyHitcount = 0;

service /cache on cachingListener1 {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = cachingEP->forward("/cachingBackend", req);

        if response is http:Response {
            lock {
                cachingProxyHitcount += 1;
            }
            string value = "";
            lock {
                value = cachingProxyHitcount.toString();
            }
            response.setHeader("x-proxy-hit-count", value);
            check caller->respond( response);
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload( response.message());
            check caller->respond(res);
        }
    }

    resource function get checkReqCC(http:Request req) returns json {
        http:RequestCacheControl? reqCC = req.cacheControl;
        if reqCC is http:RequestCacheControl {
            json value = { noCache : reqCC.noCache, noStore : reqCC.noStore, noTransform : reqCC.noTransform,
                onlyIfCached : reqCC.onlyIfCached, maxAge : reqCC.maxAge, maxStale : reqCC.maxStale,
                minFresh : reqCC.minFresh };
            return value;
        } else {
            return { value : "no reqCC"};
        }
    }

    resource function get checkResCC(http:Request req) returns http:Ok {
        string hValue = "must-revalidate, no-cache, no-store, no-transform, public, proxy-revalidate, " +
                        "max-age=60, s-maxage=65";
        return { headers: { "Cache-Control": hValue }};
    }
}

isolated int hitcount = 0;

isolated function incrementHitCount() {
    lock {
        hitcount += 1;
    }
}

isolated function getHitCount() returns int {
    lock {
        return hitcount;
    }
}

service /cachingBackend on cachingListener2 {//new http:Listener(9240) {

    isolated resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        http:ResponseCacheControl resCC = new;
        resCC.maxAge = 60;
        resCC.isPrivate = false;

        res.cacheControl = resCC;
        json payload = { "message": "Hello, World!" };
        res.setETag(payload);
        res.setLastModified();
        incrementHitCount();
        res.setHeader("x-service-hit-count", getHitCount().toString());

        res.setPayload(payload);

        check caller->respond(res);
    }
}

const string serviceHitCount = "x-service-hit-count";
const string proxyHitCount = "x-proxy-hit-count";
json cachingPayload = {message:"Hello, World!"};

//Test basic caching behaviour
@test:Config {}
function testBasicCachingBehaviour() returns error? {
    http:Response|error response = cachingTestClient->get("/cache");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(serviceHitCount), "1");
        assertHeaderValue(check response.getHeader(proxyHitCount), "1");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cachingTestClient->get("/cache");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(serviceHitCount), "1");
        assertHeaderValue(check response.getHeader(proxyHitCount), "2");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    // Wait for a while before sending the next request
    runtime:sleep(1);

    response = cachingTestClient->get("/cache");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(serviceHitCount), "1");
        assertHeaderValue(check response.getHeader(proxyHitCount), "3");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testRequestCacheControlBuildCacheControlDirectives() {
    http:RequestCacheControl reqCC = new;
    reqCC.maxAge = 60;
    reqCC.noCache = true;
    reqCC.noStore = true;
    reqCC.noTransform = true;
    reqCC.onlyIfCached = true;
    reqCC.maxStale = 120;
    reqCC.minFresh = 6;
    test:assertEquals(reqCC.buildCacheControlDirectives(),
        "no-cache, no-store, no-transform, only-if-cached, max-age=60, max-stale=120, min-fresh=6");
}

@test:Config {}
function testResponseCacheControlBuildCacheControlDirectives() {
    http:ResponseCacheControl resCC = new;
    resCC.maxAge = 60;
    resCC.isPrivate = false;
    resCC.mustRevalidate = true;
    resCC.noCache = true;
    resCC.noStore = true;
    resCC.noTransform = true;
    resCC.proxyRevalidate = true;
    resCC.sMaxAge = 60;
    test:assertEquals(resCC.buildCacheControlDirectives(),
        "must-revalidate, no-cache, no-store, no-transform, public, proxy-revalidate, max-age=60, s-maxage=60");
}

@test:Config {}
function testReqCCPopulation() {
    string hValue = "no-cache, no-store, no-transform, only-if-cached, max-age=60, max-stale=120, min-fresh=6";
    json|error response = cachingTestClient->get("/cache/checkReqCC", { "Cache-Control": hValue });
    if response is json {
        json expected =
            {noCache:true,noStore:true,noTransform:true,onlyIfCached:true,maxAge:60,maxStale:120,minFresh:6};
        test:assertEquals(response, expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testResCCPopulation() {
    http:Response|error response = cachingTestClient->get("/cache/checkResCC");
    if response is http:Response {
        http:ResponseCacheControl? resCC = response.cacheControl;
        if resCC is http:ResponseCacheControl {
            test:assertEquals(resCC.mustRevalidate, true);
            test:assertEquals(resCC.noCache, true);
            test:assertEquals(resCC.noStore, true);
            test:assertEquals(resCC.noTransform, true);
            test:assertEquals(resCC.isPrivate, false);
            test:assertEquals(resCC.proxyRevalidate, true);
            test:assertEquals(resCC.maxAge, 60d);
            test:assertEquals(resCC.sMaxAge, 65d);
        } else {
            test:assertFail(msg = "Found unexpected output type: ()");
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
