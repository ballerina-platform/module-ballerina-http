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

final http:Client maxAgeCacheEp = check new("http://localhost:" + cachingTestPort4.toString(), 
    httpVersion = http:HTTP_1_1, cache = { isShared: true });

service /maxAge on cachingProxyListener {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = maxAgeCacheEp->forward("/maxAgeBackend", req);
        if response is http:Response {
            json responsePayload;
            if response.hasHeader("cache-control") {
                responsePayload = check response.getHeader("cache-control");
                check caller->respond(responsePayload);
            } else {
                check caller->respond(response);
            }
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(response.message());
            check caller->respond(res);
        }
    }
}

isolated json maxAgePayload = {};
isolated int maxAgehitcount = 0;

service /maxAgeBackend on cachingBackendListener {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        http:ResponseCacheControl resCC = new;
        int count = 0;
        lock {
            count = maxAgehitcount;
        }
        if count < 1 {
            resCC.maxAge = 5;
            res.cacheControl = resCC;
            lock {
                maxAgePayload = { "message": "before cache expiration" };
            }
            json payload = ();
            lock {
                payload = maxAgePayload.clone();
            }
            res.setETag(payload);
        } else {
            lock {
                maxAgePayload = { "message": "after cache expiration" };
            }
        }
        lock {
            maxAgehitcount += 1;
        }
        json payload = ();
        lock {
            payload = maxAgePayload.clone();
        }
        res.setPayload(payload);

        check caller->respond(res);
    }
}

//Test max-age cache control
@test:Config {}
function testMaxAgeCacheControl() returns error? {
    http:Response|error response = cachingProxyTestClient->get("/maxAge");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "public,max-age=5");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cachingProxyTestClient->get("/maxAge");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "public,max-age=5");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    // Wait for a while before sending the next request
    runtime:sleep(5);

    response = cachingProxyTestClient->get("/maxAge");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {message:"after cache expiration"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
