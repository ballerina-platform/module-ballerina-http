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

type Person record {|
    readonly int id;
|};

type Pp Person;

service http:Service on new http:Listener(9090) {

    resource function post singleStructured(Person p) returns string {
        return "done"; // p is payload param
    }

    resource function post singleStructuredArray(Person[] p) returns string {
        return "done"; // p is payload param
    }

    resource function post singleStructuredTypeRef(Pp p) returns string {
        return "done"; // p is payload param
    }

    resource function post singleStructuredWithBasicType(string q, Person p) returns string {
        return "done"; // p is payload param
    }

    resource function post singleBasicType(string q) returns string {
        return "done"; // q is query param
    }

    resource function post singleBasicTypeArray(string[] q) returns string {
        return "done"; // q is query param
    }

    resource function post xmlTest(xml p) returns string {
        return "done"; // p is payload param
    }

    resource function post xmlElementTest(xml:Element p) returns string {
        return "done"; // p is payload param
    }

    resource function post testUnion(Person|xml p) returns string {
        return "done"; // p is payload param
    }

    resource function post testNilableUnion(map<json>? p) returns string {
        return "done"; // p is payload param
    }

    resource function post testReadonly(readonly & Person p) returns string {
        return "done";
    }

    resource function post testReadonlyUnion(readonly & (Person|xml) p) returns string {
        return "done";
    }

    resource function post testTable(table<map<int>> abc) returns string {
        return "done";
    }

    resource function post testByteArrArr(byte[][] abc) returns string {
        return "done";
    }

    resource function post testTuple([int, string, Person] abc) returns string {
        return "done";
    }

    resource function post testInlineRecord(@http:Payload record {|string abc;|} abc) returns string {
        return "done";
    }

    resource function post okWithBody(string? xyz, Person abc) returns http:Ok {
        return {body: abc};
    }
}
