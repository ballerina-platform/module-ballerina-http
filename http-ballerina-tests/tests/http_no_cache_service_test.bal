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

listener http:Listener cachingProxyListener = new(cachingTestPort3); //new(9244);
listener http:Listener cachingBackendListener = new(cachingTestPort4);  //new(9243);
http:Client cachingProxyTestClient = new("http://localhost:" + cachingTestPort3.toString(), { cache: { enabled: false }});

http:Client cachingEP1 = new("http://localhost:" + cachingTestPort4.toString(), { cache: { isShared: true } });

@http:ServiceConfig {
    basePath: "/nocache"
}
service cachingProxyService on cachingProxyListener {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function cacheableProxyResource(http:Caller caller, http:Request req) {
        var response = cachingEP1->forward("/nocachebackend", req);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else if (response is error) {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(<@untainted> response.message());
            checkpanic caller->respond(res);
        }
    }
}

int nocachehitcount = 0;

@http:ServiceConfig {
    basePath: "/nocachebackend"
}
service nocacheBackend on cachingBackendListener {

    @http:ResourceConfig { path: "/" }
    resource function sayHello(http:Caller caller, http:Request req) {
        json nocachePayload = {};
        http:Response res = new;
        http:ResponseCacheControl resCC = new;
        if (nocachehitcount < 1) {
            nocachePayload = { "message": "1st response" };
            res.cacheControl = resCC;
        } else {
            nocachePayload = { "message": "2nd response" };
        }
        resCC.noCache = true;
        res.setETag(nocachePayload);
        nocachehitcount += 1;
        res.setHeader("x-service-hit-count", nocachehitcount.toString());
        res.setPayload(nocachePayload);

        checkpanic caller->respond(res);
    }
}

//Test no-cache cache control
@test:Config {}
function testNoCacheCacheControl() {
    var response = cachingProxyTestClient->get("/nocache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(serviceHitCount), "1");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {message:"1st response"});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cachingProxyTestClient->get("/nocache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(serviceHitCount), "2");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {message:"2nd response"});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cachingProxyTestClient->get("/nocache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(serviceHitCount), "3");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {message:"2nd response"});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
