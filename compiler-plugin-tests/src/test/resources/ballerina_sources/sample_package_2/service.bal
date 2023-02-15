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
type newXml xml;
type newXmlElement xml:Element;

type ReturnValueStrNilArray string?[]?;
type ReturnValuePrimitiveUnionArr (string|int)[];
type ReturnValueNilPrimitiveUnionArr (string|int?)[]?;
type ReturnValueNilPrimitiveUnionArrAlt (string?|int?)[]?;

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

    resource function get greetings(http:Request req) returns readonly & error[] {
        return [error("error1"), error("error2")];
    }

    resource function get element() returns xml:Element {
        return xml `<placeOrder>
                          <order-status>PLACED</order-status>
                          <order-id>ORD-1234</order-id>
                    </placeOrder>`;
    }

    resource function get text() returns xml:Text|json {
        return {a:"hello"};
    }

    resource function get comment() returns xml:Comment|json {
        return {a:"hello"};
    }

    resource function get processingInstruction() returns xml:ProcessingInstruction|json {
        return {a:"hello"};
    }

    resource function get strChar() returns string:Char {
        return "a";
    }

    resource function get intSigned32() returns int:Signed32 {
        return -2147483648;
    }

    resource function get intSigned16() returns int:Signed16 {
        return -32768;
    }

    resource function get intSigned8() returns int:Signed8 {
        return -128;
    }

    resource function get intUnsigned32() returns int:Unsigned32 {
        return 4294967295;
    }

    resource function get intUnsigned16() returns int:Unsigned16 {
        return 65535;
    }

    resource function get intUnsigned8() returns int:Unsigned8 {
        return 255;
    }

    resource function get customSubtypes() returns newXml {
        return xml`<name>Tharmigan</name>`;
    }

    resource function get customXmlElement() returns newXmlElement {
        return xml `<placeOrder>
                          <order-status>PLACED</order-status>
                          <order-id>ORD-1234</order-id>
                    </placeOrder>`;
    }

    resource function get lift04(string id) returns ReturnValueStrNilArray {
        string?[]? values = ["val1", ()];
        return values;
    }

    resource function get lift10(string id) returns ReturnValuePrimitiveUnionArr {
        (string|int)[] values = ["val", 1];
        return values;
    }

    resource function get lift11(string id) returns ReturnValueNilPrimitiveUnionArr {
        (string|int?)[]? values = ["val", 1, ()];
        return values;
    }

    resource function get lift12(string id) returns ReturnValueNilPrimitiveUnionArrAlt {
        (string|int?)[]? values = ["val", 1, ()];
        return values;
    }
}
