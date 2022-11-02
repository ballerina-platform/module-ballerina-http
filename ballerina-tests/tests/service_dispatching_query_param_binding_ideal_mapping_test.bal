// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/test;

listener http:Listener QueryBindingIdealEP = new(queryParamBindingIdealTestPort, httpVersion = http:HTTP_1_1);
final http:Client queryBindingIdealClient = check new("http://localhost:" + queryParamBindingIdealTestPort.toString(), httpVersion = http:HTTP_1_1);

@http:ServiceConfig {
    treatNilableAsOptional : false
}
service /queryparamservice on QueryBindingIdealEP {

    resource function get test1(string foo, int bar) returns json {
        json responseJson = { value1: foo, value2: bar};
        return responseJson;
    }

    resource function get test2(string? foo, int bar) returns json {
        json responseJson = { value1: foo ?: "empty", value2: bar};
        return responseJson;
    }

    resource function get test3(string? foo = "baz", int bar = 10) returns json {
        json responseJson = { value1: foo ?: "empty", value2: bar};
        return responseJson;
    }
}

@test:Config {}
function testIdealQueryParamBindingWithQueryParamValue() {
    json|error response = queryBindingIdealClient->get("/queryparamservice/test1?foo=WSO2&bar=56");
    if response is json {
        test:assertEquals(response, {value1:"WSO2", value2:56}, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingIdealClient->get("/queryparamservice/test2?foo=WSO2&bar=56");
    if response is json {
        test:assertEquals(response, {value1:"WSO2", value2:56}, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testIdealQueryParamBindingWithoutQueryParam() {
    http:Response|error response = queryBindingIdealClient->get("/queryparamservice/test1?bar=56");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        assertTextPayload(response.getTextPayload(), "no query param value found for 'foo'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingIdealClient->get("/queryparamservice/test2?bar=56");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        assertTextPayload(response.getTextPayload(), "no query param value found for 'foo'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testIdealQueryParamBindingWithNoQueryParamValue() {
    http:Response|error response = queryBindingIdealClient->get("/queryparamservice/test1?foo&bar=56");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        assertTextPayload(response.getTextPayload(), "no query param value found for 'foo'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingIdealClient->get("/queryparamservice/test2?foo&bar=56");
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {value1:"empty", value2:56});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testIdealQueryParamBindingWithDefaultableQueryParamValue() returns error? {
    json response = check queryBindingIdealClient->get("/queryparamservice/test3?foo=WSO2&bar=56");
    test:assertEquals(response, {value1:"WSO2", value2:56}, msg = "Found unexpected output");

    response = check queryBindingIdealClient->get("/queryparamservice/test3?foo&bar");
    test:assertEquals(response, {value1:"baz", value2:10}, msg = "Found unexpected output");

    response = check queryBindingIdealClient->get("/queryparamservice/test3");
    test:assertEquals(response, {value1:"baz", value2:10}, msg = "Found unexpected output");
}
