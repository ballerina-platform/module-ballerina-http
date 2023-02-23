// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/url;

type DDPerson record {|
    readonly int id;
|};

type Pp DDPerson;

final http:Client defaultDBClient = check new ("http://localhost:" + generalPort.toString());

service /default on generalListener {

    resource function post okWithBody(string? xyz, DDPerson abc) returns http:Ok {
        return {body: abc};
    }

    resource function post singleStructured(DDPerson? p) returns DDPerson? {
        return p; // p is payload param
    }

    resource function post singleStructuredArray(DDPerson[] p) returns DDPerson[] {
        return p; // p is payload param
    }

    resource function post singleStructuredTypeRef(Pp p) returns Pp {
        return p; // p is payload param
    }

    resource function post singleStructuredWithBasicType(string q, DDPerson p) returns map<json> {
        return {person: p, query: q}; // p is payload param
    }

        resource function post singleStructuredWithHeaderParam(@http:Header string h, DDPerson p) returns map<json> {
        return {person: p, header: h}; // p is payload param
    }

    resource function post singleBasicType(string q) returns string {
        return q; // q is query param
    }

    resource function post singleBasicTypeArray(string[] q) returns string[] {
        return q; // q is query param
    }

    resource function post singlePayloadBasicType(@http:Payload string p) returns string {
        return p; // p is payload param
    }

    resource function post singlePayloadBasicTypeArray(@http:Payload string[] p) returns string[] {
        return p; // p is payload param
    }

    resource function post queryLikeMapJson(map<json> p) returns map<json> {
        return p; // p is payload param
    }

    resource function post queryParamCheck(@http:Query map<json> q) returns map<json> {
        return q; // q is payload param
    }
}

@test:Config {}
function testQueryType() returns error? {
    map<json> jsonObj = {name: "test", value: "json"};
    string jsonEncoded = check url:encode(jsonObj.toJsonString(), "UTF-8");
    map<json> p = check defaultDBClient->post("/default/queryParamCheck?q=" + jsonEncoded, {name: "Payload", value: "MapJson"});
    test:assertEquals(p, {name: "test", value: "json"});
}


@test:Config {}
function testQueryLikePayloadType() returns error? {
    map<json> jsonObj = {name: "test", value: "json"};
    string jsonEncoded = check url:encode(jsonObj.toJsonString(), "UTF-8");
    map<json> p = check defaultDBClient->post("/default/queryLikeMapJson?q=" + jsonEncoded, {name: "Payload", value: "MapJson"});
    test:assertEquals(p, {name: "Payload", value: "MapJson"});
}

@test:Config {}
function testSinglePayloadBasicTypeArray() returns error? {
    string[] p = check defaultDBClient->post("/default/singlePayloadBasicTypeArray?q=hello,go", ["ballerina","lang"], {h:"this_is_header"});
    test:assertEquals(p[0], "ballerina");
}

@test:Config {}
function testSinglePayloadBasicType() returns error? {
    string p = check defaultDBClient->post("/default/singlePayloadBasicType?q=hello", "ballerina", {h:"this_is_header"});
    test:assertEquals(p, "ballerina");
}


@test:Config {}
function testSingleBasicTypeArray() returns error? {
    string[] p = check defaultDBClient->post("/default/singleBasicTypeArray?q=hello,go", ["ballerina","lang"], {h:"this_is_header"});
    test:assertEquals(p[0], "hello");
}

@test:Config {}
function testSingleBasicType() returns error? {
    string p = check defaultDBClient->post("/default/singleBasicType?q=hello", "ballerina", {h:"this_is_header"});
    test:assertEquals(p, "hello");
}

@test:Config {}
function testSingleStructuredWithHeaderParam() returns error? {
    map<json> p = check defaultDBClient->post("/default/singleStructuredWithHeaderParam", {id: 234}, {h:"this_is_header"});
    test:assertEquals(p, {person: {id: 234}, header: "this_is_header"});
}

@test:Config {}
function testSingleStructuredWithBasicType() returns error? {
    map<json> p = check defaultDBClient->post("/default/singleStructuredWithBasicType?q=hello", {id: 234});
    test:assertEquals(p, {person: {id: 234}, query: "hello"});
}

@test:Config {}
function testSingleStructuredTypeRef() returns error? {
    DDPerson p = check defaultDBClient->post("/default/singleStructuredTypeRef", {id: 234});
    test:assertEquals(p, {id: 234});
}

@test:Config {}
function testSingleStructuredArray() returns error? {
    DDPerson[] p = check defaultDBClient->post("/default/singleStructuredArray", [{id: 234}, {id: 345}]);
    test:assertEquals(p, [{id: 234}, {id: 345}]);
}

@test:Config {}
function testOKWithBody() returns error? {
    DDPerson p = check defaultDBClient->post("/default/okWithBody", {id: 234});
    test:assertEquals(p, {id: 234});
}

@test:Config {}
function testSingleStructured() returns error? {
    DDPerson p = check defaultDBClient->post("/default/singleStructured", {id: 234});
    test:assertEquals(p, {id: 234});
}
