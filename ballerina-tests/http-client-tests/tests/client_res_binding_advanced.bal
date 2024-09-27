// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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
import ballerina/mime;
import ballerina/test;

service /api on new http:Listener(resBindingAdvancedPort) {

    resource function get 'string() returns string {
        return "Hello, World!";
    }

    resource function get urlEncoded() returns http:Ok {
        return {
            mediaType: mime:APPLICATION_FORM_URLENCODED,
            body: {"name": "John", "age": "23"}
        };
    }

    resource function get 'json() returns json {
        return {"name": "John", "age": "23"};
    }

    resource function get 'xml() returns xml {
        return xml `<message>Hello, World!</message>`;
    }

    resource function get byteArray() returns byte[] {
        return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    }

    resource function get overwriteNames/jsont(boolean y) returns json|TPerson {
        if y {
            return {"name": "John", "age": "23"};
        }
        TPerson t = {firstName: "Potter", personAge: "30"};
        return t;
    }

    resource function post overwriteNames/jsont(TPerson payload) returns TPerson {
        return payload;
    }

    resource function get status/code() returns OKPerson {
        return {body: {firstName: "Potter", personAge: "40"}};
    }
}

final http:Client clientEP = check new (string `localhost:${resBindingAdvancedPort}/api`);

@test:Config {}
function testAnydataResBindingWithDifferentContentType() returns error? {
    anydata response = check clientEP->/'string;
    test:assertEquals(response, "Hello, World!");

    response = check clientEP->/urlEncoded;
    map<string> expected = {"name": "John", "age": "23"};
    test:assertEquals(response, expected);

    response = check clientEP->/'json;
    test:assertEquals(response, expected);

    response = check clientEP->/'xml;
    test:assertEquals(response, xml `<message>Hello, World!</message>`);

    response = check clientEP->/'byteArray;
    test:assertEquals(response, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
}

@test:Config {}
function testResponseWithAnydataResBinding() returns error? {
    http:Response|anydata response = check clientEP->/'string;
    if response is http:Response {
        test:assertEquals(check response.getTextPayload(), "Hello, World!");
    } else {
        test:assertFail("Invalid response type");
    }

    response = check clientEP->/urlEncoded;
    if response is http:Response {
        test:assertEquals(check response.getTextPayload(), "name=John&age=23");
    } else {
        test:assertFail("Invalid response type");
    }

    response = check clientEP->/'json;
    if response is http:Response {
        test:assertEquals(check response.getJsonPayload(), {"name": "John", "age": "23"});
    } else {
        test:assertFail("Invalid response type");
    }

    response = check clientEP->/'xml;
    if response is http:Response {
        test:assertEquals(check response.getXmlPayload(), xml `<message>Hello, World!</message>`);
    } else {
        test:assertFail("Invalid response type");
    }

    response = check clientEP->/'byteArray;
    if response is http:Response {
        test:assertEquals(check response.getBinaryPayload(), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    } else {
        test:assertFail("Invalid response type");
    }
}

@test:Config {enable: false}
function clientoverwriteResponseJsonName() returns error? {
    TPerson res1 = check clientEP->/overwriteNames/jsont(y = true);
    test:assertEquals(res1, {firstName: "John", personAge: "23"});

    json res2 = check clientEP->/overwriteNames/jsont(y = false);
    test:assertEquals(res2, {"name": "Potter", "age": "30"});

    json j = {
        name: "Sumudu",
        age: "29"
    };

    TPerson res3 = check clientEP->/overwriteNames/jsont.post(j);
    test:assertEquals(res3, {firstName: "Sumudu", personAge: "29"});

    json res4 = check clientEP->/status/code;
    test:assertEquals(res4, {name: "Potter", age: "40"});
}
