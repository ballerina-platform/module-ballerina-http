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
import http;

http:Client cachingEP3 = new("http://localhost:" + cachingTestPort4.toString(), { cache: { isShared: true } });
int numberOfProxyHits = 0;

@http:ServiceConfig {
    basePath: "/mustRevalidate"
}
service mustRevalidateProxyService on cachingProxyListener {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function cacheableProxyResource(http:Caller caller, http:Request req) {
        numberOfProxyHits += 1;
        var response = cachingEP3->forward("/mustRevalidateBE", req);
        if (response is http:Response) {
            response.setHeader("x-proxy-hit-count", numberOfProxyHits.toString());
            checkpanic caller->respond(response);
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(<@untainted> response.message());
            checkpanic caller->respond(res);
        }
    }
}

int numberOfHits = 0;

@http:ServiceConfig {
    basePath: "/mustRevalidateBE"
}
service mustRevalidateBackend on cachingBackendListener {

    @http:ResourceConfig { path: "/" }
    resource function mustRevalidate(http:Caller caller, http:Request req) {
        json payload = {};
        http:Response res = new;
        http:ResponseCacheControl resCC = new;
        payload = {"message" : "Hello, World!"};
        resCC.mustRevalidate = true;
        resCC.maxAge = 5;
        res.cacheControl = resCC;
        res.setETag(payload);
        numberOfHits += 1;
        res.setPayload(payload);
        res.setHeader("x-service-hit-count", numberOfHits.toString());

        checkpanic caller->respond(res);
    }
}

//Test must-revalidate cache control
@test:Config {}
function testMustRevalidateCacheControl() {
    var response = cachingProxyTestClient->get("/mustRevalidate");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(serviceHitCount), "1");
        assertHeaderValue(response.getHeader(proxyHitCount), "1");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cachingProxyTestClient->get("/mustRevalidate");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(serviceHitCount), "1");
        assertHeaderValue(response.getHeader(proxyHitCount), "2");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    // Wait for a while before sending the next request
    runtime:sleep(5000);

    response = cachingProxyTestClient->get("/mustRevalidate");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(serviceHitCount), "2");
        assertHeaderValue(response.getHeader(proxyHitCount), "3");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), cachingPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}


