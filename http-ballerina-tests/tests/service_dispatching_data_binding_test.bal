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

listener http:Listener dataBindingEP = new(databindingTest);
http:Client dataBindingClient = new("http://localhost:" + databindingTest.toString());

type Person record {|
    string name;
    int age;
|};

type Stock record {|
    int id;
    float price;
|};

service echo on dataBindingEP {

    @http:ResourceConfig {
        body: "person"
    }
    resource function body1(http:Caller caller, http:Request req, string person) {
        json responseJson = { "Person": person };
        checkpanic caller->respond(<@untainted json> responseJson);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/body2/{key}",
        body: "person"
    }
    resource function body2(http:Caller caller, http:Request req, string key, string person) {
        json responseJson = { Key: key, Person: person };
        checkpanic caller->respond(<@untainted json> responseJson);
    }

    @http:ResourceConfig {
        methods: ["GET", "POST"],
        body: "person"
    }
    resource function body3(http:Caller caller, http:Request req, json person) {
        json|error val1 = person.name;
        json|error val2 = person.team;
        json name = val1 is json ? val1 : ();
        json team = val2 is json ? val2 : ();
        checkpanic caller->respond(<@untainted> { Key: name, Team: team });
    }

    @http:ResourceConfig {
        methods: ["POST"],
        body: "person"
    }
    resource function body4(http:Caller caller, http:Request req, xml person) {
        xmllib:Element elem = <xmllib:Element> person;
        string name = <@untainted string> elem.getName();
        string team = <@untainted string> (person/*).toString();
        checkpanic caller->respond({ Key: name, Team: team });
    }

    @http:ResourceConfig {
        methods: ["POST"],
        body: "person"
    }
    resource function body5(http:Caller caller, http:Request req, byte[] person) {
        http:Response res = new;
        var name = <@untainted> strings:fromBytes(person);
        if (name is string) {
            res.setJsonPayload({ Key: name });
        } else {
            res.setTextPayload("Error occurred while byte array to string conversion");
            res.statusCode = 500;
        }
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        body: "person"
    }
    resource function body6(http:Caller caller, http:Request req, Person person) {
        string name = <@untainted string> person.name;
        int age = <@untainted int> person.age;
        checkpanic caller->respond({ Key: name, Age: age });
    }

    @http:ResourceConfig {
        methods: ["POST"],
        body: "person"
    }
    resource function body7(http:Caller caller, http:Request req, Stock person) {
        checkpanic caller->respond();
    }

    @http:ResourceConfig {
        methods: ["POST"],
        body: "persons"
    }
    resource function body8(http:Caller caller, http:Request req, Person[] persons) {
        var jsonPayload = persons.cloneWithType(json);
        if (jsonPayload is json) {
            checkpanic caller->respond(<@untainted json> jsonPayload);
        } else {
            checkpanic caller->respond(<@untainted string> jsonPayload.message());
        }
    }
}

//Test data binding with string payload
@test:Config {}
function testDataBindingWithStringPayload() {
    http:Request req = new;
    req.setTextPayload("WSO2");
    var response = dataBindingClient->post("/echo/body1", req);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {Person:"WSO2"});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding when path param exists
@test:Config {}
function testDataBindingWhenPathParamExist() {
    http:Request req = new;
    req.setTextPayload("WSO2");
    var response = dataBindingClient->post("/echo/body2/hello", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Key", "hello");
        assertJsonValue(response.getJsonPayload(), "Person", "WSO2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with JSON payload
@test:Config {}
function testDataBindingWithJSONPayload() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:"ballerina"});
    var response = dataBindingClient->post("/echo/body3", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Key", "WSO2");
        assertJsonValue(response.getJsonPayload(), "Team", "ballerina");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with XML payload
@test:Config {}
function testDataBindingWithXMLPayload() {
    http:Request req = new;
    xml content = xml `<name>WSO2</name>`;
    req.setXmlPayload(content);
    var response = dataBindingClient->post("/echo/body4", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Key", "name");
        assertJsonValue(response.getJsonPayload(), "Team", "WSO2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with binary payload
@test:Config {}
function testDataBindingWithBinaryPayload() {
    http:Request req = new;
    req.setBinaryPayload("WSO2".toBytes());
    var response = dataBindingClient->post("/echo/body5", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Key", "WSO2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with global custom struct
@test:Config {}
function testDataBindingWithGlobalStruct() {
    http:Request req = new;
    req.setJsonPayload({name:"wso2",age:12});
    var response = dataBindingClient->post("/echo/body6", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Key", "wso2");
        assertJsonValue(response.getJsonPayload(), "Age", 12);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with an array of records
@test:Config {}
function testDataBindingWithRecordArray() {
    http:Request req = new;
    req.setJsonPayload([{name:"wso2",age:12}, {name:"ballerina",age:3}]);
    var response = dataBindingClient->post("/echo/body8", req);
    if (response is http:Response) {
        json expected = [{name:"wso2",age:12}, {name:"ballerina",age:3}];
        assertJsonPayload(response.getJsonPayload(), expected);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding without content-type header
@test:Config {}
function testDataBindingWithoutContentType() {
    http:Request req = new;
    req.setTextPayload("WSO2");
    var response = dataBindingClient->post("/echo/body1", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Person", "WSO2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with incompatible content-type
@test:Config {}
function testDataBindingIncompatibleJSONPayloadType() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:"EI"});
    req.setHeader(mime:CONTENT_TYPE, mime:TEXT_PLAIN);
    var response = dataBindingClient->post("/echo/body3", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Key", "WSO2");
        assertJsonValue(response.getJsonPayload(), "Team", "EI");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding with compatible but type different payload
@test:Config {}
function testDataBindingCompatiblePayload() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:"ballerina"});
    req.setHeader(mime:CONTENT_TYPE, mime:TEXT_PLAIN);
    var response = dataBindingClient->post("/echo/body5", req);
    if (response is http:Response) {
        json expected = {name:"WSO2", team:"ballerina"};
        assertJsonValue(response.getJsonPayload(), "Key", expected.toJsonString());
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test data binding without a payload
@test:Config {}
function testDataBindingWithoutPayload() {
    http:Request req = new;
    var response = dataBindingClient->get("/echo/body1");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "data binding failed: error(\"String payload is null\")");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingIncompatibleXMLPayload() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:"ballerina"});
    var response = dataBindingClient->post("/echo/body4", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTrueTextPayload(response.getTextPayload(), "data binding failed: error(\"failed to create xml: Unexpected character");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingIncompatibleStructPayload() {
    http:Request req = new;
    req.setTextPayload("ballerina");
    var response = dataBindingClient->post("/echo/body6", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTrueTextPayload(response.getTextPayload(), "data binding failed: error(\"unrecognized token 'ballerina'");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingWithEmptyJsonPayload() {
    http:Request req = new;
    var response = dataBindingClient->get("/echo/body3");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Key", ());
        assertJsonValue(response.getJsonPayload(), "Team", ());
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingStructWithNoMatchingContent() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:8});
    var response = dataBindingClient->post("/echo/body6", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "data binding failed: error(\"{ballerina/lang.typedesc}" +
            "ConversionError\",message=\"'map<json>' value cannot be converted to 'http_tests:Person'\")");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingStructWithInvalidTypes() {
    http:Request req = new;
    req.setJsonPayload({name:"WSO2", team:8});
    var response = dataBindingClient->post("/echo/body7", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "data binding failed: error(\"{ballerina/lang.typedesc}" +
            "ConversionError\",message=\"'map<json>' value cannot be converted to 'http_tests:Stock'\")");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testDataBindingWithRecordArrayNegative() {
    http:Request req = new;
    req.setJsonPayload([{name:"wso2",team:12}, {lang:"ballerina",age:3}]);
    var response = dataBindingClient->post("/echo/body8", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "data binding failed: error(\"{ballerina/lang.typedesc}" +
            "ConversionError\",message=\"'json[]' value cannot be converted to 'http_tests:Person[]'\")");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
