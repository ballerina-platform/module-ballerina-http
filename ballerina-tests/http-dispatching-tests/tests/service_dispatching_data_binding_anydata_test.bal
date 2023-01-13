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

import ballerina/lang.'string as strings;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

public enum MenuType {
    BREAK_FAST,
    LUNCH,
    DINNER
}

public type MenuItem record {|
    int _id;
    string name;
    string description;
    decimal price;
|};

public type Menu record {|
    int _id;
    MenuType 'type;
    MenuItem[] items;
|};

public type Restaurant record {|
    string name;
    string city;
    string description;
    Menu[] menus;
|};

public type User readonly & record {|
    int id;
    int age;
|};

public type RestaurantNew record {|
    *Restaurant;
    [int, string, decimal, float, User] address;
|};

type newXmlElement xml:Element;

final http:Client anydataBindingClient = check new ("http://localhost:" + generalPort.toString(), httpVersion = http:HTTP_1_1);

service /anydataB on generalListener {

    // int
    resource function post checkInt(@http:Payload int j) returns int {
        return j;
    }

    resource function post checkIntArray(@http:Payload int[] j) returns int[] {
        return j;
    }

    resource function post checkIntMap(@http:Payload map<int> person) returns json|error {
        int? a = person["name"];
        int? b = person["team"];
        json responseJson = {"1": a, "2": b};
        return responseJson;
    }

    resource function post checkIntTable(@http:Payload table<map<int>> tbl)
            returns http:InternalServerError|map<int> {
        object {
            public isolated function next() returns record {|map<int> value;|}?;
        } iterator = tbl.iterator();
        record {|map<int> value;|}? next = iterator.next();
        if next is record {|map<int> value;|} {
            return next.value;
        } else {
            return <http:InternalServerError>{body: "No entry found"};
        }
    }

    // string
    resource function post checkString(@http:Payload string j) returns string {
        return j;
    }

    resource function post checkStringArray(@http:Payload string[] j) returns string[] {
        return j;
    }

    resource function post checkStringMap(@http:Payload map<string> person) returns json|error {
        string? a = person["name"];
        string? b = person["team"];
        json responseJson = {"1": a, "2": b};
        return responseJson;
    }

    resource function post checkStringTable(@http:Payload table<map<string>> tbl)
            returns http:InternalServerError|map<string> {
        object {
            public isolated function next() returns record {|map<string> value;|}?;
        } iterator = tbl.iterator();
        record {|map<string> value;|}? next = iterator.next();
        if next is record {|map<string> value;|} {
            return next.value;
        } else {
            return <http:InternalServerError>{body: "No entry found"};
        }
    }

    // record
    resource function post checkRecord(@http:Payload Person person) returns json {
        string name = person.name;
        int age = person.age;
        return {Key: name, Age: age};
    }

    resource function post checkRecordArray(@http:Payload Person[] j) returns Person[] {
        return j;
    }

    resource function post checkRecordMap(@http:Payload map<Person> person) returns json|error {
        Person? a = person["name"];
        Person? b = person["team"];
        json responseJson = {"1": a, "2": b};
        return responseJson;
    }

    resource function post checkRecordTable(@http:Payload table<Person> tbl) returns http:InternalServerError|Person {
        object {
            public isolated function next() returns record {|Person value;|}?;
        } iterator = tbl.iterator();
        record {|Person value;|}? next = iterator.next();
        if next is record {|Person value;|} {
            return next.value;
        } else {
            return <http:InternalServerError>{body: "No entry found"};
        }
    }

    resource function post checkRecordWithTuple(@http:Payload RestaurantNew restaurant) returns RestaurantNew {
        return restaurant;
    }

    // byte[]
    resource function post checkByteArr(@http:Payload byte[] j) returns http:InternalServerError|string {
        var name = strings:fromBytes(j);
        if (name is string) {
            return name;
        } else {
            return <http:InternalServerError>{body: "Error occurred while byte array to string conversion"};
        }
    }

    resource function post checkByteArrArray(@http:Payload byte[][] j) returns http:InternalServerError|string {
        var name = strings:fromBytes(j[0]);
        if (name is string) {
            return name;
        } else {
            return <http:InternalServerError>{body: "Error occurred while byte array to string conversion"};
        }
    }

    resource function post checkByteArrMap(@http:Payload map<byte[]> person) returns json|error {
        byte[] a = person["name"] ?: [87, 87, 87, 50];
        byte[] b = person["team"] ?: [50, 87, 87, 50];
        json responseJson = {"1": check strings:fromBytes(a), "2": check strings:fromBytes(b)};
        return responseJson;
    }

    resource function post checkByteArrTable(@http:Payload table<map<byte[]>> tbl)
            returns http:InternalServerError|map<byte[]> {
        object {
            public isolated function next() returns record {|map<byte[]> value;|}?;
        } iterator = tbl.iterator();
        record {|map<byte[]> value;|}? next = iterator.next();
        if next is record {|map<byte[]> value;|} {
            return next.value;
        } else {
            return <http:InternalServerError>{body: "No entry found"};
        }
    }

    // xml
    resource function post checkXml(@http:Payload xml j) returns xml {
        return j;
    }

    resource function post checkXmlArray(@http:Payload xml[] j) returns xml[] {
        return j;
    }

    resource function post checkXmlMap(@http:Payload map<xml> person) returns json|error {
        xml a = person["name"] ?: xml `<name>This is Name</name>`;
        xml b = person["team"] ?: xml `<name>This is Team</name>`;
        json responseJson = {"1": a.toJson(), "2": b.toJson()};
        return responseJson;
    }

    resource function post checkXmlTable(@http:Payload table<map<xml>> tbl)
            returns http:InternalServerError|map<xml> {
        object {
            public isolated function next() returns record {|map<xml> value;|}?;
        } iterator = tbl.iterator();
        record {|map<xml> value;|}? next = iterator.next();
        if next is record {|map<xml> value;|} {
            return next.value;
        } else {
            return <http:InternalServerError>{body: "No entry found"};
        }
    }

    // table
    resource function post checkArrayOfTable(@http:Payload table<map<int>>[] tbls)
            returns http:InternalServerError|map<int> {
        table<map<int>> tbl = tbls[0];
        object {
            public isolated function next() returns record {|map<int> value;|}?;
        } iterator = tbl.iterator();
        record {|map<int> value;|}? next = iterator.next();
        if next is record {|map<int> value;|} {
            return next.value;
        } else {
            return <http:InternalServerError>{body: "No entry found"};
        }
    }

    resource function post checkMapOfTable(@http:Payload map<table<map<int>>> tbls)
            returns http:InternalServerError|map<int> {
        table<map<int>>? tbl = tbls["team"];
        if tbl is table<map<int>> {
            object {
                public isolated function next() returns record {|map<int> value;|}?;
            } iterator = tbl.iterator();
            record {|map<int> value;|}? next = iterator.next();
            if next is record {|map<int> value;|} {
                return next.value;
            } else {
                return <http:InternalServerError>{body: "No entry found"};
            }
        } else {
            return <http:InternalServerError>{body: "No table found"};
        }
    }

    // readonly
    resource function post checkReadonlyArr(@http:Payload readonly & Person[] abc) returns json {
        Person[] xyz = abc;
        if xyz is readonly & Person[] {
            return {status: "readonly", value: xyz[0]};
        } else {
            return {status: "non-readonly", value: "Invalid value"};
        }
    }

    // anydata
    resource function post checkAnydata(@http:Payload anydata j) returns int {
        return <int>j;
    }

    // Union
    resource function post checkUnionTypesWithXmlJson(@http:Payload json|xml payload) returns json|xml {
        if payload is json {
            return {result: "It's json"};
        } else {
            return payload;
        }
    }

    resource function post checkUnionTypesWithStringJson(@http:Payload json|string payload) returns json {
        if payload is string {
            return {result: "It's string"};
        } else {
            return {result: "It's json"};
        }
    }

    resource function post checkUnionTypesWithStringNil(@http:Payload string? payload) returns json {
        if payload is string {
            return {result: payload};
        } else {
            return {result: "It's nil"};
        }
    }

    resource function post checkUnionWithStringMapXml(@http:Payload xml|map<string> person) returns json|error {
        if person is map<string> {
            string? a = person["name"];
            string? b = person["team"];
            json responseJson = {"1": a, "2": b};
            return responseJson;
        } else {
            return {result: "It's xml"};
        }
    }

    resource function post checkUnionWithByteArrJson(@http:Payload json|byte[] j) returns
            http:InternalServerError|string {
        if j is byte[] {
            var name = strings:fromBytes(j);
            if (name is string) {
                return name;
            } else {
                return <http:InternalServerError>{body: "Error occurred while byte array to string conversion"};
            }
        } else {
            return "It's json";
        }
    }

    resource function post checkUnionWithStringArrJson(@http:Payload json|string[] j) returns
            http:InternalServerError|string {
        if j is string[] {
            return j[0];
        } else {
            return "It's json";
        }
    }

    resource function post checkUnionWithRecords(@http:Payload Person|Stock person) returns json {
        if person is Person {
            string name = person.name;
            int age = person.age;
            return {Key: name, Age: age};
        } else {
            float price = person.price;
            int age = person.id;
            return {Key: price, Age: age};
        }
    }

    // readonly union
    resource function post checkUnionTypesWithStringNilWithReadonly(@http:Payload readonly & byte[]? payload)
        returns json {
        if payload is byte[] {
            return {result: "payload"};
        } else {
            return {result: "It's nil"};
        }
    }

    resource function post checkUnionTypesWithReadonlyByteArrWithNil(@http:Payload readonly & byte[]|() payload)
        returns json {
        if payload is byte[] {
            return {result: "payload"};
        } else {
            return {result: "It's nil"};
        }
    }

    // builtin subtypes
    resource function post checkXmlElement(@http:Payload xml:Element payload) returns xml:Element {
        return payload;
    }

    resource function post checkCustomXmlElement(@http:Payload newXmlElement payload) returns newXmlElement {
        return payload;
    }

    resource function post checkStrChar(@http:Payload string:Char payload) returns string:Char {
        return payload;
    }

    resource function post checkIntSigned32(@http:Payload int:Signed32 payload) returns int:Signed32 {
        return payload;
    }

    // enums
    resource function post checkEnum(@http:Payload MenuType menuType) returns MenuType {
        return menuType;
    }

    resource function post checkRecordWithEnum(@http:Payload Restaurant restaurant) returns Restaurant {
        return restaurant;
    }
}

@test:Config {}
function testDataBindingAnInt() returns error? {
    json j = 12;
    json response = check anydataBindingClient->post("/anydataB/checkInt", j);
    common:assertJsonPayload(response, j);
}

@test:Config {}
function testDataBindingAnIntByType() returns error? {
    json j = 12;
    json response = check anydataBindingClient->post("/anydataB/checkInt", j, mediaType = "application/abc");
    common:assertJsonPayload(response, j);
}

@test:Config {}
function testDataBindingIntArray() returns error? {
    json j = [12, 23];
    json response = check anydataBindingClient->post("/anydataB/checkIntArray", j);
    common:assertJsonPayload(response, j);
}

@test:Config {}
function testDataBindingIntArrayByType() returns error? {
    json j = [12, 23];
    json response = check anydataBindingClient->post("/anydataB/checkIntArray", j, mediaType = "application/abc");
    common:assertJsonPayload(response, j);
}

@test:Config {}
function testDataBindingWithMapOfInt() returns error? {
    json inPayload = {name: 11, team: 22};
    json response = check anydataBindingClient->post("/anydataB/checkIntMap", inPayload);
    common:assertJsonPayload(response, {"1": 11, "2": 22});
}

@test:Config {}
function testDataBindingWithMapOfIntByType() returns error? {
    json inPayload = {name: 11, team: 22};
    json response = check anydataBindingClient->post("/anydataB/checkIntMap", inPayload, mediaType = "application/abc");
    common:assertJsonPayload(response, {"1": 11, "2": 22});
}

@test:Config {}
function testDataBindingWithMapOfIntUrlEncoded() returns error? {
    string inPayload = "name=hello%20go&team=ba%20%23ller%20%40na";
    http:Response|error response = anydataBindingClient->post("/anydataB/checkIntMap", inPayload,
        mediaType = "application/x-www-form-urlencoded");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(),
        "data binding failed: incompatible type found: 'map<int>'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingWithTableofMapOfInt() returns error? {
    json[] j = [
        {id: 1, title: 11},
        {id: 2, title: 22},
        {id: 3, title: 33}
    ];
    json response = check anydataBindingClient->post("/anydataB/checkIntTable", j);
    common:assertJsonPayload(response, j[0]);
}

@test:Config {}
function testDataBindingWithTableofMapOfIntByType() returns error? {
    json[] j = [
        {id: 1, title: 11},
        {id: 2, title: 22},
        {id: 3, title: 33}
    ];
    json response = check anydataBindingClient->post("/anydataB/checkIntTable", j, mediaType = "application/abc");
    common:assertJsonPayload(response, j[0]);
}

@test:Config {}
function testDataBindingString() returns error? {
    string j = "hello";
    string response = check anydataBindingClient->post("/anydataB/checkString", j);
    common:assertTextPayload(response, j);
}

@test:Config {}
function testDataBindingStringWithUrlEncoded() returns error? {
    string j = "name=hello%20go&team=ba%20%23ller%20%40na";
    string response = check anydataBindingClient->post("/anydataB/checkString", j,
        mediaType = "application/x-www-form-urlencoded");
    common:assertTextPayload(response, j);
}

@test:Config {}
function testDataBindingStringByType() returns error? {
    string j = "hello";
    string response = check anydataBindingClient->post("/anydataB/checkString", j, mediaType = "application/abc");
    common:assertTextPayload(response, j);
}

@test:Config {}
function testDataBindingStringArray() returns error? {
    json j = ["Hi", "Hello"];
    json response = check anydataBindingClient->post("/anydataB/checkStringArray", j);
    common:assertJsonPayload(response, j);
}

@test:Config {}
function testDataBindingStringArrayNegative() {
    json j = ["Hi", "Hello"];
    http:Response|error response = anydataBindingClient->post("/anydataB/checkStringArray", j, mediaType = "text/plain");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(),
        "data binding failed: incompatible array element type found: 'string'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingStringArrayByType() returns error? {
    json j = ["Hi", "Hello"];
    json response = check anydataBindingClient->post("/anydataB/checkStringArray", j, mediaType = "application/abc");
    common:assertJsonPayload(response, j);
}

@test:Config {}
function testDataBindingWithMapString() returns error? {
    json inPayload = {name: "Smith", team: "Aus"};
    json response = check anydataBindingClient->post("/anydataB/checkStringMap", inPayload,
        mediaType = "application/json");
    common:assertJsonPayload(response, {"1": "Smith", "2": "Aus"});
}

@test:Config {}
function testDataBindingWithMapOfStringByType() returns error? {
    json inPayload = {name: "Smith", team: "Aus"};
    json response = check anydataBindingClient->post("/anydataB/checkStringMap", inPayload, mediaType = "application/abc");
    common:assertJsonPayload(response, {"1": "Smith", "2": "Aus"});
}

@test:Config {}
function testDataBindingWithMapOfStringUrlEncoded() returns error? {
    string inPayload = "name=hello%20go&team=ba%20%23ller%20%40na";
    json response = check anydataBindingClient->post("/anydataB/checkStringMap", inPayload,
        mediaType = "application/x-www-form-urlencoded");
    common:assertJsonPayload(response, {"1": "hello go", "2": "ba #ller @na"});
}

@test:Config {}
function testDataBindingWithTableofMapOfString() returns error? {
    json[] j = [
        {id: "1", title: "11"},
        {id: "2", title: "22"},
        {id: "3", title: "33"}
    ];
    json response = check anydataBindingClient->post("/anydataB/checkStringTable", j);
    common:assertJsonPayload(response, j[0]);
}

@test:Config {}
function testDataBindingWithTableofMapOfStringByType() returns error? {
    json[] j = [
        {id: "1", title: "11"},
        {id: "2", title: "22"},
        {id: "3", title: "33"}
    ];
    json response = check anydataBindingClient->post("/anydataB/checkStringTable", j, mediaType = "application/abc");
    common:assertJsonPayload(response, j[0]);
}

@test:Config {}
function testDataBindingWithTableofMapOfStringByTypeNegative() returns error? {
    json[] j = [
        {id: "1", title: "11"},
        {id: "2", title: "22"},
        {id: "3", title: "33"}
    ];
    http:Response|error response = anydataBindingClient->post("/anydataB/checkIntTable", j);
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        common:assertTrueTextPayload(response.getTextPayload(),
        "data binding failed: {ballerina/lang.value}ConversionError");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingRecord() returns error? {
    json response = check anydataBindingClient->post("/anydataB/checkRecord", {name: "wso2", age: 12});
    common:assertJsonPayload(response, {Key: "wso2", Age: 12});
}

@test:Config {}
function testDataBindingRecordByType() returns error? {
    json response = check anydataBindingClient->post("/anydataB/checkRecord", {name: "wso2", age: 12},
        mediaType = "application/abc");
    common:assertJsonPayload(response, {Key: "wso2", Age: 12});
}

@test:Config {}
function testDataBindingRecordArray() returns error? {
    json j = [{name: "wso2", age: 17}, {name: "bal", age: 4}];
    json response = check anydataBindingClient->post("/anydataB/checkRecordArray", j);
    common:assertJsonPayload(response, j);
}

@test:Config {}
function testDataBindingRecordArrayByType() returns error? {
    json j = [{name: "wso2", age: 17}, {name: "bal", age: 4}];
    json response = check anydataBindingClient->post("/anydataB/checkRecordArray", j, mediaType = "application/abc");
    common:assertJsonPayload(response, j);
}

@test:Config {}
function testDataBindingWithMapOfRecord() returns error? {
    json inPayload = {name: {name: "wso2", age: 17}, team: {name: "bal", age: 4}};
    json response = check anydataBindingClient->post("/anydataB/checkRecordMap", inPayload);
    common:assertJsonPayload(response, {"1": {name: "wso2", age: 17}, "2": {name: "bal", age: 4}});
}

@test:Config {}
function testDataBindingWithMapOfRecordByType() returns error? {
    json inPayload = {name: {name: "wso2", age: 17}, team: {name: "bal", age: 4}};
    json response = check anydataBindingClient->post("/anydataB/checkRecordMap", inPayload, mediaType = "application/abc");
    common:assertJsonPayload(response, {"1": {name: "wso2", age: 17}, "2": {name: "bal", age: 4}});
}

@test:Config {}
function testDataBindingWithTableofRecord() returns error? {
    Person[] j = [
        {name: "wso2", age: 17},
        {name: "bal", age: 4}
    ];
    json response = check anydataBindingClient->post("/anydataB/checkRecordTable", j);
    common:assertJsonPayload(response, j[0]);
}

@test:Config {}
function testDataBindingWithTableofRecordByType() returns error? {
    Person[] j = [
        {name: "wso2", age: 17},
        {name: "bal", age: 4}
    ];
    json response = check anydataBindingClient->post("/anydataB/checkRecordTable", j, mediaType = "application/abc");
    common:assertJsonPayload(response, j[0]);
}

@test:Config {}
function testDataBindingRecordWithTuple() returns error? {
    RestaurantNew restaurant = {
        name: "name1",
        city: "city1",
        address: [10, "street", 9, 12.45, {id: 4012, age: 36}],
        description: "description1",
        menus: [
            {
                _id: 5,
                'type: "LUNCH",
                items: []
            }
        ]
    };
    RestaurantNew response = check anydataBindingClient->post("/anydataB/checkRecordWithTuple", restaurant);
    test:assertEquals(response, restaurant);
}

@test:Config {}
function testDataBindingByteArrayWithJson() {
    json j = "WSO2".toBytes();
    http:Response|error response = anydataBindingClient->post("/anydataB/checkByteArr", j, mediaType = "application/json");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        common:assertTrueTextPayload(response.getTextPayload(),
            "data binding failed: unrecognized token 'WSO2'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingByteArrayWithTextPlain() returns error? {
    string response = check anydataBindingClient->post("/anydataB/checkByteArr", "WSO2".toBytes(),
        mediaType = "text/plain");
    common:assertTextPayload(response, "WSO2");
}

@test:Config {}
function testDataBindingOctetStreamNegative() {
    http:Response|error response = anydataBindingClient->post("/anydataB/checkRecord", "WSO2".toBytes());
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(),
            "data binding failed: incompatible type found: 'http_dispatching_tests:Person'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingByteArrayByType() returns error? {
    json j = "WSO2".toBytes();
    string response = check anydataBindingClient->post("/anydataB/checkByteArr", j, mediaType = "application/abc");
    common:assertTextPayload(response, "WSO2");
}

@test:Config {}
function testDataBindingByteArrayArray() returns error? {
    json j = ["WSO2".toBytes(), "Ballerina".toBytes()];
    string response = check anydataBindingClient->post("/anydataB/checkByteArrArray", j);
    common:assertTextPayload(response, "WSO2");
}

@test:Config {}
function testDataBindingByteArrayArrayByType() returns error? {
    json j = ["WSO2".toBytes(), "Ballerina".toBytes()];
    string response = check anydataBindingClient->post("/anydataB/checkByteArrArray", j, mediaType = "application/abc");
    common:assertTextPayload(response, "WSO2");
}

@test:Config {}
function testDataBindingWithMapOfByteArray() returns error? {
    json inPayload = {name: "WSO2".toBytes(), team: "Ballerina".toBytes()};
    json response = check anydataBindingClient->post("/anydataB/checkByteArrMap", inPayload);
    common:assertJsonPayload(response, {"1": "WSO2", "2": "Ballerina"});
}

@test:Config {}
function testDataBindingWithMapOfByteArrayByType() returns error? {
    json inPayload = {name: "WSO2".toBytes(), team: "Ballerina".toBytes()};
    json response = check anydataBindingClient->post("/anydataB/checkByteArrMap", inPayload, mediaType = "application/abc");
    common:assertJsonPayload(response, {"1": "WSO2", "2": "Ballerina"});
}

@test:Config {}
function testDataBindingWithTableofMapOfByteArray() returns error? {
    json[] j = [
        {id: "WSO2".toBytes(), title: "Company".toBytes()},
        {id: "Ballerina".toBytes(), title: "Language".toBytes()},
        {id: "Srilanka".toBytes(), title: "Country".toBytes()}
    ];
    json response = check anydataBindingClient->post("/anydataB/checkByteArrTable", j);
    common:assertJsonPayload(response, j[0]);
}

@test:Config {}
function testDataBindingWithTableofMapOfByteArrayByType() returns error? {
    json[] j = [
        {id: "WSO2".toBytes(), title: "Company".toBytes()},
        {id: "Ballerina".toBytes(), title: "Language".toBytes()},
        {id: "Srilanka".toBytes(), title: "Country".toBytes()}
    ];
    json response = check anydataBindingClient->post("/anydataB/checkByteArrTable", j, mediaType = "application/abc");
    common:assertJsonPayload(response, j[0]);
}

@test:Config {}
function testDataBindingAXml() returns error? {
    xml j = xml `<name>WSO2</name>`;
    xml response = check anydataBindingClient->post("/anydataB/checkXml", j);
    common:assertXmlPayload(response, j);
}

@test:Config {}
function testDataBindingXmlByType() returns error? {
    xml j = xml `<name>WSO2</name>`;
    xml response = check anydataBindingClient->post("/anydataB/checkXml", j, mediaType = "application/abc");
    common:assertXmlPayload(response, j);
}

@test:Config {}
function testDataBindingXmlNegative() {
    xml j = xml `<name>WSO2</name>`;
    http:Response|error response = anydataBindingClient->post("/anydataB/checkIntMap", j);
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(),
            "data binding failed: incompatible type found: 'map<int>'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// enable after fixing https://github.com/ballerina-platform/ballerina-lang/issues/38715
@test:Config {enable: false}
function testDataBindingXmlArray() {
    xml[] j = [xml `<name>WSO2</name>`, xml `<name>Ballerina</name>`];
    http:Response|error response = anydataBindingClient->post("/anydataB/checkXmlArray", j.toJson());
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertTrueTextPayload(response.getTextPayload(),
            "[\"<name>WSO2</name>\", \"<name>Ballerina</name>\"]");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// enable after fixing https://github.com/ballerina-platform/ballerina-lang/issues/38715
@test:Config {enable: false}
function testDataBindingXmlArrayByType() {
    xml[] j = [xml `<name>WSO2</name>`, xml `<name>Ballerina</name>`];
    http:Response|error response = anydataBindingClient->post("/anydataB/checkXmlArray", j.toJson(),
        mediaType = "application/abc");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertTrueTextPayload(response.getTextPayload(), "[\"<name>WSO2</name>\", \"<name>Ballerina</name>\"]");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// enable after fixing https://github.com/ballerina-platform/ballerina-lang/issues/38715
@test:Config {enable: false}
function testDataBindingWithMapOfXml() {
    xml wso2 = xml `<name>WSO2</name>`;
    xml bal = xml `<name>Ballerina</name>`;
    json inPayload = {name: wso2.toJson(), team: bal.toJson()};
    http:Response|error response = anydataBindingClient->post("/anydataB/checkXmlMap", inPayload);
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertTrueTextPayload(response.getTextPayload(),
            "{\"1\":\"<name>WSO2</name>\", \"2\":\"<name>Ballerina</name>\"}");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// enable after fixing https://github.com/ballerina-platform/ballerina-lang/issues/38715
@test:Config {enable: false}
function testDataBindingWithMapOfXmlByType() returns error? {
    xml wso2 = xml `<name>WSO2</name>`;
    xml bal = xml `<name>Ballerina</name>`;
    json inPayload = {name: wso2.toJson(), team: bal.toJson()};
    http:Response|error response = anydataBindingClient->post("/anydataB/checkXmlMap", inPayload,
        mediaType = "application/abc");
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertTrueTextPayload(response.getTextPayload(),
            "{\"1\":\"<name>WSO2</name>\", \"2\":\"<name>Ballerina</name>\"}");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// enable after fixing https://github.com/ballerina-platform/ballerina-lang/issues/38715
@test:Config {enable: false}
function testDataBindingWithTableofMapOfXml() {
    xml wso2 = xml `<name>WSO2</name>`;
    xml bal = xml `<name>Ballerina</name>`;
    json[] j = [
        {id: wso2.toJson(), title: bal.toJson()}
    ];
    http:Response|error response = anydataBindingClient->post("/anydataB/checkXmlTable", j);
    if response is http:Response {
        test:assertEquals(response.statusCode, 201, msg = "Found unexpected output");
        common:assertTrueTextPayload(response.getTextPayload(),
            "{\"id\":\"<name>WSO2</name>\", \"title\":\"<name>Ballerina</name>\"}");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingWithArrayOfTable() returns error? {
    json[] j1 = [
        {id: 1, title: 11},
        {id: 2, title: 22},
        {id: 3, title: 33}
    ];
    json[] j2 = [
        {id: 11, title: 111},
        {id: 22, title: 222},
        {id: 33, title: 333}
    ];
    json response = check anydataBindingClient->post("/anydataB/checkArrayOfTable", [j1, j2]);
    common:assertJsonPayload(response, j1[0]);
}

@test:Config {}
function testDataBindingWithMapOfTable() returns error? {
    json[] j1 = [
        {id: 1, title: 11},
        {id: 2, title: 22},
        {id: 3, title: 33}
    ];
    json[] j2 = [
        {id: 11, title: 111},
        {id: 22, title: 222},
        {id: 33, title: 333}
    ];
    json response = check anydataBindingClient->post("/anydataB/checkMapOfTable", {name: j1, team: j2});
    common:assertJsonPayload(response, j2[0]);
}

@test:Config {}
function testDataBindingReadonlyRecordArray() returns error? {
    json j = [{name: "wso2", age: 17}, {name: "bal", age: 4}];
    json response = check anydataBindingClient->post("/anydataB/checkReadonlyArr", j);
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", {name: "wso2", age: 17});
}

@test:Config {}
function testDataBindingAnydata() returns error? {
    json j = 12;
    json response = check anydataBindingClient->post("/anydataB/checkAnydata", j);
    common:assertJsonPayload(response, j);
}

@test:Config {}
function testDataBindingUnionWithJson() returns error? {
    json response = check anydataBindingClient->post("/anydataB/checkUnionTypesWithXmlJson", {name: "wso2", age: 12},
    mediaType = "application/json");
    common:assertJsonPayload(response, {result: "It's json"});
}

@test:Config {}
function testDataBindingUnionWithXml() returns error? {
    xml j = xml `<name>WSO2</name>`;
    xml response = check anydataBindingClient->post("/anydataB/checkUnionTypesWithXmlJson", j);
    common:assertXmlPayload(response, j);
}

@test:Config {}
function testDataBindingUnionWithString() returns error? {
    string payload = "hello";
    json response = check anydataBindingClient->post("/anydataB/checkUnionTypesWithStringNil", payload);
    common:assertJsonPayload(response, {result: payload});
}

@test:Config {}
function testDataBindingUnionWithNil() returns error? {
    string payload = "";
    json response = check anydataBindingClient->post("/anydataB/checkUnionTypesWithStringNil", payload);
    common:assertJsonPayload(response, {result: "It's nil"});
}

@test:Config {}
function testDataBindingUnionWithMapOfStringUrlEncodedAndXml() returns error? {
    string inPayload = "name=hello%20go&team=ba%20%23ller%20%40na";
    json response = check anydataBindingClient->post("/anydataB/checkUnionWithStringMapXml", inPayload,
        mediaType = "application/x-www-form-urlencoded");
    common:assertJsonPayload(response, {"1": "hello go", "2": "ba #ller @na"});
}

@test:Config {}
function testDataBindingUnionWithMapOfStringAndXml() returns error? {
    xml j = xml `<name>WSO2</name>`;
    json response = check anydataBindingClient->post("/anydataB/checkUnionWithStringMapXml", j);
    common:assertJsonPayload(response, {result: "It's xml"});
}

@test:Config {}
function testDataBindingUnionByteArrayJsonWithTextPlain() returns error? {
    string response = check anydataBindingClient->post("/anydataB/checkUnionWithByteArrJson", "WSO2".toBytes(),
        mediaType = "text/plain");
    common:assertTextPayload(response, "WSO2");
}

@test:Config {}
function testDataBindingUnionByteArrayJsonWithOctet() returns error? {
    string response = check anydataBindingClient->post("/anydataB/checkUnionWithByteArrJson", "WSO2".toBytes());
    common:assertTextPayload(response, "WSO2");
}

@test:Config {}
function testDataBindingUnionWithRecords() returns error? {
    json response = check anydataBindingClient->post("/anydataB/checkUnionWithRecords", {name: "wso2", age: 12});
    common:assertJsonPayload(response, {Key: "wso2", Age: 12});
}

@test:Config {}
function testDataBindingUnionWithRecordsStocks() returns error? {
    json response = check anydataBindingClient->post("/anydataB/checkUnionWithRecords", {id: 34, price: 4324.65});
    common:assertJsonPayload(response, {Key: 4324.65d, Age: 34});
}

@test:Config {}
function testDataBindingUnionWithJsonAndStringWithAppJson() returns error? {
    json response = check anydataBindingClient->post("/anydataB/checkUnionTypesWithStringJson", {name: "wso2", age: 12},
    mediaType = "application/json");
    common:assertJsonPayload(response, {result: "It's json"});
}

@test:Config {}
function testDataBindingUnionWithJsonAndStringWithTextPlain() returns error? {
    json response = check anydataBindingClient->post("/anydataB/checkUnionTypesWithStringJson", "Hello");
    common:assertJsonPayload(response, {result: "It's string"});
}

@test:Config {}
function testDataBindingUnionStringArrayJsonWithTextPlain() {
    http:Response|error response = anydataBindingClient->post("/anydataB/checkUnionWithStringArrJson", "WSO2");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(),
            "data binding failed: incompatible type found: '(json|string[])'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingUnionWithNilReadonly() returns error? {
    string payload = "";
    json response = check anydataBindingClient->post("/anydataB/checkUnionTypesWithStringNilWithReadonly", payload);
    common:assertJsonPayload(response, {result: "It's nil"});
}

@test:Config {}
function testDataBindingUnionTypesWithReadonlyByteArrWithNil() returns error? {
    string payload = "";
    json response = check anydataBindingClient->post("/anydataB/checkUnionTypesWithReadonlyByteArrWithNil", payload);
    common:assertJsonPayload(response, {result: "It's nil"});
}

@test:Config {}
function testDataBindingSubtypeXmlElement() returns error? {
    xml:Element payload = xml `<placeOrder><order-status>PLACED</order-status><order-id>ORD-1234</order-id></placeOrder>`;
    xml:Element response = check anydataBindingClient->post("/anydataB/checkXmlElement", payload);
    test:assertEquals(response, payload);
}

@test:Config {}
function testDataBindingCustomSubtypeXmlElement() returns error? {
    xml:Element payload = xml `<placeOrder><order-status>PLACED</order-status><order-id>ORD-1234</order-id></placeOrder>`;
    xml:Element response = check anydataBindingClient->post("/anydataB/checkCustomXmlElement", payload);
    test:assertEquals(response, payload);
}

@test:Config {}
function testDataBindingSubtypeStringChar() returns error? {
    string:Char payload = "t";
    string:Char response = check anydataBindingClient->post("/anydataB/checkStrChar", payload);
    test:assertEquals(response, payload);
}

@test:Config {}
function testDataBindingSubtypeIntSigned32() returns error? {
    int:Signed32 payload = 123;
    int:Signed32 response = check anydataBindingClient->post("/anydataB/checkIntSigned32", payload);
    test:assertEquals(response, payload);
}

@test:Config {}
function testDataBindingEnum() returns error? {
    MenuType response = check anydataBindingClient->post("/anydataB/checkEnum", "DINNER");
    test:assertEquals(response, "DINNER");
}

@test:Config {}
function testDataBindingRecordWithEnum() returns error? {
    Restaurant restaurant = {
        name: "name1",
        city: "city1",
        description: "description1",
        menus: [
            {
                _id: 5,
                'type: "LUNCH",
                items: []
            }
        ]
    };
    Restaurant response = check anydataBindingClient->post("/anydataB/checkRecordWithEnum", restaurant);
    test:assertEquals(response, restaurant);
}
