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

import ballerina/runtime;
import ballerina/test;
import ballerina/http;

listener http:Listener cachingListener1 = new(cachingTestPort1);
listener http:Listener cachingListener2 = new(cachingTestPort2);
http:Client cachingTestClient = new("http://localhost:" + cachingTestPort1.toString(), { cache: { enabled: false }});

http:Client cachingEP = new("http://localhost:" + cachingTestPort2.toString(), { cache: { isShared: true } });
int cachingProxyHitcount = 0;

@http:ServiceConfig {
    basePath: "/cache"
}
service cachingProxy on cachingListener1 { //new http:Listener(9239) {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function cacheableResource(http:Caller caller, http:Request req) {
        var response = cachingEP->forward("/hello", req);

        if (response is http:Response) {
            cachingProxyHitcount += 1;
            response.setHeader("x-proxy-hit-count", cachingProxyHitcount.toString());
            checkpanic caller->respond(<@untainted> response);
        } else if (response is error) {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(<@untainted> response.message());
            checkpanic caller->respond(res);
        }
    }
}

json payload = { "message": "Hello, World!" };
int hitcount = 0;

@http:ServiceConfig {
    basePath: "/hello"
}
service cachingBackend on cachingListener2 {//new http:Listener(9240) {

    @http:ResourceConfig { path: "/" }
    resource function sayHello(http:Caller caller, http:Request req) {
        http:Response res = new;

        http:ResponseCacheControl resCC = new;
        resCC.maxAge = 60;
        resCC.isPrivate = false;

        res.cacheControl = resCC;

        res.setETag(payload);
        res.setLastModified();

        hitcount += 1;
        res.setHeader("x-service-hit-count", hitcount.toString());

        res.setPayload(payload);

        checkpanic caller->respond(res);
    }
}

const string serviceHitCount = "x-service-hit-count";
const string proxyHitCount = "x-proxy-hit-count";
json cachingPayload = {message:"Hello, World!"};

//Test basic caching behaviour
@test:Config {}
function testBasicCachingBehaviour() {
    var response = cachingTestClient->get("/cache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(serviceHitCount), "1");
        assertHeaderValue(response.getHeader(proxyHitCount), "1");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cachingTestClient->get("/cache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(serviceHitCount), "1");
        assertHeaderValue(response.getHeader(proxyHitCount), "2");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    // Wait for a while before sending the next request
    runtime:sleep(1000);

    response = cachingTestClient->get("/cache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(serviceHitCount), "1");
        assertHeaderValue(response.getHeader(proxyHitCount), "3");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
