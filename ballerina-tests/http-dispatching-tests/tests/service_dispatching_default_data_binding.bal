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

type DDPerson record {|
    readonly int id;
|};

type Pp DDPerson;

final http:Client defaultDBClient = check new ("http://localhost:" + generalPort.toString());

service /default on generalListener {

    resource function post okWithBody(string? xyz, DDPerson abc) returns http:Ok {
       return {body: abc};
    }

    resource function post singleStructured(DDPerson p) returns DDPerson {
        return p; // p is payload param
    }

    resource function post singleStructuredArray(DDPerson[] p) returns string {
        return "done"; // p is payload param
    }

    resource function post singleStructuredTypeRef(Pp p) returns string {
        return "done"; // p is payload param
    }

    resource function post singleStructuredWithBasicType(string q, DDPerson p) returns string {
        return "done"; // p is payload param
    }

    resource function post singleBasicType(string q) returns string {
        return "done"; // q is query param
    }

    resource function post singleBasicTypeArray(string[] q) returns string {
        return "done"; // q is query param
    }
}

@test:Config {}
function testOKWithBody() returns error? {
    DDPerson p = check defaultDBClient->post("/default/okWithBody", {id:234});
    test:assertEquals(p, {id:234});
}

@test:Config {}
function testSingleStructured() returns error? {
    DDPerson p = check defaultDBClient->post("/default/singleStructured", {id:234});
    test:assertEquals(p, {id:234});
}

