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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/test;

listener http:Listener HeaderBindingEP = new(headerParamBindingTest);
http:Client headerBindingClient = check new("http://localhost:" + headerParamBindingTest.toString());

service /headerparamservice on HeaderBindingEP {

    resource function get .(@http:Header {} string foo, int bar, http:Request req) returns json {
        json responseJson = { value1: foo, value2: bar};
        return responseJson;
    }

    resource function get q1/[string go](@http:Header {} string[] foo, @http:Payload {} string a, string b) 
            returns json {
        json responseJson = { xType: foo, path: go, payload:a, page: b};
        return responseJson;
    }

    resource function get q2(@http:Header {name:"x-Type" } string foo, @http:Header { name:"x-Type" } string[] bar) 
            returns json {
        json responseJson = { firstValue: foo, allValue: bar};
        return responseJson;
    }

    resource function get q3(@http:Header {} string? foo, http:Request req, @http:Header {} string[]? bar, 
            http:Headers headerObj) returns json {
        string[] err = ["bar header not found"];
        string header1 = foo ?: "foo header not found";
        string[] header2 = bar ?: err;
        string header3 = checkpanic headerObj.getHeader("BAz");
        json responseJson = { val1: header1, val2: header2, val3: header3};
        return responseJson;
    }

    resource function get q4(http:Caller caller, @http:Header {} string? foo, http:Headers headerObj) returns json {
        string header1 = foo ?: "foo header not found";
        boolean headerBool = headerObj.hasHeader("foo");

        string|error header2Val = headerObj.getHeader("baz");
        string header2 = header2Val is string ? header2Val : (header2Val.message());

        string[]|error header3Val = headerObj.getHeaders("daz");
        string[] header3 = [];
        if (header3Val is string[]) {
            header3 = header3Val;
        } else {
            header3[0]= header3Val.message();
        }
        string[] headerNames = headerObj.getHeaderNames();
        json responseJson = { val1: header1, val2: header2, val3: headerBool, val4: header3, val5: headerNames};
        return responseJson;
    }
}

@test:Config {}
function testHeaderTokenBinding() {
    http:Request req = new;
    req.setHeader("foo", "Ballerina");
    var response = headerBindingClient->get("/headerparamservice/?foo=WSO2&bar=56", req);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {value1:"Ballerina", value2:56});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    
    req.setHeader("foo", "WSO2");
    response = headerBindingClient->get("/headerparamservice?foo=bal&bar=12", req);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {value1:"WSO2", value2:12});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Header params are not case sensitive
@test:Config {}
function testHeaderBindingCaseInSensitivity() {
    http:Request req = new;
    req.setHeader("FOO", "HTtP");
    var response = headerBindingClient->get("/headerparamservice/?baz=WSO2&bar=56", req);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {value1:"HTtP", value2:56});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderUnavailability() {
    http:Request req = new;
    var response = headerBindingClient->get("/headerparamservice/?foo=WSO2&bar=56", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400);
        assertTextPayload(response.getTextPayload(), "no header value found for 'foo'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderArrayUnavailability() {
    http:Request req = new;
    req.setTextPayload("All in one");
    var response = headerBindingClient->get("/headerparamservice/q1/hello?b=hi", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400);
        assertTextPayload(response.getTextPayload(), "no header value found for 'foo'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAllParamBinding() {
    http:Request req = new;
    req.addHeader("foo", "Hello");
    req.addHeader("Foo", "World");
    req.setTextPayload("All in one");
    var response = headerBindingClient->get("/headerparamservice/q1/hello?b=hi", req);
    if (response is http:Response) {
        json expected = {xType:["Hello", "World"], path: "hello", payload: "All in one", page: "hi"};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderBindingArrayAndString() {
    http:Request req = new;
    req.addHeader("X-Type", "Hello");
    req.addHeader("X-Type", "World");
    var response = headerBindingClient->get("/headerparamservice/q2", req);
    if (response is http:Response) {
        json expected = {firstValue: "Hello", allValue:["Hello", "World"]};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilableHeaderBinding() {
    http:Request req = new;
    req.addHeader("X-Type", "Hello");
    req.addHeader("Foo", "World");
    req.addHeader("bar", "Write");
    req.addHeader("baaz", "All");
    req.addHeader("baz", "Ballerina");
    req.addHeader("bar", "Language");
    req.addHeader("X-Type", "Hello");
    var response = headerBindingClient->get("/headerparamservice/q3", req);
    if (response is http:Response) {
        json expected = { val1: "World", val2: ["Write", "Language"], val3: "Ballerina"};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    req = new;
    req.addHeader("X-Type", "Hello");
    req.addHeader("bar", "Write");
    req.addHeader("bar", "All");
    req.addHeader("baz", "Language");
    req.addHeader("X-Type", "Hello");
    response = headerBindingClient->get("/headerparamservice/q3", req);
    if (response is http:Response) {
        json expected = { val1: "foo header not found", val2: ["Write", "All"], val3: "Language"};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    req = new;
    req.addHeader("X-Type", "Hello");
    req.addHeader("foo", "Write");
    req.addHeader("foo", "All");
    req.addHeader("baz", "Hello");
    response = headerBindingClient->get("/headerparamservice/q3", req);
    if (response is http:Response) {
        json expected = { val1: "Write", val2: ["bar header not found"], val3: "Hello"};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderObjectBinding() {
    http:Request req = new;
    req.addHeader("X-Type", "Hello");
    req.addHeader("Foo", "World");
    req.addHeader("baz", "Write");
    req.addHeader("daz", "All");
    req.addHeader("DAZ", "Ballerina");
    req.addHeader("bar", "Language");
    req.addHeader("X-Type", "Hello");
    var response = headerBindingClient->get("/headerparamservice/q4", req);
    if (response is http:Response) {
        json expected = { val1: "World", val2: "Write", val3: true, val4: ["All", "Ballerina"], 
                                val5: ["bar", "baz", "connection", "daz", "Foo", "host", "X-Type"]};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    req = new;
    req.addHeader("X-Type", "Hello");
    req.addHeader("bar", "Language");
    req.addHeader("X-Type", "Hello");
    response = headerBindingClient->get("/headerparamservice/q4", req);
    if (response is http:Response) {
        json expected = { val1: "foo header not found", val2: "Http header does not exist", val3: false, 
                                val4: ["Http header does not exist"],  val5: ["bar", "connection", "host", "X-Type"]};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
