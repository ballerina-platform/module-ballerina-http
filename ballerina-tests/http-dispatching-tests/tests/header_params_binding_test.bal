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

final http:Client resourceHeaderParamBindingClient = check new("http://localhost:" + resourceParamBindingTestPort.toString());

@test:Config {}
function testHeaderParamBindingCase1() returns error? {
    string resPayload = check resourceHeaderParamBindingClient->/header/case1({header: "value1"});
    test:assertEquals(resPayload, "value1");

    resPayload = check resourceHeaderParamBindingClient->/header/case1({header: "value2"});
    test:assertEquals(resPayload, "value2");

    http:Response res = check resourceHeaderParamBindingClient->/header/case1({header: "value3"});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase2() returns error? {
    decimal resPayload = check resourceHeaderParamBindingClient->/header/case2({header: "1.234"});
    test:assertEquals(resPayload, 1.234d);

    resPayload = check resourceHeaderParamBindingClient->/header/case2;
    test:assertEquals(resPayload, 0.0d);

    http:Response res = check resourceHeaderParamBindingClient->/header/case2({header: "1.11"});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase3() returns error? {
    string resPayload = check resourceHeaderParamBindingClient->/header/case3;
    test:assertEquals(resPayload, "default");

    resPayload = check resourceHeaderParamBindingClient->/header/case3({header: "value1"});
    test:assertEquals(resPayload, "value1");

    http:Response res = check resourceHeaderParamBindingClient->/header/case3({header: "value5"});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase4() returns error? {
    string resPayload = check resourceHeaderParamBindingClient->/header/case4({header: "VALUE2"});
    test:assertEquals(resPayload, "VALUE2");

    http:Response res = check resourceHeaderParamBindingClient->/header/case4({header: "VALUE9"});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase5() returns error? {
    string resPayload = check resourceHeaderParamBindingClient->/header/case5({header: "VALUE4"});
    test:assertEquals(resPayload, "VALUE4");

    resPayload = check resourceHeaderParamBindingClient->/header/case5({header: "VALUE1"});
    test:assertEquals(resPayload, "EnumValue: VALUE1");

    http:Response res = check resourceHeaderParamBindingClient->/header/case5({header: "VALUE9"});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase6() returns error? {
    http:Response res = check resourceHeaderParamBindingClient->/header/case6({header: ["1", "2", "3", "2", "1"]});
    test:assertEquals(res.statusCode, 200);
    common:assertTextPayload(res.getTextPayload(), "[1,2,3,2,1]");

    res = check resourceHeaderParamBindingClient->/header/case6({header: ["1", "2", "5"]});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase7() returns error? {
    http:Response res = check resourceHeaderParamBindingClient->/header/case7;
    test:assertEquals(res.statusCode, 200);
    common:assertTextPayload(res.getTextPayload(), "[\"default\"]");

    res = check resourceHeaderParamBindingClient->/header/case7({header: ["value1", "value2", "value1"]});
    test:assertEquals(res.statusCode, 200);
    common:assertTextPayload(res.getTextPayload(), "[\"value1\", \"value2\", \"value1\"]");

    res = check resourceHeaderParamBindingClient->/header/case7({header: ["value1", "value5", "value3"]});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase8() returns error? {
    http:Response res = check resourceHeaderParamBindingClient->/header/case8({header: ["VALUE1", "value2", "VALUE2", "value1"]});
    test:assertEquals(res.statusCode, 200);
    common:assertTextPayload(res.getTextPayload(), "[\"EnumValue: VALUE1\", \"Value: value2\", \"EnumValue: VALUE2\", \"Value: value1\"]");

    res = check resourceHeaderParamBindingClient->/header/case8({header: ["VALUE1", "value5", "VALUE2", "value1"]});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase91() returns error? {
    map<string|string[]> headers = {header1: "value1", header2: "VALUE3", header3: ["1", "2", "3"], header4: ["VALUE1", "value2"]};
    map<json> resPayload = check resourceHeaderParamBindingClient->/header/case9(headers);
    test:assertEquals(resPayload, {header1: "value1", header2: "VALUE3", header3: [1,2,3], header4: ["VALUE1", "value2"]});

    headers = {header1: "value1", header2: "VALUE3", header3: ["1", "2", "3"], header4: ["VALUE1", "value5"]};
    http:Response res = check resourceHeaderParamBindingClient->/header/case9(headers);
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase92() returns error? {
    HeaderRecord headers = {header1: "value1", header2: "VALUE3", header3: [1, 2, 3], header4: ["VALUE1", "value2"]};
    map<string|string[]> headerMap = http:getHeaderMap(headers);
    map<json> resPayload = check resourceHeaderParamBindingClient->/header/case9(headerMap);
    test:assertEquals(resPayload, {header1: "value1", header2: "VALUE3", header3: [1,2,3], header4: ["VALUE1", "value2"]});
}

@test:Config {}
function testHeaderParamBindingCase10() returns error? {
    int:Signed32 resPayload = check resourceHeaderParamBindingClient->/header/case10({header: "32"});
    test:assertEquals(resPayload, 32);

    resPayload = check resourceHeaderParamBindingClient->/header/case10({header: "-32"});
    test:assertEquals(resPayload, -32);

    http:Response res = check resourceHeaderParamBindingClient->/header/case10({header: "5000000000"});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase11() returns error? {
    int:Unsigned32 resPayload = check resourceHeaderParamBindingClient->/header/case11({header: "32"});
    test:assertEquals(resPayload, 32);

    http:Response res = check resourceHeaderParamBindingClient->/header/case11({header: "-32"});
    test:assertEquals(res.statusCode, 400);

    res = check resourceHeaderParamBindingClient->/header/case11({header: "5000000000"});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase12() returns error? {
    int:Signed8[] resPayload = check resourceHeaderParamBindingClient->/header/case12({header: ["32", "-38", "1", "-43"]});
    test:assertEquals(resPayload, [32, -38, 1, -43]);

    http:Response res = check resourceHeaderParamBindingClient->/header/case12({header: ["32", "-38", "1", "-43", "-50000000"]});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase13() returns error? {
    string:Char resPayload = check resourceHeaderParamBindingClient->/header/case13({header: "a"});
    test:assertEquals(resPayload, "a");

    resPayload = check resourceHeaderParamBindingClient->/header/case13({header: "*"});
    test:assertEquals(resPayload, "*");

    http:Response res = check resourceHeaderParamBindingClient->/header/case13({header: "ab"});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase14() returns error? {
    [StringCharacter, SmallInt] resPayload = check resourceHeaderParamBindingClient->/header/case14({header1: "a", header2: "32"});
    test:assertEquals(resPayload, ["a", 32]);

    resPayload = check resourceHeaderParamBindingClient->/header/case14({header1: "*", header2: "-32"});
    test:assertEquals(resPayload, ["*", -32]);

    http:Response res = check resourceHeaderParamBindingClient->/header/case14({header1: "ab", header2: "32"});
    test:assertEquals(res.statusCode, 400);

    res = check resourceHeaderParamBindingClient->/header/case14({header1: "a", header2: "5000000000"});
    test:assertEquals(res.statusCode, 400);

    res = check resourceHeaderParamBindingClient->/header/case14({header1: "ab", header2: "5000000000"});
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase151() returns error? {
    HeaderRecordWithName headers = {header1: "value1", header2: "VALUE3", header3: ["VALUE1", "value2"]};
    map<json> resPayload = check resourceHeaderParamBindingClient->/header/case15(headers);
    test:assertEquals(resPayload, {header1: "value1", header2: "VALUE3", header3: ["VALUE1", "value2"]});

    headers = {header1: "value1", header2: "VALUE3", header3: ["VALUE1", "value5"]};
    http:Response res = check resourceHeaderParamBindingClient->/header/case15(headers);
    test:assertEquals(res.statusCode, 400);
}

@test:Config {}
function testHeaderParamBindingCase152() returns error? {
    HeaderRecordWithType headers = {header1: "value1", header2: "VALUE3", header3: ["VALUE1", "value2"]};
    map<string|string[]> headerMap = http:getHeaderMap(headers);
    map<json> resPayload = check resourceHeaderParamBindingClient->/header/case15(headerMap);
    test:assertEquals(resPayload, {header1: "value1", header2: "VALUE3", header3: ["VALUE1", "value2"]});
}

@test:Config {}
function testHeaderParamBindingCase153() returns error? {
    map<string|string[]> headerMap = {x\-header1: "value1", x\-header2: "VALUE3", x\-header3: ["VALUE1", "value2"]};
    map<json> resPayload = check resourceHeaderParamBindingClient->/header/case15(headerMap);
    test:assertEquals(resPayload, {header1: "value1", header2: "VALUE3", header3: ["VALUE1", "value2"]});
}

@test:Config {}
function testHeaderParamBindingCase154() returns error? {
    map<string|string[]> headerMap = {header1: "value1", x\-header2: "VALUE3", x\-header3: ["VALUE1", "value2"]};
    http:Response res = check resourceHeaderParamBindingClient->/header/case15(headerMap);
    test:assertEquals(res.statusCode, 400);
}
