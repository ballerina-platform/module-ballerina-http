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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;
import ballerina/io;
import ballerina/url;

listener http:Listener readonlyQueryEP = new(readonlyQueryTestPort);
final http:Client readonlyQueryClient = check new("http://localhost:" + readonlyQueryTestPort.toString());

service /readonlyQuery on readonlyQueryEP {
    resource function get ofStringArr(readonly & string[] person) returns json {
        string[] name = person;
        if name is readonly & string[] {
            io:println("status: readonly");
            return { status : "readonly", value : name[1] };
        } else {
            io:println("status: non-readonly");
            return { status : "non-readonly", value : name[1] };
        }
    }

    resource function get ofStringNilableArr(readonly & string[]? person) returns json {
        string[]? name = person;
        if name is readonly & string[] {
            io:println("status: readonly");
            return { status : "readonly", value : name[1] };
        } else {
            io:println("status: non-readonly");
            return { status : "non-readonly", value : "Invalid value" };
        }
    }

    resource function get ofIntArr(readonly & int[] person) returns json {
        int[] name = person;
        if name is readonly & int[] {
            io:println("status: readonly");
            return { status : "readonly", value : name[1] };
        } else {
            io:println("status: non-readonly");
            return { status : "non-readonly", value : name[1] };
        }
    }

    resource function get ofMapJson(readonly & map<json> person) returns json {
        map<json> name = person;
        if name is readonly & map<json> {
            io:println("status: readonly");
            return { status : "readonly", value : name };
        } else {
            io:println("status: non-readonly");
            return { status : "non-readonly", value : name };
        }
    }

    resource function get ofMapJsonArr(readonly & map<json>[] person) returns json {
        map<json>[] name = person;
        if name is readonly & map<json>[] {
            io:println("status: readonly");
            return { status : "readonly", value : name };
        } else {
            io:println("status: non-readonly");
            return { status : "non-readonly", value : name };
        }
    }
}

@test:Config {}
function testReadonlyTypeWithQueryStringArray() returns error? {
    json response = check dataBindingClient->get("/readonlyQuery/ofStringArr?person=a,b,c");
    assertJsonValue(response, "status", "readonly");
    assertJsonValue(response, "value", "b");
}

@test:Config {}
function testReadonlyTypeWithQueryStringNilableArray() returns error? {
    json response = check dataBindingClient->get("/readonlyQuery/ofStringNilableArr?person=a,b,c");
    assertJsonValue(response, "status", "readonly");
    assertJsonValue(response, "value", "b");
}

@test:Config {}
function testReadonlyTypeWithQueryIntArray() returns error? {
    json response = check dataBindingClient->get("/readonlyQuery/ofIntArr?person=1,2,3");
    assertJsonValue(response, "status", "readonly");
    assertJsonValue(response, "value", 2);
}

@test:Config {}
function testReadonlyTypeWithQueryMapJson() returns error? {
    map<json> jsonObj = { name : "test", value : "json" };
    string jsonEncoded = check url:encode(jsonObj.toJsonString(), "UTF-8");
    json response = check dataBindingClient->get("/readonlyQuery/ofMapJson?person=" + jsonEncoded);
    assertJsonValue(response, "status", "readonly");
    assertJsonValue(response, "value", jsonObj);
}

@test:Config {}
function testReadonlyTypeWithQueryMapJsonArr() returns error? {
    map<json> jsonObj1 = { name : "test1", value : "json1" };
    map<json> jsonObj2 = { name : "test2", value : "json2" };
    json[] expected = [jsonObj1, jsonObj2];
    string jsonEncoded1 = check url:encode(jsonObj1.toJsonString(), "UTF-8");
    string jsonEncoded2 = check url:encode(jsonObj2.toJsonString(), "UTF-8");
    json response = check dataBindingClient->get("/readonlyQuery/ofMapJsonArr?person=" + jsonEncoded1 + ","
                            + jsonEncoded2);
    assertJsonValue(response, "status", "readonly");
    assertJsonValue(response, "value", expected);
}
