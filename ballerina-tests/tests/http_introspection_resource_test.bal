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
import ballerina/http;

listener http:Listener httpIntroResTestListener = new(introResTest);
http:Client httpIntroResTestClient = check new("http://localhost:" + introResTest.toString());

service / on httpIntroResTestListener {
    resource function get greeting() returns string|error {
        check httpIntroResTestListener.attach(openApiMock, "/mock");
        return "Hello Swan";
    }
}

service /lake on httpIntroResTestListener {
    resource function post greeting() returns string {
        return "Hello Lake";
    }
}

http:Service openApiMock = service object {
    resource function get mockResource() returns string {
        return "Hello ballerina";
    }
};

@test:Config {}
function testIntrospectionResourceLink() returns error? {
    http:Response|error response = httpIntroResTestClient->options("/greeting");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected statusCode");
        test:assertEquals(check response.getHeader(ALLOW), "GET, OPTIONS", msg = "Found unexpected Header");
        assertHeaderValue(check response.getHeader(LINK), "</openapi-doc-dygixywsw>;rel=\"service-desc\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testIntrospectionResourceLinkForBasePath() returns error? {
    http:Response|error response = httpIntroResTestClient->options("/");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected statusCode");
        test:assertEquals(check response.getHeader(ALLOW), "GET, OPTIONS", msg = "Found unexpected Header");
        assertHeaderValue(check response.getHeader(LINK), "</openapi-doc-dygixywsw>;rel=\"service-desc\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testIntrospectionResourceLinkLakeResource() returns error? {
    http:Response|error response = httpIntroResTestClient->options("/lake/greeting");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected statusCode");
        test:assertEquals(check response.getHeader(ALLOW), "POST, OPTIONS", msg = "Found unexpected Header");
        assertHeaderValue(check response.getHeader(LINK), "</lake/openapi-doc-dygixywsw>;rel=\"service-desc\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testOptionsCallForIntrospectionResource() returns error? {
    http:Response|error response = httpIntroResTestClient->options("/lake/openapi-doc-dygixywsw");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected statusCode");
        test:assertEquals(check response.getHeader(ALLOW), "GET, OPTIONS", msg = "Found unexpected Header");
        assertHeaderValue(check response.getHeader(LINK), "</lake/openapi-doc-dygixywsw>;rel=\"service-desc\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPOSTCallForIntrospectionResource() {
    http:Response|error response = httpIntroResTestClient->post("/lake/openapi-doc-dygixywsw", "hi");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected statusCode");
        assertTextPayload(response.getTextPayload(), "Method not allowed");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testOpenApiSpecRetrievalWithNoFile() {
    http:Response|error response = httpIntroResTestClient->get("/openapi-doc-dygixywsw");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Error retrieving OpenAPI spec: generated doc does not exist");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testIntrospectionAnnotationInConstructorExpression() returns error? {
    http:Response|error response = httpIntroResTestClient->get("/greeting");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "Hello Swan");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpIntroResTestClient->options("/mock");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected statusCode");
        test:assertEquals(check response.getHeader(ALLOW), "GET, OPTIONS", msg = "Found unexpected Header");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpIntroResTestClient->get("/mock/openapi-doc-dygixywsw");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected statusCode");
        assertTrueTextPayload(response.getTextPayload(), "no matching resource found for path");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
