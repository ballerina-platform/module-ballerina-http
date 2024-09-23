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
import ballerina/http_test_common as common;
import ballerina/test;
import ballerina/url;

listener http:Listener QueryBindingEP = new (queryParamBindingTestPort, httpVersion = http:HTTP_1_1);
final http:Client queryBindingClient = check new ("http://localhost:" + queryParamBindingTestPort.toString(), httpVersion = http:HTTP_1_1);

// This is user-defined type
public type Count int;

public type TypeJson json;

public type Name string;

public type FirstName Name;

public type FullName FirstName;

public type UnionType decimal|string|boolean;

public type Student record {|
    string name;
    int age;
|};

public type StudentArray Student[];

public type StudentMap map<Student>;

public type StudentRest record {|
    string name;
    int age;
    json...;
|};

service /queryparamservice on QueryBindingEP {

    resource function get .(string foo, http:Caller caller, int bar, http:Request req) returns error? {
        json responseJson = {value1: foo, value2: bar};
        check caller->respond(responseJson);
    }

    resource function get q1(int id, string PersoN, http:Caller caller, float val, boolean isPresent, decimal dc)
            returns error? {
        json responseJson = {iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc};
        check caller->respond(responseJson);
    }

    resource function get q2(int[] id, string[] PersoN, float[] val, boolean[] isPresent,
            http:Caller caller, decimal[] dc) returns error? {
        json responseJson = {iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc};
        check caller->respond(responseJson);
    }

    resource function get q3(http:Caller caller, int? id, string? PersoN, float? val,
            boolean? isPresent, decimal? dc) returns error? {
        json responseJson = {iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc};
        check caller->respond(responseJson);
    }

    resource function get q4(int[]? id, string[]? PersoN, float[]? val, boolean[]? isPresent,
            http:Caller caller, decimal[]? dc) returns error? {
        json responseJson = {iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc};
        check caller->respond(responseJson);
    }

    resource function get q5(map<json> obj) returns json {
        return obj;
    }

    resource function get q6(map<json>? obj) returns json {
        if obj is () {
            return {name: "empty", value: "empty"};
        }
        return obj;
    }

    resource function get q7(map<json>[] objs) returns json {
        json responseJson = {objects: objs};
        return responseJson;
    }

    resource function get q8(map<json>[]? objs) returns json {
        if objs is () {
            return {name: "empty", value: "empty"};
        }
        json responseJson = {objects: objs};
        return responseJson;
    }

    resource function get q9(string x\-Type) returns string {
        return x\-Type;
    }

    resource function get q10(string? x\-Type) returns string {
        return x\-Type ?: "default";
    }

    resource function get q11(map<int> obj) returns json {
        return obj;
    }

    resource function get q12(map<string|int>? obj) returns json {
        return obj;
    }

    resource function get q13(map<UnionType> obj) returns json {
        return obj;
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

    resource function get encodedValuePath/[string valuePath](string? valueQuery) returns string {
        return valuePath;
    }

    resource function get student(Student? student) returns Student {
        return student ?: {name: "John", age: 25};
    }

    resource function get studentArray(StudentArray? studentArray) returns StudentArray {
        return studentArray ?: [];
    }

    resource function get studentMap(StudentMap studentMap) returns StudentMap {
        return studentMap;
    }

    resource function get studentRest(StudentRest studentRest) returns StudentRest {
        return studentRest;
    }

    resource function get queryAnnotation(@http:Query {name: "first"} string firstName, @http:Query {name: "last-name"} string lastName) returns string {
        return string `Hello, ${firstName} ${lastName}`;
    }

    resource function get queryAnnotation/negative/q1(@http:Query {name: ""} string firstName) returns string {
        return string `Hello, ${firstName}`;
    }

    resource function get queryAnnotation/negative/q2(@http:Query {name: ()} string lastName) returns string {
        return string `Hello, ${lastName}`;
    }

    resource function get queryAnnotation/mapQueries(@http:Query {name: "rMq"} Mq mq) returns string {
        return string `Hello, ${mq.name} ${mq.age}`;
    }
}

public type Mq record {
    string name;
    int age;
};

service /default on QueryBindingEP {
    resource function get checkstring(string foo = "hello") returns json {
        json responseJson = {value1: foo};
        return responseJson;
    }

    resource function get checkstringNilable(string? foo = "hello") returns json {
        json responseJson = {value1: foo};
        return responseJson;
    }

    resource function get checkInt(int foo = 10) returns json {
        json responseJson = {value1: foo};
        return responseJson;
    }

    resource function get checkIntNilable(int? foo = 15) returns json {
        json responseJson = {value1: foo};
        return responseJson;
    }

    resource function get q1(float val = 1.11, boolean isPresent = true, decimal dc = 5.67d) returns json {
        json responseJson = {fValue: val, bValue: isPresent, dValue: dc};
        return responseJson;
    }

    resource function get q2(int[] id = [324441, 5652], string[] PersoN = ["hello", "gool"],
            float[] val = [1.11, 53.9], boolean[] isPresent = [true, false], decimal[] dc = [4.78, 5.67]) returns json {
        json responseJson = {iValue: id, sValue: PersoN, fValue: val, bValue: isPresent, dValue: dc};
        return responseJson;
    }

    resource function get q3(map<json> obj = {name: "test", value: "json"}) returns json {
        return obj;
    }

    resource function get q4(map<json>[] objs = [
                {name: "test1", value: "json1"},
                {name: "test2", value: "json2"}
            ]) returns json {
        json responseJson = {objects: objs};
        return responseJson;
    }

    resource function get q5(map<int>[] objs = [{value: 1}, {value: 2}]) returns json {
        json responseJson = {objects: objs};
        return responseJson;
    }

    resource function get student(Student student = {name: "John", age: 25}) returns Student {
        return student;
    }

    resource function get studentArray(StudentArray studentArray = [{name: "John", age: 25}]) returns StudentArray {
        return studentArray;
    }
}

@test:Config {}
function testStringDefaultableQueryBinding() returns error? {
    json response = check queryBindingClient->get("/default/checkstring?foo=WSO2&bar=56");
    test:assertEquals(response, {value1: "WSO2"});

    response = check queryBindingClient->get("/default/checkstring?foo=BALLERINA,WSO2&bar=56");
    test:assertEquals(response, {value1: "BALLERINA"});

    response = check queryBindingClient->get("/default/checkstring?bar=12");
    test:assertEquals(response, {value1: "hello"});

    response = check queryBindingClient->get("/default/checkstring?foo");
    test:assertEquals(response, {value1: "hello"});

    response = check queryBindingClient->get("/default/checkstring?foo=");
    test:assertEquals(response, {value1: ""});
}

@test:Config {}
function testStringDefaultableNilableQueryBinding() returns error? {
    json response = check queryBindingClient->get("/default/checkstringNilable?foo=WSO2&bar=56");
    test:assertEquals(response, {value1: "WSO2"});

    response = check queryBindingClient->get("/default/checkstringNilable?foo=BALLERINA,WSO2&bar=56");
    test:assertEquals(response, {value1: "BALLERINA"});

    response = check queryBindingClient->get("/default/checkstringNilable?bar=12");
    test:assertEquals(response, {value1: "hello"});

    response = check queryBindingClient->get("/default/checkstringNilable?foo");
    test:assertEquals(response, {value1: "hello"});

    response = check queryBindingClient->get("/default/checkstringNilable?foo=");
    test:assertEquals(response, {value1: ""});
}

@test:Config {}
function testIntDefaultableQueryBinding() returns error? {
    json response = check queryBindingClient->get("/default/checkInt?foo=23&bar=56");
    test:assertEquals(response, {value1: 23});

    response = check queryBindingClient->get("/default/checkInt?foo=20,30&bar=56");
    test:assertEquals(response, {value1: 20});

    response = check queryBindingClient->get("/default/checkInt?bar=12");
    test:assertEquals(response, {value1: 10});

    response = check queryBindingClient->get("/default/checkInt?foo");
    test:assertEquals(response, {value1: 10});
}

@test:Config {}
function testIntDefaultableNilableQueryBinding() returns error? {
    json response = check queryBindingClient->get("/default/checkIntNilable?foo=23&bar=56");
    test:assertEquals(response, {value1: 23});

    response = check queryBindingClient->get("/default/checkIntNilable?foo=20,30&bar=56");
    test:assertEquals(response, {value1: 20});

    response = check queryBindingClient->get("/default/checkIntNilable?bar=12");
    test:assertEquals(response, {value1: 15});

    response = check queryBindingClient->get("/default/checkIntNilable?foo");
    test:assertEquals(response, {value1: 15});
}

@test:Config {}
function testRestOfDefaultableQueryBinding() returns error? {
    json response = check queryBindingClient->get("/default/q1");
    common:assertJsonPayloadtoJsonString(response, {fValue: 1.11, bValue: true, dValue: 5.67});
}

@test:Config {}
function testArrayRestOfDefaultableQueryBinding() returns error? {
    json response = check queryBindingClient->get("/default/q2");
    json expected = {
        iValue: [324441, 5652],
        sValue: ["hello", "gool"],
        fValue: [1.11, 53.9],
        bValue: [true, false],
        dValue: [4.78, 5.67]
    };
    common:assertJsonPayloadtoJsonString(response, expected);
}

@test:Config {}
function testMapJsonOfDefaultableQueryBinding() returns error? {
    json response = check queryBindingClient->get("/default/q3");
    common:assertJsonPayloadtoJsonString(response, {name: "test", value: "json"});
}

@test:Config {}
function testMapJsonArrOfDefaultableQueryBinding() returns error? {
    json response = check queryBindingClient->get("/default/q4");
    common:assertJsonPayloadtoJsonString(response, {
        objects: [
            {name: "test1", value: "json1"},
            {name: "test2", value: "json2"}
        ]
    });
}

@test:Config {}
function testStringQueryBinding() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/?foo=WSO2&bar=56");
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {value1: "WSO2", value2: 56});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get("/queryparamservice?foo=bal&bar=12");
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {value1: "bal", value2: 12});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Query params are case sensitive, https://tools.ietf.org/html/rfc7230#page-19
@test:Config {}
function testNegativeStringQueryBindingCaseSensitivity() returns error? {
    http:Response|error response = queryBindingClient->get("/queryparamservice/?FOO=WSO2&bar=go");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "no query param value found for 'foo'",
                "Bad Request", 400, "/queryparamservice/?FOO=WSO2&bar=go", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNegativeIntQueryBindingCastingError() returns error? {
    http:Response|error response = queryBindingClient->get("/queryparamservice/?foo=WSO2&bar=go");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "error in casting query param : 'bar'",
                "Bad Request", 400, "/queryparamservice/?foo=WSO2&bar=go", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get("/queryparamservice/?foo=WSO2&bar=");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "error in casting query param : 'bar'",
                "Bad Request", 400, "/queryparamservice/?foo=WSO2&bar=", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAllTypeQueryBinding() {
    http:Response|error response = queryBindingClient->get(
        "/queryparamservice/q1?id=324441&isPresent=true&dc=5.67&PersoN=hello&val=1.11");
    json expected = {iValue: 324441, sValue: "hello", fValue: 1.11, bValue: true, dValue: 5.67};
    if response is http:Response {
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get(
        "/queryparamservice/q1?id=5652,324441,652&isPresent=false,true,false&dc=4.78,5.67,2.34" +
        "&PersoN=no,hello,gool&val=53.9,1.11,43.9");
    expected = {iValue: 5652, sValue: "no", fValue: 53.9, bValue: false, dValue: 4.78};
    if response is http:Response {
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testAllTypeArrQueryBinding() {
    http:Response|error response = queryBindingClient->get(
        "/queryparamservice/q2?id=324441,5652&isPresent=true,false&PersoN=hello,gool&val=1.11,53.9&dc=4.78,5.67");
    json expected = {
        iValue: [324441, 5652],
        sValue: ["hello", "gool"],
        fValue: [1.11, 53.9],
        bValue: [true, false],
        dValue: [4.78, 5.67]
    };
    if response is http:Response {
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilableAllTypeQueryBinding() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/q3");
    json expected = {iValue: null, sValue: null, fValue: null, bValue: null, dValue: null};
    if response is http:Response {
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get(
        "/queryparamservice/q3?id=5652,324441,652&isPresent=false,true,false&dc=4.78,5.67" +
        "&PersoN=no,hello,gool&val=53.9,1.11,43.9");
    expected = {iValue: 5652, sValue: "no", fValue: 53.9, bValue: false, dValue: 4.78};
    if response is http:Response {
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilableAllTypeQueryArrBinding() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/q4?ID=8?lang=bal");
    json expected = {iValue: null, sValue: null, fValue: null, bValue: null, dValue: null};
    if response is http:Response {
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get(
        "/queryparamservice/q4?id=324441,5652&isPresent=true,false&PersoN=hello,gool&val=1.11,53.9&dc=4.78,5.67");
    expected = {
        iValue: [324441, 5652],
        sValue: ["hello", "gool"],
        fValue: [1.11, 53.9],
        bValue: [true, false],
        dValue: [4.78, 5.67]
    };
    if response is http:Response {
        common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMapJsonQueryBinding() returns error? {
    map<json> jsonObj = {name: "test", value: "json"};
    string jsonEncoded = check url:encode(jsonObj.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/q5?obj=" + jsonEncoded);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), jsonObj);
    return;
}

@test:Config {}
function testMapJsonArrayQueryBinding() returns error? {
    map<json> jsonObj1 = {name: "test1", value: "json1"};
    map<json> jsonObj2 = {name: "test2", value: "json2"};
    json expected = {objects: [jsonObj1, jsonObj2]};
    string jsonEncoded1 = check url:encode(jsonObj1.toJsonString(), "UTF-8");
    string jsonEncoded2 = check url:encode(jsonObj2.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/q7?objs=" + jsonEncoded1 + "," +
                                jsonEncoded2);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);
    return;
}

@test:Config {}
function testNillableMapJsonQueryBinding() returns error? {
    json emptyObj = {name: "empty", value: "empty"};
    map<json> jsonObj = {name: "test", value: "json"};
    string jsonEncoded = check url:encode(jsonObj.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/q6?obj=" + jsonEncoded);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), jsonObj);

    response = check queryBindingClient->get("/queryparamservice/q6");
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), emptyObj);
    return;
}

@test:Config {}
function testNillableMapJsonArrayQueryBinding() returns error? {
    json emptyObj = {name: "empty", value: "empty"};
    map<json> jsonObj1 = {name: "test1", value: "json1"};
    map<json> jsonObj2 = {name: "test2", value: "json2"};
    json expected = {objects: [jsonObj1, jsonObj2]};
    string jsonEncoded1 = check url:encode(jsonObj1.toJsonString(), "UTF-8");
    string jsonEncoded2 = check url:encode(jsonObj2.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/q8?objs=" + jsonEncoded1 + "," +
                                jsonEncoded2);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), expected);

    response = check queryBindingClient->get("/queryparamservice/q8");
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), emptyObj);
    return;
}

@test:Config {}
function testQueryParamTokenWithEscapeChar() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/q9?x-Type=test");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "test");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get("/queryparamservice/q10");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "default");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = queryBindingClient->get("/queryparamservice/q10?x-Type=test");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "test");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testEmptyQueryParamBinding() returns error? {
    http:Response|error response = queryBindingClient->get("/queryparamservice/q9?x-Type");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "no query param value found for 'x-Type'",
                "Bad Request", 400, "/queryparamservice/q9?x-Type", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testEmptyOptionalQueryParamBinding() {
    http:Response|error response = queryBindingClient->get("/queryparamservice/q10?x-Type");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "default");
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
    common:assertTextPayload(response.getTextPayload(), "10");

    response = check queryBindingClient->get("/queryparamservice/petsUnion?");
    common:assertTextPayload(response.getTextPayload(), "nil");

    response = check queryBindingClient->get("/queryparamservice/petsArr?count=30,20,10");
    common:assertTextPayload(response.getTextPayload(), "30");

    response = check queryBindingClient->get("/queryparamservice/nestedTypeRef?name=wso2");
    common:assertTextPayload(response.getTextPayload(), "wso2");
}

@test:Config {}
function testTypeReferenceConstrainedMapQueryParamBinding() returns error? {
    map<json> jsonObj = {name: "test", value: "json"};
    string jsonEncoded = check url:encode(jsonObj.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/petsMap?count=" + jsonEncoded);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), jsonObj);
}

@test:Config {}
function testEncodedValuePath() returns error? {
    http:Response response = check queryBindingClient->get("/queryparamservice/encodedValuePath/CSM-459%2B862?valueQuery=CSM-459%2B862");

    test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
    common:assertTextPayload(response.getTextPayload(), "CSM-459+862");

    response = check queryBindingClient->get("/queryparamservice/encodedValuePath/IPX20%25?valueQuery=IPX20%25");

    test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
    common:assertTextPayload(response.getTextPayload(), "IPX20%");
}

@test:Config {}
function testRecordQueryParamBinding() returns error? {
    http:Response response = check queryBindingClient->get("/queryparamservice/student");
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), {name: "John", age: 25});

    Student student = {name: "John Doe", age: 25};
    string studentEncoded = check url:encode(student.toJsonString(), "UTF-8");
    response = check queryBindingClient->get("/queryparamservice/student?student=" + studentEncoded);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), student);
}

@test:Config {}
function testRecordQueryParamBindingNegative() returns error? {
    map<json> student = {name: "John Doe", address: "Colombo 03"};
    string studentEncoded = check url:encode(student.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/student?student=" + studentEncoded);
    test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
}

@test:Config {}
function testDefaultRecordQueryParamBinding() returns error? {
    http:Response response = check queryBindingClient->get("/default/student");
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), {name: "John", age: 25});

    Student student = {name: "John Doe", age: 25};
    string studentEncoded = check url:encode(student.toJsonString(), "UTF-8");
    response = check queryBindingClient->get("/default/student?student=" + studentEncoded);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), student);
}

@test:Config {}
function testRecordArrayQueryParamBinding() returns error? {
    http:Response response = check queryBindingClient->get("/queryparamservice/studentArray");
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), []);

    Student student1 = {name: "John Doe", age: 25};
    Student student2 = {name: "Jane Doe", age: 30};
    Student[] students = [student1, student2];
    string studentEncoded1 = check url:encode(student1.toJsonString(), "UTF-8");
    string studentEncoded2 = check url:encode(student2.toJsonString(), "UTF-8");
    response = check queryBindingClient->get("/queryparamservice/studentArray?studentArray=" + studentEncoded1 +
                                "," + studentEncoded2);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), students);
}

@test:Config {}
function testDefaultRecordArrayQueryParamBinding() returns error? {
    http:Response response = check queryBindingClient->get("/default/studentArray");
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), [{name: "John", age: 25}]);

    Student student1 = {name: "John Doe", age: 25};
    Student student2 = {name: "Jane Doe", age: 30};
    Student[] students = [student1, student2];
    string studentEncoded1 = check url:encode(student1.toJsonString(), "UTF-8");
    string studentEncoded2 = check url:encode(student2.toJsonString(), "UTF-8");
    response = check queryBindingClient->get("/default/studentArray?studentArray=" + studentEncoded1 +
                                "," + studentEncoded2);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), students);
}

@test:Config {}
function testRecordMapQueryParamBinding() returns error? {
    Student student1 = {name: "John Doe", age: 25};
    Student student2 = {name: "Jane Doe", age: 30};
    map<Student> students = {"student1": student1, "student2": student2};
    string studentsEncoded = check url:encode(students.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/studentMap?studentMap=" + studentsEncoded);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), students);
}

@test:Config {}
function testRecordRestQueryParamBinding() returns error? {
    StudentRest student = {name: "John Doe", age: 25, "address": "Colombo", "phone": 1234567890};
    string studentEncoded = check url:encode(student.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/studentRest?studentRest=" + studentEncoded);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), student);
}

@test:Config {}
function testMapOfJsonTypedQueryParamBinding1() returns error? {
    map<int> mapOfInts = {a: 1, b: 2, c: 3};
    string mapOfIntsEncoded = check url:encode(mapOfInts.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/q11?obj=" + mapOfIntsEncoded);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), mapOfInts);

    map<string> mapOfStrings = {a: "a", b: "b", c: "c"};
    string mapOfStringsEncoded = check url:encode(mapOfStrings.toJsonString(), "UTF-8");
    response = check queryBindingClient->get("/queryparamservice/q11?obj=" + mapOfStringsEncoded);
    test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
}

@test:Config {}
function testMapOfJsonTypedQueryParamBinding2() returns error? {
    map<string|int> mapOfStringsAndInts = {a: "a", b: 2, c: "c"};
    string mapOfStringsAndIntsEncoded = check url:encode(mapOfStringsAndInts.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/q12?obj=" + mapOfStringsAndIntsEncoded);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), mapOfStringsAndInts);

    map<string|boolean> mapOfStringsAndFloats = {a: "a", b: true, c: "c"};
    string mapOfStringsAndFloatsEncoded = check url:encode(mapOfStringsAndFloats.toJsonString(), "UTF-8");
    response = check queryBindingClient->get("/queryparamservice/q12?obj=" + mapOfStringsAndFloatsEncoded);
    test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
}

@test:Config {}
function testMapOfJsonTypedQueryParamBinding3() returns error? {
    map<UnionType> mapOfUnionTypes = {a: "a", b: 2, c: true};
    string mapOfUnionTypesEncoded = check url:encode(mapOfUnionTypes.toJsonString(), "UTF-8");
    http:Response response = check queryBindingClient->get("/queryparamservice/q13?obj=" + mapOfUnionTypesEncoded);
    common:assertJsonPayloadtoJsonString(response.getJsonPayload(), {a: "a", b: 2.0, c: true});

    map<json> mapOfJsons = {a: "a", b: {name: "John", age: 35}, c: 4.56};
    string mapOfJsonsEncoded = check url:encode(mapOfJsons.toJsonString(), "UTF-8");
    response = check queryBindingClient->get("/queryparamservice/q13?obj=" + mapOfJsonsEncoded);
    test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
}

@test:Config {}
function testforQueryParamterNameOverwrite() returns error? {
    string result = check queryBindingClient->get("/queryparamservice/queryAnnotation?first=Harry&last-name=Potter");
    test:assertEquals(result, "Hello, Harry Potter", msg = string `Found ${result}, expected Harry`);

    map<json> mapOfJsons = {
        name: "Ron",
        age: 10
    };
    string mapOfQueries = check url:encode(mapOfJsons.toJsonString(), "UTF-8");

    result = check queryBindingClient->get("/queryparamservice/queryAnnotation/mapQueries?rMq=" + mapOfQueries);
    test:assertEquals(result, "Hello, Ron 10", msg = string `Found ${result}, expected Harry`);
}

@test:Config {}
function testforNegativeQueryParamterNameOverwrite() returns error? {
    string result = check queryBindingClient->get("/queryparamservice/queryAnnotation/negative/q1?firstName=Harry");
    test:assertEquals(result, "Hello, Harry");

    result = check queryBindingClient->get("/queryparamservice/queryAnnotation/negative/q2?lastName=Anne");
    test:assertEquals(result, "Hello, Anne");
}
