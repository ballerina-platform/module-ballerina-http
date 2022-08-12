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

import ballerina/http;
import ballerina/test;
import ballerina/url;

listener http:Listener QueryBindingEP = new(queryParamBindingTest, httpVersion = http:HTTP_1_1);
final http:Client queryBindingClient = check new("http://localhost:" + queryParamBindingTest.toString(), httpVersion = http:HTTP_1_1);

// This is user-defined type
public type Count int;
public type TypeJson json;
public type Name string;
public type FirstName Name;
public type FullName FirstName;

service /queryparamservice on QueryBindingEP {

    resource function get .(string foo, http:Caller caller, int bar, http:Request req) returns error? {
        json responseJson = { value1: foo, value2: bar};
        check caller->respond(responseJson);
    }

    resource function get q1(int id, string PersoN, http:Caller caller, float val, boolean isPresent, decimal dc)
            returns error? {
        json responseJson = { iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc };
        check caller->respond(responseJson);
    }

    resource function get q2(int[] id, string[] PersoN, float[] val, boolean[] isPresent,
            http:Caller caller, decimal[] dc) returns error? {
        json responseJson = { iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc };
        check caller->respond(responseJson);
    }

    resource function get q3(http:Caller caller, int? id, string? PersoN, float? val,
            boolean? isPresent, decimal? dc) returns error? {
        json responseJson = { iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc };
        check caller->respond(responseJson);
    }

    resource function get q4(int[]? id, string[]? PersoN, float[]? val, boolean[]? isPresent,
            http:Caller caller, decimal[]? dc) returns error? {
        json responseJson = { iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc };
        check caller->respond(responseJson);
    }

    resource function get q5(map<json> obj) returns json {
        return obj;
    }

    resource function get q6(map<json>? obj) returns json {
        if obj is () {
            return { name : "empty", value : "empty" };
        }
        return obj;
    }

    resource function get q7(map<json>[] objs) returns json {
        json responseJson = { objects : objs };
        return responseJson;
    }

    resource function get q8(map<json>[]? objs) returns json {
        if objs is () {
            return { name : "empty", value : "empty" };
        }
        json responseJson = { objects : objs };
        return responseJson;
    }

    resource function get q9(string x\-Type) returns string {
        return x\-Type;
    }

    resource function get q10(string? x\-Type) returns string {
        return x\-Type ?: "default";
    }

    resource function get pets(Count count) returns http:Ok {
        http:Ok ok = {body: count};
        return ok;
    }

    resource function get petsUnion(Count? count) returns http:Ok {
        http:Ok ok = {body: "nil"};
        return ok;
    }

    resource function get petsArr(Count[] count) returns http:Ok {
        http:Ok ok = {body: count[0]};
        return ok;
    }

    resource function get petsMap(map<TypeJson> count) returns json {
        return count;
    }
    
    resource function get nestedTypeRef(FullName name) returns string {
        return name;
    }
}

@test:Config {}
function testStringQueryBinding() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/?foo=WSO2&bar=56");
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {value1:"WSO2", value2:56});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get("/queryparamservice?foo=bal&bar=12");
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {value1:"bal", value2:12});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Query params are case sensitive, https://tools.ietf.org/html/rfc7230#page-19
@test:Config {}
function testNegativeStringQueryBindingCaseSensitivity() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/?FOO=WSO2&bar=go");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        assertTextPayload(response.getTextPayload(), "no query param value found for 'foo'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNegativeIntQueryBindingCastingError() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/?foo=WSO2&bar=go");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        assertTextPayload(response.getTextPayload(), "error in casting query param : 'bar'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get("/queryparamservice/?foo=WSO2&bar=");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        assertTextPayload(response.getTextPayload(), "error in casting query param : 'bar'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAllTypeQueryBinding() {
    http:Response|error response = queryBindingClient->get(
        "/queryparamservice/q1?id=324441&isPresent=true&dc=5.67&PersoN=hello&val=1.11");
    json expected = {iValue:324441, sValue:"hello", fValue: 1.11, bValue: true, dValue: 5.67};
    if response is http:Response {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get(
        "/queryparamservice/q1?id=5652,324441,652&isPresent=false,true,false&dc=4.78,5.67,2.34" +
        "&PersoN=no,hello,gool&val=53.9,1.11,43.9");
    expected = {iValue:5652, sValue:"no", fValue: 53.9, bValue: false, dValue: 4.78 };
    if response is http:Response {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAllTypeArrQueryBinding() {
    http:Response|error response = queryBindingClient->get(
        "/queryparamservice/q2?id=324441,5652&isPresent=true,false&PersoN=hello,gool&val=1.11,53.9&dc=4.78,5.67");
    json expected = {iValue:[324441, 5652], sValue:["hello", "gool"], fValue:[1.11, 53.9],
            bValue:[true, false], dValue:[4.78, 5.67]};
    if response is http:Response {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilableAllTypeQueryBinding() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/q3");
    json expected = {iValue: null, sValue: null, fValue: null, bValue: null, dValue: null};
    if response is http:Response {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get(
        "/queryparamservice/q3?id=5652,324441,652&isPresent=false,true,false&dc=4.78,5.67" +
        "&PersoN=no,hello,gool&val=53.9,1.11,43.9");
    expected = {iValue:5652, sValue:"no", fValue: 53.9, bValue: false, dValue: 4.78};
    if response is http:Response {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilableAllTypeQueryArrBinding() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/q4?ID=8?lang=bal");
    json expected = {iValue: null, sValue: null, fValue: null, bValue: null, dValue: null};
    if response is http:Response {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get(
        "/queryparamservice/q4?id=324441,5652&isPresent=true,false&PersoN=hello,gool&val=1.11,53.9&dc=4.78,5.67");
    expected = {iValue:[324441, 5652], sValue:["hello", "gool"], fValue:[1.11, 53.9],
            bValue:[true, false], dValue:[4.78, 5.67]};
    if response is http:Response {
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMapJsonQueryBinding() returns error? {
    map<json> jsonObj = { name : "test", value : "json" };
    string jsonEncoded = check url:encode(jsonObj.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/q5?obj=" + jsonEncoded);
    assertJsonPayloadtoJsonString(response.getJsonPayload(), jsonObj);
    return;
}

@test:Config {}
function testMapJsonArrayQueryBinding() returns error? {
    map<json> jsonObj1 = { name : "test1", value : "json1" };
    map<json> jsonObj2 = { name : "test2", value : "json2" };
    json expected = { objects : [jsonObj1, jsonObj2] };
    string jsonEncoded1 = check url:encode(jsonObj1.toJsonString(), "UTF-8");
    string jsonEncoded2 = check url:encode(jsonObj2.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/q7?objs=" + jsonEncoded1 + "," +
                                jsonEncoded2);
    assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    return;
}

@test:Config {}
function testNillableMapJsonQueryBinding() returns error? {
    json emptyObj = { name : "empty", value : "empty" };
    map<json> jsonObj = { name : "test", value : "json" };
    string jsonEncoded = check url:encode(jsonObj.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/q6?obj=" + jsonEncoded);
    assertJsonPayloadtoJsonString(response.getJsonPayload(), jsonObj);

    response = check queryBindingClient->get("/queryparamservice/q6");
    assertJsonPayloadtoJsonString(response.getJsonPayload(), emptyObj);
    return;
}

@test:Config {}
function testNillableMapJsonArrayQueryBinding() returns error? {
    json emptyObj = { name : "empty", value : "empty" };
    map<json> jsonObj1 = { name : "test1", value : "json1" };
    map<json> jsonObj2 = { name : "test2", value : "json2" };
    json expected = { objects : [jsonObj1, jsonObj2] };
    string jsonEncoded1 = check url:encode(jsonObj1.toJsonString(), "UTF-8");
    string jsonEncoded2 = check url:encode(jsonObj2.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/q8?objs=" + jsonEncoded1 + "," +
                                jsonEncoded2);
    assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);

    response = check queryBindingClient->get("/queryparamservice/q8");
    assertJsonPayloadtoJsonString(response.getJsonPayload(), emptyObj);
    return;
}

@test:Config {}
function testQueryParamTokenWithEscapeChar() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/q9?x-Type=test");
    if response is http:Response {
        assertTextPayload(response.getTextPayload(), "test");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get("/queryparamservice/q10");
    if response is http:Response {
        assertTextPayload(response.getTextPayload(), "default");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get("/queryparamservice/q10?x-Type=test");
    if response is http:Response {
        assertTextPayload(response.getTextPayload(), "test");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testEmptyQueryParamBinding() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/q9?x-Type");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        assertTextPayload(response.getTextPayload(), "no query param value found for 'x-Type'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testEmptyOptionalQueryParamBinding() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/q10?x-Type");
    if response is http:Response {
        assertTextPayload(response.getTextPayload(), "default");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testOptionalRepeatingQueryParamBinding() {
    string|error response = queryBindingClient->get("/queryparamservice/q10?x-Type=test&x-Type");
    if response is string {
        test:assertEquals(response, "test", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get("/queryparamservice/q10?x-Type&x-Type=test");
    if response is string {
        test:assertEquals(response, "test", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testTypeReferenceQueryParamBinding() returns error? {
    http:Response response = check queryBindingClient->get("/queryparamservice/pets?count=10");
    assertTextPayload(response.getTextPayload(), "10");

    response = check queryBindingClient->get("/queryparamservice/petsUnion?");
    assertTextPayload(response.getTextPayload(), "nil");

    response = check queryBindingClient->get("/queryparamservice/petsArr?count=30,20,10");
    assertTextPayload(response.getTextPayload(), "30");
    
    response = check queryBindingClient->get("/queryparamservice/nestedTypeRef?name=wso2");
    assertTextPayload(response.getTextPayload(), "wso2");
}

@test:Config {}
function testTypeReferenceConstrainedMapQueryParamBinding() returns error? {
    map<json> jsonObj = { name : "test", value : "json" };
    string jsonEncoded = check url:encode(jsonObj.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/petsMap?count=" + jsonEncoded);
    assertJsonPayloadtoJsonString(response.getJsonPayload(), jsonObj);
}
