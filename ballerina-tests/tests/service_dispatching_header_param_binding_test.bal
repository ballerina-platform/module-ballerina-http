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

    resource function get q4(@http:Header string? foo, http:Headers headerObj) returns json {
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

type ReadonlyTypeHeaders record {|
    readonly & string[] sid;
    readonly & int[]? iid;
    readonly & string[]? said;
    readonly & int[] iaid;
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

    resource function get rateLimitHeadersNilableRecord(@http:Header RateLimitHeaders? rateLimitHeaders) returns json {
        RateLimitHeaders? headers = rateLimitHeaders;
        if headers is RateLimitHeaders {
            return { status : "non-nil", value : headers.x\-rate\-limit\-id };
        } else {
            return { status : "nil" };
        }
    }

    resource function get rateLimitHeadersReadOnly(@http:Header readonly & RateLimitHeaders rateLimitHeaders) returns json {
        RateLimitHeaders headers = rateLimitHeaders;
        if headers is readonly & RateLimitHeaders {
            return { status : "readonly", value : headers.x\-rate\-limit\-id };
        } else {
            return { status : "non-readonly", value : headers.x\-rate\-limit\-id };
        }
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

    resource function get ofReadonlyHeaders(@http:Header ReadonlyTypeHeaders rateLimitHeaders) returns json {
        string[] stringId = rateLimitHeaders.sid;
        json j1;
        if stringId is readonly & string[] {
            j1 = { status : "readonly", value : stringId };
        } else {
            j1 = { status : "non-readonly", value : stringId };
        }

        int[]? intId = rateLimitHeaders.iid;
        json j2;
        if intId is readonly & int[]? {
            j2 = { status : "readonly", value : intId };
        } else {
            j2 = { status : "non-readonly", value : intId };
        }

        string[]? stringArrId = rateLimitHeaders.said;
        json j3;
        if stringArrId is readonly & string[]? {
            j3 = { status : "readonly", value : stringArrId };
        } else {
            j3 = { status : "non-readonly", value : stringArrId };
        }

        int[] intArrId = rateLimitHeaders.iaid;
        json j4;
        if intArrId is readonly & int[] {
            j4 = { status : "readonly", value : intArrId };
        } else {
            j4 = { status : "non-readonly", value : intArrId };
        }

        return { header1 : j1, header2 : j2, header3 : j3, header4 : j4 };
    }

    resource function get ofOtherPureHeaders(@http:Header int iid, @http:Header float fid,
            @http:Header decimal did,  @http:Header boolean bid,  @http:Header int[] iaid, @http:Header float[] faid,
            @http:Header decimal[] daid, @http:Header boolean[] baid) returns json {
        return { header1 : iid, header2 : fid, header3 : did, header4 : bid, header5 : iaid, header6 : faid,
            header7 : daid, header8 : baid };
    }

    resource function get ofOtherNilableHeaders(@http:Header int? iid, @http:Header float? fid,
            @http:Header decimal? did, @http:Header boolean? bid, @http:Header int[]? iaid,
            @http:Header float[]? faid, @http:Header decimal[]? daid, @http:Header boolean[]? baid) returns json {
        json j1 = iid is int ? iid : "no header iid";
        json j2 = fid is float ? fid : "no header fid";
        json j3 = did is decimal ? did : "no header did";
        json j4 = bid is boolean ? bid : "no header bid";
        json j5 = iaid is int[] ? iaid : "no header iaid";
        json j6 = faid is float[] ? faid : "no header faid";
        json j7 = daid is decimal[] ? daid : "no header daid";
        json j8 = baid is boolean[] ? baid : "no header baid";

        return { header1 : j1, header2 : j2, header3 : j3, header4 : j4, header5 : j5, header6 : j6, header7 : j7,
                header8 : j8 };
    }

    resource function get ofOtherHeaderTypesWithReadonly(@http:Header readonly & int[] iaid,
            @http:Header readonly & float[]? faid, @http:Header readonly & decimal[]? daid,
            @http:Header readonly & boolean[] baid) returns json {
        int[] intId = iaid;
        json j1;
        if intId is readonly & int[] {
            j1 = { status : "readonly", value : intId };
        } else {
            j1 = { status : "non-readonly", value : intId };
        }
        boolean[] booleanId = baid;
        json j2;
        if booleanId is readonly & boolean[] {
            j2 = { status : "readonly", value : booleanId };
        } else {
            j2 = { status : "non-readonly", value : booleanId };
        }
        float[]? floatId = faid;
        json j3;
        if floatId is readonly & float[] {
            j3 = { status : "readonly", value : floatId };
        } else {
            j3 = { status : "non-readonly", value : "nil float" };
        }
        decimal[]? decimalId = daid;
        json j4;
        if decimalId is readonly & decimal[] {
            j4 = { status : "readonly", value : decimalId };
        } else {
            j4 = { status : "non-readonly", value : "nil decimal" };
        }
        return { header1 : j1, header2 : j2, header3 : j3, header4 : j4};
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

@test:Config {}
function testReadonlyTypeWithHeaderRecord() returns error? {
    json response = check headerBindingClient->get("/headerRecord/rateLimitHeadersReadOnly",
        { "x-rate-limit-id" : "dwqfec", "x-rate-limit-remaining" : "23", "x-rate-limit-types" : ["weweq", "fefw"]});
    assertJsonValue(response, "status", "readonly");
    assertJsonValue(response, "value", "dwqfec");
}

@test:Config {}
function testNilableHeaderRecordSuccess() returns error? {
    json response = check headerBindingClient->get("/headerRecord/rateLimitHeadersNilableRecord",
        { "x-rate-limit-id" : "dwqfec", "x-rate-limit-remaining" : "23", "x-rate-limit-types" : ["weweq", "fefw"]});
    assertJsonValue(response, "status", "non-nil");
    assertJsonValue(response, "value", "dwqfec");
}

@test:Config {}
function testNilableHeaderRecordNegative() returns error? {
    json response = check headerBindingClient->get("/headerRecord/rateLimitHeadersNilableRecord",
        {"x-rate-limit-types" : ["weweq", "fefw"]});
    assertJsonValue(response, "status", "nil");
}

@test:Config {}
function testReadonlyHeaderRecordParam() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofReadonlyHeaders",
        {
            "sid" : ["dwqfec"],
            "iid" : ["345"],
            "said" : ["fewnvw", "ceq"],
            "iaid" : ["23", "56"]
        });
    assertJsonValue(response, "header1", { status : "readonly", value : ["dwqfec"] });
    assertJsonValue(response, "header2", { status : "readonly", value : [345] });
    assertJsonValue(response, "header3", { status : "readonly", value : ["fewnvw", "ceq"] });
    assertJsonValue(response, "header4", { status : "readonly", value : [23, 56] });
}

@test:Config {}
function testHeaderRecordOfPureTypeHeaders() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofOtherPureHeaders",
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
    assertJsonValue(response, "header1", 23);
    assertJsonValue(response, "header2", 2.892d);
    assertJsonValue(response, "header3", 2.8d);
    assertJsonValue(response, "header4", true);
    assertJsonValue(response, "header5", [23, 56]);
    assertJsonValue(response, "header6", [2.892d, 3.564d]);
    assertJsonValue(response, "header7", [2.8d, 3.4d]);
    assertJsonValue(response, "header8", [true, false]);
}

@test:Config {}
function testHeaderRecordOfPureTypeHeadersNegative() {
    json|error response = headerBindingClient->get("/headerRecord/ofOtherPureHeaders",
        {
            "sid" : "dwqfec",
            "fid" : "2.892",
            "iid" : "23",
            "iaid" : ["23", "56"],
            "daid" : ["2.8", "3.4"]
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
function testHeaderParamOfNilableTypeHeaders() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofOtherNilableHeaders",
        {
            "sid" : "dwqfec",
            "fid" : "2.892",
            "iid" : "23",
            "iaid" : ["23", "56"],
            "daid" : ["2.8", "3.4"],
            "baid" : ["true", "false"]
        });
    assertJsonValue(response, "header1", 23);
    assertJsonValue(response, "header2", 2.892d);
    assertJsonValue(response, "header3", "no header did");
    assertJsonValue(response, "header4", "no header bid");
    assertJsonValue(response, "header5", [23, 56]);
    assertJsonValue(response, "header6", "no header faid");
    assertJsonValue(response, "header7", [2.8d, 3.4d]);
    assertJsonValue(response, "header8", [true, false]);
}

@test:Config {}
function testReadonlyHeaderParams() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofOtherHeaderTypesWithReadonly",
        {
            "said" : ["dwqfec", "fnefbw"],
            "iaid" : ["23", "56"],
            "daid" : ["2.8", "3.4"],
            "baid" : ["true", "false"]
        });
    assertJsonValue(response, "header1", { status : "readonly", value : [23, 56] });
    assertJsonValue(response, "header2", { status : "readonly", value : [true, false] });
    assertJsonValue(response, "header3", { status : "non-readonly", value : "nil float" });
    assertJsonValue(response, "header4", { status : "readonly", value : [2.8d, 3.4d] });
}
