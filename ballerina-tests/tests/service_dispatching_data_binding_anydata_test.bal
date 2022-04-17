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

//import ballerina/lang.'string as strings;
//import ballerina/lang.'xml as xmllib;
//import ballerina/mime;
import ballerina/test;
import ballerina/http;
import ballerina/io;

final http:Client anydataBindingClient = check new("http://localhost:" + generalPort.toString());

type Person record {|
    string name;
    int age;
|};

type Stock record {|
    int id;
    float price;
|};

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
        json responseJson = { "1": a, "2": b};
        return responseJson;
    }

    resource function post checkIntTable(http:Caller caller, @http:Payload table<map<int>> tbl) returns error? {
        check caller->respond(tbl);
    }

    // string
    resource function post checkString(@http:Payload string j) returns string {
        return j;
    }

    resource function post checkStringArray(@http:Payload string[] j) returns string[] {
        io:println(j);
        var a = j[0];
        if a is string {
            io:println(a);
        }
        return j;
    }

    resource function post checkStringMap(@http:Payload map<string> person) returns json|error {
        string? a = person["name"];
        string? b = person["team"];
        json responseJson = { "1": a, "2": b};
        return responseJson;
    }

    resource function post checkStringTable(http:Caller caller, @http:Payload table<map<string>> tbl) returns error? {
        check caller->respond(tbl);
    }

    // record
    resource function post checkRecord(@http:Payload Person person) returns json {
        string name = person.name;
        int age = person.age;
        return { Key: name, Age: age };
    }

    resource function post checkRecordArray(@http:Payload Person[] j) returns Person[] {
        return j;
    }
}

//@test:Config {}
function testDataBindingAnInt() returns error? {
    json j = 12;
    json response = check anydataBindingClient->post("/anydataB/checkInt", j);
    assertJsonPayload(response, j);
}

//@test:Config {}
function testDataBindingAnIntByType() returns error? {
    json j = 12;
    json response = check anydataBindingClient->post("/anydataB/checkInt", j, mediaType = "application/abc");
    assertJsonPayload(response, j);
}

//@test:Config {}
function testDataBindingIntArray() returns error? {
    json j = [12, 23];
    json response = check anydataBindingClient->post("/anydataB/checkIntArray", j);
    assertJsonPayload(response, j);
}

//@test:Config {}
function testDataBindingIntArrayByType() returns error? {
    json j = [12, 23];
    json response = check anydataBindingClient->post("/anydataB/checkIntArray", j, mediaType = "application/abc");
    assertJsonPayload(response, j);
}

//@test:Config {}
function testDataBindingWithMapOfInt() returns error? {
    json inPayload = {name:11, team:22};
    json response = check anydataBindingClient->post("/anydataB/checkIntMap", inPayload);
    assertJsonPayload(response, {"1":11, "2":22});
}

//@test:Config {}
function testDataBindingWithMapOfIntByType() returns error? {
    json inPayload = {name:11, team:22};
    json response = check anydataBindingClient->post("/anydataB/checkIntMap", inPayload, mediaType = "application/abc");
    assertJsonPayload(response, {"1":11, "2":22});
}

//@test:Config {}
function testDataBindingWithMapOfIntUrlEncoded() returns error? {
    string inPayload = "name=hello%20go&team=ba%20%23ller%20%40na";
    http:Response|error response = anydataBindingClient->post("/anydataB/checkIntMap", inPayload,
        mediaType = "application/x-www-form-urlencoded");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(),
        "data binding failed: error GenericListenerError (\"incompatible type found: 'map<int>'\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//@test:Config {}
function testDataBindingWithTableofMapOfInt() returns error? {
    json[] j = [
                   {id: 1, title: 11},
                   {id: 2, title: 22},
                   {id: 3, title: 33}
               ];
    json response = check anydataBindingClient->post("/anydataB/checkIntTable", j);
    assertJsonPayload(response, j);
}

//@test:Config {}
function testDataBindingWithTableofMapOfIntByType() returns error? {
    json[] j = [
                   {id: 1, title: 11},
                   {id: 2, title: 22},
                   {id: 3, title: 33}
               ];
    json response = check anydataBindingClient->post("/anydataB/checkIntTable", j, mediaType = "application/abc");
    assertJsonPayload(response, j);
}

//@test:Config {}
function testDataBindingString() returns error? {
    string j = "hello";
    string response = check anydataBindingClient->post("/anydataB/checkString", j);
    assertTextPayload(response, j);
}

//@test:Config {}
function testDataBindingStringWithJson() returns error? {
    json j = "hello";
    string response = check anydataBindingClient->post("/anydataB/checkString", j, mediaType = "application/json");
    assertTextPayload(response, "hello");
}

//@test:Config {}
function testDataBindingStringWithUrlEncoded() returns error? {
    string j = "name=hello%20go&team=ba%20%23ller%20%40na";
    string response = check anydataBindingClient->post("/anydataB/checkString", j,
        mediaType = "application/x-www-form-urlencoded");
    assertTextPayload(response, j);
}

//@test:Config {}
function testDataBindingStringByType() returns error? {
    string j = "hello";
    string response = check anydataBindingClient->post("/anydataB/checkString", j, mediaType = "application/abc");
    assertTextPayload(response, j);
}

//@test:Config {}
function testDataBindingStringArray() returns error? {
    json j = ["Hi", "Hello"];
    json response = check anydataBindingClient->post("/anydataB/checkStringArray", j);
    assertJsonPayload(response, j);
}

//@test:Config {}
function testDataBindingStringArrayByType() returns error? {
    json j = ["Hi", "Hello"];
    json response = check anydataBindingClient->post("/anydataB/checkStringArray", j, mediaType = "application/abc");
    assertJsonPayload(response, j);
}

//@test:Config {}
function testDataBindingWithMapOfString() returns error? {
    json inPayload = {name:"Smith", team:"Aus"};
    json response = check anydataBindingClient->post("/anydataB/checkStringMap", inPayload);
    assertJsonPayload(response, {"1":"Smith", "2":"Aus"});
}

//@test:Config {}
function testDataBindingWithMapOfStringByType() returns error? {
    json inPayload = {name:"Smith", team:"Aus"};
    json response = check anydataBindingClient->post("/anydataB/checkStringMap", inPayload, mediaType = "application/abc");
    assertJsonPayload(response, {"1":"Smith", "2":"Aus"});
}

//@test:Config {}
function testDataBindingWithMapOfStringUrlEncoded() returns error? {
    string inPayload = "name=hello%20go&team=ba%20%23ller%20%40na";
    json response = check anydataBindingClient->post("/anydataB/checkStringMap", inPayload,
        mediaType = "application/x-www-form-urlencoded");
    assertJsonPayload(response, {"1":"hello go", "2":"ba #ller @na"});
}

//@test:Config {}
function testDataBindingWithTableofMapOfString() returns error? {
    json[] j = [
                   {id: "1", title: "11"},
                   {id: "2", title: "22"},
                   {id: "3", title: "33"}
               ];
    json response = check anydataBindingClient->post("/anydataB/checkStringTable", j);
    assertJsonPayload(response, j);
}

//@test:Config {}
function testDataBindingWithTableofMapOfStringByType() returns error? {
    json[] j = [
                   {id: "1", title: "11"},
                   {id: "2", title: "22"},
                   {id: "3", title: "33"}
               ];
    json response = check anydataBindingClient->post("/anydataB/checkStringTable", j, mediaType = "application/abc");
    assertJsonPayload(response, j);
}

//@test:Config {}
function testDataBindingWithTableofMapOfStringByTypeNegative() returns error? {
    json[] j = [
                   {id: "1", title: "11"},
                   {id: "2", title: "22"},
                   {id: "3", title: "33"}
               ];
    http:Response|error response = anydataBindingClient->post("/anydataB/checkIntTable", j);
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTrueTextPayload(response.getTextPayload(),
        "data binding failed: error(\"{ballerina/lang.value}ConversionError\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//@test:Config {}
function testDataBindingRecord() returns error? {
    json response = check anydataBindingClient->post("/anydataB/checkRecord", {name:"wso2",age:12});
    assertJsonPayload(response, {Key:"wso2",Age:12});
}

//@test:Config {}
function testDataBindingRecordByType() returns error? {
    json response = check anydataBindingClient->post("/anydataB/checkRecord", {name:"wso2",age:12},
        mediaType = "application/abc");
    assertJsonPayload(response, {Key:"wso2",Age:12});
}

//@test:Config {}
function testDataBindingRecordArray() returns error? {
    json j = [{name:"wso2",age:17}, {name:"bal",age:4}];
    json response = check anydataBindingClient->post("/anydataB/checkRecordArray", j);
    assertJsonPayload(response, j);
}

@test:Config {}
function testDataBindingRecordArrayByType() returns error? {
    json j = [{name:"wso2",age:17}, {name:"bal",age:4}];
    json response = check anydataBindingClient->post("/anydataB/checkRecordArray", j, mediaType = "application/abc");
    assertJsonPayload(response, j);
}
