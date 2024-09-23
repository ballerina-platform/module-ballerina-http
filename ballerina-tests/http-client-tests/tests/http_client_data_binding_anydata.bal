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
import ballerina/mime;
import ballerina/http;
import ballerina/lang.'string as strings;
import ballerina/http_test_common as common;

public type ClientAnydataDBPerson record {|
    string name;
    int age;
|};

type ClientAnydataDBStock record {|
    int id;
    float price;
|};

service /anydataTest on clientDBBackendListener {

    resource function get intType() returns int {
        return 56;
    }

    resource function get intTypeWithInvalidMimeType() returns @http:Payload {mediaType: "type2/subtype2"} int {
        return 65;
    }

    resource function get intTypeWithIncompatibleMimeType() returns @http:Payload {mediaType: "application/xml"} int {
        return 65;
    }

    resource function get intArrType() returns int[] {
        return [56, 34];
    }

    resource function get intArrTypeWithInvalidMimeType() returns @http:Payload {mediaType: "type2/subtype2"} int[] {
        return [56, 34];
    }

    resource function get intMapType() returns map<int> {
        return {name: 11, team: 22};
    }

    resource function get intMapTypeWithInvalidMimeType() returns @http:Payload {mediaType: "type2/subtype2"} map<int> {
        return {name: 11, team: 22};
    }

    resource function get intTableType() returns table<map<int>> {
        return table [
                {id: 1, title: 11},
                {id: 2, title: 22},
                {id: 3, title: 33}
            ];
    }

    resource function get intTableTypeWithInvalidMimeType()
            returns @http:Payload {mediaType: "type2/subtype2"} table<map<int>> {
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
            returns @http:Payload {mediaType: "type2/subtype2"} string {
        return "hello";
    }

    resource function get stringArrType() returns string[] {
        return ["hello", "ballerina"];
    }

    resource function get stringArrTypeWithInvalidMimeType()
            returns @http:Payload {mediaType: "type2/subtype2"} string[] {
        return ["hello", "ballerina"];
    }

    resource function get stringMapType() returns map<string> {
        return {name: "hello", team: "ballerina"};
    }

    resource function get stringMapTypeWithInvalidMimeType()
            returns @http:Payload {mediaType: "type2/subtype2"} map<string> {
        return {name: "hello", team: "ballerina"};
    }

    resource function get stringTableType() returns table<map<string>> {
        return table [
                {id: "1", title: "11"},
                {id: "2", title: "22"},
                {id: "3", title: "33"}
            ];
    }

    resource function get stringTableTypeWithInvalidMimeType()
            returns @http:Payload {mediaType: "type2/subtype2"} table<map<string>> {
        return table [
                {id: "1", title: "11"},
                {id: "2", title: "22"},
                {id: "3", title: "33"}
            ];
    }

    // anydata
    resource function get anydataType() returns anydata {
        return 563;
    }

    // issue #2813
    resource function get status() returns http:Ok {
        return {
            body: {status: "OK"},
            mediaType: mime:APPLICATION_JSON
        };
    }

    // record
    resource function get recordMapType() returns map<ClientAnydataDBPerson> {
        ClientAnydataDBPerson a = {name: "hello", age: 23};
        ClientAnydataDBPerson b = {name: "ballerina", age: 5};
        return {"1": a, "2": b};
    }

    resource function get recordMapTypeWithInvalidMimeType()
            returns @http:Payload {mediaType: "type2/subtype2"} map<ClientAnydataDBPerson> {
        ClientAnydataDBPerson a = {name: "hello", age: 23};
        ClientAnydataDBPerson b = {name: "ballerina", age: 5};
        return {"1": a, "2": b};
    }

    resource function get recordTableType() returns table<ClientAnydataDBPerson> {
        return table [
                {name: "hello", age: 23},
                {name: "ballerina", age: 5}
            ];
    }

    resource function get recordTableTypeWithInvalidMimeType()
            returns @http:Payload {mediaType: "type2/subtype2"} table<ClientAnydataDBPerson> {
        return table [
                {name: "hello", age: 23},
                {name: "ballerina", age: 5}
            ];
    }

    // byte[]
    resource function get byteArrType() returns byte[] {
        return "WSO2".toBytes();
    }

    resource function get byteArrTypeWithInvalidMimeType()
            returns @http:Payload {mediaType: "type2/subtype2"} byte[] {
        return "WSO2".toBytes();
    }

    resource function get byteArrArrType() returns byte[][] {
        return ["WSO2".toBytes(), "Ballerina".toBytes()];
    }

    resource function get byteArrArrTypeWithInvalidMimeType()
            returns @http:Payload {mediaType: "type2/subtype2"} byte[][] {
        return ["WSO2".toBytes(), "Ballerina".toBytes()];
    }

    resource function get byteArrMapType() returns map<byte[]> {
        return {name: "STDLIB".toBytes(), team: "Ballerina".toBytes()};
    }

    resource function get byteArrMapTypeWithInvalidMimeType()
            returns @http:Payload {mediaType: "type2/subtype2"} map<byte[]> {
        return {name: "STDLIB".toBytes(), team: "Ballerina".toBytes()};
    }

    resource function get byteArrTableType() returns table<map<byte[]>> {
        return table [
                {id: "WSO2".toBytes(), title: "Company".toBytes()},
                {id: "Ballerina".toBytes(), title: "Language".toBytes()},
                {id: "Srilanka".toBytes(), title: "Country".toBytes()}
            ];
    }

    resource function get byteArrTableTypeWithInvalidMimeType()
            returns @http:Payload {mediaType: "type2/subtype2"} table<map<byte[]>> {
        return table [
                {id: "WSO2".toBytes(), title: "Company".toBytes()},
                {id: "Ballerina".toBytes(), title: "Language".toBytes()},
                {id: "Srilanka".toBytes(), title: "Country".toBytes()}
            ];
    }

    // xml
    resource function get xmlArrType() returns xml[] {
        return [xml `<name>WSO2</name>`, xml `<name>Ballerina</name>`];
    }

    resource function get xmlArrTypeWithInvalidMimeType() returns @http:Payload {mediaType: "type2/subtype2"} xml[] {
        return [xml `<name>WSO2</name>`, xml `<name>Ballerina</name>`];
    }

    // union
    resource function get xmlType() returns xml {
        return xml `<name>WSO2</name>`;
    }

    resource function get jsonType() returns json {
        return {name: "hello", id: 20};
    }

    resource function get recordType() returns ClientAnydataDBPerson {
        return {name: "hello", age: 20};
    }

    resource function get getFormData() returns http:Ok|error {
        return {body: "first%20Name=WS%20O2&tea%24%2Am=Bal%40Dance", mediaType: "application/x-www-form-urlencoded"};
    }

    // nilable union
    resource function get getNoContentXml() returns http:Created {
        return {mediaType: "application/xml"};
    }

    resource function get getNoContentString() returns http:Created {
        return {mediaType: "text/plain"};
    }

    resource function get getNoContentUrlEncoded() returns http:Created {
        return {mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getNoContentBlob() returns http:Created {
        return {mediaType: "application/octet-stream"};
    }

    resource function get getNoContentJson() returns http:Created {
        return {mediaType: "application/json"};
    }

    // builtin subtypes
    resource function get getXmlElement() returns xml:Element {
        return xml `<placeOrder><order-status>PLACED</order-status><order-id>ORD-1234</order-id></placeOrder>`;
    }

    resource function get getStringChar() returns string:Char {
        string str = "text";
        string:Char getStringChar = str[0];
        return getStringChar;
    }

    resource function get getIntSigned32() returns int:Signed32 {
        return -2147483648;
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
function testIntDatabindingByTypeNegative() returns error? {
    int|error response = clientDBBackendClient->get("/anydataTest/intTypeWithIncompatibleMimeType");
    if response is error {
        common:assertTrueTextPayload(response.message(), "incompatible typedesc int found for 'application/xml' mime type");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
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
    test:assertEquals(response, {"name": 11, "team": 22}, msg = "Found unexpected output");
}

@test:Config {}
function testIntMapDatabindingByType() returns error? {
    map<int> response = check clientDBBackendClient->get("/anydataTest/intMapTypeWithInvalidMimeType");
    test:assertEquals(response, {"name": 11, "team": 22}, msg = "Found unexpected output");
}

@test:Config {}
function testIntTableDatabinding() returns error? {
    table<map<int>> tbl = check clientDBBackendClient->get("/anydataTest/intTableType");
    object {
        public isolated function next() returns record {|map<int> value;|}?;
    } iterator = tbl.iterator();
    record {|map<int> value;|}? next = iterator.next();
    if next is record {|map<int> value;|} {
        test:assertEquals(next.value, {id: 1, title: 11});
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testIntTableOrMapofIntArrayDatabinding() returns error? {
    map<int>[]|table<map<int>> response = check clientDBBackendClient->get("/anydataTest/intTableType");
    if response is map<int>[] {
        map<int> entry = response[0];
        int? val1 = entry["id"];
        int? val2 = entry["title"];
        test:assertEquals(val1, 1, msg = "Found unexpected output");
        test:assertEquals(val2, 11, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: table<map<int>>");
    }
}

@test:Config {}
function testIntTableOrXmlArrayDatabinding() returns error? {
    table<map<int>>|xml tbl = check clientDBBackendClient->get("/anydataTest/intTableType");
    if tbl is table<map<int>> {
        object {
            public isolated function next() returns record {|map<int> value;|}?;
        } iterator = tbl.iterator();
        record {|map<int> value;|}? next = iterator.next();
        if next is record {|map<int> value;|} {
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
    object {
        public isolated function next() returns record {|map<int> value;|}?;
    } iterator = tbl.iterator();
    record {|map<int> value;|}? next = iterator.next();
    if next is record {|map<int> value;|} {
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
    test:assertEquals(response, {name: "hello", team: "ballerina"}, msg = "Found unexpected output");
}

@test:Config {}
function testStringMapDatabindingByType() returns error? {
    map<string> response = check clientDBBackendClient->get("/anydataTest/stringMapTypeWithInvalidMimeType");
    test:assertEquals(response, {name: "hello", team: "ballerina"}, msg = "Found unexpected output");
}

@test:Config {}
function testStringTableDatabinding() returns error? {
    table<map<string>> tbl = check clientDBBackendClient->get("/anydataTest/stringTableType");
    object {
        public isolated function next() returns record {|map<string> value;|}?;
    } iterator = tbl.iterator();
    record {|map<string> value;|}? next = iterator.next();
    if next is record {|map<string> value;|} {
        test:assertEquals(next.value, {id: "1", title: "11"});
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testStringTableDatabindingByType() returns error? {
    table<map<string>> tbl = check clientDBBackendClient->get("/anydataTest/stringTableTypeWithInvalidMimeType");
    object {
        public isolated function next() returns record {|map<string> value;|}?;
    } iterator = tbl.iterator();
    record {|map<string> value;|}? next = iterator.next();
    if next is record {|map<string> value;|} {
        test:assertEquals(next.value, {id: "1", title: "11"});
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testAnydataDatabinding() returns error? {
    anydata response = check clientDBBackendClient->get("/anydataTest/anydataType");
    if response is int {
        test:assertEquals(response, 563, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testJsonWithStringDatabinding() returns error? {
    json response = check clientDBBackendClient->get("/anydataTest/status");
    test:assertEquals(response, {"status": "OK"}, msg = "Found unexpected output");
    record {|
        string status;
    |} recordOfString = check clientDBBackendClient->get("/anydataTest/status");
    test:assertEquals(recordOfString, {"status": "OK"}, msg = "Found unexpected output");
}

@test:Config {}
function testRecordMapDatabinding() returns error? {
    map<ClientAnydataDBPerson> response = check clientDBBackendClient->get("/anydataTest/recordMapType");
    test:assertEquals(response.get("1"), {name: "hello", age: 23}, msg = "Found unexpected output");
}

@test:Config {}
function testRecordMapDatabindingByType() returns error? {
    map<ClientAnydataDBPerson> response = check clientDBBackendClient->get("/anydataTest/recordMapTypeWithInvalidMimeType");
    test:assertEquals(response.get("1"), {name: "hello", age: 23}, msg = "Found unexpected output");
}

@test:Config {}
function testRecordTableDatabinding() returns error? {
    table<ClientAnydataDBPerson> tbl = check clientDBBackendClient->get("/anydataTest/recordTableType");
    object {
        public isolated function next() returns record {|ClientAnydataDBPerson value;|}?;
    } iterator = tbl.iterator();
    record {|ClientAnydataDBPerson value;|}? next = iterator.next();
    if next is record {|ClientAnydataDBPerson value;|} {
        test:assertEquals(next.value, {name: "hello", age: 23});
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testRecordTableDatabindingByType() returns error? {
    table<ClientAnydataDBPerson> tbl = check clientDBBackendClient->get("/anydataTest/recordTableTypeWithInvalidMimeType");
    object {
        public isolated function next() returns record {|ClientAnydataDBPerson value;|}?;
    } iterator = tbl.iterator();
    record {|ClientAnydataDBPerson value;|}? next = iterator.next();
    if next is record {|ClientAnydataDBPerson value;|} {
        test:assertEquals(next.value, {name: "hello", age: 23});
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testByteArrDatabinding() returns error? {
    byte[] response = check clientDBBackendClient->get("/anydataTest/byteArrType");
    test:assertEquals(check strings:fromBytes(response), "WSO2", msg = "Found unexpected output");
}

@test:Config {}
function testByteArrDatabindingByType() returns error? {
    byte[] response = check clientDBBackendClient->get("/anydataTest/byteArrTypeWithInvalidMimeType");
    test:assertEquals(check strings:fromBytes(response), "WSO2", msg = "Found unexpected output");
}

@test:Config {}
function testByteArrArrDatabinding() returns error? {
    byte[][] response = check clientDBBackendClient->get("/anydataTest/byteArrArrType");
    test:assertEquals(check strings:fromBytes(response[1]), "Ballerina", msg = "Found unexpected output");
}

@test:Config {}
function testByteArrArrDatabindingByType() returns error? {
    byte[][] response = check clientDBBackendClient->get("/anydataTest/byteArrArrTypeWithInvalidMimeType");
    test:assertEquals(check strings:fromBytes(response[1]), "Ballerina", msg = "Found unexpected output");
}

@test:Config {}
function testByteArrMapDatabinding() returns error? {
    map<byte[]> response = check clientDBBackendClient->get("/anydataTest/byteArrMapType");
    byte[] val = response["name"] ?: [87, 87, 87, 50];
    test:assertEquals(check strings:fromBytes(val), "STDLIB", msg = "Found unexpected output");
}

@test:Config {}
function testByteArrMapDatabindingByType() returns error? {
    map<byte[]> response = check clientDBBackendClient->get("/anydataTest/byteArrMapTypeWithInvalidMimeType");
    byte[] val = response["name"] ?: [87, 87, 87, 50];
    test:assertEquals(check strings:fromBytes(val), "STDLIB", msg = "Found unexpected output");
}

@test:Config {}
function testByteArrTableDatabinding() returns error? {
    table<map<byte[]>> response = check clientDBBackendClient->get("/anydataTest/byteArrTableType");
    object {
        public isolated function next() returns record {|map<byte[]> value;|}?;
    } iterator = response.iterator();
    record {|map<byte[]> value;|}? next = iterator.next();
    if next is record {|map<byte[]> value;|} {
        byte[] val = next.value["id"] ?: [87, 87, 87, 50];
        test:assertEquals(check strings:fromBytes(val), "WSO2", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testByteArrTableDatabindingByType() returns error? {
    table<map<byte[]>> response = check clientDBBackendClient->get("/anydataTest/byteArrTableTypeWithInvalidMimeType");
    object {
        public isolated function next() returns record {|map<byte[]> value;|}?;
    } iterator = response.iterator();
    record {|map<byte[]> value;|}? next = iterator.next();
    if next is record {|map<byte[]> value;|} {
        byte[] val = next.value["title"] ?: [87, 87, 87, 50];
        test:assertEquals(check strings:fromBytes(val), "Company", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testXmlArrDatabinding() {
    xml[]|error response = clientDBBackendClient->get("/anydataTest/xmlArrType");
    if response is error {
        common:assertTrueTextPayload(response.message(),
            "Payload binding failed: invalid type 'xml<(lang.xml:Element|lang.xml:Comment|lang.xml:ProcessingInstruction|lang.xml:Text)>' expected 'anydata'");
    } else {
        test:assertEquals(response[0], xml `<name>WSO2</name>`, msg = "Found unexpected output");
    }
}

@test:Config {}
function testXmlArrDatabindingByType() {
    xml[]|error response = clientDBBackendClient->get("/anydataTest/xmlArrTypeWithInvalidMimeType");
    if response is error {
        common:assertTrueTextPayload(response.message(),
            "Payload binding failed: invalid type 'xml<(lang.xml:Element|lang.xml:Comment|lang.xml:ProcessingInstruction|lang.xml:Text)>' expected 'anydata'");
    } else {
        test:assertEquals(response[0], xml `<name>WSO2</name>`, msg = "Found unexpected output");
    }
}

@test:Config {}
function testUnionOfDatabindingForXmlWithJsonXml() returns error? {
    xml|json response = check clientDBBackendClient->get("/anydataTest/xmlType");
    if response is xml {
        common:assertXmlPayload(response, xml `<name>WSO2</name>`);
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testUnionOfDatabindingForJsonWithJsonXml() returns error? {
    xml|json response = check clientDBBackendClient->get("/anydataTest/jsonType");
    if response is json {
        common:assertJsonPayload(response, {name: "hello", id: 20});
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testUnionOfDatabindingForStringWithStringXml() returns error? {
    xml|string response = check clientDBBackendClient->get("/anydataTest/stringType");
    if response is string {
        test:assertEquals(response, "hello", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testUnionOfDatabindingForByteArrWithStringByteArr() returns error? {
    xml|byte[] response = check clientDBBackendClient->get("/anydataTest/stringType");
    if response is byte[] {
        test:assertEquals(check strings:fromBytes(response), "hello", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testUnionOfDatabindingForMapStringWithMapStringXml() returns error? {
    xml|map<string> person = check clientDBBackendClient->get("/anydataTest/getFormData");
    if person is map<string> {
        string? val1 = person["first Name"];
        string? val2 = person["tea$*m"];
        test:assertEquals(val1, "WS O2", msg = "Found unexpected output");
        test:assertEquals(val2, "Bal@Dance", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testUnionOfDatabindingForStringWithMapStringXml() returns error? {
    string|xml person = check clientDBBackendClient->get("/anydataTest/getFormData");
    if person is string {
        test:assertEquals(person, "first%20Name=WS%20O2&tea%24%2Am=Bal%40Dance", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testUnionOfDatabindingForByteArrWithByteArrXml() returns error? {
    byte[]|xml response = check clientDBBackendClient->get("/anydataTest/byteArrType");
    if response is byte[] {
        test:assertEquals(check strings:fromBytes(response), "WSO2", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testUnionOfDatabindingForRecordWithPersonNStock() returns error? {
    ClientAnydataDBPerson|ClientAnydataDBStock response = check clientDBBackendClient->get("/anydataTest/recordType");
    if response is ClientAnydataDBPerson {
        test:assertEquals(response, {name: "hello", age: 20}, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testUnionOfDatabindingForMoreTypesWithString() returns error? {
    xml|json|string|byte[] response = check clientDBBackendClient->get("/anydataTest/stringType");
    if response is string {
        test:assertEquals(response, "hello", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testUnionOfDatabindingForMoreTypesWithJson() returns error? {
    xml|json|string|byte[] response = check clientDBBackendClient->get("/anydataTest/jsonType");
    if response is json {
        common:assertJsonPayload(response, {name: "hello", id: 20});
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testUnionOfDatabindingForMoreTypesWithXml() returns error? {
    xml|json|string|byte[] response = check clientDBBackendClient->get("/anydataTest/xmlType");
    if response is xml {
        common:assertXmlPayload(response, xml `<name>WSO2</name>`);
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testUnionOfDatabindingForMoreTypesWithByteArr() returns error? {
    xml|json|string|byte[] response = check clientDBBackendClient->get("/anydataTest/byteArrType");
    if response is byte[] {
        test:assertEquals(check strings:fromBytes(response), "WSO2", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

@test:Config {}
function testNilableUnionOfDatabindingForXml() returns error? {
    xml|string? response = check clientDBBackendClient->get("/anydataTest/getNoContentXml");
    test:assertTrue(response is (), msg = "Found unexpected output");
}

@test:Config {}
function testNilableUnionOfDatabindingForString() returns error? {
    xml|string? response = check clientDBBackendClient->get("/anydataTest/getNoContentString");
    test:assertTrue(response is (), msg = "Found unexpected output");
}

@test:Config {}
function testNilableUnionOfDatabindingForByteArr() returns error? {
    xml|byte[]? response = check clientDBBackendClient->get("/anydataTest/getNoContentString");
    test:assertTrue(response is (), msg = "Found unexpected output");
}

@test:Config {}
function testNilableUnionOfDatabindingForMapFormData() returns error? {
    xml|map<string>? response = check clientDBBackendClient->get("/anydataTest/getNoContentUrlEncoded");
    test:assertTrue(response is (), msg = "Found unexpected output");
}

@test:Config {}
function testNilableUnionOfDatabindingForStringFormData() returns error? {
    xml|string? response = check clientDBBackendClient->get("/anydataTest/getNoContentUrlEncoded");
    test:assertTrue(response is (), msg = "Found unexpected output");
}

@test:Config {}
function testNilableUnionOfDatabindingForOctetBlob() returns error? {
    xml|byte[]? response = check clientDBBackendClient->get("/anydataTest/getNoContentBlob");
    test:assertTrue(response is (), msg = "Found unexpected output");
}

@test:Config {}
function testNilableUnionOfDatabindingForJson() returns error? {
    xml|json? response = check clientDBBackendClient->get("/anydataTest/getNoContentJson");
    test:assertTrue(response is (), msg = "Found unexpected output");
}

@test:Config {}
function testBuiltInSubtypeXmlElement() returns error? {
    xml response = check clientDBBackendClient->get("/anydataTest/getXmlElement");
    test:assertTrue(response is xml:Element, msg = "Found unexpected output");
    common:assertXmlPayload(response,
        xml `<placeOrder><order-status>PLACED</order-status><order-id>ORD-1234</order-id></placeOrder>`);
}

@test:Config {}
function testBuiltInSubtypeStringChar() returns error? {
    string:Char response = check clientDBBackendClient->get("/anydataTest/getStringChar");
    test:assertEquals(response, "t", msg = "Found unexpected output");
}

@test:Config {}
function testBuiltInSubtypegetIntSigned32() returns error? {
    int:Signed32 response = check clientDBBackendClient->get("/anydataTest/getIntSigned32");
    test:assertEquals(response, -2147483648, msg = "Found unexpected output");
}
