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
import ballerina/io;
import ballerina/http_test_common as common;

listener http:Listener httpIntroResTestListener = new (introResTestPort, httpVersion = http:HTTP_1_1);
final http:Client httpIntroResTestClient = check new ("http://localhost:" + introResTestPort.toString(), httpVersion = http:HTTP_1_1);

service / on httpIntroResTestListener {
    resource function get greeting() returns string|error {
        lock {
            check httpIntroResTestListener.attach(openApiMock, "/mock");
        }
        return "Hello Swan";
    }
}

json openApiDoc = check io:fileReadJson(common:OPENAPI_DOC);
byte[] openApiDef = openApiDoc.toJsonString().toBytes();

@http:ServiceConfig {
    openApiDefinition: openApiDef
}
service /hello on httpIntroResTestListener {
    resource function get greeting() returns string {
        return "Greetings!";
    }
}

isolated http:Service openApiMock = service object {
    resource function get mockResource() returns string {
        return "Hello ballerina";
    }
};

@test:Config {}
function testIntrospectionResourceLinkWithoutOpenApiDefinition() returns error? {
    http:Response response = check httpIntroResTestClient->options("/greeting");
    test:assertEquals(response.statusCode, 204, msg = "Found unexpected statusCode");
    test:assertEquals(check response.getHeader(common:ALLOW), "GET, OPTIONS", msg = "Found unexpected Header");
    string|error header = response.getHeader(common:LINK);
    if header is error {
        test:assertEquals(header.message(), "Http header does not exist", msg = "Found unexpected Error");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + header);
    }
}

@test:Config {}
function testIntrospectionResourceLinkForBasePathWithoutOpenApiDefinition() returns error? {
    http:Response response = check httpIntroResTestClient->options("/");
    test:assertEquals(response.statusCode, 204, msg = "Found unexpected statusCode");
    test:assertEquals(check response.getHeader(common:ALLOW), "GET, OPTIONS", msg = "Found unexpected Header");
    string|error header = response.getHeader(common:LINK);
    if header is error {
        test:assertEquals(header.message(), "Http header does not exist", msg = "Found unexpected Error");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + header);
    }
}

@test:Config {}
function testIntrospectionResourceLink() returns error? {
    http:Response response = check httpIntroResTestClient->options("/hello");
    test:assertEquals(response.statusCode, 204, msg = "Found unexpected statusCode");
    test:assertEquals(check response.getHeader(common:ALLOW), "GET, OPTIONS", msg = "Found unexpected Header");
    common:assertHeaderValue(check response.getHeader(common:LINK), 
        "</hello/openapi-doc-dygixywsw>;rel=\"service-desc\", </hello/swagger-ui-dygixywsw>;rel=\"service-desc\"");

    response = check httpIntroResTestClient->options("/hello/greeting");
    test:assertEquals(response.statusCode, 204, msg = "Found unexpected statusCode");
    test:assertEquals(check response.getHeader(common:ALLOW), "GET, OPTIONS", msg = "Found unexpected Header");
    common:assertHeaderValue(check response.getHeader(common:LINK), 
        "</hello/openapi-doc-dygixywsw>;rel=\"service-desc\", </hello/swagger-ui-dygixywsw>;rel=\"service-desc\"");
}

@test:Config {}
function testIntrospectionResourceGetPayload() returns error? {
    http:Response response = check httpIntroResTestClient->get("/hello/openapi-doc-dygixywsw");
    test:assertEquals(response.statusCode, 200, msg = "Found unexpected statusCode");
    test:assertEquals(response.getContentType(), "application/json", msg = "Found unexpected Header");
    common:assertJsonPayload(check response.getJsonPayload(), openApiDoc);
}

@test:Config {}
function testIntrospectionAnnotationInConstructorExpression() returns error? {
    http:Response response = check httpIntroResTestClient->get("/greeting");
    test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    common:assertTextPayload(response.getTextPayload(), "Hello Swan");

    response = check httpIntroResTestClient->options("/mock");
    test:assertEquals(response.statusCode, 204, msg = "Found unexpected statusCode");
    test:assertEquals(check response.getHeader(common:ALLOW), "GET, OPTIONS", msg = "Found unexpected Header");

    response = check httpIntroResTestClient->get("/mock/openapi-doc-dygixywsw");
    test:assertEquals(response.statusCode, 404, msg = "Found unexpected statusCode");
    common:assertTrueTextPayload(response.getTextPayload(), "no matching resource found for path");
}
