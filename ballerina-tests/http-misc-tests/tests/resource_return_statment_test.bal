// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/mime;
import ballerina/lang.'string as strings;
import ballerina/test;
import ballerina/http_test_common as common;

listener http:Listener resourceReturnTestEP = new (resourceReturnTestPort, httpVersion = http:HTTP_1_1);
final http:Client resourceReturnTestClient = check new ("http://localhost:" + resourceReturnTestPort.toString(), httpVersion = http:HTTP_1_1);

public type RetPerson record {
    string name;
    int age;
};

public type RetEmployee record {
    readonly int id;
    string name;
    float salary;
};

type PersonTable table<RetEmployee> key(id);

service http:Service /mytest on resourceReturnTestEP {
    resource function get test1(http:Caller caller) returns error? {
        _ = check caller->respond("hello");
        return;
    }

    resource function get test2() returns string {
        return "world";
    }

    resource function get test2a() returns @http:Payload {mediaType: "text/plain+id"} string {
        return "world";
    }

    resource function get test3() returns json {
        return {hello: "world"};
    }

    resource function get test3a() returns @http:Payload {mediaType: ["application/json+123"]} json {
        return {hello: "world"};
    }

    resource function get test4() returns @http:Payload {mediaType: ["text/xml", "app/xml"]} xml {
        return xml `<book>Hello World</book>`;
    }

    resource function get test5() returns byte[] {
        byte[] binaryValue = "Sample Text".toBytes();
        return binaryValue;
    }

    resource function get test6() returns http:Response {
        http:Response resp = new;
        resp.setTextPayload("Hello");
        resp.statusCode = 201;
        resp.setHeader("x-test", "header");
        return resp;
    }

    resource function get test7() returns int {
        return 32;
    }

    resource function get test7a() returns @http:Payload {mediaType: ["text/plain"]} int {
        return 56;
    }

    resource function get test8() returns float {
        return 3.2456;
    }

    resource function get test9() returns decimal {
        return 3.2;
    }

    resource function get test10() returns boolean {
        return true;
    }

    resource function get test11() returns error {
        return error http:GenericListenerError("Don't panic. This is to test the error!");
    }

    resource function get test12() returns @http:Payload {mediaType: ["application/json+id"]} http:Accepted {
        http:Accepted acc = {body: {hello: "World"}, headers: {xtest: "Elle"}};
        return acc;
    }

    resource function get test13() returns @http:Payload {mediaType: "application/json"} http:Created|http:Ok {
        http:Created cre = {body: {hello: "World"}, headers: {xtest: "Elle"}, mediaType: "application/json+id"};
        return cre;
    }

    resource function get test14() returns http:Created|http:Ok {
        http:Ok ok = {body: "hello world", headers: {xtest: ["Go", "Elle"], ytest: ["foo"]}};
        return ok;
    }

    resource function get test15() returns record {|*http:Created; RetPerson body;|} {
        RetPerson person = {age: 1, name: "Joe"};
        return {
            mediaType: "application/person+json",
            headers: {
                "X-Server": "myServer"
            },
            body: person
        };
    }

    resource function get test16() returns string[] {
        return ["Abc", "Xyz"];
    }

    resource function get test17() returns @http:Payload {mediaType: ["text/plain"]} RetPerson {
        return {age: 10, name: "Monica"};
    }

    resource function get test18() returns RetPerson[] {
        return [{age: 10, name: "Monica"}, {age: 15, name: "Chandler"}];
    }

    resource function get test19() returns PersonTable {
        PersonTable tbPerson = table [
                {id: 1, name: "John", salary: 300.50},
                {id: 2, name: "Bella", salary: 500.50}
            ];
        return tbPerson;
    }

    resource function get test20() returns map<int> {
        map<int> marks = {sam: 50, jon: 60};
        return marks;
    }

    resource function get test21() returns map<json>|string {
        map<json> jj = {sam: {hello: "world"}, jon: {no: 56}};
        return jj;
    }

    resource function get test22() returns map<json>[]|string {
        map<json> jj = {sam: {hello: "world"}, jon: {no: 56}};
        return [jj, jj];
    }

    resource function get test23() returns PersonTable[]? {
        PersonTable tbPerson = table [
                {id: 1, name: "John", salary: 300.50},
                {id: 2, name: "Bella", salary: 500.50}
            ];
        return [tbPerson, tbPerson];
    }

    resource function get test24() returns xml[] {
        xml x1 = xml `<book>Hello World</book>`;
        return [x1, x1];
    }

    resource function get test25() returns map<xml> {
        xml x1 = xml `<book>Hello World</book>`;
        map<xml> xx = {sam: x1, jon: x1};
        return xx;
    }

    resource function get test26/[string ret]() returns
            @http:Payload {mediaType: "application/custom+json"} http:Gone|http:Response|string {
        if ret == "gone" {
            http:Gone gone = {body: "hello world", headers: {xtest: ["Go", "Elle"]}, mediaType: "text/plain"};
            return gone;
        }
        if ret == "response" {
            http:Response resp = new;
            resp.setJsonPayload({jh: "hello"});
            return resp;
        }
        return "hello";
    }

    resource function get test27/[string sType]() returns http:Continue|http:SwitchingProtocols|
            http:NonAuthoritativeInformation|http:ResetContent|http:PartialContent|http:MultipleChoices|
            http:MovedPermanently|http:Found|http:SeeOther|http:NotModified|http:UseProxy|http:TemporaryRedirect|
            http:PermanentRedirect|http:PaymentRequired|http:MethodNotAllowed|http:NotAcceptable|
            http:ProxyAuthenticationRequired|http:RequestTimeout|http:Conflict|http:LengthRequired|
            http:PreconditionFailed|http:PayloadTooLarge|http:UriTooLong|http:UnsupportedMediaType|
            http:RangeNotSatisfiable|http:ExpectationFailed|http:UpgradeRequired|http:TooManyRequests|
            http:RequestHeaderFieldsTooLarge|http:NotImplemented|http:BadGateway|http:ServiceUnavailable|
            http:GatewayTimeout|http:HttpVersionNotSupported|http:Ok {
        match sType {
            "Continue" => {
                http:Continue res = {};
                return res;
            }
            "SwitchingProtocols" => {
                http:SwitchingProtocols res = {};
                return res;
            }
            "NonAuthoritativeInformation" => {
                http:NonAuthoritativeInformation res = {};
                return res;
            }
            "ResetContent" => {
                http:ResetContent res = {};
                return res;
            }
            "PartialContent" => {
                http:PartialContent res = {};
                return res;
            }
            "MultipleChoices" => {
                http:MultipleChoices res = {};
                return res;
            }
            "MovedPermanently" => {
                http:MovedPermanently res = {};
                return res;
            }
            "Found" => {
                http:Found res = {};
                return res;
            }
            "SeeOther" => {
                http:SeeOther res = {};
                return res;
            }
            "NotModified" => {
                http:NotModified res = {};
                return res;
            }
            "UseProxy" => {
                http:UseProxy res = {};
                return res;
            }
            "TemporaryRedirect" => {
                http:TemporaryRedirect res = {};
                return res;
            }
            "PermanentRedirect" => {
                http:PermanentRedirect res = {};
                return res;
            }
            "PaymentRequired" => {
                http:PaymentRequired res = {};
                return res;
            }
            "MethodNotAllowed" => {
                http:MethodNotAllowed res = {};
                return res;
            }
            "NotAcceptable" => {
                http:NotAcceptable res = {};
                return res;
            }
            "ProxyAuthenticationRequired" => {
                http:ProxyAuthenticationRequired res = {};
                return res;
            }
            "RequestTimeout" => {
                http:RequestTimeout res = {};
                return res;
            }
            "Conflict" => {
                http:Conflict res = {};
                return res;
            }
            "LengthRequired" => {
                http:LengthRequired res = {};
                return res;
            }
            "PreconditionFailed" => {
                http:PreconditionFailed res = {};
                return res;
            }
            "PayloadTooLarge" => {
                http:PayloadTooLarge res = {};
                return res;
            }
            "UriTooLong" => {
                http:UriTooLong res = {};
                return res;
            }
            "UnsupportedMediaType" => {
                http:UnsupportedMediaType res = {};
                return res;
            }
            "RangeNotSatisfiable" => {
                http:RangeNotSatisfiable res = {};
                return res;
            }
            "ExpectationFailed" => {
                http:ExpectationFailed res = {};
                return res;
            }
            "UpgradeRequired" => {
                http:UpgradeRequired res = {};
                return res;
            }
            "TooManyRequests" => {
                http:TooManyRequests res = {};
                return res;
            }
            "RequestHeaderFieldsTooLarge" => {
                http:RequestHeaderFieldsTooLarge res = {};
                return res;
            }
            "NotImplemented" => {
                http:NotImplemented res = {};
                return res;
            }
            "BadGateway" => {
                http:BadGateway res = {};
                return res;
            }
            "ServiceUnavailable" => {
                http:ServiceUnavailable res = {};
                return res;
            }
            "GatewayTimeout" => {
                http:GatewayTimeout res = {};
                return res;
            }
            "HttpVersionNotSupported" => {
                http:HttpVersionNotSupported res = {};
                return res;
            }
            _ => {
                http:Ok res = {};
                return res;
            }
        }
    }

    resource function get test28(http:Request req) returns string|error {
        string header = check req.getHeader("filePath");
        return header;
    }

    resource function get test29(http:Caller caller) returns error? {
        _ = check caller->respond("Hello");
        _ = check caller->respond("Hello2"); // return error
        return;
    }

    resource function get test31(http:Caller caller) returns error? {
        check caller->respond("Hello"); // log error
        return;
    }

    resource function get test32(http:Caller caller) returns error? {
        check caller->respond("Hello"); // log error
    }

    resource function get test33() returns http:Ok {
        return {
            headers: {
                "Content-Type": "text/html; charset=UTF-8"
            },
            body: "<h1>HI</h1>"
        };
    }
}

@test:Config {}
public function testRespondAndReturnNil() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test1");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(resp.getTextPayload(), "hello");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnString() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test2");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(resp.getTextPayload(), "world");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnStringWithMediaType() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test2a");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN + "+id");
        common:assertTextPayload(resp.getTextPayload(), "world");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnJson() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test3");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(resp.getJsonPayload(), {hello: "world"});
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnJsonWithMediaType() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test3a");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON + "+123");
        common:assertJsonPayload(resp.getJsonPayload(), {hello: "world"});
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnXml() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test4");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), "text/xml");
        test:assertEquals(resp.getXmlPayload(), xml `<book>Hello World</book>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnByte() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test5");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), mime:APPLICATION_OCTET_STREAM);
        var blobValue = resp.getBinaryPayload();
        if blobValue is byte[] {
            test:assertEquals(strings:fromBytes(blobValue), "Sample Text", msg = "Payload mismatched");
        } else {
            test:assertFail(msg = "Found unexpected output: " + blobValue.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnResponse() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test6");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        test:assertEquals(check resp.getHeader("x-test"), "header");
        common:assertTextPayload(resp.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnInt() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test7");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(resp.getJsonPayload(), 32);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnIntWithMediaType() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test7a");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(resp.getTextPayload(), "56");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnFloat() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test8");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayloadtoJsonString(resp.getJsonPayload(), 3.2456);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnDecimal() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test9");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        decimal dValue = 3.2;
        common:assertJsonPayloadtoJsonString(resp.getJsonPayload(), dValue);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnBoolean() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test10");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(resp.getJsonPayload(), true);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnError() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test11");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 500, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(check resp.getJsonPayload(), "Don't panic. This is to test the error!",
            "Internal Server Error", 500, "/mytest/test11", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnStatusCodeRecord() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test12");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON + "+id");
        test:assertEquals(check resp.getHeader("xtest"), "Elle");
        common:assertJsonPayload(resp.getJsonPayload(), {hello: "World"});
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnStatusCodeRecordWithMediaType() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test13");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON + "+id");
        test:assertEquals(check resp.getHeader("xtest"), "Elle");
        common:assertJsonPayload(resp.getJsonPayload(), {hello: "World"});
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnStatusCodeRecordWithArrayOfHeaders() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test14");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        test:assertEquals(check resp.getHeader("xtest"), "Go");
        test:assertEquals(check resp.getHeader("ytest"), "foo");
        common:assertTextPayload(resp.getTextPayload(), "hello world");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnInlineRecord() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test15");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), "application/person+json");
        test:assertEquals(check resp.getHeader("X-Server"), "myServer");
        common:assertJsonPayload(resp.getJsonPayload(), {age: 1, name: "Joe"});
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnStringArr() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test16");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(resp.getJsonPayload(), ["Abc", "Xyz"]);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnJsonAsString() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test17");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(resp.getTextPayload(), "{\"name\":\"Monica\", \"age\":10}");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnRecordArr() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test18");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(resp.getJsonPayload(), [{"name": "Monica", "age": 10}, {"name": "Chandler", "age": 15}]);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnTable() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test19");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayloadtoJsonString(resp.getJsonPayload(), [
            {"id": 1, "name": "John", "salary": 300.5},
            {"id": 2, "name": "Bella", "salary": 500.5}
        ]);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnMapOfInt() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test20");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(resp.getJsonPayload(), {"sam": 50, "jon": 60});
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnMapOfJson() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test21");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(resp.getJsonPayload(), {"sam": {"hello": "world"}, "jon": {"no": 56}});
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    enable: false
}
public function testReturnMapOfJsonArr() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test22");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(resp.getJsonPayload(), [
            {"sam": {"hello": "world"}, "jon": {"no": 56}},
            {"sam": {"hello": "world"}, "jon": {"no": 56}}
        ]);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    enable: false
}
public function testReturnTableArr() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test23");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayloadtoJsonString(resp.getJsonPayload(), [
            [
                {"id": 1, "name": "John", "salary": 300.5},
                {"id": 2, "name": "Bella", "salary": 500.5}
            ],
            [
                {"id": 1, "name": "John", "salary": 300.5},
                {"id": 2, "name": "Bella", "salary": 500.5}
            ]
        ]);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    enable: false
}
public function testReturnXmlArr() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test24");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(resp.getJsonPayload(), ["<book>Hello World</book>", "<book>Hello World</book>"]);
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {
    enable: false
}
public function testReturnMapOfXml() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test25");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(resp.getJsonPayload(), {"sam": "<book>Hello World</book>", "jon": "<book>Hello World</book>"});
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testReturnMultipleTypes() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test26/gone");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 410, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        test:assertEquals(check resp.getHeader("xtest"), "Go");
        common:assertTextPayload(resp.getTextPayload(), "hello world");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test26/response");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(resp.getJsonPayload(), {jh: "hello"});
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test26/nothing");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), "application/custom+json");
        common:assertTextPayload(resp.getTextPayload(), "hello");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testSwitchingProtocolsStatusCodes() {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test27/SwitchingProtocols");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 101, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testNonAuthoritativeInformationStatusCodes() {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test27/NonAuthoritativeInformation");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 203, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testAllOtherStatusCodes() {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test27/ResetContent");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 205, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/PartialContent");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 206, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/MultipleChoices");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 300, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/MovedPermanently");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 301, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/Found");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 302, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/SeeOther");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 303, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/NotModified");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 304, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/UseProxy");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 305, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/TemporaryRedirect");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 307, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/PermanentRedirect");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 308, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/PaymentRequired");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 402, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/MethodNotAllowed");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 405, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/NotAcceptable");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 406, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/ProxyAuthenticationRequired");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 407, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/RequestTimeout");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 408, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/Conflict");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 409, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/LengthRequired");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 411, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/PreconditionFailed");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 412, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/PayloadTooLarge");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 413, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/UriTooLong");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 414, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/UnsupportedMediaType");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 415, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/RangeNotSatisfiable");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 416, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/ExpectationFailed");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 417, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/UpgradeRequired");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 426, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/TooManyRequests");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 429, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/RequestHeaderFieldsTooLarge");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 431, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/NotImplemented");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 501, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/BadGateway");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 502, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/ServiceUnavailable");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 503, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/GatewayTimeout");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 504, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test27/HttpVersionNotSupported");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 505, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testCheckPanic() {
    string|error resp = resourceReturnTestClient->get("/mytest/test28");
    if resp is error {
        test:assertEquals(resp.message(), "Internal Server Error", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output: string");
    }
}

@test:Config {}
public function testDoubleResponse() {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test29");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(resp.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testCheckErrorAfterResponse() {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test31");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(resp.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testCheckPanicErrorAfterResponse() {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test32");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(resp.getTextPayload(), "Hello");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}

@test:Config {}
public function testContentTypeHeaderInHeaderField() returns error? {
    http:Response|error resp = resourceReturnTestClient->get("/mytest/test33");
    if resp is http:Response {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), "text/html;charset=UTF-8");
        common:assertTextPayload(resp.getTextPayload(), "<h1>HI</h1>");
    } else {
        test:assertFail(msg = "Found unexpected output: " + resp.message());
    }
}
