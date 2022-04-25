// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;

service /anydataTest on clientDBBackendListener {

    resource function get intType() returns int {
        return 56;
    }

    resource function get intTypeWithInvalidMimeType() returns @http:Payload{mediaType : "type2/subtype2"} int {
        return 65;
    }

    resource function get intArrType() returns int[] {
        return [56, 34];
    }

    resource function get intArrTypeWithInvalidMimeType() returns @http:Payload{mediaType : "type2/subtype2"} int[] {
        return [56, 34];
    }

    resource function get intMapType() returns map<int> {
        return {name:11, team:22};
    }

    resource function get intMapTypeWithInvalidMimeType() returns @http:Payload{mediaType : "type2/subtype2"} map<int> {
        return {name:11, team:22};
    }

    resource function get intTableType() returns table<map<int>> {
        return table [
           {id: 1, title: 11},
           {id: 2, title: 22},
           {id: 3, title: 33}
        ];
    }

    resource function get intTableTypeWithInvalidMimeType()
            returns @http:Payload{mediaType : "type2/subtype2"} table<map<int>> {
        return table [
           {id: 1, title: 11},
           {id: 2, title: 22},
           {id: 3, title: 33}
        ];
    }

    // string type
    resource function get stringType() returns string {
        return "hello";
    }

    resource function get stringTypeWithInvalidMimeType()
            returns @http:Payload{mediaType : "type2/subtype2"} string {
        return "hello";
    }

    resource function get stringArrType() returns string[] {
        return ["hello", "ballerina"];
    }

    resource function get stringArrTypeWithInvalidMimeType()
            returns @http:Payload{mediaType : "type2/subtype2"} string[] {
        return ["hello", "ballerina"];
    }

    resource function get stringMapType() returns map<string> {
        return {name:"hello", team:"ballerina"};
    }

    resource function get stringMapTypeWithInvalidMimeType()
            returns @http:Payload{mediaType : "type2/subtype2"} map<string> {
        return {name:"hello", team:"ballerina"};
    }

    resource function get stringTableType() returns table<map<string>> {
        return table [
           {id: "1", title: "11"},
           {id: "2", title: "22"},
           {id: "3", title: "33"}
        ];
    }

    resource function get stringTableTypeWithInvalidMimeType()
            returns @http:Payload{mediaType : "type2/subtype2"} table<map<string>> {
        return table [
           {id: "1", title: "11"},
           {id: "2", title: "22"},
           {id: "3", title: "33"}
        ];
    }
}

@test:Config {}
function testIntDatabinding() returns error? {
    int response = check clientDBBackendClient->get("/anydataTest/intType");
    test:assertEquals(response, 56, msg = "Found unexpected output");
}

@test:Config {}
function testIntDatabindingByType() returns error? {
    int response = check clientDBBackendClient->get("/anydataTest/intTypeWithInvalidMimeType");
    test:assertEquals(response, 65, msg = "Found unexpected output");
}

@test:Config {}
function testIntArrayDatabinding() returns error? {
    int[] response = check clientDBBackendClient->get("/anydataTest/intArrType");
    test:assertEquals(response, [56, 34], msg = "Found unexpected output");
}

@test:Config {}
function testIntArrayDatabindingByType() returns error? {
    int[] response = check clientDBBackendClient->get("/anydataTest/intArrTypeWithInvalidMimeType");
    test:assertEquals(response, [56, 34], msg = "Found unexpected output");
}

@test:Config {}
function testIntStringDatabindingAsJson() returns error? {
    int|string response = check clientDBBackendClient->get("/anydataTest/intType");
    test:assertEquals(response, 56, msg = "Found unexpected output");
}

@test:Config {}
function testIntStringDatabindingByType() returns error? {
    int|string response = check clientDBBackendClient->get("/anydataTest/intTypeWithInvalidMimeType");
    test:assertEquals(response, 65, msg = "Found unexpected output");
}

@test:Config {}
function testReadonlyIntArrayDatabinding() returns error? {
    readonly & int[] response = check clientDBBackendClient->get("/anydataTest/intArrType");
    int[] a = response;
    if a is readonly & int[] {
        test:assertEquals(response, [56, 34], msg = "Found unexpected output");
    } else {
        test:assertFail("Found unexpected output");
    }
}

@test:Config {}
function testIntMapDatabinding() returns error? {
    map<int> response = check clientDBBackendClient->get("/anydataTest/intMapType");
    test:assertEquals(response, {"name":11,"team":22}, msg = "Found unexpected output");
}

@test:Config {}
function testIntMapDatabindingByType() returns error? {
    map<int> response = check clientDBBackendClient->get("/anydataTest/intMapTypeWithInvalidMimeType");
    test:assertEquals(response, {"name":11,"team":22}, msg = "Found unexpected output");
}

@test:Config {}
function testIntTableDatabinding() returns error? {
    table<map<int>> tbl = check clientDBBackendClient->get("/anydataTest/intTableType");
    object {public isolated function next() returns record {| map<int> value; |}?;} iterator = tbl.iterator();
    record {| map<int> value; |}? next = iterator.next();
    if next is record {| map<int> value; |} {
        test:assertEquals(next.value, {id: 1, title: 11});
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testIntTableOrMapofIntArrayDatabinding() {
    table<map<int>>|map<int>[]|error response = clientDBBackendClient->get("/anydataTest/intTableType");
    if response is error {
        assertTrueTextPayload(response.message(),
                    "Payload binding failed: 'json[]' value cannot be converted to '(table<map<int>>|map<int>[])");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testIntTableOrXmlArrayDatabinding() returns error? {
    table<map<int>>|xml tbl = check clientDBBackendClient->get("/anydataTest/intTableType");
    if tbl is table<map<int>> {
        object {public isolated function next() returns record {| map<int> value; |}?;} iterator = tbl.iterator();
        record {| map<int> value; |}? next = iterator.next();
        if next is record {| map<int> value; |} {
            test:assertEquals(next.value, {id: 1, title: 11});
        } else {
            test:assertFail(msg = "Found unexpected output type");
        }
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testIntTableDatabindingByType() returns error? {
    table<map<int>> tbl = check clientDBBackendClient->get("/anydataTest/intTableTypeWithInvalidMimeType");
    object {public isolated function next() returns record {| map<int> value; |}?;} iterator = tbl.iterator();
    record {| map<int> value; |}? next = iterator.next();
    if next is record {| map<int> value; |} {
        test:assertEquals(next.value, {id: 1, title: 11});
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testStringDatabinding() returns error? {
    string response = check clientDBBackendClient->get("/anydataTest/stringType");
    test:assertEquals(response, "hello", msg = "Found unexpected output");
}

@test:Config {}
function testStringDatabindingByType() returns error? {
    string response = check clientDBBackendClient->get("/anydataTest/stringTypeWithInvalidMimeType");
    test:assertEquals(response, "hello", msg = "Found unexpected output");
}

@test:Config {}
function testStringArrayDatabinding() returns error? {
    string[] response = check clientDBBackendClient->get("/anydataTest/stringArrType");
    test:assertEquals(response, ["hello", "ballerina"], msg = "Found unexpected output");
}

@test:Config {}
function testStringArrayDatabindingByType() returns error? {
    string[] response = check clientDBBackendClient->get("/anydataTest/stringArrTypeWithInvalidMimeType");
    test:assertEquals(response, ["hello", "ballerina"], msg = "Found unexpected output");
}

@test:Config {}
function testReadonlyStringArrayDatabinding() returns error? {
    readonly & string[] response = check clientDBBackendClient->get("/anydataTest/stringArrType");
    string[] a = response;
    if a is readonly & string[] {
        test:assertEquals(response, ["hello", "ballerina"], msg = "Found unexpected output");
    } else {
        test:assertFail("Found unexpected output");
    }
}

@test:Config {}
function testStringMapDatabinding() returns error? {
    map<string> response = check clientDBBackendClient->get("/anydataTest/stringMapType");
    test:assertEquals(response, {name:"hello", team:"ballerina"}, msg = "Found unexpected output");
}

@test:Config {}
function testStringMapDatabindingByType() returns error? {
    map<string> response = check clientDBBackendClient->get("/anydataTest/stringMapTypeWithInvalidMimeType");
    test:assertEquals(response, {name:"hello", team:"ballerina"}, msg = "Found unexpected output");
}

@test:Config {}
function testStringTableDatabinding() returns error? {
    table<map<string>> tbl = check clientDBBackendClient->get("/anydataTest/stringTableType");
    object {public isolated function next() returns record {| map<string> value; |}?;} iterator = tbl.iterator();
    record {| map<string> value; |}? next = iterator.next();
    if next is record {| map<string> value; |} {
        test:assertEquals(next.value, {id: "1", title: "11"});
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testStringTableDatabindingByType() returns error? {
    table<map<string>> tbl = check clientDBBackendClient->get("/anydataTest/stringTableTypeWithInvalidMimeType");
    object {public isolated function next() returns record {| map<string> value; |}?;} iterator = tbl.iterator();
    record {| map<string> value; |}? next = iterator.next();
    if next is record {| map<string> value; |} {
        test:assertEquals(next.value, {id: "1", title: "11"});
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}
