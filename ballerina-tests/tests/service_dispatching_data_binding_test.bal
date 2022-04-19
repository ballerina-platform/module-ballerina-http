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
import ballerina/lang.'xml as xmllib;
import ballerina/mime;
import ballerina/test;
import ballerina/http;

final http:Client dataBindingClient = check new("http://localhost:" + generalPort.toString());

type Person record {|
    string name;
    int age;
|};

type Stock record {|
    int id;
    float price;
|};

service /dataBinding on generalListener {

    resource function 'default body1(http:Caller caller, @http:Payload string person, http:Request req) returns error? {
        json responseJson = { "Person": person };
        check caller->respond(responseJson);
    }

    resource function post body2/[string key](@http:Payload {mediaType:"text/plain"} string person, http:Caller caller)
            returns error? {
        json responseJson = { Key: key, Person: person };
        check caller->respond(responseJson);
    }

    resource function 'default body3(http:Caller caller, @http:Payload {mediaType:["text/plain"]} json person) returns error? {
        json|error val1 = person.name;
        json|error val2 = person.team;
        json name = val1 is json ? val1 : ();
        json team = val2 is json ? val2 : ();
        check caller->respond({ Key: name, Team: team });
    }

    resource function post body4(@http:Payload xml person, http:Caller caller, http:Request req) returns error? {
        xmllib:Element elem = <xmllib:Element> person;
        string name = <string> elem.getName();
        string team = <string> (person/*).toString();
        check caller->respond({ Key: name, Team: team });
    }

    resource function post body5(http:Caller caller, @http:Payload byte[] person) returns error? {
        http:Response res = new;
        var name = strings:fromBytes(person);
        if (name is string) {
            res.setJsonPayload({ Key: name });
        } else {
            res.setTextPayload("Error occurred while byte array to string conversion");
            res.statusCode = 500;
        }
        check caller->respond(res);
    }

    resource function post body6(http:Caller caller, http:Request req, @http:Payload Person person) returns error? {
        string name = person.name;
        int age = person.age;
        check caller->respond({ Key: name, Age: age });
    }

    resource function post body7(http:Caller caller, http:Request req, @http:Payload Stock person) returns error? {
        check caller->respond();
    }

    resource function post body8(http:Caller caller, @http:Payload Person[] persons) returns error? {
        var jsonPayload = persons.cloneWithType(json);
        if (jsonPayload is json) {
            check caller->respond(jsonPayload);
        } else {
            check caller->respond(jsonPayload.message());
        }
    }

    resource function 'default body9(http:Caller caller, @http:Payload map<string> person) returns error? {
        string? a = person["name"];
        string? b = person["team"];
        json responseJson = { "1": a, "2": b};
        check caller->respond(responseJson);
    }

    resource function 'default body10(http:Caller caller,
            @http:Payload {mediaType: "application/x-www-form-urlencoded"} map<string> person) returns error? {
        string? a = person["name"];
        string? b = person["team"];
        json responseJson = { "1": a, "2": b};
        check caller->respond(responseJson);
    }

    resource function get negative1(http:Caller caller) returns error? {
        lock {
            var err = generalListener.attach(multipleAnnot1, "multipleAnnot1");
            if err is error {
                check caller->respond(err.message());
            } else {
                check caller->respond("ok");
            }
        }
    }

    resource function get negative2(http:Caller caller) returns error? {
        lock {
            var err = generalListener.attach(multipleAnnot2, "multipleAnnot2");
            if err is error {
                check caller->respond(err.message());
            } else {
                check caller->respond("ok");
            }
        }
    }
}

isolated http:Service multipleAnnot1 = service object {
    resource function get annot(@http:Payload {} @http:CallerInfo {} string payload) {
        //...
    }
};

isolated http:Service multipleAnnot2 = service object {
    resource function get annot(@http:Payload {} string payload1, @http:Payload {} string payload2) {
        //...
    }
};

# Album represents data about a record album.
type Album readonly & record {|
    string id;
    string title;
    string artist;
    decimal price;
|};

// albums table to seed record album data.
table<Album> key(id) albums = table [
    {id: "1", title: "Blue Train", artist: "John Coltrane", price: 56.99},
    {id: "2", title: "Jeru", artist: "Gerry Mulligan", price: 17.99},
    {id: "3", title: "Sarah Vaughan and Clifford Brown", artist: "Sarah Vaughan", price: 39.99}
];

service /readonlyRecord on generalListener {
    // Responds with the list of all albums as JSON.
    resource function get albums() returns Album[] {
        return albums.toArray();
    }

    // Adds an album from JSON received in the request body.
    resource function get albums/[string id]() returns Album | http:NotFound {
        Album? album = albums[id];
        if album is () {
            return <http:NotFound>{};
        } else {
            return album;
        }
    }

    // Locates the album whose ID value matches the id
    // parameter sent by the client, then returns that album as a response.
    resource function post albums(@http:Payload Album album) returns Album {
        // Add the new album to the table.
        albums.add(album);
        return album;
    }

    resource function post tableBinding(http:Caller caller, @http:Payload table<Album> key(id) albums) returns error? {
        Album? album = albums["1"];
        check caller->respond(album);
    }
}

//Test data binding with string payload
@test:Config {}
function testDataBindingWithStringPayload() {
    http:Request req = new;
    req.setTextPayload("WSO2");
    http:Response|error response = dataBindingClient->post("/dataBinding/body1", req);
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {Person:"WSO2"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding when path param exists
@test:Config {}
function testDataBindingWhenPathParamExist() {
    http:Request req = new;
    req.setTextPayload("WSO2");
    http:Response|error response = dataBindingClient->post("/dataBinding/body2/hello", req);
    if response is http:Response {
        assertJsonValue(response.getJsonPayload(), "Key", "hello");
        assertJsonValue(response.getJsonPayload(), "Person", "WSO2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with JSON payload
@test:Config {}
function testDataBindingWithJSONPayload() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:"ballerina"});
    http:Response|error response = dataBindingClient->post("/dataBinding/body3", req);
    if response is http:Response {
        assertJsonValue(response.getJsonPayload(), "Key", "WSO2");
        assertJsonValue(response.getJsonPayload(), "Team", "ballerina");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with XML payload
@test:Config {}
function testDataBindingWithXMLPayload() {
    http:Request req = new;
    xml content = xml `<name>WSO2</name>`;
    req.setXmlPayload(content);
    http:Response|error response = dataBindingClient->post("/dataBinding/body4", req);
    if response is http:Response {
        assertJsonValue(response.getJsonPayload(), "Key", "name");
        assertJsonValue(response.getJsonPayload(), "Team", "WSO2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with binary payload
@test:Config {}
function testDataBindingWithBinaryPayload() {
    http:Request req = new;
    req.setBinaryPayload("WSO2".toBytes());
    http:Response|error response = dataBindingClient->post("/dataBinding/body5", req);
    if response is http:Response {
        assertJsonValue(response.getJsonPayload(), "Key", "WSO2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with global custom struct
@test:Config {}
function testDataBindingWithGlobalStruct() {
    http:Request req = new;
    req.setJsonPayload({name:"wso2",age:12});
    http:Response|error response = dataBindingClient->post("/dataBinding/body6", req);
    if response is http:Response {
        assertJsonValue(response.getJsonPayload(), "Key", "wso2");
        assertJsonValue(response.getJsonPayload(), "Age", 12);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with an array of records
@test:Config {}
function testDataBindingWithRecordArray() {
    http:Request req = new;
    req.setJsonPayload([{name:"wso2",age:12}, {name:"ballerina",age:3}]);
    http:Response|error response = dataBindingClient->post("/dataBinding/body8", req);
    if response is http:Response {
        json expected = [{name:"wso2",age:12}, {name:"ballerina",age:3}];
        assertJsonPayload(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding without content-type header
@test:Config {}
function testDataBindingWithoutContentType() {
    http:Request req = new;
    req.setTextPayload("WSO2");
    http:Response|error response = dataBindingClient->post("/dataBinding/body1", req);
    if response is http:Response {
        assertJsonValue(response.getJsonPayload(), "Person", "WSO2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with incompatible content-type leads to an error
@test:Config {}
function testDataBindingIncompatibleJSONPayloadType() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:"EI"});
    req.setHeader(mime:CONTENT_TYPE, mime:TEXT_PLAIN);
    http:Response|error response = dataBindingClient->post("/dataBinding/body3", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(),
            "data binding failed: error PayloadBindingError (\"incompatible type found: 'json'\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with compatible but type different payload
@test:Config {}
function testDataBindingCompatiblePayload() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:"ballerina"});
    req.setHeader(mime:CONTENT_TYPE, mime:TEXT_PLAIN);
    http:Response|error response = dataBindingClient->post("/dataBinding/body5", req);
    if response is http:Response {
        json expected = {name:"WSO2", team:"ballerina"};
        assertJsonValue(response.getJsonPayload(), "Key", expected.toJsonString());
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding without a payload
@test:Config {}
function testDataBindingWithoutPayload() {
    http:Response|error response = dataBindingClient->get("/dataBinding/body1");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "data binding failed: error(\"String payload is null\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingIncompatibleXMLPayload() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:"ballerina"});
    http:Response|error response = dataBindingClient->post("/dataBinding/body4", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTrueTextPayload(response.getTextPayload(),
            "data binding failed: error(\"{ballerina/lang.value}ConversionError\"");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingIncompatibleStructPayload() {
    http:Request req = new;
    req.setTextPayload("ballerina");
    http:Response|error response = dataBindingClient->post("/dataBinding/body6", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(),
        "data binding failed: error PayloadBindingError (\"incompatible type found: 'http_tests:Person'\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingWithEmptyJsonPayload() {
    http:Response|error response = dataBindingClient->get("/dataBinding/body3");
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "data binding failed: error(\"empty JSON document\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingStructWithNoMatchingContent() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:8});
    http:Response|error response = dataBindingClient->post("/dataBinding/body6", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTrueTextPayload(response.getTextPayload(), "data binding failed: error(\"{ballerina/lang");
        assertTrueTextPayload(response.getTextPayload(), ".value}ConversionError\",message=\"'map<json>' ");
        assertTrueTextPayload(response.getTextPayload(), "value cannot be converted to 'http_tests:Person':");
        assertTrueTextPayload(response.getTextPayload(), "missing required field 'age' of type 'int' in record 'http_tests:Person'");
        assertTrueTextPayload(response.getTextPayload(), "field 'team' cannot be added to the closed record 'http_tests:Person'\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingStructWithInvalidTypes() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:8});
    http:Response|error response = dataBindingClient->post("/dataBinding/body7", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTrueTextPayload(response.getTextPayload(), "data binding failed: error(\"{ballerina/lang.value}");
        assertTrueTextPayload(response.getTextPayload(), "'map<json>' value cannot be converted to 'http_tests:Stock'");
        assertTrueTextPayload(response.getTextPayload(), "missing required field 'price' of type 'float' in record 'http_tests:Stock'");
        assertTrueTextPayload(response.getTextPayload(), "missing required field 'id' of type 'int' in record 'http_tests:Stock'");
        assertTrueTextPayload(response.getTextPayload(), "field 'name' cannot be added to the closed record 'http_tests:Stock'");
        assertTrueTextPayload(response.getTextPayload(), "field 'team' cannot be added to the closed record 'http_tests:Stock'\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingWithRecordArrayNegative() {
    http:Request req = new;
    req.setJsonPayload([{name:"wso2",team:12}, {lang:"ballerina",age:3}]);
    http:Response|error response = dataBindingClient->post("/dataBinding/body8", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTrueTextPayload(response.getTextPayload(), "data binding failed: error(\"{ballerina/lang.value}" +
            "ConversionError\",message=\"'json[]' value cannot be converted to 'http_tests:Person[]");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test init error for multiple http annotations in a single param
@test:Config {}
function testMultipleAnnotsInASingleParam() {
    http:Response|error response = dataBindingClient->get("/dataBinding/negative1");
    if response is http:Response {
        assertTextPayload(response.getTextPayload(), "cannot specify more than one http annotation for parameter 'payload'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test init error for multiple Payload annotated params
@test:Config {}
function testMultiplePayloadAnnots() {
    http:Response|error response = dataBindingClient->get("/dataBinding/negative2");
    if response is http:Response {
        assertTextPayload(response.getTextPayload(), "invalid multiple 'http:Payload' annotation usage");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with map of string type
@test:Config {}
function testDataBindingWithMapOfString() {
    http:Request req = new;
    req.setTextPayload("name=hello%20go&team=ba%20%23ller%20%40na", contentType = "application/x-www-form-urlencoded");
    http:Response|error response = dataBindingClient->post("/dataBinding/body9", req);
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {"1":"hello go","2":"ba #ller @na"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with map of string type
@test:Config {}
function testDataBindingWithMapOfStringNegative() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:"ballerina"});
    http:Response|error response = dataBindingClient->post("/dataBinding/body9", req);
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {"1":"WSO2","2":"ballerina"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingWithMapOfStringWithSinglePair() {
    http:Request req = new;
    req.setTextPayload("name=hello%20go", contentType = "application/x-www-form-urlencoded");
    http:Response|error response = dataBindingClient->post("/dataBinding/body9", req);
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {"1":"hello go", "2":()});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingWithMapOfStringEmptyValue() {
    http:Request req = new;
    req.setTextPayload("name=hello%20go&team=", contentType = "application/x-www-form-urlencoded");
    http:Response|error response = dataBindingClient->post("/dataBinding/body9", req);
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {"1":"hello go","2":""});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingWithMapOfStringEmptyKeyValue() {
    http:Request req = new;
    req.setTextPayload("name=hello%20go&=ballerina", contentType = "application/x-www-form-urlencoded");
    http:Response|error response = dataBindingClient->post("/dataBinding/body9", req);
    if response is http:Response {
        assertJsonPayload(response.getJsonPayload(), {"1":"hello go","2":()});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingWithMapOfStringEmptyPayload() {
    http:Request req = new;
    req.setTextPayload("", contentType = "application/x-www-form-urlencoded");
    http:Response|error response = dataBindingClient->post("/dataBinding/body9", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "data binding failed: error(\"String payload is null\")");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDatabindingWithReadOnlyRecordsGetAll() returns error? {
    json expectedPayload = [{"id":"1", "title":"Blue Train", "artist":"John Coltrane", "price":56.99}, {"id":"2", "title":"Jeru", "artist":"Gerry Mulligan", "price":17.99}, {"id":"3", "title":"Sarah Vaughan and Clifford Brown", "artist":"Sarah Vaughan", "price":39.99}];
    http:Response|error response = dataBindingClient->get("/readonlyRecord/albums");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expectedPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDatabindingWithReadOnlyRecordsGetAlbum() returns error? {
    json expectedPayload = {"id":"1", "title":"Blue Train", "artist":"John Coltrane", "price":56.99};
    http:Response|error response = dataBindingClient->get("/readonlyRecord/albums/1");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(response.getJsonPayload(), expectedPayload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn:[testDatabindingWithReadOnlyRecordsGetAll]}
function testDatabindingWithReadOnlyRecordsAddAlbum() returns error? {
    json newAlbum = {"id":"4", "title":"Blackout", "artist":"Scorpions", "price":27.99};
    http:Response|error response = dataBindingClient->post("/readonlyRecord/albums", newAlbum);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(response.getJsonPayload(), newAlbum);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingTable() {
    json[] j = [
                   {id: "1", title: "Blue Train", artist: "John Coltrane", price: 56.99},
                   {id: "2", title: "Jeru", artist: "Gerry Mulligan", price: 17.99},
                   {id: "3", title: "Sarah Vaughan and Clifford Brown", artist: "Sarah Vaughan", price: 39.99}
               ];
    http:Response|error response = dataBindingClient->post("/readonlyRecord/tableBinding", j);
    if response is http:Response {
        json expected = {id: "1", title: "Blue Train", artist: "John Coltrane", price: 56.99d};
        assertJsonPayload(response.getJsonPayload(), expected);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
