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
import ballerina/http;
import ballerina/http_test_common as common;

final http:Client resourcePathParamBindingClient = check new("http://localhost:" + resourceParamBindingTestPort.toString());

@test:Config {}
function testPathParamBindingCase1() returns error? {
    string resPayload = check resourcePathParamBindingClient->/path/case1/value1;
    test:assertEquals(resPayload, "value1", "Payload mismatched");

    "value1"|"value2" value = "value2";
    resPayload = check resourcePathParamBindingClient->/path/case1/[value];
    test:assertEquals(resPayload, value, "Payload mismatched");

    http:Response res = check resourcePathParamBindingClient->/path/case1/value3;
    test:assertEquals(res.statusCode, 404, "Status code mismatched");
}

@test:Config {}
function testPathParamBindingCase2() returns error? {
    string resPayload = check resourcePathParamBindingClient->/path/case2/value1;
    test:assertEquals(resPayload, "value1", "Payload mismatched");

    Value value = "value2";
    resPayload = check resourcePathParamBindingClient->/path/case2/[value];
    test:assertEquals(resPayload, value, "Payload mismatched");

    http:Response res = check resourcePathParamBindingClient->/path/case2/value3;
    test:assertEquals(res.statusCode, 404, "Status code mismatched");
}

@test:Config {}
function testPathParamBindingCase3() returns error? {
    string resPayload = check resourcePathParamBindingClient->/path/case3/VALUE1;
    test:assertEquals(resPayload, "VALUE1", "Payload mismatched");

    EnumValue value = "VALUE2";
    resPayload = check resourcePathParamBindingClient->/path/case3/[value];
    test:assertEquals(resPayload, value, "Payload mismatched");

    http:Response res = check resourcePathParamBindingClient->/path/case3/value;
    test:assertEquals(res.statusCode, 404, "Status code mismatched");
}

@test:Config {}
function testPathParamBindingCase4() returns error? {
    http:Response res = check resourcePathParamBindingClient->/path/case4/'1/'2/'1;
    test:assertEquals(res.statusCode, 200, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "[1,2,1]");

    (1|2)[] values = [2, 1, 1, 1, 2, 1];
    res = check resourcePathParamBindingClient->/path/case4/[...values];
    test:assertEquals(res.statusCode, 200, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), values.toString());

    res = check resourcePathParamBindingClient->/path/case4/'1/'34;
    test:assertEquals(res.statusCode, 404, "Status code mismatched");
}

@test:Config {}
function testPathParamBindingCase5() returns error? {
    Value[] resPayload = check resourcePathParamBindingClient->/path/case5/value1/value2;
    test:assertEquals(resPayload, ["value1", "value2"], "Payload mismatched");

    Value[] values = ["value2", "value1", "value1", "value1", "value2", "value1"];
    resPayload = check resourcePathParamBindingClient->/path/case5/[...values];
    test:assertEquals(resPayload, values, "Payload mismatched");

    http:Response res = check resourcePathParamBindingClient->/path/case5/value6;
    test:assertEquals(res.statusCode, 404, "Status code mismatched");
}

@test:Config {}
function testPathParamBindingCase6() returns error? {
    EnumValue[] resPayload = check resourcePathParamBindingClient->/path/case6/VALUE1/VALUE2;
    test:assertEquals(resPayload, ["VALUE1", "VALUE2"], "Payload mismatched");

    EnumValue[] values = ["VALUE2", "VALUE1", "VALUE3", "VALUE1", "VALUE2", "VALUE1"];
    resPayload = check resourcePathParamBindingClient->/path/case6/[...values];
    test:assertEquals(resPayload, values, "Payload mismatched");

    http:Response res = check resourcePathParamBindingClient->/path/case6/VALUE6;
    test:assertEquals(res.statusCode, 404, "Status code mismatched");
}

@test:Config {}
function testPathParamBindingCase7() returns error? {
    string resPayload = check resourcePathParamBindingClient->/path/case7/value1;
    test:assertEquals(resPayload, "value1", "Payload mismatched");

    EnumValue value = "VALUE2";
    resPayload = check resourcePathParamBindingClient->/path/case7/[value];
    test:assertEquals(resPayload, "EnumValue: " + value, "Payload mismatched");
}

@test:Config {}
function testPathParamBindingCase8() returns error? {
    string resPayload = check resourcePathParamBindingClient->/path/case8/value3;
    test:assertEquals(resPayload, "value3", "Payload mismatched");

    EnumValue value = "VALUE2";
    resPayload = check resourcePathParamBindingClient->/path/case8/[value];
    test:assertEquals(resPayload, "EnumValue: " + value, "Payload mismatched");

    http:Response res = check resourcePathParamBindingClient->/path/case8/value5;
    test:assertEquals(res.statusCode, 404, "Status code mismatched");
}

@test:Config {}
function testPathParamBindingCase9() returns error? {
    string resPayload = check resourcePathParamBindingClient->/path/case9/value1;
    test:assertEquals(resPayload, "Value: value1", "Payload mismatched");

    EnumValue value = "VALUE2";
    resPayload = check resourcePathParamBindingClient->/path/case9/[value];
    test:assertEquals(resPayload, "EnumValue: " + value, "Payload mismatched");

    http:Response res = check resourcePathParamBindingClient->/path/case9/value5;
    test:assertEquals(res.statusCode, 404, "Status code mismatched");
}


@test:Config {}
function testPathParamBindingCase10() returns error? {
    string[] resPayload = check resourcePathParamBindingClient->/path/case10/VALUE1/value2/VALUE3;
    test:assertEquals(resPayload, ["EnumValue: VALUE1", "Value: value2", "EnumValue: VALUE3"], "Payload mismatched");

    http:Response res = check resourcePathParamBindingClient->/path/case10/value1/value9/value3;
    test:assertEquals(res.statusCode, 404, "Status code mismatched");
}
