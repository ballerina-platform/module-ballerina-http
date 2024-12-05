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

import ballerina/lang.'float as langfloat;
import ballerina/lang.'int as langint;
import ballerina/lang.'boolean as langboolean;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener utmTestEP = new (uriTemplateMatchingTestPort, httpVersion = http:HTTP_1_1);
final http:Client utmClient = check new ("http://localhost:" + uriTemplateMatchingTestPort.toString(), httpVersion = http:HTTP_1_1);

service /hello on utmTestEP {

    resource function get echo2(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"echo5": "echo5"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo2/[string abc](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"echo3": abc};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo2/[string abc]/bar(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"first": abc, "echo4": "echo4"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo2/literal\.id(http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {"echo6": "literal invoked"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo2/[string zz]/foo(http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {"echo6": "specific path invoked"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo2/[string... s](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"echo5": "any"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo3/[string abc](http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        json responseJson = {"first": abc, "second": (foo is string[] ? foo[0] : "go"), "echo9": "echo9"};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get .(http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        json responseJson = {"third": (foo is string[] ? foo[0] : "go"), "echo10": "echo10"};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default echo11(http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        json responseJson = {"third": (foo is string[] ? foo[0] : ""), "echo11": "echo11"};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo12/[string abc]/bar(http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {"echo12": abc};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo125(http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();
        string[]? bar = params["foo"];
        json responseJson = {"echo125": (bar is string[] ? bar[0] : "")};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get paramNeg(http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();
        string[]? bar = params["foo"] ?: [""];
        json responseJson = {"echo125": (bar is string[] ? bar[0] : "")};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo13(http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();
        string[]? barStr = params["foo"];
        var result = langint:fromString(barStr is string[] ? barStr[0] : "0");
        int bar = (result is int) ? result : 0;
        json responseJson = {"echo13": bar};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo14(http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();
        string[]? barStr = params["foo"];
        var result = langfloat:fromString(barStr is string[] ? barStr[0] : "0.0");
        float bar = (result is float) ? result : 0.0;
        json responseJson = {"echo14": bar};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo15(http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();
        string[]? barStr = params["foo"];
        string val = barStr is string[] ? barStr[0] : "";
        boolean bar = false;
        boolean|error result = langboolean:fromString(val);
        if result is boolean {
            bar = result;
        }
        json responseJson = {"echo15": bar};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo155(http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        string[]? bar = params["bar"];
        string name1 = foo is string[] ? foo[0] : "";
        string name2 = foo is string[] ? foo[1] : "";
        string name3 = bar is string[] ? bar[0] : "";
        string name4 = foo is string[] ? foo[2] : "";
        json responseJson = {
            "name1": name1,
            "name2": name2,
            "name3": (name3 != "" ? name3 : ()),
            "name4": name4
        };
        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo156/[string key](http:Caller caller, http:Request req) returns error? {
        map<string[]> paramMap = req.getQueryParams();
        string[] valueArray = req.getQueryParamValues(key) ?: ["array not found"];
        string value = req.getQueryParamValue(key) ?: "value not found";
        string[]? paramVals = paramMap[key];
        string mapVal = paramVals is string[] ? paramVals[0] : "";
        string[]? paramVals2 = paramMap["foo"];
        string mapVal2 = paramVals2 is string[] ? paramVals2[0] : "";
        json responseJson = {
            "map": mapVal,
            "array": valueArray[0],
            "value": value,
            "map_": mapVal2,
            "array_": valueArray[1]
        };
        check caller->respond(responseJson);
    }

    resource function post so2(http:Caller caller, http:Request req) {
    }
}

service /hello/world on utmTestEP {

    resource function get echo2(http:Caller caller) returns error? {
        json responseJson = {"echo1": "echo1"};
        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo2/[string... s](http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {"echo2": "echo2"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo2/foo/bar(http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {"echo3": "echo3"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }
}

service on utmTestEP {
    resource function 'default echo1(http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        json responseJson = {"third": (foo is string[] ? foo[0] : ""), "echo33": "echo1"};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }
}

service /echo44 on utmTestEP {

    resource function 'default echo2(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"first": "zzz"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default echo1(http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        json responseJson = {"first": (foo is string[] ? foo[0] : ""), "echo44": "echo1"};

        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function get echo2(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"first": "bar"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }
}

service /echo55 on utmTestEP {

    resource function 'default foo/bar(http:Caller caller, http:Request req) returns error? {
        json responseJson = {"echo55": "echo55"};
        map<string[]> params = req.getQueryParams();
        string[]? foo = params["foo"];
        if foo is () {
            responseJson = {"echo55": "nil"};
        }

        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default [string... s](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"echo55": "default"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default foo/[string... s](http:Caller caller, http:Request req) returns error? {
        json responseJson = {"echo55": "/foo/*"};
        http:Response res = new;
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }
}

service /echo69 on utmTestEP {
    resource function 'default a/[string... a](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"echo66": req.extraPathInfo};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default a(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        if req.extraPathInfo == "" {
            req.extraPathInfo = "empty";
        }
        json responseJson = {"echo66": req.extraPathInfo};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }
}

service /wildcard on utmTestEP {

    resource function post [string id](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {message: "Path Params Resource is invoked."};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default [string... wildcardResource](http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {message: "Wildcard Params Resource is invoked."};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default go/[string aaa]/[string bbb]/[string ccc](http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {aaa: aaa, bbb: bbb, ccc: ccc};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default go/[string xxx]/[string yyy](http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {xxx: xxx, yyy: yyy};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default Go(http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {value: "capitalized"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default twisted/[string age]/[string name](http:Caller caller) returns error? {
        json responseJson = {Name: name, Age: age};
        check caller->respond(responseJson);
    }

    resource function 'default 'type/[int age]/[string name]/[boolean status]/[float weight](http:Caller caller)
            returns error? {
        int balAge = age + 1;
        float balWeight = weight + 2.95;
        string balName = name + " false";
        if status {
            balName = name;
        }
        json responseJson = {Name: name, Age: balAge, Weight: balWeight, Status: status, Lang: balName};
        check caller->respond(responseJson);
    }
}

service /encodedUri on utmTestEP {
    resource function 'default test/[string aaa]/[string bbb]/[string ccc](http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {aaa: aaa, bbb: bbb, ccc: ccc};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }
}

service /restParam on utmTestEP {

    resource function 'default 'string/[string... aaa]() returns json {
        return {aaa: aaa};
    }

    resource function 'default 'int/[int... aaa](http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {aaa: aaa};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default 'bool/[boolean... aaa](http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {aaa: aaa};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default 'float/[float... aaa](http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {aaa: aaa};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    resource function 'default 'decimal/[decimal... aaa](http:Caller caller) returns error? {
        http:Response res = new;
        json responseJson = {aaa: aaa};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }
}

//Test dispatching with URL. /hello/world/echo2?regid=abc
@test:Config {}
function testMostSpecificMatchWithQueryParam() {
    http:Response|error response = utmClient->get("/hello/world/echo2?regid=abc");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo1", "echo1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/world/echo2/bar
@test:Config {}
function testMostSpecificMatchWithWildCard() {
    http:Response|error response = utmClient->get("/hello/world/echo2/bar");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo2", "echo2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/world/echo2/foo/bar
@test:Config {}
function testMostSpecificMatch() {
    http:Response|error response = utmClient->get("/hello/world/echo2/foo/bar");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo3", "echo3");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/echo2?regid=abc
@test:Config {}
function testMostSpecificServiceDispatch() {
    http:Response|error response = utmClient->get("/hello/echo2?regid=abc");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo5", "echo5");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSubPathEndsWithPathParam() {
    http:Response|error response = utmClient->get("/hello/echo2/shafreen");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo3", "shafreen");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/echo2/shafreen-anfar & /hello/echo2/shafreen+anfar
@test:Config {}
function testMostSpecificWithPathParam() {
    http:Response|error response = utmClient->get("/hello/echo2/shafreen-anfar");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo3", "shafreen-anfar");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo2/shafreen+anfar");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo3", "shafreen anfar");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/echo2/shafreen+anfar/bar
@test:Config {}
function testSubPathEndsWithBar() {
    http:Response|error response = utmClient->get("/hello/echo2/shafreen+anfar/bar");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "first", "shafreen anfar");
        common:assertJsonValue(response.getJsonPayload(), "echo4", "echo4");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with URL. /hello/echo2/shafreen+anfar/foo/bar
@test:Config {}
function testLeastSpecificURITemplate() {
    http:Response|error response = utmClient->get("/hello/echo2/shafreen+anfar/foo/bar");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo5", "any");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testParamDefaultValues() {
    http:Response|error response = utmClient->get("/hello/echo3/shafreen+anfar?foo=bar");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "first", "shafreen anfar");
        common:assertJsonValue(response.getJsonPayload(), "second", "bar");
        common:assertJsonValue(response.getJsonPayload(), "echo9", "echo9");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPathParamWithSuffix() {
    http:Response|error response = utmClient->get("/hello/echo2/suffix.id");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo3", "suffix.id");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBestMatchWhenPathLiteralHasSameSuffix() {
    http:Response|error response = utmClient->get("/hello/echo2/literal.id");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo6", "literal invoked");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSpecificMatchForPathParamWithSuffix() {
    http:Response|error response = utmClient->get("/hello/echo2/ballerina.id/foo");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo6", "specific path invoked");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPathParamWithInvalidSuffix() {
    http:Response|error response = utmClient->get("/hello/echo2/suffix.hello");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo3", "suffix.hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPathSegmentContainsBothLeadingDotsAndSuffix() {
    http:Response|error response = utmClient->get("/hello/echo2/Rs.654.58.id");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo3", "Rs.654.58.id");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSpecificPathParamSuffix() {
    http:Response|error response = utmClient->get("/hello/echo2/hello.identity");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo3", "hello.identity");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testRootPathDefaultValues() {
    http:Response|error response = utmClient->get("/hello?foo=zzz");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "third", "zzz");
        common:assertJsonValue(response.getJsonPayload(), "echo10", "echo10");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDefaultPathDefaultValues() {
    http:Response|error response = utmClient->get("/hello/echo11?foo=zzz");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "third", "zzz");
        common:assertJsonValue(response.getJsonPayload(), "echo11", "echo11");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testServiceRoot() {
    http:Response|error response = utmClient->get("/echo1?foo=zzz");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "third", "zzz");
        common:assertJsonValue(response.getJsonPayload(), "echo33", "echo1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAllDefaultValues() {
    http:Response|error response = utmClient->get("/echo44/echo1?foo=zzz");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "first", "zzz");
        common:assertJsonValue(response.getJsonPayload(), "echo44", "echo1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testWrongGETMethod() {
    http:Response|error response = utmClient->get("/hello/so2");
    if response is http:Response {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testWrongPOSTMethod() {
    http:Response|error response = utmClient->post("/hello/echo2", "hi");
    if response is http:Response {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testValueWithNextSegmentStartCharacter() {
    http:Response|error response = utmClient->get("/hello/echo12/bar/bar");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo12", "bar");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testStringQueryParam() {
    http:Response|error response = utmClient->get("/hello/echo125?foo=hello");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo125", "hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo125?foo=");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo125", "");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetQueryParamNegative() {
    http:Response|error response = utmClient->get("/hello/paramNeg");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo125", "");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testIntegerQueryParam() {
    http:Response|error response = utmClient->get("/hello/echo13?foo=1");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo13", 1);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo13?foo=");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo13", 0);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testFloatQueryParam() {
    http:Response|error response = utmClient->get("/hello/echo14?foo=1.11");
    if response is http:Response {
        decimal dValue = 1.11;
        common:assertJsonValue(response.getJsonPayload(), "echo14", dValue);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo14?foo=");
    if response is http:Response {
        decimal dValue = 0.0;
        common:assertJsonValue(response.getJsonPayload(), "echo14", dValue);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBooleanQueryParam() {
    http:Response|error response = utmClient->get("/hello/echo15?foo=true");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo15", true);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo15?foo=");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo15", false);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSameNameQueryParam() {
    http:Response|error response = utmClient->get("/hello/echo155?foo=a,b&bar=c&foo=d");
    if response is http:Response {
        json expected = {name1: "a", name2: "b", name3: "c", name4: "d"};
        common:assertJsonPayload(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo155?foo=a,b,c");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "name3", ());
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testQueryParamWithSpecialChars() {
    http:Response|error response = utmClient->get("/hello/echo125?foo=%25aaa");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo125", "%aaa");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo125?foo=abc%21");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo125", "abc!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo125?foo=Owner%20IN%20%28%27owner1%27%2C%27owner2%27%29,Owner%20OUT");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo125", "Owner IN ('owner1','owner2')");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetQueryParamValueNegative() {
    http:Response|error response = utmClient->get("/hello?bar=");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "third", "go");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetQueryParamValuesNegative() {
    http:Response|error response = utmClient->get("/hello/paramNeg?bar=xxx,zzz");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo125", "");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAllInOneQueryParamAPIs() {
    http:Response|error response = utmClient->get("/hello/echo156/bar?foo=a,b&bar=c&bar=d");
    if response is http:Response {
        json expected = {'map: "c", array: "c", value: "c", map_: "a", array_: "d"};
        common:assertJsonPayload(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/hello/echo156/zzz?zzz=x,X&bar=x&foo=");
    if response is http:Response {
        json expected = {'map: "x", array: "x", value: "x", map_: "", array_: "X"};
        common:assertJsonPayload(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testResourceWithoutMethod() {
    http:Response|error response = utmClient->post("/echo44/echo2", "hi");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "first", "zzz");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->head("/echo44/echo2");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->put("/echo44/echo2", "hi");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "first", "zzz");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->delete("/echo44/echo2");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "first", "zzz");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->options("/echo44/echo2");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "first", "zzz");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBestMatchingResource() {
    http:Response|error response = utmClient->get("/echo44/echo2");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "first", "bar");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDefaultResourceSupport() {
    http:Response|error response = utmClient->post("/echo55/hello", "Test");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo55", "default");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/echo55/foo");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo55", "default");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/echo55/foo/");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo55", "default");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/echo55/foo/abc");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo55", "/foo/*");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testRestUriPostFix() {
    http:Response|error response = utmClient->get("/echo69/a/b/c");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo66", "/b/c");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/echo69/a/c");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo66", "/c");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/echo69/a");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo66", "empty");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMatchWithWildCard() {
    http:Response|error response = utmClient->get("/wildcard/123");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "message", "Wildcard Params Resource is invoked.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBestMatchWithWildCard() {
    http:Response|error response = utmClient->post("/wildcard/123", "hi");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "message", "Path Params Resource is invoked.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDifferentLengthPathParams() {
    http:Response|error response = utmClient->get("/wildcard/go/wso2/ballerina/http");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "aaa", "wso2");
        common:assertJsonValue(response.getJsonPayload(), "bbb", "ballerina");
        common:assertJsonValue(response.getJsonPayload(), "ccc", "http");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/wildcard/go/123/456");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "xxx", "123");
        common:assertJsonValue(response.getJsonPayload(), "yyy", "456");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBestMatchWithCapitalizedPathSegments() {
    http:Response|error response = utmClient->post("/wildcard/Go", "POST");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "value", "capitalized");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testTwistedPathSegmentsInTheSignature() {
    http:Response|error response = utmClient->get("/wildcard/twisted/20/john");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "Name", "john");
        common:assertJsonValue(response.getJsonPayload(), "Age", "20");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMultiTypePathSegmentsInTheSignature() {
    http:Response|error response = utmClient->get("/wildcard/type/20/ballerina/true/15.6");
    if response is http:Response {
        decimal dValue = 18.55;
        common:assertJsonValue(response.getJsonPayload(), "Name", "ballerina");
        common:assertJsonValue(response.getJsonPayload(), "Age", 21);
        common:assertJsonValue(response.getJsonPayload(), "Weight", dValue);
        common:assertJsonValue(response.getJsonPayload(), "Status", true);
        common:assertJsonValue(response.getJsonPayload(), "Lang", "ballerina");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/wildcard/type/120/hello/false/15.9");
    if response is http:Response {
        decimal dValue = 18.85;
        common:assertJsonValue(response.getJsonPayload(), "Name", "hello");
        common:assertJsonValue(response.getJsonPayload(), "Age", 121);
        common:assertJsonValue(response.getJsonPayload(), "Weight", dValue);
        common:assertJsonValue(response.getJsonPayload(), "Status", false);
        common:assertJsonValue(response.getJsonPayload(), "Lang", "hello false");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testEncodedPathParams() {
    http:Response|error response = utmClient->get("/wildcard/go/1%2F1/ballerina/1%2F3");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "aaa", "1/1");
        common:assertJsonValue(response.getJsonPayload(), "bbb", "ballerina");
        common:assertJsonValue(response.getJsonPayload(), "ccc", "1/3");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = utmClient->get("/wildcard/go/123/456");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "xxx", "123");
        common:assertJsonValue(response.getJsonPayload(), "yyy", "456");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testRestParamWithEncodedPathSegments() {
http:Response|error response = utmClient->get("/restParam/string/path%2Fseg/path%20seg/path%2Fseg+123");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "aaa", ["path/seg", "path seg", "path/seg+123"]);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMultipleIntTypedRestParams() {
    http:Response|error response = utmClient->get("/restParam/int/345/234/123");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "aaa", [345, 234, 123]);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMultipleNegativeRestParams() returns error? {
    http:Response|error response = utmClient->get("/restParam/int/12.3/4.56");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "error in casting path parameter : 'aaa'",
            "Bad Request", 400, "/restParam/int/12.3/4.56", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMultipleFloatRestParams() {
    http:Response|error response = utmClient->get("/restParam/float/12.3/4.56");
    if response is http:Response {
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), {"aaa": [12.3, 4.56]});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMultipleBoolRestParams() {
    http:Response|error response = utmClient->get("/restParam/bool/true/false/true");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "aaa", [true, false, true]);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMultipleDeciRestParams() {
    http:Response|error response = utmClient->get("/restParam/decimal/12.3/4.56");
    if response is http:Response {
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), {"aaa": [12.3, 4.56]});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
