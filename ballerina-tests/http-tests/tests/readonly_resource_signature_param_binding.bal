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
import ballerina/url;
import ballerina/lang.'string as strings;
import ballerina/http_test_common as common;

type ReadonlyPerson record {|
    string name;
    int age;
|};

listener http:Listener readonlyParamEP = new (readonlyQueryTestPort, httpVersion = http:HTTP_1_1);
final http:Client readonlyParamClient = check new ("http://localhost:" + readonlyQueryTestPort.toString(), httpVersion = http:HTTP_1_1);

service /readonlyQuery on readonlyParamEP {
    resource function get ofStringArr(readonly & string[] person) returns json {
        string[] name = person;
        if name is readonly & string[] {
            return {status: "readonly", value: name[1]};
        } else {
            return {status: "non-readonly", value: name[1]};
        }
    }

    resource function get ofStringNilableArr(readonly & string[]? person) returns json {
        string[]? name = person;
        if name is readonly & string[] {
            return {status: "readonly", value: name[1]};
        } else {
            return {status: "non-readonly", value: "Invalid value"};
        }
    }

    resource function get ofIntArr(readonly & int[] person) returns json {
        int[] name = person;
        if name is readonly & int[] {
            return {status: "readonly", value: name[1]};
        } else {
            return {status: "non-readonly", value: name[1]};
        }
    }

    resource function get ofMapJson(readonly & map<json> person) returns json {
        map<json> name = person;
        if name is readonly & map<json> {
            return {status: "readonly", value: name};
        } else {
            return {status: "non-readonly", value: name};
        }
    }

    resource function get ofMapJsonArr(readonly & map<json>[] person) returns json {
        map<json>[] name = person;
        if name is readonly & map<json>[] {
            return {status: "readonly", value: name};
        } else {
            return {status: "non-readonly", value: name};
        }
    }

    resource function get ofMapJsonArrNilable(readonly & map<json>[]? person) returns json {
        map<json>[]? name = person;
        if name is readonly & map<json>[] {
            return {status: "readonly", value: name};
        } else {
            return {status: "non-readonly", value: name};
        }
    }
}

service /readonlyHeader on readonlyParamEP {
    resource function get ofStringArr(@http:Header readonly & string[] person) returns json {
        string[] name = person;
        if name is readonly & string[] {
            return {status: "readonly", value: name[1]};
        } else {
            return {status: "non-readonly", value: name[1]};
        }
    }

    resource function get ofStringArrNilable(@http:Header readonly & string[]? person) returns json {
        string[]? name = person;
        if name is readonly & string[] {
            return {status: "readonly", value: name[1]};
        } else {
            return {status: "non-readonly", value: "invalid value"};
        }
    }
}

service /readonlyPayload on readonlyParamEP {
    resource function post ofRecord(@http:Payload readonly & ReadonlyPerson person) returns json {
        ReadonlyPerson name = person;
        if name is readonly & ReadonlyPerson {
            return {status: "readonly", value: name};
        } else {
            return {status: "non-readonly", value: name};
        }
    }

    resource function post ofJson(@http:Payload readonly & json person) returns json {
        json name = person;
        if name is readonly & json {
            return {status: "readonly", value: name};
        } else {
            return {status: "non-readonly", value: name};
        }
    }

    resource function post ofMapString(@http:Payload readonly & map<string> person) returns json {
        map<string> name = person;
        if name is readonly & map<string> {
            return {status: "readonly", value: name};
        } else {
            return {status: "non-readonly", value: name};
        }
    }

    resource function post ofXml(@http:Payload readonly & xml person) returns json {
        xml name = person;
        if name is readonly & xml {
            return {status: "readonly", value: "xml"};
        } else {
            return {status: "non-readonly", value: "invalid value"};
        }
    }

    resource function post ofByteArr(@http:Payload readonly & byte[] person) returns json|error {
        byte[] name = person;
        if name is readonly & byte[] {
            string value = check strings:fromBytes(person);
            return {status: "readonly", value: value};
        } else {
            return {status: "non-readonly", value: "invalid value"};
        }
    }

    resource function post ofRecArray(@http:Payload readonly & ReadonlyPerson[] person) returns json {
        ReadonlyPerson[] name = person;
        if name is readonly & ReadonlyPerson[] {
            return {status: "readonly", value: name};
        } else {
            return {status: "non-readonly", value: name};
        }
    }
}

@test:Config {}
function testReadonlyTypeWithQueryStringArray() returns error? {
    json response = check readonlyParamClient->get("/readonlyQuery/ofStringArr?person=a,b,c");
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", "b");
}

@test:Config {}
function testReadonlyTypeWithQueryStringNilableArray() returns error? {
    json response = check readonlyParamClient->get("/readonlyQuery/ofStringNilableArr?person=a,b,c");
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", "b");
}

@test:Config {}
function testReadonlyTypeWithQueryIntArray() returns error? {
    json response = check readonlyParamClient->get("/readonlyQuery/ofIntArr?person=1,2,3");
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", 2);
}

@test:Config {}
function testReadonlyTypeWithQueryMapJson() returns error? {
    map<json> jsonObj = {name: "test", value: "json"};
    string jsonEncoded = check url:encode(jsonObj.toJsonString(), "UTF-8");
    json response = check readonlyParamClient->get("/readonlyQuery/ofMapJson?person=" + jsonEncoded);
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", jsonObj);
}

@test:Config {}
function testReadonlyTypeWithQueryMapJsonArr() returns error? {
    map<json> jsonObj1 = {name: "test1", value: "json1"};
    map<json> jsonObj2 = {name: "test2", value: "json2"};
    json[] expected = [jsonObj1, jsonObj2];
    string jsonEncoded1 = check url:encode(jsonObj1.toJsonString(), "UTF-8");
    string jsonEncoded2 = check url:encode(jsonObj2.toJsonString(), "UTF-8");
    json response = check readonlyParamClient->get("/readonlyQuery/ofMapJsonArr?person=" + jsonEncoded1 + ","
                            + jsonEncoded2);
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", expected);
}

@test:Config {}
function testReadonlyTypeWithQueryMapJsonArrNilable() returns error? {
    map<json> jsonObj1 = {name: "test1", value: "json1"};
    map<json> jsonObj2 = {name: "test2", value: "json2"};
    json[] expected = [jsonObj1, jsonObj2];
    string jsonEncoded1 = check url:encode(jsonObj1.toJsonString(), "UTF-8");
    string jsonEncoded2 = check url:encode(jsonObj2.toJsonString(), "UTF-8");
    json response = check readonlyParamClient->get("/readonlyQuery/ofMapJsonArrNilable?person=" + jsonEncoded1 + ","
                            + jsonEncoded2);
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", expected);
}

@test:Config {}
function testReadonlyTypeWithHeaderStringArray() returns error? {
    json response = check readonlyParamClient->get("/readonlyHeader/ofStringArr", {person: ["a", "b", "c"]});
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", "b");
}

@test:Config {}
function testReadonlyTypeWithHeaderStringArrayNilable() returns error? {
    json response = check readonlyParamClient->get("/readonlyHeader/ofStringArrNilable", {person: ["a", "b", "c"]});
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", "b");
}

@test:Config {}
function testReadonlyTypeWithPayloadStringArr() returns error? {
    json j = {name: "wso2", age: 12};
    json response = check readonlyParamClient->post("/readonlyPayload/ofRecord", j);
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", j);
}

@test:Config {}
function testReadonlyTypeWithPayloadJson() returns error? {
    json expected = {name: "WSO2", team: "ballerina"};
    json response = check readonlyParamClient->post("/readonlyPayload/ofJson", expected);
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", expected);
}

@test:Config {}
function testReadonlyTypeWithPayloadMapJson() returns error? {
    http:Request req = new;
    req.setTextPayload("name=hello%20go&team=ba%20%23ller%20%40na", contentType = "application/x-www-form-urlencoded");
    json response = check readonlyParamClient->post("/readonlyPayload/ofMapString", req);
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", {"name": "hello go", "team": "ba #ller @na"});
}

@test:Config {}
function testReadonlyTypeWithPayloadXML() returns error? {
    xml content = xml `<name>WSO2</name>`;
    json response = check readonlyParamClient->post("/readonlyPayload/ofXml", content);
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", "xml");
}

@test:Config {}
function testReadonlyTypeWithPayloadByteArr() returns error? {
    http:Request req = new;
    req.setBinaryPayload("WSO2".toBytes());
    json response = check readonlyParamClient->post("/readonlyPayload/ofByteArr", req);
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", "WSO2");
}

@test:Config {}
function testReadonlyTypeWithPayloadRecordArr() returns error? {
    json[] j = [{name: "wso2", age: 12}, {name: "ballerina", age: 3}];
    json response = check readonlyParamClient->post("/readonlyPayload/ofRecArray", j);
    common:assertJsonValue(response, "status", "readonly");
    common:assertJsonValue(response, "value", j);
}
