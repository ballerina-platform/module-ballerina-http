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
final http:Client headerBindingClient = check new("http://localhost:" + headerParamBindingTest.toString());

service /headerparamservice on HeaderBindingEP {

    resource function get .(@http:Header string foo, int bar, http:Request req) returns json {
        json responseJson = { value1: foo, value2: bar};
        return responseJson;
    }

    resource function post q1/[string go](@http:Header string[] foo, @http:Payload string a, string b)
            returns json {
        json responseJson = { xType: foo, path: go, payload:a, page: b};
        return responseJson;
    }

    resource function get q2(@http:Header {name:"x-Type" } string foo, @http:Header { name:"x-Type" } string[] bar)
            returns json {
        json responseJson = { firstValue: foo, allValue: bar};
        return responseJson;
    }

    resource function get q3(@http:Header string? foo, http:Request req, @http:Header string[]? bar,
            http:Headers headerObj) returns json|error {
        string[] err = ["bar header not found"];
        string header1 = foo ?: "foo header not found";
        string[] header2 = bar ?: err;
        string header3 = check headerObj.getHeader("BAz");
        json responseJson = { val1: header1, val2: header2, val3: header3};
        return responseJson;
    }

    resource function get q4(http:Caller caller, @http:Header string? foo, http:Headers headerObj) returns json {
        string header1 = foo ?: "foo header not found";
        boolean headerBool = headerObj.hasHeader("foo");

        string|error header2Val = headerObj.getHeader("baz");
        string header2 = header2Val is string ? header2Val : (header2Val.message());

        string[]|error header3Val = headerObj.getHeaders("daz");
        string[] header3 = [];
        if header3Val is string[] {
            header3 = header3Val;
        } else {
            header3[0]= header3Val.message();
        }
        string[] headerNames = headerObj.getHeaderNames();
        json responseJson = { val1: header1, val2: header2, val3: headerBool, val4: header3, val5: headerNames};
        return responseJson;
    }

    resource function get q5(@http:Header string x\-Type) returns string {
        return x\-Type;
    }

    resource function get q6(@http:Header string? foo) returns string {
        return foo ?: "empty";
    }
}

type RateLimitHeaders record {|
    string x\-rate\-limit\-id;
    int? x\-rate\-limit\-remaining;
    string[]? x\-rate\-limit\-types;
|};

type PureTypeHeaders record {|
    string sid;
    int iid;
    float fid;
    decimal did;
    boolean bid;
    string[] said;
    int[] iaid;
    float[] faid;
    decimal[] daid;
    boolean[] baid;
|};

type NilableTypeHeaders record {|
    string? sid;
    int? iid;
    float? fid;
    decimal? did;
    boolean? bid;
    string[]? said;
    int[]? iaid;
    float[]? faid;
    decimal[]? daid;
    boolean[]? baid;
|};

service /headerRecord on HeaderBindingEP {
    resource function get rateLimitHeaders(@http:Header RateLimitHeaders rateLimitHeaders) returns json {
        return {
            header1 : rateLimitHeaders.x\-rate\-limit\-id,
            header2 : rateLimitHeaders.x\-rate\-limit\-remaining,
            header3 : rateLimitHeaders.x\-rate\-limit\-types
        };
    }

    resource function post ofStringOfPost(@http:Header RateLimitHeaders rateLimitHeaders) returns json {
        return {
            header1 : rateLimitHeaders.x\-rate\-limit\-id,
            header2 : rateLimitHeaders.x\-rate\-limit\-remaining,
            header3 : rateLimitHeaders.x\-rate\-limit\-types
        };
    }

    resource function get ofPureTypeHeaders(@http:Header PureTypeHeaders headers) returns json {
        return {
            header1 : headers.sid,
            header2 : headers.iid,
            header3 : headers.fid,
            header4 : headers.did,
            header5 : headers.bid,
            header6 : headers.said,
            header7 : headers.iaid,
            header8 : headers.faid,
            header9 : headers.daid,
            header10 : headers.baid
        };
    }

    resource function get ofNilableTypeHeaders(@http:Header NilableTypeHeaders headers) returns json {
        return {
            header1 : headers.sid,
            header2 : headers.iid,
            header3 : headers.fid,
            header4 : headers.did,
            header5 : headers.bid,
            header6 : headers.said,
            header7 : headers.iaid,
            header8 : headers.faid,
            header9 : headers.daid,
            header10 : headers.baid
        };
    }
}

@test:Config {}
function testHeaderTokenBinding() {
    http:Response|error response = headerBindingClient->get("/headerparamservice/?foo=WSO2&bar=56", {"foo":"Ballerina"});
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {value1:"Ballerina", value2:56});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = headerBindingClient->get("/headerparamservice?foo=bal&bar=12", {"foo":"WSO2"});
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {value1:"WSO2", value2:12});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Header params are not case sensitive
@test:Config {}
function testHeaderBindingCaseInSensitivity() {
    http:Response|error response = headerBindingClient->get("/headerparamservice/?baz=WSO2&bar=56", {"FOO":"HTtP"});
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {value1:"HTtP", value2:56});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderUnavailability() {
    http:Response|error response = headerBindingClient->get("/headerparamservice/?foo=WSO2&bar=56");
    if response is http:Response {
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
    http:Response|error response = headerBindingClient->post("/headerparamservice/q1/hello?b=hi", req);
    if response is http:Response {
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
    http:Response|error response = headerBindingClient->post("/headerparamservice/q1/hello?b=hi", req);
    if response is http:Response {
        json expected = {xType:["Hello", "World"], path: "hello", payload: "All in one", page: "hi"};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderBindingArrayAndString() {
    http:Response|error response = headerBindingClient->get("/headerparamservice/q2", {"X-Type":["Hello", "World"]});
    if response is http:Response {
        json expected = {firstValue: "Hello", allValue:["Hello", "World"]};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilableHeaderBinding() {
    var headers1 = {"X-Type":["Hello", "Hello"], "bar":["Write", "Language"], "Foo":"World", "baaz":"All",
            "baz":"Ballerina"};
    http:Response|error response = headerBindingClient->get("/headerparamservice/q3", headers1);
    if response is http:Response {
        json expected = { val1: "World", val2: ["Write", "Language"], val3: "Ballerina"};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    var headers2 = {"X-Type":["Hello", "Hello"], "bar":["Write", "All"], "baz":"Language"};
    response = headerBindingClient->get("/headerparamservice/q3", headers2);
    if response is http:Response {
        json expected = { val1: "foo header not found", val2: ["Write", "All"], val3: "Language"};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    var headers3 = {"X-Type":"Hello", "Foo":["Write", "All"], "baz":"Hello"};
    response = headerBindingClient->get("/headerparamservice/q3", headers3);
    if response is http:Response {
        json expected = { val1: "Write", val2: ["bar header not found"], val3: "Hello"};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderObjectBinding() {
    var headers = {"X-Type":["Hello", "Hello"], "Foo":"World", "baz":"Write", "daz":["All", "Ballerina"],
        "bar":"Language"};
    http:Response|error response = headerBindingClient->get("/headerparamservice/q4", headers);
    if response is http:Response {
        json expected = { val1: "World", val2: "Write", val3: true, val4: ["All", "Ballerina"],
                                val5: ["bar", "baz", "connection", "daz", "Foo", "host", "X-Type"]};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    var headers2 = {"X-Type":["Hello", "Hello"], "bar":"Language"};
    response = headerBindingClient->get("/headerparamservice/q4", headers2);
    if response is http:Response {
        json expected = { val1: "foo header not found", val2: "Http header does not exist", val3: false,
                                val4: ["Http header does not exist"],  val5: ["bar", "connection", "host", "X-Type"]};
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderParamTokenWithEscapeChar() {
    http:Response|error response = headerBindingClient->get("/headerparamservice/q5", {"x-Type" : "test"});
    if response is http:Response {
        assertTextPayload(response.getTextPayload(), "test");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderBindingWithNoHeaderValue() {
    string|error response = headerBindingClient->get("/headerparamservice/q6", {"foo" : ""});
    if response is string {
        test:assertEquals(response, "empty", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderRecordParam() returns error? {
    json response = check headerBindingClient->get("/headerRecord/rateLimitHeaders", { "x-rate-limit-id" : "dwqfec",
        "x-rate-limit-remaining" : "23", "x-rate-limit-types" : ["weweq", "fefw"]});
    assertJsonValue(response, "header1", "dwqfec");
    assertJsonValue(response, "header2", 23);
    assertJsonValue(response, "header3", ["weweq", "fefw"]);
}

@test:Config {}
function testHeaderRecordParamWithPost() returns error? {
    http:Request req = new;
    req.setHeader("x-rate-limit-id", "dwqfec");
    req.setHeader("x-rate-limit-remaining", "23");
    req.setHeader("x-rate-limit-types",  "weweq");
    req.addHeader("x-rate-limit-types",  "fefw");
    json response = check headerBindingClient->post("/headerRecord/ofStringOfPost", req);
    assertJsonValue(response, "header1", "dwqfec");
    assertJsonValue(response, "header2", 23);
    assertJsonValue(response, "header3", ["weweq", "fefw"]);
}

@test:Config {}
function testHeaderRecordParamOfPureTypeHeaders() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofPureTypeHeaders",
        {
            "sid" : "dwqfec",
            "iid" : "23",
            "fid" : "2.892",
            "did" : "2.8",
            "bid" : "true",
            "said" : ["dwqfec", "fnefbw"],
            "iaid" : ["23", "56"],
            "faid" : ["2.892", "3.564"],
            "daid" : ["2.8", "3.4"],
            "baid" : ["true", "false"]
        });
    assertJsonValue(response, "header1", "dwqfec");
    assertJsonValue(response, "header2", 23);
    assertJsonValue(response, "header3", 2.892d);
    assertJsonValue(response, "header4", 2.8d);
    assertJsonValue(response, "header5", true);
    assertJsonValue(response, "header6", ["dwqfec", "fnefbw"]);
    assertJsonValue(response, "header7", [23, 56]);
    assertJsonValue(response, "header8", [2.892d, 3.564d]);
    assertJsonValue(response, "header9", [2.8d, 3.4d]);
    assertJsonValue(response, "header10", [true, false]);
}

@test:Config {}
function testHeaderRecordParamOfPureTypeHeadersNegative() returns error? {
    json|error response = headerBindingClient->get("/headerRecord/ofPureTypeHeaders",
        {
            "sid" : "dwqfec",
            "iid" : "23",
            "fid" : "2.892"
        });
    if response is http:ClientRequestError {
        test:assertEquals(response.detail().statusCode, 400, msg = "Found unexpected output");
        assertErrorHeaderValue(response.detail().headers[CONTENT_TYPE], TEXT_PLAIN);
        test:assertEquals(response.detail().body, "no header value found for 'did'", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testHeaderRecordParamOfNilableTypeHeaders() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofNilableTypeHeaders",
        {
            "sid" : "dwqfec",
            "did" : "2.8",
            "fid" : "2.892",
            "bid" : "true",
            "iid" : "23",
            "said" : ["dwqfec", "fnefbw"],
            "iaid" : ["23", "56"],
            "faid" : ["2.892", "3.564"],
            "daid" : ["2.8", "3.4"],
            "baid" : ["true", "false"]
        });
    assertJsonValue(response, "header1", "dwqfec");
    assertJsonValue(response, "header2", 23);
    assertJsonValue(response, "header3", 2.892d);
    assertJsonValue(response, "header4", 2.8d);
    assertJsonValue(response, "header5", true);
    assertJsonValue(response, "header6", ["dwqfec", "fnefbw"]);
    assertJsonValue(response, "header7", [23, 56]);
    assertJsonValue(response, "header8", [2.892d, 3.564d]);
    assertJsonValue(response, "header9", [2.8d, 3.4d]);
    assertJsonValue(response, "header10", [true, false]);
}

@test:Config {}
function testHeaderRecordParamOfNilableTypeHeadersWithMissingFields() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofNilableTypeHeaders",
        {
            "sid" : "dwqfec",
            "fid" : "2.892",
            "bid" : "true",
            "iaid" : ["23", "56"],
            "faid" : ["2.892", "3.564"],
            "daid" : ["2.8", "3.4"]
        });
    assertJsonValue(response, "header1", "dwqfec");
    assertJsonValue(response, "header2", null);
    assertJsonValue(response, "header3", 2.892d);
    assertJsonValue(response, "header4", null);
    assertJsonValue(response, "header5", true);
    assertJsonValue(response, "header6", null);
    assertJsonValue(response, "header7", [23, 56]);
    assertJsonValue(response, "header8", [2.892d, 3.564d]);
    assertJsonValue(response, "header9", [2.8d, 3.4d]);
    assertJsonValue(response, "header10", null);
}
