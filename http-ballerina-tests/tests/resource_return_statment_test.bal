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

listener http:Listener resourceReturnTestEP = checkpanic new(resourceReturnTest);
http:Client resourceReturnTestClient = checkpanic new("http://localhost:" + resourceReturnTest.toString());

type RetPerson record {
    string name;
    int age;
};

type RetEmployee record {
    readonly int id;
    string name;
    float salary;
};

type PersonTable table<RetEmployee> key(id);

service http:Service /mytest on resourceReturnTestEP {
    resource function get test1(http:Caller caller) {
        var result = caller->respond("hello");
        return;
    }
    
    resource function get test2() returns string {
        return "world";
    }    
    
    resource function get test2a() returns @http:Payload {mediaType:"text/plain+id"} string {
        return "world";
    }

    resource function get test3() returns json {
        return {hello: "world"};
    }

    resource function get test3a() returns @http:Payload {mediaType:["application/json+123"]} json {
        return {hello: "world"};
    }

    resource function get test4() returns @http:Payload {mediaType:["text/xml", "app/xml"]} xml {
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

    resource function get test7a() returns @http:Payload {mediaType:["text/plain"]} int {
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

    resource function get test12() returns @tainted @http:Payload {mediaType:["application/json+id"]} http:Accepted {
        http:Accepted acc = { body: {hello:"World"}, headers: { xtest: "Elle"} };
        return acc;
    }

    resource function get test13() returns @http:Payload {mediaType:"application/json"} http:Created|http:Ok {
        http:Created cre = { body: {hello:"World"}, headers: { xtest: "Elle"}, mediaType:"application/json+id" };
        return cre;
    }

    resource function get test14() returns http:Created|http:Ok {
        http:Ok ok = { body: "hello world", headers: { xtest: ["Go", "Elle"], ytest: ["foo"]} };
        return ok;
    }

    resource function get test15() returns record {*http:Created; RetPerson body;} {
        RetPerson person = {age:1, name:"Joe"};
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

    resource function get test17() returns @http:Payload {mediaType:["text/plain"]} RetPerson {
        return {age:10, name:"Monica"};
    }

    resource function get test18() returns RetPerson[] {
        return [{age:10, name:"Monica"}, {age:15, name:"Chandler"}];
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
        map<json> jj = {sam: {hello:"world"}, jon: {no:56}};
        return jj;
    }

    resource function get test22() returns map<json>[]|string {
        map<json> jj = {sam: {hello:"world"}, jon: {no:56}};
        return [jj,jj];
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
            @http:Payload {mediaType:"application/custom+json"} http:Gone|http:Response|string {
        if (ret == "gone") {
            http:Gone gone = { body: "hello world", headers: { xtest: ["Go", "Elle"]}, mediaType:"text/plain" };
            return gone;
        }
        if (ret == "response") {
            http:Response resp = new;
            resp.setJsonPayload({jh:"hello"});
            return resp;
        }
        return "hello";
    }
}

@test:Config {}
public function testRespondAndReturnNil() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test1");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "hello");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnString() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test2");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "world");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnStringWithMediaType() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test2a");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), TEXT_PLAIN + "+id");
        assertTextPayload(resp.getTextPayload(), "world");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnJson() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test3");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {hello: "world"});
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnJsonWithMediaType() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test3a");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON + "+123");
        assertJsonPayload(resp.getJsonPayload(), {hello: "world"});
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnXml() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test4");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(resp.getHeader(CONTENT_TYPE), "text/xml");
        test:assertEquals(resp.getXmlPayload(), xml `<book>Hello World</book>`, msg = "Mismatched xml payload");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnByte() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test5");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(resp.getHeader(CONTENT_TYPE), mime:APPLICATION_OCTET_STREAM);
        var blobValue = resp.getBinaryPayload();
        if (blobValue is byte[]) {
            test:assertEquals(strings:fromBytes(blobValue), "Sample Text", msg = "Payload mismatched");
        } else {
            test:assertFail(msg = "Found unexpected output: " +  blobValue.message());
        }
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnResponse() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test6");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        test:assertEquals(resp.getHeader("x-test"), "header");
        assertTextPayload(resp.getTextPayload(), "Hello");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnInt() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test7");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), 32);
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnIntWithMediaType() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test7a");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "56");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnFloat() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test8");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(resp.getJsonPayload(), 3.2456);
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnDecimal() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test9");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        decimal dValue = 3.2;
        assertJsonPayloadtoJsonString(resp.getJsonPayload(), 3.2);
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnBoolean() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test10");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), true);
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnError() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test11");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 500, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "Don't panic. This is to test the error!");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnStatusCodeRecord() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test12");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 202, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON + "+id");
        test:assertEquals(resp.getHeader("xtest"), "Elle");
        assertJsonPayload(resp.getJsonPayload(), {hello: "World"});
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnStatusCodeRecordWithMediaType() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test13");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON + "+id");
        test:assertEquals(resp.getHeader("xtest"), "Elle");
        assertJsonPayload(resp.getJsonPayload(), {hello: "World"});
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnStatusCodeRecordWithArrayOfHeaders() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test14");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        test:assertEquals(resp.getHeader("xtest"), "Go");
        test:assertEquals(resp.getHeader("ytest"), "foo");
        assertTextPayload(resp.getTextPayload(), "hello world");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnInlineRecord() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test15");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), "application/person+json");
        test:assertEquals(resp.getHeader("X-Server"), "myServer");
        assertJsonPayload(resp.getJsonPayload(), {age:1, name:"Joe"});
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnStringArr() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test16");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), ["Abc", "Xyz"]);
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnJsonAsString() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test17");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "{\"name\":\"Monica\", \"age\":10}");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnRecordArr() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test18");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [{"name":"Monica","age":10},{"name":"Chandler","age":15}]);
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnTable() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test19");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(resp.getJsonPayload(), [{"id":1, "name":"John", "salary":300.5}, 
            {"id":2, "name":"Bella", "salary":500.5}]);
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnMapOfInt() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test20");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {"sam":50, "jon":60} );
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnMapOfJson() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test21");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {"sam":{"hello":"world"},"jon":{"no":56}});
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnMapOfJsonArr() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test22");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [{"sam":{"hello":"world"},"jon":{"no":56}},
            {"sam":{"hello":"world"},"jon":{"no":56}}]);
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnTableArr() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test23");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(resp.getJsonPayload(), [[{"id":1, "name":"John", "salary":300.5}, 
            {"id":2, "name":"Bella", "salary":500.5}], [{"id":1, "name":"John", "salary":300.5}, 
            {"id":2, "name":"Bella", "salary":500.5}]] );
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnXmlArr() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test24");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), ["<book>Hello World</book>","<book>Hello World</book>"]);
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnMapOfXml() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test25");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {"sam":"<book>Hello World</book>","jon":"<book>Hello World</book>"});
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testReturnMultipleTypes() {
    http:Request req = new;
    var resp = resourceReturnTestClient->get("/mytest/test26/gone");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 410, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        test:assertEquals(resp.getHeader("xtest"), "Go");
        assertTextPayload(resp.getTextPayload(), "hello world");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test26/response");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {jh:"hello"});
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }

    resp = resourceReturnTestClient->get("/mytest/test26/nothing");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(resp.getHeader(CONTENT_TYPE), "application/custom+json");
        assertTextPayload(resp.getTextPayload(), "hello");
    } else if (resp is error) {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
