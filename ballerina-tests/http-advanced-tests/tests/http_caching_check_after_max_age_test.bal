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

import ballerina/lang.runtime as runtime;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

final http:Client maxAgeCacheEp2 = check new ("http://localhost:" + cachingTestPort4.toString(),
    httpVersion = http:HTTP_1_1, cache = {enabled: true, isShared: true});

service /maxAgeCache on cachingProxyListener {

    resource function get withEtag(http:Request req) returns string|error {
        http:Response response = check maxAgeCacheEp2->forward("/maxAgeCacheBackend/true", req);
        return response.getHeader("cache-control");
    }

    resource function get withoutEtag(http:Request req) returns string|error {
        http:Response response = check maxAgeCacheEp2->forward("/maxAgeCacheBackend/false", req);
        return response.getHeader("cache-control");
    }
}

isolated int backendMaxAgehitcount = 0;

service /maxAgeCacheBackend on cachingBackendListener {

    resource function 'default [boolean needETag]() returns http:Response {
        lock {
            backendMaxAgehitcount += 1;
        }
        http:Response res = new;
        http:ResponseCacheControl resCC = new;
        resCC.maxAge = 2;
        resCC.mustRevalidate = true;
        resCC.isPrivate = false;
        res.cacheControl = resCC;
        json payload = {"message": "Hello, World!"};
        if (needETag) {
            res.setETag(payload);
        }
        res.setLastModified();
        res.setPayload(payload);
        return res;
    }
}

//Test with the e-tag, so the backend should send 304 for the 3rd request
@test:Config {}
function testCacheControlAfterFirstMaxAgeWithStrongValidator() returns error? {
    check sendRequestAndAssert("/maxAgeCache/withEtag", 1);
    // This should be a cached response
    check sendRequestAndAssert("/maxAgeCache/withEtag", 1);
    // Wait for a while until the initial max age expires
    runtime:sleep(3);
    check sendRequestAndAssert("/maxAgeCache/withEtag", 2);
    // This should be a cached response
    check sendRequestAndAssert("/maxAgeCache/withEtag", 2);
}

//Test without the e-tag, so the backend should send 200 for the 3rd request
@test:Config {dependsOn: [testCacheControlAfterFirstMaxAgeWithStrongValidator]}
function testCacheControlAfterFirstMaxAgeWithWeakValidator() returns error? {
    check sendRequestAndAssert("/maxAgeCache/withoutEtag", 3);
    // This should be a cached response
    check sendRequestAndAssert("/maxAgeCache/withoutEtag", 3);
    // Wait for a while until the initial max age expires
    runtime:sleep(3);
    check sendRequestAndAssert("/maxAgeCache/withoutEtag", 4);
    // This should be a cached response
    check sendRequestAndAssert("/maxAgeCache/withoutEtag", 4);
}

function sendRequestAndAssert(string path, int backendHit) returns error? {
    http:Response response = check cachingProxyTestClient->get(path);
    test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    int count = 0;
    lock {
        count = backendMaxAgehitcount;
    }
    test:assertEquals(count, backendHit, msg = "Found unexpected output");
    common:assertTextPayload(response.getTextPayload(), "must-revalidate,public,max-age=2");
}
