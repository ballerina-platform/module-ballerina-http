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
import ballerina/crypto;

http:Client cacheClientEP = check new("http://localhost:" + cacheAnnotationTestPort1.toString(), { cache: { enabled: false }});

http:Client cacheBackendEP = check new("http://localhost:" + cacheAnnotationTestPort2.toString(), { cache: { isShared: true } });

int numberOfProxyHitsNew = 0;
int noCacheHitCountNew = 0;
int maxAgeHitCountNew = 0;
int numberOfHitsNew = 0;
int statusHits = 0;
xml maxAgePayload1 = xml `<message>before cache expiration</message>`;
xml maxAgePayload2 = xml `<message>after cache expiration</message>`;
string errorBody = "Error";
string mustRevalidatePayload1 = "Hello, World!";
byte[] mustRevalidatePayload2 = "Hello, New World!".toBytes();
json nocachePayload1 = { "message": "1st response" };
json nocachePayload2 = { "message": "2nd response" };
http:Ok ok = {body : mustRevalidatePayload1};
http:InternalServerError err = {body : errorBody};

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
            response.setHeader(serviceHitCount, numberOfHitsNew.toString());
            response.setHeader(proxyHitCount, numberOfProxyHitsNew.toString());
            checkpanic caller->respond(response);
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(response.message());
            checkpanic caller->respond(res);
        }
    }

    resource function get statusResponse(http:Caller caller, http:Request req) {
        http:Response|error response = cacheBackendEP->forward("/statusResponseBE", req);
        if (response is http:Response) {
            checkpanic caller->respond(response);
        } else {
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(response.message());
            checkpanic caller->respond(res);
        }
    }
}

service / on new http:Listener(cacheAnnotationTestPort2) {

    resource function default nocacheBE(http:Request req) returns @http:CacheConfig{} json {
        noCacheHitCountNew += 1;
        if (noCacheHitCountNew == 1) {
            return nocachePayload1;
        } else {
            return nocachePayload2;
        }
    }

    resource function default maxAgeBE(http:Request req) returns @http:CacheConfig{noCache : false, maxAge : 5} xml {
        maxAgeHitCountNew += 1;
        if (maxAgeHitCountNew == 1) {
            return maxAgePayload1;
        } else {
            return maxAgePayload2;
        }
    }

    resource function get mustRevalidateBE(http:Request req) returns @http:CacheConfig{noCache : false, mustRevalidate : true,
        maxAge : 5} string|byte[] {
        numberOfHitsNew += 1;
        if (numberOfHitsNew < 2) {
            return mustRevalidatePayload1;
        } else {
            return mustRevalidatePayload2;
        }
    }

    resource function get statusResponseBE(http:Request req) returns @http:CacheConfig{} http:Ok|http:InternalServerError {
        statusHits += 1;
        if (statusHits < 3) {
            return ok;
        } else {
            return err;
        }
    }
}

@test:Config {}
function testNoCacheCacheControlWithAnnotation() {
    http:Response|error response = cacheClientEP->get("/noCache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(noCacheHitCountNew, 1);
        assertHeaderValue(checkpanic response.getHeader(ETAG), crypto:crc32b(nocachePayload1.toString().toBytes()));
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), nocachePayload1);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cacheClientEP->get("/noCache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(noCacheHitCountNew, 2);
        assertHeaderValue(checkpanic response.getHeader(ETAG), crypto:crc32b(nocachePayload2.toString().toBytes()));
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), nocachePayload2);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cacheClientEP->get("/noCache");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(noCacheHitCountNew, 3);
        assertHeaderValue(checkpanic response.getHeader(ETAG), crypto:crc32b(nocachePayload2.toString().toBytes()));
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), nocachePayload2);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMaxAgeCacheControlWithAnnotation() {
    http:Response|error response = cacheClientEP->get("/maxAge");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(maxAgeHitCountNew, 1);
        assertHeaderValue(checkpanic response.getHeader(ETAG), crypto:crc32b(maxAgePayload1.toString().toBytes()));
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        assertXmlPayload(response.getXmlPayload(), maxAgePayload1);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cacheClientEP->get("/maxAge");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(maxAgeHitCountNew, 1);
        assertHeaderValue(checkpanic response.getHeader(ETAG), crypto:crc32b(maxAgePayload1.toString().toBytes()));
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        assertXmlPayload(response.getXmlPayload(), maxAgePayload1);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    // Wait for a while before sending the next request
    runtime:sleep(5);

    response = cacheClientEP->get("/maxAge");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(maxAgeHitCountNew, 2);
        assertHeaderValue(checkpanic response.getHeader(ETAG), crypto:crc32b(maxAgePayload2.toString().toBytes()));
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        assertXmlPayload(response.getXmlPayload(), maxAgePayload2);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMustRevalidateCacheControlWithAnnotation() {
    http:Response|error response = cacheClientEP->get("/mustRevalidate");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(ETAG), crypto:crc32b(mustRevalidatePayload1.toBytes()));
        assertHeaderValue(checkpanic response.getHeader(serviceHitCount), "1");
        assertHeaderValue(checkpanic response.getHeader(proxyHitCount), "1");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), mustRevalidatePayload1);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cacheClientEP->get("/mustRevalidate");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(ETAG), crypto:crc32b(mustRevalidatePayload1.toBytes()));
        assertHeaderValue(checkpanic response.getHeader(serviceHitCount), "1");
        assertHeaderValue(checkpanic response.getHeader(proxyHitCount), "2");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), mustRevalidatePayload1);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    // Wait for a while before sending the next request
    runtime:sleep(5);

    response = cacheClientEP->get("/mustRevalidate");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(ETAG), crypto:crc32b(mustRevalidatePayload2));
        assertHeaderValue(checkpanic response.getHeader(serviceHitCount), "2");
        assertHeaderValue(checkpanic response.getHeader(proxyHitCount), "3");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_BINARY);
        assertBinaryPayload(response.getBinaryPayload(), mustRevalidatePayload2);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testReturnStatusCodeResponsesWithAnnotation() {
    http:Response|error response = cacheClientEP->get("/statusResponse");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(statusHits, 1);
        assertHeaderValue(checkpanic response.getHeader(ETAG), crypto:crc32b(mustRevalidatePayload1.toBytes()));
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), mustRevalidatePayload1);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cacheClientEP->get("/statusResponse");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(statusHits, 2);
        assertHeaderValue(checkpanic response.getHeader(ETAG), crypto:crc32b(mustRevalidatePayload1.toBytes()));
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), mustRevalidatePayload1);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = cacheClientEP->get("/statusResponse");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        test:assertEquals(statusHits, 3);
        test:assertFalse(response.hasHeader(ETAG));
        test:assertFalse(response.hasHeader(CACHE_CONTROL));
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), errorBody);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
