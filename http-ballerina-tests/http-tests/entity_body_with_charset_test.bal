// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;

string textValue = "Hello Ballerina!";
xml testValue = xml `<test><name>ballerina</name></test>`;
xml xmlValue = xml `<菜鸟驿站><name>菜鸟驿站</name></菜鸟驿站>`;

//Request charset with json payload
@test:Config {}
function testSetJsonPayloadWithoutCharset() {
    http:Request request = new;
    request.setJsonPayload({ test: "testValue" });
    string[] headers = request.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/json", msg = "Content-type mismatched");

}

@test:Config {}
function testCharsetWithExistingContentType() {
    http:Request request = new;
    request.setJsonPayload({ test: "testValue" }, "application/json;charset=\"ISO_8859-1:1987\"");
    string[] headers = request.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/json;charset=ISO_8859-1:1987", msg = "Content-type mismatched");
}

@test:Config {}
function testSetHeaderAfterJsonPayload() {
    http:Request request = new;
    request.setHeader("content-type", "application/json;charset=utf-8");
    request.setJsonPayload({ test: "testValue" });
    request.setHeader("content-type", "application/json;charset=\"ISO_8859-1:1987\"");
    string[] headers = request.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/json;charset=\"ISO_8859-1:1987\"", msg = "Content-type mismatched");
}

@test:Config {}
function testJsonPayloadWithDefaultCharset() {
    http:Request request = new;
    json payload = { test: "菜鸟驿站" };
    request.setJsonPayload(payload);
    json|error jsonPayload = request.getJsonPayload();
    if (jsonPayload is json) {
        test:assertEquals(jsonPayload, payload);
    } else {
        test:assertFail("Test failed");
    }
}

@test:Config {}
function testJsonPayloadWithCharset() {
    http:Request request = new;
    request.setJsonPayload({ test: "ߢߚߟ" }, "application/json;charset=utf-8");
    json|error jsonPayload = request.getJsonPayload();
    if (jsonPayload is json) {
        test:assertEquals(jsonPayload, { test: "ߢߚߟ" });
    } else {
        test:assertFail("Test failed");
    }
}

//Request charset with xml payload
@test:Config {}
function testSetXmlPayloadWithoutCharset() {
    http:Request request = new;
    request.setXmlPayload(testValue);
    string[] headers = request.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/xml");
}

@test:Config {}
function testCharsetWithExistingContentTypeXml() {
    http:Request request = new;
    request.setHeader("content-type", "application/xml;charset=\"ISO_8859-1:1987\"");
    request.setXmlPayload(testValue);
    string[] headers = request.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/xml");
}

@test:Config {}
function testSetHeaderAfterXmlPayload() {
    http:Request request = new;
    request.setHeader("content-type", "application/xml;charset=utf-8");
    request.setXmlPayload(testValue);
    request.setHeader("content-type", "application/xml;charset=\"ISO_8859-1:1987\"");
    string[] headers = request.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/xml;charset=\"ISO_8859-1:1987\"");
}

// Disabled due to https://github.com/ballerina-platform/module-ballerina-http/issues/62
@test:Config {enable:false}
function testXmlPayloadWithDefaultCharset() {
    http:Request request = new;
    request.setXmlPayload(xmlValue);
    xml|error xmlPayload = request.getXmlPayload();
    if (xmlPayload is xml) {
        test:assertEquals(xmlPayload.toString(), "<菜鸟驿站><name>菜鸟驿站</name></菜鸟驿站>");
    } else {
        test:assertFail("Payload mismatched");
    }
}

// Disabled due to https://github.com/ballerina-platform/module-ballerina-http/issues/62
@test:Config {enable:false}
function testXmlPayloadWithCharset() {
    http:Request request = new;
    request.setXmlPayload(xmlValue, "application/xml;charset=utf-8");
    xml|error xmlPayload = request.getXmlPayload();
    if (xmlPayload is xml) {
        test:assertEquals(xmlPayload.toString(), "<菜鸟驿站><name>菜鸟驿站</name></菜鸟驿站>");
    } else {
        test:assertFail("Payload mismatched");
    }
}

//Request charset with string payload
@test:Config {}
function testSetStringPayloadWithoutCharset() {
    http:Request request = new;
    request.setTextPayload(textValue);
    string[] headers = request.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "text/plain");
}

@test:Config {}
function testCharsetWithExistingContentTypeString() {
    http:Request request = new;
    request.setHeader("content-type", "text/plain;charset=\"ISO_8859-1:1987\"");
    request.setTextPayload(textValue);
    string[] headers = request.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "text/plain");
}

@test:Config {}
function testSetHeaderAfterStringPayload() {
    http:Request request = new;
    request.setHeader("content-type", "text/plain;charset=utf-8");
    request.setTextPayload(textValue);
    request.setHeader("content-type", "text/plain;charset=\"ISO_8859-1:1987\"");
    string[] headers = request.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "text/plain;charset=\"ISO_8859-1:1987\"", msg = "Payload mismatched");
}

@test:Config {}
function testTextPayloadWithDefaultCharset() {
    http:Request request = new;
    request.setTextPayload("菜鸟驿站");
    string|error textPayload = request.getTextPayload();
    if (textPayload is string) {
        test:assertEquals(textPayload, "菜鸟驿站", msg = "Payload mismatched");
    } else {
        test:assertFail("Test failed");
    }
}

@test:Config {}
function testTextPayloadWithCharset() {
    http:Request request = new;
    request.setTextPayload("菜鸟驿站", "text/plain;charset=utf-8");
    string|error textPayload = request.getTextPayload();
    if (textPayload is string) {
        test:assertEquals(textPayload, "菜鸟驿站", msg = "Payload mismatched");
    } else {
        test:assertFail("Test failed");
    }
}

//Response charset with json payload
@test:Config {}
function testSetJsonPayloadWithoutCharsetResponse() {
    http:Response response = new;
    response.setJsonPayload({ test: "testValue" });
    string[] headers = response.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/json");
}

@test:Config {}
function testCharsetWithExistingContentTypeResponse() {
    http:Response response = new;
    response.setHeader("content-type", "application/json;charset=\"ISO_8859-1:1987\"");
    response.setJsonPayload({ test: "testValue" });
    string[] headers = response.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/json");
}

@test:Config {}
function testSetHeaderAfterJsonPayloadResponse() {
    http:Response response = new;
    response.setHeader("content-type", "application/json;charset=utf-8");
    response.setJsonPayload({ test: "testValue" });
    response.setHeader("content-type", "application/json;charset=\"ISO_8859-1:1987\"");
    string[] headers = response.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/json;charset=\"ISO_8859-1:1987\"");
}

//Response charset with xml payload
@test:Config {}
function testSetXmlPayloadWithoutCharsetResponse() {
    http:Response response = new;
    response.setXmlPayload(testValue);
    string[] headers = response.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/xml");
}

@test:Config {}
function testCharsetWithExistingContentTypeXmlResponse() {
    http:Response response = new;
    response.setHeader("content-type", "application/xml;charset=\"ISO_8859-1:1987\"");
    response.setXmlPayload(testValue);
    string[] headers = response.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/xml");
}

@test:Config {}
function testSetHeaderAfterXmlPayloadResponse() {
    http:Response response = new;
    response.setHeader("content-type", "application/xml;charset=utf-8");
    response.setXmlPayload(testValue);
    response.setHeader("content-type", "application/xml;charset=\"ISO_8859-1:1987\"");
    string[] headers = response.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "application/xml;charset=\"ISO_8859-1:1987\"");
}

//Response charset with string payload
@test:Config {}
function testSetStringPayloadWithoutCharsetResponse() {
    http:Response response = new;
    response.setTextPayload(textValue);
    string[] headers = response.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "text/plain");
}

@test:Config {}
function testCharsetWithExistingContentTypeStringResponse() {
    http:Response response = new;
    response.setHeader("content-type", "text/plain;charset=\"ISO_8859-1:1987\"");
    response.setTextPayload(textValue);
    string[] headers = response.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "text/plain");
}

@test:Config {}
function testSetHeaderAfterStringPayloadResponse() {
    http:Response response = new;
    response.setHeader("content-type", "text/plain;charset=utf-8");
    response.setTextPayload(textValue);
    response.setHeader("content-type", "text/plain;charset=\"ISO_8859-1:1987\"");
    string[] headers = response.getHeaders("content-type");
    test:assertEquals(headers.length(), 1, msg = "Output mismatched");
    test:assertEquals(headers[0], "text/plain;charset=\"ISO_8859-1:1987\"");
}

listener http:Listener entityEP = new(entityTest);

@http:ServiceConfig { basePath: "/test" }
service entityService on entityEP {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/jsonTest"
    }
    resource function getJson(http:Caller caller, http:Request request) {
        http:Response response = new;
        var payload = request.getJsonPayload();
        if (payload is json) {
            response.setPayload(<@untainted> payload);
        } else {
            response.setPayload(<@untainted> payload.message());
        }
        checkpanic caller->respond(response);
    }
}

http:Client entityClient = new("http://localhost:" + entityTest.toString());

// Test addHeader function within a service
// Disabled due to https://github.com/ballerina-platform/module-ballerina-http/issues/62
@test:Config {enable:false}
function jsonTest() {
    string path = "/test/jsonTest";
    http:Request request = new;
    request.setHeader("content-type", "application/json");
    request.setPayload({test: "菜鸟驿站"});
    var response = entityClient->post(path, request);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {test: "菜鸟驿站"});
    } else if (response is error) {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}
