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

import ballerina/http;
import ballerina/lang.'string as strings;
import ballerina/lang.'xml as xmllib;
import ballerina/test;

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
    } else {
        test:assertFail(msg = "Test Failed! " + <string>response.message());
    }
}


function assertJsonPayload(json|error payload, json expectValue) {
    if payload is json {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type" + payload.message());
    }
}
