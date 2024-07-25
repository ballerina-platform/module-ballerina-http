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

import ballerina/lang.runtime as runtime;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

int http2CachingTestPort1 = common:getHttp2Port(cachingTestPort1);
int http2CachingTestPort2 = common:getHttp2Port(cachingTestPort2);

listener http:Listener http2CachingListener1 = new (http2CachingTestPort1);
listener http:Listener http2CachingListener2 = new (http2CachingTestPort2);
final http:Client http2CachingTestClient = check new ("http://localhost:" + http2CachingTestPort1.toString(),
    http2Settings = {http2PriorKnowledge: true}, cache = {enabled: false});

final http:Client http2CachingEP = check new ("http://localhost:" + http2CachingTestPort2.toString(),
    http2Settings = {http2PriorKnowledge: true}, cache = {isShared: true});

int http2CachingProxyHitcount = 0;

service /cache on http2CachingListener1 {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = http2CachingEP->forward("/cachingBackend", req);

        if response is http:Response {
            lock {
                http2CachingProxyHitcount += 1;
            }
            string value = "";
            lock {
                value = http2CachingProxyHitcount.toString();
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

    resource function get checkReqCC(http:Request req) returns json {
        http:RequestCacheControl? reqCC = req.cacheControl;
        if reqCC is http:RequestCacheControl {
            json value = {
                noCache: reqCC.noCache,
                noStore: reqCC.noStore,
                noTransform: reqCC.noTransform,
                onlyIfCached: reqCC.onlyIfCached,
                maxAge: reqCC.maxAge,
                maxStale: reqCC.maxStale,
                minFresh: reqCC.minFresh
            };
            return value;
        } else {
            return {value: "no reqCC"};
        }
    }

    resource function get checkResCC(http:Request req) returns http:Ok {
        string hValue = "must-revalidate, no-cache, no-store, no-transform, public, proxy-revalidate, " +
                        "max-age=60, s-maxage=65";
        return {headers: {"Cache-Control": hValue}};
    }
}

isolated int http2Hitcount = 0;

isolated function incrementHttp2HitCount() {
    lock {
        http2Hitcount += 1;
    }
}

isolated function getHttp2HitCount() returns int {
    lock {
        return http2Hitcount;
    }
}

service /cachingBackend on http2CachingListener2 { //new http:Listener(9240) {

    isolated resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        http:ResponseCacheControl resCC = new;
        resCC.maxAge = 60.54;
        resCC.isPrivate = false;

        res.cacheControl = resCC;
        json payload = {"message": "Hello, World!"};
        res.setETag(payload);
        res.setLastModified();
        incrementHttp2HitCount();
        res.setHeader("x-service-hit-count", getHitCount().toString());

        res.setPayload(payload);

        check caller->respond(res);
    }
}

//Test basic caching behaviour
@test:Config {}
function testHttp2BasicCachingBehaviour() returns error? {
    http:Response|error response = http2CachingTestClient->get("/cache");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(serviceHitCount), "1");
        common:assertHeaderValue(check response.getHeader(proxyHitCount), "1");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = http2CachingTestClient->get("/cache");
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
    runtime:sleep(1);

    response = http2CachingTestClient->get("/cache");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(serviceHitCount), "1");
        common:assertHeaderValue(check response.getHeader(proxyHitCount), "3");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2RequestCacheControlBuildCacheControlDirectives() {
    http:RequestCacheControl reqCC = new;
    reqCC.maxAge = 60.34;
    reqCC.noCache = true;
    reqCC.noStore = true;
    reqCC.noTransform = true;
    reqCC.onlyIfCached = true;
    reqCC.maxStale = 120.04;
    reqCC.minFresh = 6.0;
    test:assertEquals(reqCC.buildCacheControlDirectives(),
        "no-cache, no-store, no-transform, only-if-cached, max-age=60, max-stale=120, min-fresh=6");
}

@test:Config {}
function testHttp2ResponseCacheControlBuildCacheControlDirectives() {
    http:ResponseCacheControl resCC = new;
    resCC.maxAge = 60.54;
    resCC.isPrivate = false;
    resCC.mustRevalidate = true;
    resCC.noCache = true;
    resCC.noStore = true;
    resCC.noTransform = true;
    resCC.proxyRevalidate = true;
    resCC.sMaxAge = 60.32;
    test:assertEquals(resCC.buildCacheControlDirectives(),
        "must-revalidate, no-cache, no-store, no-transform, public, proxy-revalidate, max-age=60, s-maxage=60");
}

@test:Config {}
function testHttp2ReqCCPopulation() returns error? {
    string hValue = "no-cache, no-store, no-transform, only-if-cached, max-age=60, max-stale=120, min-fresh=6";
    json response = check http2CachingTestClient->get("/cache/checkReqCC", {"Cache-Control": hValue});
    json expected =
            {noCache: true, noStore: true, noTransform: true, onlyIfCached: true, maxAge: 60, maxStale: 120, minFresh: 6};
    test:assertEquals(response, expected);
}

@test:Config {}
function testHttp2ResCCPopulation() returns error? {
    http:Response response = check http2CachingTestClient->get("/cache/checkResCC");
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
}
