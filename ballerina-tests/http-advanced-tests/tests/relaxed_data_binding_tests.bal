// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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

type Citizen record {
    int id;
    string name;
    string address?;
};

type Student record {|
    string name;
    string module;
    string grade?;
|};

type Teacher record {
    int id;
    string name;
    string? subject;
};

listener http:Listener laxDataBindingEP = new (laxDataBindingTestPort, httpVersion = http:HTTP_2_0);
final http:Client laxClient = check new ("http://localhost:" + laxDataBindingTestPort.toString(), {
    httpVersion: http:HTTP_2_0,
    laxDataBinding: true
});

@http:ServiceConfig {
    laxDataBinding: true
}
service /people on laxDataBindingEP {

    resource function post test1(@http:Payload Citizen citizen) returns Citizen {
        return citizen;
    }

    resource function post test2(@http:Payload Student student) returns Student {
        return student;
    }

    resource function post test3(@http:Payload Teacher teacher) returns Teacher {
        return teacher;
    }

    resource function get test4() returns json {
        return {
            "id": 3001,
            "name": "Sachin",
            "address": null
        };
    }

    resource function get test5() returns json {
        return {
            "id": 1001,
            "name": "Anna"
        };
    }

    resource function get test6() returns json {
        return {
            "name": "Sumudu",
            "module": "DSA",
            "grade": null,
            "rank": "1",
            "classification": "unknown"
        };
    }
}

@test:Config
function testNullForOptionalField() returns error? {
    Citizen expectedPayload = {"id": 3001, "name": "Sachin", "address": null};
    Citizen response = check laxClient->/people/test1.post({"id": 3001, "name": "Sachin", "address": null});
    test:assertEquals(response, expectedPayload);
}

@test:Config
function testMissingOptionalField() returns error? {
    Citizen expectedPayload = {"id": 3001, "name": "Sachin"};
    Citizen reponse = check laxClient->/people/test1.post({"id": 3001, "name": "Sachin"});
    test:assertEquals(reponse, expectedPayload);
}

@test:Config
function testExtraFieldsIgnored() returns error? {
    Student expectedPayload = {"name": "Sachin", "module": "OOP", "grade": null};
    Student reponse = check laxClient->/people/test2.post({
        "name": "Sachin",
        "module": "OOP",
        "grade": null,
        "rank": "1",
        "classification": "unknown"
    });
    test:assertEquals(reponse, expectedPayload);
}

@test:Config
function testMissingRequiredField() returns error? {
    Teacher expectedPayload = {"id": 3001, "name": "Anna", "subject": null};
    Teacher response = check laxClient->/people/test3.post({"id": 3001, "name": "Anna"});
    test:assertEquals(response, expectedPayload);
}

@test:Config
function testNullForRequiredField() returns error? {
    Teacher expectedPayload = {"id": 3001, "name": "Anna", "subject": null};
    Teacher response = check laxClient->/people/test3.post({ "id": 3001, "name": "Anna", "subject": null});
    test:assertEquals(response, expectedPayload);
}

@test:Config
function testNullForOptionalFieldClient() returns error? {
    Citizen expectedPayload = {
        "id": 3001,
        "name": "Sachin",
        "address": null
    };
    Citizen response = check laxClient->/people/test4;
    test:assertEquals(response, expectedPayload);
}

@test:Config
function testMissingRequiredFieldClient() returns error? {
    Teacher expectedPayload = {
        "id": 1001,
        "name": "Anna",
        "subject": null
    };
    Teacher response = check laxClient->/people/test5;
    test:assertEquals(response, expectedPayload);
}

@test:Config
function testExtraFieldsIgnoreClient() returns error? {
    Student expectedPayload = {"name": "Sumudu", "module": "DSA", "grade": null};
    Student response = check laxClient->/people/test6;
    test:assertEquals(response, expectedPayload);
}
