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

