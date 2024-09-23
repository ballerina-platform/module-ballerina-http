// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerina/http_test_common as common;

listener http:Listener HeaderBindingEP = new (headerParamBindingTestPort);
final http:Client headerBindingClient = check new ("http://localhost:" + headerParamBindingTestPort.toString());

service /headerparamservice on HeaderBindingEP {

    resource function get .(@http:Header string foo, int bar, http:Request req) returns json {
        json responseJson = {value1: foo, value2: bar};
        return responseJson;
    }

    resource function post q1/[string go](@http:Header string[] foo, @http:Payload string a, string b)
            returns json {
        json responseJson = {xType: foo, path: go, payload: a, page: b};
        return responseJson;
    }

    resource function get q2(@http:Header {name: "x-Type"} string foo, @http:Header {name: "x-Type"} string[] bar)
            returns json {
        json responseJson = {firstValue: foo, allValue: bar};
        return responseJson;
    }

    resource function get q3(@http:Header string? foo, http:Request req, @http:Header string[]? bar,
            http:Headers headerObj) returns json|error {
        string[] err = ["bar header not found"];
        string header1 = foo ?: "foo header not found";
        string[] header2 = bar ?: err;
        string header3 = check headerObj.getHeader("BAz");
        json responseJson = {val1: header1, val2: header2, val3: header3};
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
            header3[0] = header3Val.message();
        }
        string[] headerNames = headerObj.getHeaderNames();
        json responseJson = {val1: header1, val2: header2, val3: headerBool, val4: header3, val5: headerNames};
        return responseJson;
    }

    resource function get q5(@http:Header string x\-Type) returns string {
        return x\-Type;
    }

    resource function get q6(@http:Header string? foo) returns string {
        return foo ?: "empty";
    }
}

public type RateLimitHeaders record {|
    string x\-rate\-limit\-id;
    int? x\-rate\-limit\-remaining;
    string[]? x\-rate\-limit\-types;
|};

public type RateLimitHeadersNew record {|
    @http:Header {name: "x-rate-limit-id"}
    string rateLimitId;
    @http:Header {name: "x-rate-limit-remaining"}
    int? rateLimitRemaining;
    @http:Header {name: "x-rate-limit-types"}
    string[]? rateLimitTypes;
|};

public type PureTypeHeaders record {|
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

public type NilableTypeHeaders record {|
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

public type ReadonlyTypeHeaders record {|
    readonly & string[] sid;
    readonly & int[]? iid;
    readonly & string[]? said;
    readonly & int[] iaid;
|};

service /headerRecord on HeaderBindingEP {
    resource function get rateLimitHeaders(@http:Header RateLimitHeaders rateLimitHeaders) returns json {
        return {
            header1: rateLimitHeaders.x\-rate\-limit\-id,
            header2: rateLimitHeaders.x\-rate\-limit\-remaining,
            header3: rateLimitHeaders.x\-rate\-limit\-types
        };
    }

    resource function get rateLimitHeadersNew(@http:Header RateLimitHeadersNew rateLimitHeaders) returns json {
            return {
                header1: rateLimitHeaders.rateLimitId,
                header2: rateLimitHeaders.rateLimitRemaining,
                header3: rateLimitHeaders.rateLimitTypes
            };
        }

    resource function post ofStringOfPost(@http:Header RateLimitHeaders rateLimitHeaders) returns json {
        return {
            header1: rateLimitHeaders.x\-rate\-limit\-id,
            header2: rateLimitHeaders.x\-rate\-limit\-remaining,
            header3: rateLimitHeaders.x\-rate\-limit\-types
        };
    }

    resource function get rateLimitHeadersNilableRecord(@http:Header RateLimitHeaders? rateLimitHeaders) returns json {
        RateLimitHeaders? headers = rateLimitHeaders;
        if headers is RateLimitHeaders {
            return {status: "non-nil", value: headers.x\-rate\-limit\-id};
        } else {
            return {status: "nil"};
        }
    }

    resource function get rateLimitHeadersReadOnly(@http:Header readonly & RateLimitHeaders rateLimitHeaders) returns json {
        RateLimitHeaders headers = rateLimitHeaders;
        if headers is readonly & RateLimitHeaders {
            return {status: "readonly", value: headers.x\-rate\-limit\-id};
        } else {
            return {status: "non-readonly", value: headers.x\-rate\-limit\-id};
        }
    }

    resource function get ofPureTypeHeaders(@http:Header PureTypeHeaders headers) returns json {
        return {
            header1: headers.sid,
            header2: headers.iid,
            header3: headers.fid,
            header4: headers.did,
            header5: headers.bid,
            header6: headers.said,
            header7: headers.iaid,
            header8: headers.faid,
            header9: headers.daid,
            header10: headers.baid
        };
    }

    resource function get ofNilableTypeHeaders(@http:Header NilableTypeHeaders headers) returns json {
        return {
            header1: headers.sid,
            header2: headers.iid,
            header3: headers.fid,
            header4: headers.did,
            header5: headers.bid,
            header6: headers.said,
            header7: headers.iaid,
            header8: headers.faid,
            header9: headers.daid,
            header10: headers.baid
        };
    }

    resource function get ofReadonlyHeaders(@http:Header ReadonlyTypeHeaders rateLimitHeaders) returns json {
        string[] stringId = rateLimitHeaders.sid;
        json j1;
        if stringId is readonly & string[] {
            j1 = {status: "readonly", value: stringId};
        } else {
            j1 = {status: "non-readonly", value: stringId};
        }

        int[]? intId = rateLimitHeaders.iid;
        json j2;
        if intId is readonly & int[]? {
            j2 = {status: "readonly", value: intId};
        } else {
            j2 = {status: "non-readonly", value: intId};
        }

        string[]? stringArrId = rateLimitHeaders.said;
        json j3;
        if stringArrId is readonly & string[]? {
            j3 = {status: "readonly", value: stringArrId};
        } else {
            j3 = {status: "non-readonly", value: stringArrId};
        }

        int[] intArrId = rateLimitHeaders.iaid;
        json j4;
        if intArrId is readonly & int[] {
            j4 = {status: "readonly", value: intArrId};
        } else {
            j4 = {status: "non-readonly", value: intArrId};
        }

        return {header1: j1, header2: j2, header3: j3, header4: j4};
    }

    resource function get ofOtherPureHeaders(@http:Header int iid, @http:Header float fid,
            @http:Header decimal did, @http:Header boolean bid, @http:Header int[] iaid, @http:Header float[] faid,
            @http:Header decimal[] daid, @http:Header boolean[] baid) returns json {
        return {
            header1: iid,
            header2: fid,
            header3: did,
            header4: bid,
            header5: iaid,
            header6: faid,
            header7: daid,
            header8: baid
        };
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

        return {
            header1: j1,
            header2: j2,
            header3: j3,
            header4: j4,
            header5: j5,
            header6: j6,
            header7: j7,
            header8: j8
        };
    }

    resource function get ofOtherHeaderTypesWithReadonly(@http:Header readonly & int[] iaid,
            @http:Header readonly & float[]? faid, @http:Header readonly & decimal[]? daid,
            @http:Header readonly & boolean[] baid) returns json {
        int[] intId = iaid;
        json j1;
        if intId is readonly & int[] {
            j1 = {status: "readonly", value: intId};
        } else {
            j1 = {status: "non-readonly", value: intId};
        }
        boolean[] booleanId = baid;
        json j2;
        if booleanId is readonly & boolean[] {
            j2 = {status: "readonly", value: booleanId};
        } else {
            j2 = {status: "non-readonly", value: booleanId};
        }
        float[]? floatId = faid;
        json j3;
        if floatId is readonly & float[] {
            j3 = {status: "readonly", value: floatId};
        } else {
            j3 = {status: "non-readonly", value: "nil float"};
        }
        decimal[]? decimalId = daid;
        json j4;
        if decimalId is readonly & decimal[] {
            j4 = {status: "readonly", value: decimalId};
        } else {
            j4 = {status: "non-readonly", value: "nil decimal"};
        }
        return {header1: j1, header2: j2, header3: j3, header4: j4};
    }

    resource function post userAgentWithPayload(@http:Payload string payloadVal,
            @http:Header {name: "user-agent"} string? userAgent) returns json {
        return {"hello": userAgent};
    }

    resource function get userAgentWithRequest(http:Request req,
            @http:Header {name: "user-agent"} string? userAgent) returns json {
        return {"hello": userAgent};
    }

    resource function get host(@http:Header {name: "host"} string? host) returns json {
        return {"hello": host ?: "nil"};
    }

    resource function get hostFromRequest(http:Request req) returns json {
        string|error host = req.getHeader("host");
        if host is string {
            return {"hello": host};
        } else {
            return {"error": host.message()};
        }
    }

    resource function get scheme(@http:Header {name: "x-http2-scheme"} string? scheme) returns json {
        return {"hello": scheme ?: "nil"};
    }
}

@test:Config {}
function testHeaderTokenBinding() {
    http:Response|error response = headerBindingClient->get("/headerparamservice/?foo=WSO2&bar=56", {"foo": "Ballerina"});
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {value1: "Ballerina", value2: 56});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = headerBindingClient->get("/headerparamservice?foo=bal&bar=12", {"foo": "WSO2"});
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {value1: "WSO2", value2: 12});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Header params are not case sensitive
@test:Config {}
function testHeaderBindingCaseInSensitivity() {
    http:Response|error response = headerBindingClient->get("/headerparamservice/?baz=WSO2&bar=56", {"FOO": "HTtP"});
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {value1: "HTtP", value2: 56});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderUnavailability() returns error? {
    http:Response|error response = headerBindingClient->get("/headerparamservice/?foo=WSO2&bar=56");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "no header value found for 'foo'",
            "Bad Request", 400, "/headerparamservice/?foo=WSO2&bar=56", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderArrayUnavailability() returns error? {
    http:Request req = new;
    req.setTextPayload("All in one");
    http:Response|error response = headerBindingClient->post("/headerparamservice/q1/hello?b=hi", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "no header value found for 'foo'",
            "Bad Request", 400, "/headerparamservice/q1/hello?b=hi", "POST");
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
        json expected = {xType: ["Hello", "World"], path: "hello", payload: "All in one", page: "hi"};
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderBindingArrayAndString() {
    http:Response|error response = headerBindingClient->get("/headerparamservice/q2", {"X-Type": ["Hello", "World"]});
    if response is http:Response {
        json expected = {firstValue: "Hello", allValue: ["Hello", "World"]};
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilableHeaderBinding() {
    var headers1 = {
        "X-Type": ["Hello", "Hello"],
        "bar": ["Write", "Language"],
        "Foo": "World",
        "baaz": "All",
        "baz": "Ballerina"
    };
    http:Response|error response = headerBindingClient->get("/headerparamservice/q3", headers1);
    if response is http:Response {
        json expected = {val1: "World", val2: ["Write", "Language"], val3: "Ballerina"};
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    var headers2 = {"X-Type": ["Hello", "Hello"], "bar": ["Write", "All"], "baz": "Language"};
    response = headerBindingClient->get("/headerparamservice/q3", headers2);
    if response is http:Response {
        json expected = {val1: "foo header not found", val2: ["Write", "All"], val3: "Language"};
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    var headers3 = {"X-Type": "Hello", "Foo": ["Write", "All"], "baz": "Hello"};
    response = headerBindingClient->get("/headerparamservice/q3", headers3);
    if response is http:Response {
        json expected = {val1: "Write", val2: ["bar header not found"], val3: "Hello"};
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderObjectBinding() {
    var headers = {
        "X-Type": ["Hello", "Hello"],
        "Foo": "World",
        "baz": "Write",
        "daz": ["All", "Ballerina"],
        "bar": "Language"
    };
    http:Response|error response = headerBindingClient->get("/headerparamservice/q4", headers);
    if response is http:Response {
        json expected = {
            val1: "World",
            val2: "Write",
            val3: true,
            val4: ["All", "Ballerina"],
            val5: ["bar", "baz", "daz", "foo", "host", "user-agent", "x-http2-scheme", "x-http2-stream-id", "x-type"]
        };
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    var headers2 = {"X-Type": ["Hello", "Hello"], "bar": "Language"};
    response = headerBindingClient->get("/headerparamservice/q4", headers2);
    if response is http:Response {
        json expected = {
            val1: "foo header not found",
            val2: "Http header does not exist",
            val3: false,
            val4: ["Http header does not exist"],
            val5: ["bar", "host", "user-agent", "x-http2-scheme", "x-http2-stream-id", "x-type"]
        };
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderParamTokenWithEscapeChar() {
    http:Response|error response = headerBindingClient->get("/headerparamservice/q5", {"x-Type": "test"});
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "test");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderBindingWithNoHeaderValue() {
    string|error response = headerBindingClient->get("/headerparamservice/q6", {"foo": ""});
    if response is string {
        test:assertEquals(response, "empty", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHeaderRecordParam() returns error? {
    json response = check headerBindingClient->get("/headerRecord/rateLimitHeaders", {
        "x-rate-limit-id": "dwqfec",
        "x-rate-limit-remaining": "23",
        "x-rate-limit-types": ["weweq", "fefw"]
    });
    common:assertJsonValue(response, "header1", "dwqfec");
    common:assertJsonValue(response, "header2", 23);
    common:assertJsonValue(response, "header3", ["weweq", "fefw"]);
}

@test:Config {}
function testHeaderRecordParamWithHeaderNameAnnotation() returns error? {
    json response = check headerBindingClient->get("/headerRecord/rateLimitHeadersNew", {
        "x-rate-limit-id": "dwqfec",
        "x-rate-limit-remaining": "23",
        "x-rate-limit-types": ["weweq", "fefw"]
    });
    common:assertJsonValue(response, "header1", "dwqfec");
    common:assertJsonValue(response, "header2", 23);
    common:assertJsonValue(response, "header3", ["weweq", "fefw"]);
}

@test:Config {}
function testHeaderRecordParamWithHeaderNameNotFound() returns error? {
    http:Response response = check headerBindingClient->get("/headerRecord/rateLimitHeadersNew", {
        "rate-limit-id": "dwqfec",
        "x-rate-limit-remaining": "23",
        "x-rate-limit-types": ["weweq", "fefw"]
    });
    test:assertEquals(response.statusCode, 400);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "no header value found for 'rateLimitId'",
        "Bad Request", 400, "/headerRecord/rateLimitHeadersNew", "GET");
}

@test:Config {}
function testHeaderRecordParamWithCastingError() returns error? {
    http:Response response = check headerBindingClient->get("/headerRecord/rateLimitHeaders", {
        "x-rate-limit-id": "dwqfec",
        "x-rate-limit-remaining": "23xyz",
        "x-rate-limit-types": ["weweq", "fefw"]
    });
    test:assertEquals(response.statusCode, 400);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "header binding failed for parameter: 'x-rate-limit-remaining'",
        "Bad Request", 400, "/headerRecord/rateLimitHeaders", "GET");
}

@test:Config {}
function testHeaderRecordParamWithPost() returns error? {
    http:Request req = new;
    req.setHeader("x-rate-limit-id", "dwqfec");
    req.setHeader("x-rate-limit-remaining", "23");
    req.setHeader("x-rate-limit-types", "weweq");
    req.addHeader("x-rate-limit-types", "fefw");
    json response = check headerBindingClient->post("/headerRecord/ofStringOfPost", req);
    common:assertJsonValue(response, "header1", "dwqfec");
    common:assertJsonValue(response, "header2", 23);
    common:assertJsonValue(response, "header3", ["weweq", "fefw"]);
}

@test:Config {}
function testHeaderRecordParamOfPureTypeHeaders() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofPureTypeHeaders",
        {
        "sid": "dwqfec",
        "iid": "23",
        "fid": "2.892",
        "did": "2.8",
        "bid": "true",
        "said": ["dwqfec", "fnefbw"],
        "iaid": ["23", "56"],
        "faid": ["2.892", "3.564"],
        "daid": ["2.8", "3.4"],
        "baid": ["true", "false"]
    });
    common:assertJsonValue(response, "header1", "dwqfec");
    common:assertJsonValue(response, "header2", 23);
    common:assertJsonValue(response, "header3", 2.892d);
    common:assertJsonValue(response, "header4", 2.8d);
    common:assertJsonValue(response, "header5", true);
    common:assertJsonValue(response, "header6", ["dwqfec", "fnefbw"]);
    common:assertJsonValue(response, "header7", [23, 56]);
    common:assertJsonValue(response, "header8", [2.892d, 3.564d]);
    common:assertJsonValue(response, "header9", [2.8d, 3.4d]);
    common:assertJsonValue(response, "header10", [true, false]);
}

@test:Config {}
function testHeaderRecordParamOfPureTypeHeadersNegative() returns error? {
    json|error response = headerBindingClient->get("/headerRecord/ofPureTypeHeaders",
        {
        "sid": "dwqfec",
        "iid": "23",
        "fid": "2.892"
    });
    if response is http:ClientRequestError {
        test:assertEquals(response.detail().statusCode, 400, msg = "Found unexpected output");
        common:assertErrorHeaderValue(response.detail().headers[common:CONTENT_TYPE], common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(<json>response.detail().body, "no header value found for 'did'",
            "Bad Request", 400, "/headerRecord/ofPureTypeHeaders", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testHeaderRecordParamOfNilableTypeHeaders() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofNilableTypeHeaders",
        {
        "sid": "dwqfec",
        "did": "2.8",
        "fid": "2.892",
        "bid": "true",
        "iid": "23",
        "said": ["dwqfec", "fnefbw"],
        "iaid": ["23", "56"],
        "faid": ["2.892", "3.564"],
        "daid": ["2.8", "3.4"],
        "baid": ["true", "false"]
    });
    common:assertJsonValue(response, "header1", "dwqfec");
    common:assertJsonValue(response, "header2", 23);
    common:assertJsonValue(response, "header3", 2.892d);
    common:assertJsonValue(response, "header4", 2.8d);
    common:assertJsonValue(response, "header5", true);
    common:assertJsonValue(response, "header6", ["dwqfec", "fnefbw"]);
    common:assertJsonValue(response, "header7", [23, 56]);
    common:assertJsonValue(response, "header8", [2.892d, 3.564d]);
    common:assertJsonValue(response, "header9", [2.8d, 3.4d]);
    common:assertJsonValue(response, "header10", [true, false]);
}

@test:Config {}
function testHeaderRecordParamOfNilableTypeHeadersWithMissingFields() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofNilableTypeHeaders",
        {
        "sid": "dwqfec",
        "fid": "2.892",
        "bid": "true",
        "iaid": ["23", "56"],
        "faid": ["2.892", "3.564"],
        "daid": ["2.8", "3.4"]
    });
    common:assertJsonValue(response, "header1", "dwqfec");
    common:assertJsonValue(response, "header2", null);
    common:assertJsonValue(response, "header3", 2.892d);
    common:assertJsonValue(response, "header4", null);
    common:assertJsonValue(response, "header5", true);
    common:assertJsonValue(response, "header6", null);
    common:assertJsonValue(response, "header7", [23, 56]);
    common:assertJsonValue(response, "header8", [2.892d, 3.564d]);
    common:assertJsonValue(response, "header9", [2.8d, 3.4d]);
    common:assertJsonValue(response, "header10", null);
}

@test:Config {}
function testReadonlyTypeWithHeaderRecord() returns error? {
    json response = check headerBindingClient->get("/headerRecord/rateLimitHeadersReadOnly",
        {"x-rate-limit-id": "dwqfec", "x-rate-limit-remaining": "23", "x-rate-limit-types": ["weweq", "fefw"]});
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", "dwqfec");
}

@test:Config {}
function testNilableHeaderRecordSuccess() returns error? {
    json response = check headerBindingClient->get("/headerRecord/rateLimitHeadersNilableRecord",
        {"x-rate-limit-id": "dwqfec", "x-rate-limit-remaining": "23", "x-rate-limit-types": ["weweq", "fefw"]});
    common:assertJsonValue(response, "status", "non-nil");
    common:assertJsonValue(response, "value", "dwqfec");
}

@test:Config {}
function testNilableHeaderRecordNegative() returns error? {
    json response = check headerBindingClient->get("/headerRecord/rateLimitHeadersNilableRecord",
        {"x-rate-limit-types": ["weweq", "fefw"]});
    common:assertJsonValue(response, "status", "nil");
}

@test:Config {}
function testReadonlyHeaderRecordParam() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofReadonlyHeaders",
        {
        "sid": ["dwqfec"],
        "iid": ["345"],
        "said": ["fewnvw", "ceq"],
        "iaid": ["23", "56"]
    });
    common:assertJsonValue(response, "header1", {status: "readonly", value: ["dwqfec"]});
    common:assertJsonValue(response, "header2", {status: "readonly", value: [345]});
    common:assertJsonValue(response, "header3", {status: "readonly", value: ["fewnvw", "ceq"]});
    common:assertJsonValue(response, "header4", {status: "readonly", value: [23, 56]});
}

@test:Config {}
function testHeaderRecordOfPureTypeHeaders() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofOtherPureHeaders",
        {
        "sid": "dwqfec",
        "did": "2.8",
        "fid": "2.892",
        "bid": "true",
        "iid": "23",
        "said": ["dwqfec", "fnefbw"],
        "iaid": ["23", "56"],
        "faid": ["2.892", "3.564"],
        "daid": ["2.8", "3.4"],
        "baid": ["true", "false"]
    });
    common:assertJsonValue(response, "header1", 23);
    common:assertJsonValue(response, "header2", 2.892d);
    common:assertJsonValue(response, "header3", 2.8d);
    common:assertJsonValue(response, "header4", true);
    common:assertJsonValue(response, "header5", [23, 56]);
    common:assertJsonValue(response, "header6", [2.892d, 3.564d]);
    common:assertJsonValue(response, "header7", [2.8d, 3.4d]);
    common:assertJsonValue(response, "header8", [true, false]);
}

@test:Config {}
function testHeaderRecordOfPureTypeHeadersNegative() returns error? {
    json|error response = headerBindingClient->get("/headerRecord/ofOtherPureHeaders",
        {
        "sid": "dwqfec",
        "fid": "2.892",
        "iid": "23",
        "iaid": ["23", "56"],
        "daid": ["2.8", "3.4"]
    });
    if response is http:ClientRequestError {
        test:assertEquals(response.detail().statusCode, 400, msg = "Found unexpected output");
        common:assertErrorHeaderValue(response.detail().headers[common:CONTENT_TYPE], common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(<json>response.detail().body, "no header value found for 'did'",
            "Bad Request", 400, "/headerRecord/ofOtherPureHeaders", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testHeaderParamOfNilableTypeHeaders() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofOtherNilableHeaders",
        {
        "sid": "dwqfec",
        "fid": "2.892",
        "iid": "23",
        "iaid": ["23", "56"],
        "daid": ["2.8", "3.4"],
        "baid": ["true", "false"]
    });
    common:assertJsonValue(response, "header1", 23);
    common:assertJsonValue(response, "header2", 2.892d);
    common:assertJsonValue(response, "header3", "no header did");
    common:assertJsonValue(response, "header4", "no header bid");
    common:assertJsonValue(response, "header5", [23, 56]);
    common:assertJsonValue(response, "header6", "no header faid");
    common:assertJsonValue(response, "header7", [2.8d, 3.4d]);
    common:assertJsonValue(response, "header8", [true, false]);
}

@test:Config {}
function testReadonlyHeaderParams() returns error? {
    json response = check headerBindingClient->get("/headerRecord/ofOtherHeaderTypesWithReadonly",
        {
        "said": ["dwqfec", "fnefbw"],
        "iaid": ["23", "56"],
        "daid": ["2.8", "3.4"],
        "baid": ["true", "false"]
    });
    common:assertJsonValue(response, "header1", {status: "readonly", value: [23, 56]});
    common:assertJsonValue(response, "header2", {status: "readonly", value: [true, false]});
    common:assertJsonValue(response, "header3", {status: "non-readonly", value: "nil float"});
    common:assertJsonValue(response, "header4", {status: "readonly", value: [2.8d, 3.4d]});
}

@test:Config {}
function testHeaderParamsCastingError() returns error? {
    http:Response response = check headerBindingClient->get("/headerRecord/ofOtherNilableHeaders",
        {"iid": "hello"});
    test:assertEquals(response.statusCode, 400);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "header binding failed for parameter: 'iid'",
        "Bad Request", 400, "/headerRecord/ofOtherNilableHeaders", "GET");

    response = check headerBindingClient->get("/headerRecord/ofOtherNilableHeaders",
        {"fid": "hello"});
    test:assertEquals(response.statusCode, 400);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "header binding failed for parameter: 'fid'",
        "Bad Request", 400, "/headerRecord/ofOtherNilableHeaders", "GET");

    response = check headerBindingClient->get("/headerRecord/ofOtherNilableHeaders",
        {"did": "hello"});
    test:assertEquals(response.statusCode, 400);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "header binding failed for parameter: 'did'",
        "Bad Request", 400, "/headerRecord/ofOtherNilableHeaders", "GET");

    response = check headerBindingClient->get("/headerRecord/ofOtherNilableHeaders",
        {"iaid": ["3", "5", "8", "hello"]});
    test:assertEquals(response.statusCode, 400);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "header binding failed for parameter: 'iaid'",
        "Bad Request", 400, "/headerRecord/ofOtherNilableHeaders", "GET");

    response = check headerBindingClient->get("/headerRecord/ofOtherNilableHeaders",
        {"faid": ["3.445", "hello", "5.667", "8.206"]});
    test:assertEquals(response.statusCode, 400);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "header binding failed for parameter: 'faid'",
        "Bad Request", 400, "/headerRecord/ofOtherNilableHeaders", "GET");

    response = check headerBindingClient->get("/headerRecord/ofOtherNilableHeaders",
        {"daid": ["3.4", "5.6", "hello", "8"]});
    test:assertEquals(response.statusCode, 400);
    check common:assertJsonErrorPayload(check response.getJsonPayload(), "header binding failed for parameter: 'daid'",
        "Bad Request", 400, "/headerRecord/ofOtherNilableHeaders", "GET");
}

@test:Config {}
function userAgentHeaderBindingTest() returns error? {
    json response = check headerBindingClient->post("/headerRecord/userAgentWithPayload", "world",
        {"user-agent": "slbeta3"});
    common:assertJsonValue(response, "hello", "slbeta3");

    response = check headerBindingClient->get("/headerRecord/userAgentWithRequest", {"user-agent": "slbeta4"});
    common:assertJsonValue(response, "hello", "slbeta4");
}

@test:Config {}
function hostHeaderBindingTest() returns error? {
    http:Client clientEP = check new("localhost:" + headerParamBindingTestPort.toString(), httpVersion = http:HTTP_1_1);
    json response = check clientEP->/headerRecord/host;
    common:assertJsonValue(response, "hello", "localhost:" + headerParamBindingTestPort.toString());

    clientEP = check new("localhost:" + headerParamBindingTestPort.toString());
    response = check clientEP->/headerRecord/host;
    common:assertJsonValue(response, "hello", "localhost:" + headerParamBindingTestPort.toString());

    response = check clientEP->/headerRecord/host;
    common:assertJsonValue(response, "hello", "localhost:" + headerParamBindingTestPort.toString());

    clientEP = check new("localhost:" + headerParamBindingTestPort.toString(), http2Settings = {http2PriorKnowledge: true});
    response = check clientEP->/headerRecord/host;
    common:assertJsonValue(response, "hello", "localhost:" + headerParamBindingTestPort.toString());
}

@test:Config {}
function hostHeaderFromRequestTest() returns error? {
    http:Client clientEP = check new("localhost:" + headerParamBindingTestPort.toString(), httpVersion = http:HTTP_1_1);
    json response = check clientEP->/headerRecord/hostFromRequest;
    common:assertJsonValue(response, "hello", "localhost:" + headerParamBindingTestPort.toString());

    clientEP = check new("localhost:" + headerParamBindingTestPort.toString());
    response = check clientEP->/headerRecord/hostFromRequest;
    common:assertJsonValue(response, "hello", "localhost:" + headerParamBindingTestPort.toString());

    response = check clientEP->/headerRecord/hostFromRequest;
    common:assertJsonValue(response, "hello", "localhost:" + headerParamBindingTestPort.toString());

    clientEP = check new("localhost:" + headerParamBindingTestPort.toString(), http2Settings = {http2PriorKnowledge: true});
    response = check clientEP->/headerRecord/hostFromRequest;
    common:assertJsonValue(response, "hello", "localhost:" + headerParamBindingTestPort.toString());
}

@test:Config {}
function schemeHeaderBindingTest() returns error? {
    http:Client clientEP = check new("localhost:" + headerParamBindingTestPort.toString(), httpVersion = http:HTTP_1_1);
    json response = check clientEP->/headerRecord/scheme;
    common:assertJsonValue(response, "hello", "nil");

    clientEP = check new("localhost:" + headerParamBindingTestPort.toString());
    response = check clientEP->/headerRecord/scheme;
    common:assertJsonValue(response, "hello", "http");

    response = check clientEP->/headerRecord/scheme;
    common:assertJsonValue(response, "hello", "http");

    clientEP = check new("localhost:" + headerParamBindingTestPort.toString(), http2Settings = {http2PriorKnowledge: true});
    response = check clientEP->/headerRecord/scheme;
    common:assertJsonValue(response, "hello", "http");
}
