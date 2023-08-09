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

import ballerina/test;
import ballerina/url;
import ballerina/http;

final http:Client resourceQueryParamBindingClient = check new("http://localhost:" + resourceParamBindingTestPort.toString());

@test:Config {}
function testQueryParamBindingCase1() returns error? {
    "value1"|"value2" value = "value1";
    string resPayload = check resourceQueryParamBindingClient->/query/case1(query = value);
    test:assertEquals(resPayload, value);

    resPayload = check resourceQueryParamBindingClient->/query/case1(query = "value2");
    test:assertEquals(resPayload, "value2");

    http:Response res = check resourceQueryParamBindingClient->/query/case1(query = "value3");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase2() returns error? {
    1.2|2.4 value = 1.2;
    float resPayload = check resourceQueryParamBindingClient->/query/case2(query = value);
    test:assertEquals(resPayload, value);

    resPayload = check resourceQueryParamBindingClient->/query/case2;
    test:assertEquals(resPayload, 0.0);

    resPayload = check resourceQueryParamBindingClient->/query/case2(query = 3.6);
    test:assertEquals(resPayload, 3.6);

    http:Response res = check resourceQueryParamBindingClient->/query/case2(query = "value3");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase3() returns error? {
    string resPayload = check resourceQueryParamBindingClient->/query/case3;
    test:assertEquals(resPayload, "value2");

    resPayload = check resourceQueryParamBindingClient->/query/case3(query = "value1");
    test:assertEquals(resPayload, "value1");

    http:Response res = check resourceQueryParamBindingClient->/query/case3(query = "value");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase4() returns error? {
    string resPayload = check resourceQueryParamBindingClient->/query/case4(query = "VALUE1");
    test:assertEquals(resPayload, "VALUE1");

    EnumValue value = "VALUE3";
    resPayload = check resourceQueryParamBindingClient->/query/case4(query = value);
    test:assertEquals(resPayload, value);

    http:Response res = check resourceQueryParamBindingClient->/query/case4(query = "value");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase5() returns error? {
    string resPayload = check resourceQueryParamBindingClient->/query/case5(query = "VALUE2");
    test:assertEquals(resPayload, "EnumValue: VALUE2");

    resPayload = check resourceQueryParamBindingClient->/query/case5(query = "VALUE4");
    test:assertEquals(resPayload, "VALUE4");

    http:Response res = check resourceQueryParamBindingClient->/query/case5(query = "VALUE6");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase6() returns error? {
    string[] resPayload = check resourceQueryParamBindingClient->/query/case6;
    test:assertEquals(resPayload, ["default"]);

    Value[] values = ["value2", "value1"];
    resPayload = check resourceQueryParamBindingClient->/query/case6(query = values);
    test:assertEquals(resPayload, values);

    http:Response res = check resourceQueryParamBindingClient->/query/case6(query = ["value1", "value2", "value3"]);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase7() returns error? {
    EnumValue[] values = ["VALUE2", "VALUE1"];
    string[] resPayload = check resourceQueryParamBindingClient->/query/case7(query = values);
    test:assertEquals(resPayload, values);

    http:Response res = check resourceQueryParamBindingClient->/query/case7(query = ["value1", "value2"]);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase8() returns error? {
    UnionFiniteType[] values = ["VALUE2", "value1", "VALUE1", "value2"];
    string[] resPayload = check resourceQueryParamBindingClient->/query/case8(query = values);
    test:assertEquals(resPayload, ["EnumValue: VALUE2","Value: value1","EnumValue: VALUE1","Value: value2"]);

    http:Response res = check resourceQueryParamBindingClient->/query/case8(query = ["value1", "value3", "VALUE3"]);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase9() returns error? {
    QueryRecord value1 = {enumValue: "VALUE3", value: "value1"};
    string encodedValue = check url:encode(value1.toJsonString(), "UTF-8");
    map<json> resPayload = check resourceQueryParamBindingClient->/query/case9(query = encodedValue);
    test:assertEquals(resPayload, {...value1, 'type: "QueryRecord"});

    record{|never 'type?; json...;|} value2 = {"enumValue": "VALUE6", "value": "value1"};
    encodedValue = check url:encode(value2.toJsonString(), "UTF-8");
    resPayload = check resourceQueryParamBindingClient->/query/case9(query = encodedValue);
    test:assertEquals(resPayload, {...value2, 'type: "map<json>"});

    resPayload = check resourceQueryParamBindingClient->/query/case9();
    test:assertEquals(resPayload, {'type: "default"});

    http:Response res = check resourceQueryParamBindingClient->/query/case9(query = "value");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase10() returns error? {
    QueryRecord value1 = {enumValue: "VALUE3", value: "value1"};
    record{|never 'type?; json...;|} value2 = {"enumValue": "VALUE6", "value": "value1"};
    string encodedValue1 = check url:encode(value1.toJsonString(), "UTF-8");
    string encodedValue2 = check url:encode(value2.toJsonString(), "UTF-8");
    string[] encodedValues = [encodedValue2, encodedValue1];
    map<json>[] resPayload = check resourceQueryParamBindingClient->/query/case10(query = encodedValues);
    test:assertEquals(resPayload, [{...value2, 'type: "map<json>"}, {...value1, 'type: "QueryRecord"}]);

    http:Response res = check resourceQueryParamBindingClient->/query/case10(query = "value");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase11() returns error? {
    int:Signed32 resPayload = check resourceQueryParamBindingClient->/query/case11(query = 32);
    test:assertEquals(resPayload, 32, "Payload mismatched");

    resPayload = check resourceQueryParamBindingClient->/query/case11(query = -32);
    test:assertEquals(resPayload, -32, "Payload mismatched");

    http:Response res = check resourceQueryParamBindingClient->/query/case11(query = 5000000000);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase12() returns error? {
    int:Unsigned32 resPayload = check resourceQueryParamBindingClient->/query/case12(query = 32);
    test:assertEquals(resPayload, 32, "Payload mismatched");

    http:Response res = check resourceQueryParamBindingClient->/query/case12(query = -32);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");

    res = check resourceQueryParamBindingClient->/query/case12(query = 5000000000);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase13() returns error? {
    int:Signed8[] resPayload = check resourceQueryParamBindingClient->/query/case13(query = [32, -38, 1, -43]);
    test:assertEquals(resPayload, [32, -38, 1, -43], "Payload mismatched");

    http:Response res = check resourceQueryParamBindingClient->/query/case13(query = [32, -38, 1, -43, 50000000]);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase14() returns error? {
    string:Char resPayload = check resourceQueryParamBindingClient->/query/case14(query = "a");
    test:assertEquals(resPayload, "a", "Payload mismatched");

    resPayload = check resourceQueryParamBindingClient->/query/case14(query = "*");
    test:assertEquals(resPayload, "*", "Payload mismatched");

    resPayload = check resourceQueryParamBindingClient->/query/case14(query = ".");
    test:assertEquals(resPayload, ".", "Payload mismatched");

    http:Response res = check resourceQueryParamBindingClient->/query/case14(query = "ab");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase15() returns error? {
    [StringCharacter, SmallInt] resPayload = check resourceQueryParamBindingClient->/query/case15(query1 = "*", query2 = 34);
    test:assertEquals(resPayload, ["*", 34], "Payload mismatched");

    resPayload = check resourceQueryParamBindingClient->/query/case15(query1 = " ", query2 = -34);
    test:assertEquals(resPayload, [" ", -34], "Payload mismatched");

    http:Response res = check resourceQueryParamBindingClient->/query/case15(query1 = "ab", query2 = 34);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");

    res = check resourceQueryParamBindingClient->/query/case15(query1 = "*", query2 = 500000);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");

    res = check resourceQueryParamBindingClient->/query/case15(query1 = "abc", query2 = 500000);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
}

@test:Config {}
function testQueryParamBindingCase9WithCurlyBracesUnencoded() returns error? {
    map<json> resPayload = check resourceQueryParamBindingClient->/query/case9(query = string`{"name":"John"%2C "age":37}`);
    test:assertEquals(resPayload, {"name": "John", "age": 37, "type": "map<json>"});
}

@test:Config {}
function testQueryParamBindingCase16() returns error? {
    string[] strVals = ["Hi", "Hello", "Bye"];
    [map<json>, string[]] resPayload = check resourceQueryParamBindingClient->/query/case16(query1 = string`{"name":"John"%2C "age":37}`, query2 = strVals);
    test:assertEquals(resPayload, [{"name":"John", "age":37}, strVals]);
}

@test:Config {}
function testQueryParamBindingCase17() returns error? {
    map<anydata> resPayload = check resourceQueryParamBindingClient->/query/case17;
    test:assertEquals(resPayload, {"type": "default"});

    QueryRecord query = {enumValue: "VALUE3", value: "value1"};
    string encodedQuery = check url:encode(query.toJsonString(), "UTF-8");
    resPayload = check resourceQueryParamBindingClient->/query/case17(query = encodedQuery);
    test:assertEquals(resPayload, {'type: "QueryRecord", ...query});

    QueryRecordOpen queryOpen = {enumValue: "VALUE3", value: "value1", "extra": "extra"};
    string encodedQueryOpen = check url:encode(queryOpen.toJsonString(), "UTF-8");
    resPayload = check resourceQueryParamBindingClient->/query/case17(query = encodedQueryOpen);
    test:assertEquals(resPayload, {'type: "QueryRecordOpen", ...queryOpen});

    queryOpen = {enumValue: "VALUE3", value: "value1", "xml": xml `<book><name>Harry Potter</name></book>`};
    encodedQueryOpen = check url:encode(queryOpen.toJsonString(), "UTF-8");
    resPayload = check resourceQueryParamBindingClient->/query/case17(query = encodedQueryOpen);
    test:assertEquals(resPayload["type"], "QueryRecordOpenWithXML");
    test:assertEquals(resPayload["xml"], "<book><name>Harry Potter</name></book>");
}

@test:Config {}
function testQueryParamBindingCase18() returns error? {
    QueryRecord query1 = {enumValue: "VALUE3", value: "value1"};
    string encodedQuery1 = check url:encode(query1.toJsonString(), "UTF-8");
    QueryRecordOpen query2 = {enumValue: "VALUE2", value: "value2", "extra": "extra"};
    string encodedQuery2 = check url:encode(query2.toJsonString(), "UTF-8");
    record{never 'type?;} query3 = {"name": "John", "age": 37};
    string encodedQuery3 = check url:encode(query3.toJsonString(), "UTF-8");
    string[] queries = [encodedQuery1, encodedQuery2, encodedQuery3];
    map<anydata>[] resPayload = check resourceQueryParamBindingClient->/query/case18(query = queries);
    test:assertEquals(resPayload, [{'type: "QueryRecord", ...query1},
        {'type: "QueryRecordOpen", ...query2}, {'type: "map<anydata>", ...query3}]);

    query2["xml"] = xml `<book><name>Harry Potter</name></book>`;
    encodedQuery2 = check url:encode(query2.toJsonString(), "UTF-8");
    query3["xml"] = xml `<song><name>Shape of You</name></song>`;
    encodedQuery3 = check url:encode(query3.toJsonString(), "UTF-8");
    queries = [encodedQuery1, encodedQuery2, encodedQuery3];
    resPayload = check resourceQueryParamBindingClient->/query/case18(query = queries);
    test:assertEquals(resPayload[0], {'type: "QueryRecord", ...query1});
    test:assertEquals(resPayload[1]["type"], "QueryRecordOpenWithXML");
    test:assertEquals(resPayload[1]["extra"], "extra");
    test:assertEquals(resPayload[1]["xml"], "<book><name>Harry Potter</name></book>");
    test:assertEquals(resPayload[2]["type"], "map<anydata>");
    test:assertEquals(resPayload[2]["xml"], "<song><name>Shape of You</name></song>");
}

@test:Config {}
function testNoQueryParamBindingCase19() returns error? {
    map<string[]> resPayload = check resourceQueryParamBindingClient->/query/case19;
    test:assertEquals(resPayload, {});
}
