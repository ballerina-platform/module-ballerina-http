// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;

type Person record {|
    readonly int id;
    string name;
|};

type RetPerson record {
    string name;
    int age;
};

type PersonTable table<Person> key(id);

service http:Service on new http:Listener(9090) {
    resource function get greeting() returns int|error|string {
        return error http:Error("hello") ;
    }

    resource function get greeting2() returns http:Error {
        return error http:ListenerError("hello") ;
    }

    resource function post greeting3() returns () {
        // Request hangs without a response
        return;
    }

    resource function get greeting4() returns http:Client { // Compiler error
        http:Client httpClient = checkpanic new("path");
        return httpClient;
    }

    resource function get greeting5() returns Person {
        return {id:123, name: "john"};
    }

    resource function get greeting6() returns string[] {
        return ["Abc", "Xyz"];
    }

    resource function get greeting7() returns int[] {
        return [15, 34];
    }

    resource function get greeting8() returns error[] { // Compiler error
        error e1 = error http:ListenerError("hello1");
        error e2 = error http:ListenerError("hello2");
        return [e1, e2];
    }

    resource function get greeting9() returns byte[] {
        byte[] binaryValue = "Sample Text".toBytes();
        return binaryValue;
    }

    resource function get greeting10() returns map<string> {
        return {};
    }

    resource function get greeting11() returns PersonTable {
        PersonTable tbPerson = table [
            {id: 1, name: "John"},
            {id: 2, name: "Bella"}
        ];
        return tbPerson;
    }

    resource function get greeting12() returns table<Person> key(id) {
        PersonTable tbPerson = table [
            {id: 1, name: "John"},
            {id: 2, name: "Bella"}
        ];
        return tbPerson;
    }

    resource function get greeting13() returns map<http:Client> {
        http:Client httpClient = checkpanic new("path");
        return {name:httpClient};
    }

    resource function get greeting14() returns http:Ok {
        return {};
    }

    resource function get greeting15() returns Person[] {
        return [{id:123, name: "john"}, {id:124, name: "khan"}];
    }

    resource function post greeting16() returns @http:Payload {mediaType:["application/json+123"]} json {
        return {hello: "world"};
    }

    resource function post greeting17() returns @http:Payload {mediaType:["text/xml", "app/xml"]} xml {
        return xml `<book>Hello World</book>`;
    }

    resource function get greeting18() returns http:Response {
        http:Response resp = new;
        return resp;
    }

    resource function post greeting19() returns @http:Payload {mediaType:["text/plain"]} int {
        return 56;
    }

    resource function get greeting20() returns float {
        return 3.2456;
    }

    resource function get greeting21() returns decimal {
        return 3.2;
    }

    resource function get greeting22() returns boolean {
        return true;
    }

    resource function post greeting23() returns @http:Payload {mediaType:"application/json"} http:Created|http:Ok {
        http:Created cre = { body: {hello:"World"}, headers: { xtest: "Elle"}, mediaType:"application/json+id" };
        return cre;
    }

    resource function get greeting24() returns record {|*http:Created; RetPerson body;|} {
        RetPerson person = {age:1, name:"Joe"};
        return {
            mediaType: "application/person+json",
            headers: {
                "X-Server": "myServer"
            },
            body: person
        };
    }

    resource function get greeting25() returns PersonTable[] {
        PersonTable tbPerson = table [
            {id: 1, name: "John"},
            {id: 2, name: "Bella"}
        ];
        return [tbPerson, tbPerson];
    }

    resource function get greeting26() returns map<json>[]|string {
        map<json> jj = {sam: {hello:"world"}, jon: {no:56}};
        return [jj,jj];
    }
}
