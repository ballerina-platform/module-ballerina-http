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

import ballerina/http;
import ballerina/constraint;
import ballerina/url;
import ballerina/http_test_common as common;
import ballerina/test;

@constraint:Int {minValue: 1, maxValue: 100}
type Id int;

@constraint:String {pattern: re `[a-zA-Z]+`}
type Path string;

type User1 record {
    Id id;
    string name;
    Age age?;
};

@constraint:String {minLength: 2, maxLength: 20}
type UserName string;

@constraint:Array {minLength: 2, maxLength: 5}
type UserNames UserName[];

@constraint:Int {minValue: 18, maxValue: 50}
type Age int;

type UserDetails1 record {|
    @constraint:String {minLength: 2, maxLength: 20}
    string name;
    Age age;
|};

type UserDetails2 record {|
    @constraint:String {minLength: 2, maxLength: 20}
    string xname;
    @constraint:Array {maxLength: 2}
    Age[] xages;
|};

type Path1 Path|UserName;
type Path2 UserName|Path;

service on new http:Listener(resourceParamConstraintValidationTestPort) {

    resource function get users/[Id id]() returns User1 {
        return {id: id, name: "John"};
    }

    resource function get [Path... path]() returns string[] {
        return path;
    }

    resource function get users1(UserName name) returns User1 {
        return {id: 1, name: name};
    }

    resource function get users2(UserName? name) returns User1 {
        return {id: 1, name: name ?: "james"};
    }

    resource function get users3(UserName name = "a") returns User1 {
        return {id: 1, name: name};
    }

    resource function get users4/v1(UserName[] names) returns User1[] {
        User1[] users = [];
        foreach var name in names {
            users.push({id: 1, name: name});
        }
        return users;
    }

    resource function get users4/v2(UserNames names) returns User1[] {
        User1[] users = [];
        foreach var name in names {
            users.push({id: 1, name: name});
        }
        return users;
    }

    resource function get users5(UserDetails1 details) returns User1 {
        return {id: 1, name: details.name};
    }

    resource function get users6(@http:Header UserName x\-name) returns User1 {
        return {id: 1, name: x\-name};
    }

    resource function get users7(@http:Header UserName? x\-name) returns User1 {
        return {id: 1, name: x\-name ?: "james"};
    }

    resource function get users8(@http:Header UserName x\-name = "a") returns User1 {
        return {id: 1, name: x\-name};
    }

    resource function get users9(@http:Header UserNames x\-names) returns User1[] {
        User1[] users = [];
        foreach var name in x\-names {
            users.push({id: 1, name: name});
        }
        return users;
    }

    resource function get users10(@http:Header UserDetails2 details) returns User1|User1[] {
        string name = details.xname;
        Age[]? ages = details.xages;
        if ages is () {
            return {id: 1, name: name};
        } else {
            User1[] users = [];
            int id = 0;
            foreach var age in ages {
                users.push({id: id, name: name, "age": age});
                id += 1;
            }
            return users;
        }
    }

    resource function get users/v1(Id|Age query) returns User1 {
        return {id: query, name: "John", age: query};
    }

    resource function get users/v2(Age|Id query) returns User1 {
        return {id: query, name: "John", age: query};
    }
}

final http:Client constraintResourceParamValidationClient = check new("http://localhost:" + resourceParamConstraintValidationTestPort.toString());

@test:Config {}
function testPathConstraintType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users/'0;
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "path validation failed: Validation failed for '$:minValue' constraint(s).");

    res = check constraintResourceParamValidationClient->/users/'10;
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users/'110;
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "path validation failed: Validation failed for '$:maxValue' constraint(s).");
}

@test:Config {}
function testPathConstraintRestType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/pathOne/pathTwo/pathThree;
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/path/'123/hello/t1m3;
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "path validation failed: Validation failed for '$[1]:pattern','$[3]:pattern' constraint(s).");
}

@test:Config {}
function testQueryConstraintType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users1(name = "");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users1(name = "Joe");
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users1(name = "This is a invalid username");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:maxLength' constraint(s).");
}

@test:Config {}
function testQueryConstraintNilableType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users2;
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users2(name = "J");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users2(name = "Joe");
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users2(name = "This is a invalid username");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:maxLength' constraint(s).");
}

@test:Config {}
function testQueryConstraintDefaultableType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users3;
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users3(name = "J");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users3(name = "Joe");
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users3(name = "This is a invalid username");
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:maxLength' constraint(s).");
}

@test:Config {}
function testQueryArrayConstraintType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users4/v1(names = ["Joe"]);
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users4/v1(names = ["Joe", "J", "This is a invalid username"]);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$[1]:minLength','$[2]:maxLength' constraint(s).");
}

@test:Config {}
function testQueryConstraintArrayType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users4/v2(names = ["Joe"]);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users4/v2(names = ["Joe", "Jane"]);
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users4/v2(names = ["Joe", "J", "This is a invalid username"]);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$[1]:minLength','$[2]:maxLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users4/v2(names = ["Joe", "Jane", "John", "David", "James", "Robert"]);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:maxLength' constraint(s).");
}

@test:Config {}
function testQueryConstraintMapType() returns error? {
    UserDetails1 details = {name: "Joe", age: 25};
    string encodedQuery = check url:encode(details.toJsonString(), "UTF-8");
    http:Response res = check constraintResourceParamValidationClient->/users5(details = encodedQuery);
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    details.name = "This is a invalid username";
    details.age = 5;
    encodedQuery = check url:encode(details.toJsonString(), "UTF-8");
    res = check constraintResourceParamValidationClient->/users5(details = encodedQuery);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$.age:minValue','$.name:maxLength' constraint(s).");
}

@test:Config {}
function testHeaderConstraintType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users6({x\-name: "Joe"});
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users6({x\-name: "J"});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users6({x\-name: "This is a invalid username"});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$:maxLength' constraint(s).");
}

@test:Config {}
function testHeaderConstraintNilableType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users7;
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users7({x\-name: "J"});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users7({x\-name: "Joe"});
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users7({x\-name: "This is a invalid username"});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$:maxLength' constraint(s).");
}

// TODO: Enable this after supporting defaultable types for header parameters
@test:Config {enable: false}
function testHeaderConstraintDefaultableType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users8;
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users8({x\-name: "J"});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users8({x\-name: "Joe"});
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users8({x\-name: "This is a invalid username"});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$:maxLength' constraint(s).");
}

@test:Config {}
function testHeaderConstraintArrayType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users9({x\-names: ["Joe"]});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users9({x\-names: ["Joe", "Jane"]});
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users9({x\-names: ["Joe", "J", "This is a invalid username"]});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$[1]:minLength','$[2]:maxLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users9({x\-names: ["Joe", "Jane", "John", "David", "James", "Robert"]});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$:maxLength' constraint(s).");
}

@test:Config {}
function testHeaderConstraintRecordType() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users10({"xname": "Joe", "xages": ["25"]});
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users10({"xname": "Joe", "xages": ["25", "20", "50"]});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$.xages:maxLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users10({"xname": "J", "xages": ["25", "20", "50"]});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$.xages:maxLength','$.xname:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users10({"xname": "J", "xages": ["25", "17", "50"]});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$.xages:maxLength','$.xages[1]:minValue','$.xname:minLength' constraint(s).");

    res = check constraintResourceParamValidationClient->/users10({"xname": "Joe", "xages": ["25", "17"]});
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "header validation failed: Validation failed for '$.xages[1]:minValue' constraint(s).");
}

@test:Config {}
function testConstraintUnionType1() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users/v1(query = 10);
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users/v1(query = 0);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:minValue' constraint(s).");

    res = check constraintResourceParamValidationClient->/users/v1(query = 55);
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users/v1(query = 110);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:maxValue' constraint(s).");
}

@test:Config {}
function testConstraintUnionType2() returns error? {
    http:Response res = check constraintResourceParamValidationClient->/users/v2(query = 25);
    test:assertEquals(res.statusCode, 200, "Status code mismatched");

    res = check constraintResourceParamValidationClient->/users/v2(query = 10);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:minValue' constraint(s).");

    res = check constraintResourceParamValidationClient->/users/v2(query = 55);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:maxValue' constraint(s).");

    res = check constraintResourceParamValidationClient->/users/v2(query = 110);
    test:assertEquals(res.statusCode, 400, "Status code mismatched");
    common:assertTextPayload(res.getTextPayload(), "query validation failed: Validation failed for '$:maxValue' constraint(s).");
}
