// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/lang.runtime as runtime;
import ballerina/test;
// import ballerina/log;
import ballerina/http;
import ballerina/mime;
import ballerina/url;
import ballerina/lang.'string as strings;
import ballerina/http_test_common as common;

listener http:Listener clientDBProxyListener = new (clientDatabindingTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener clientDBBackendListener = new (clientDatabindingTestPort2, httpVersion = http:HTTP_1_1);
listener http:Listener clientDBBackendListener2 = new (clientDatabindingTestPort3);
final http:Client clientDBTestClient = check new ("http://localhost:" + clientDatabindingTestPort1.toString(), httpVersion = http:HTTP_1_1);
final http:Client clientDBBackendClient = check new ("http://localhost:" + clientDatabindingTestPort2.toString(), httpVersion = http:HTTP_1_1);

public type Person record {|
    string name;
    int age;
|};

type ClientDBPerson record {|
    string name;
    int age;
|};

type JsonOpt json?;

type MapJsonOpt map<json>?;

type XmlOpt xml?;

type StringOpt string?;

type ByteOpt byte[]?;

int clientDBCounter = 0;

service /passthrough on clientDBProxyListener {

    resource function get allTypes(http:Caller caller, http:Request request) returns error? {
        string payload = "";

        json jsonPayload = check clientDBBackendClient->post("/backend/getJson", "want json");
        payload = payload + jsonPayload.toJsonString();

        map<json> jsonMapPayload = check clientDBBackendClient->post("/backend/getJson", "want json");
        json name = check jsonMapPayload.id;
        payload = payload + " | " + name.toJsonString();

        xml xmlPayload = check clientDBBackendClient->post("/backend/getXml", "want xml");
        payload = payload + " | " + xmlPayload.toString();

        string stringPayload = check clientDBBackendClient->post("/backend/getString", "want string");
        payload = payload + " | " + stringPayload;

        byte[] binaryPaylod = check clientDBBackendClient->post("/backend/getByteArray", "want byte[]");
        string convertedPayload = check 'string:fromBytes(binaryPaylod);
        payload = payload + " | " + convertedPayload;

        ClientDBPerson person = check clientDBBackendClient->post("/backend/getRecord", "want record");
        payload = payload + " | " + person.name;

        ClientDBPerson[] clients = check clientDBBackendClient->post("/backend/getRecordArr", "want record[]");
        payload = payload + " | " + clients[0].name + " | " + clients[1].age.toString();

        http:Response response = check clientDBBackendClient->post("/backend/getResponse", "want record[]");
        payload = payload + " | " + check response.getHeader("x-fact");

        check caller->respond(payload);
    }

    resource function get nillableTypes() returns string|error {
        string payload = "";

        json? jsonPayload = check clientDBBackendClient->post("/backend/getJson", "want json");
        payload = payload + jsonPayload.toJsonString();

        map<json>? jsonMapPayload = check clientDBBackendClient->post("/backend/getJson", "want json");
        if jsonMapPayload is map<json> {
            json name = check jsonMapPayload.id;
            payload = payload + " | " + name.toJsonString();
        }

        xml? xmlPayload = check clientDBBackendClient->post("/backend/getXml", "want xml");
        if xmlPayload is xml {
            payload = payload + " | " + xmlPayload.toString();
        }

        string? stringPayload = check clientDBBackendClient->post("/backend/getString", "want string");
        if stringPayload is string {
            payload = payload + " | " + stringPayload;
        }

        byte[]? binaryPaylod = check clientDBBackendClient->post("/backend/getByteArray", "want byte[]");
        if binaryPaylod is byte[] {
            string convertedPayload = check 'string:fromBytes(binaryPaylod);
            payload = payload + " | " + convertedPayload;
        }

        return payload;
    }

    resource function get nillableRecordTypes() returns string|error {
        string payload = "";

        ClientDBPerson? person = check clientDBBackendClient->post("/backend/getRecord", "want record");
        if person is ClientDBPerson {
            payload = payload + person.name;
        }

        ClientDBPerson[]? clients = check clientDBBackendClient->post("/backend/getRecordArr", "want record[]");
        if clients is ClientDBPerson[] {
            payload = payload + " | " + clients[0].name + " | " + clients[1].age.toString();
        }

        return payload;
    }

    resource function get nilTypes() returns string|error {
        string payload = "";

        var jsonPayload = check clientDBBackendClient->post("/backend/getNil", "want json", targetType = JsonOpt);
        if jsonPayload is () {
            payload = payload + "Nil Json";
        }

        var jsonMapPayload = check clientDBBackendClient->post("/backend/getNil", "want json", targetType = MapJsonOpt);
        if jsonMapPayload is () {
            payload = payload + " | " + "Nil Map Json";
        }

        var xmlPayload = check clientDBBackendClient->post("/backend/getNil", "want xml", targetType = XmlOpt);
        if xmlPayload is () {
            payload = payload + " | " + "Nil XML";
        }

        var stringPayload = check clientDBBackendClient->post("/backend/getNil", "want string", targetType = StringOpt);
        if stringPayload is () {
            payload = payload + " | " + "Nil String";
        }

        var binaryPaylod = check clientDBBackendClient->post("/backend/getNil", "want byte[]", targetType = ByteOpt);
        if binaryPaylod is () {
            payload = payload + " | " + "Nil Bytes";
        }

        return payload;
    }

    resource function get nilRecords() returns string|error {
        string payload = "";

        ClientDBPerson? person = check clientDBBackendClient->post("/backend/getNil", "want record");
        if person is () {
            payload = payload + "NilRecord";
        }

        ClientDBPerson[]? clients = check clientDBBackendClient->post("/backend/getNil", "want record[]");
        if clients is () {
            payload = payload + " | " + "NilRecordArr";
        }

        return payload;
    }

    resource function get errorReturns() returns string {
        string payload = "";

        map<json>|http:ClientError jsonMapPayload = clientDBBackendClient->post("/backend/getNil", "want json");
        if jsonMapPayload is http:ClientError {
            payload = payload + jsonMapPayload.message();
        }

        xml|http:ClientError xmlPayload = clientDBBackendClient->post("/backend/getNil", "want xml");
        if xmlPayload is http:ClientError {
            payload = payload + " | " + xmlPayload.message();
        }

        string|http:ClientError stringPaylod = clientDBBackendClient->post("/backend/getNil", "want string");
        if stringPaylod is http:ClientError {
            payload = payload + " | " + stringPaylod.message();
        }

        return payload;
    }

    resource function get runtimeErrors() returns string {
        string[] payload = [];

        xml|json|http:ClientError unionPayload = clientDBBackendClient->post("/backend/getJson", "want json");
        if unionPayload is http:ClientError {
            payload.push(unionPayload.message());
        } else if unionPayload is json {
            payload.push(unionPayload.toString());
        }

        int|string|http:ClientError basicTypeUnionPayload = clientDBBackendClient->post("/backend/getString", "want string");
        if basicTypeUnionPayload is http:ClientError {
            payload.push(basicTypeUnionPayload.message());
        } else if basicTypeUnionPayload is string {
            payload.push(basicTypeUnionPayload);
        }
        return string:'join("|", ...payload);
    }

    resource function get runtimeErrorsNillable() returns string {
        string[] payload = [];

        xml?|http:ClientError unionPayload = clientDBBackendClient->post("/backend/getJson", "want json");
        if unionPayload is http:ClientError {
            payload.push(unionPayload.message());
        }

        int?|http:ClientError basicTypeUnionPayload = clientDBBackendClient->post("/backend/getString", "want string");
        if basicTypeUnionPayload is http:ClientError {
            payload.push(basicTypeUnionPayload.message());
        }

        return string:'join("|", ...payload);
    }

    resource function get allMethods(http:Caller caller, http:Request request) returns error? {
        string payload = "";

        // This is to check any compile failures with multiple default-able args
        json|error hello = clientDBBackendClient->get("/backend/getJson");
        if hello is error {
            // log:printError("Error reading payload", 'error = hello);
        }
        json p = check clientDBBackendClient->get("/backend/getJson");
        payload = payload + p.toJsonString();

        http:Response v = check clientDBBackendClient->head("/backend/getXml");
        payload = payload + " | " + check v.getHeader("Content-type");

        string r = check clientDBBackendClient->delete("/backend/getString", "want string");
        payload = payload + " | " + r;

        byte[] val = check clientDBBackendClient->put("/backend/getByteArray", "want byte[]");
        string s = check 'string:fromBytes(val);
        payload = payload + " | " + s;

        ClientDBPerson t = check clientDBBackendClient->execute("POST", "/backend/getRecord", "want record");
        payload = payload + " | " + t.name;

        ClientDBPerson[] u = check clientDBBackendClient->forward("/backend/getRecordArr", request);
        payload = payload + " | " + u[0].name + " | " + u[1].age.toString();

        check caller->respond(payload);
    }

    resource function get redirect(http:Caller caller, http:Request req) returns error? {
        http:Client redirectClient = check new ("http://localhost:" + clientDatabindingTestPort3.toString(),
            httpVersion = http:HTTP_1_1, followRedirects = {enabled: true, maxCount: 5});
        json p = check redirectClient->post("/redirect1/", "want json", targetType = json);
        check caller->respond(p);
    }

    resource function get 'retry(http:Caller caller, http:Request request) returns error? {
        http:Client retryClient = check new ("http://localhost:" + clientDatabindingTestPort2.toString(),
            httpVersion = http:HTTP_1_1, retryConfig = {interval: 3, count: 3, backOffFactor: 2.0, maxWaitInterval: 2}, timeout = 2);
        string r = check retryClient->forward("/backend/getRetryResponse", request);
        check caller->respond(r);
    }

    resource function 'default '500(http:Caller caller, http:Request request) returns error? {
        json p = check clientDBBackendClient->post("/backend/get5XX", "want 500");
        check caller->respond(p);
    }

    resource function 'default '500handle(http:Caller caller, http:Request request) returns error? {
        json|error res = clientDBBackendClient->post("/backend/get5XX", "want 500");
        if res is http:RemoteServerError {
            http:Response resp = new;
            resp.statusCode = res.detail().statusCode;
            resp.setPayload(<string>res.detail().body);
            string[] val = res.detail().headers.get("X-Type");
            resp.setHeader("X-Type", val[0]);
            check caller->respond(resp);
        } else {
            json p = check res;
            check caller->respond(p);
        }
    }

    resource function 'default '404(http:Caller caller, http:Request request) returns error? {
        json p = check clientDBBackendClient->post("/backend/getIncorrectPath404", "want 500");
        check caller->respond(p);
    }

    resource function 'default '404/[string path](http:Caller caller, http:Request request) returns error? {
        json|error res = clientDBBackendClient->post("/backend/" + path, "want 500");
        if res is http:ClientRequestError {
            http:Response resp = new;
            resp.statusCode = res.detail().statusCode;
            resp.setPayload(<json>res.detail().body);
            check caller->respond(resp);
        } else {
            json p = check res;
            check caller->respond(p);
        }
    }

    resource function get testBody/[string path](http:Caller caller, http:Request request) returns error? {
        json p = check clientDBBackendClient->get("/backend/" + path);
        check caller->respond(p);
    }

    resource function get mapOfString1() returns json|error {
        map<string> person = check clientDBBackendClient->get("/backend/getFormData1");
        string? val1 = person["key1"];
        string? val2 = person["key2"];
        return {key1: val1, key2: val2};
    }

    resource function get mapOfString2() returns json|error {
        map<string> person = check clientDBBackendClient->get("/backend/getFormData2");
        string? val1 = person["first Name"];
        string? val2 = person["tea$*m"];
        return {key1: val1, key2: val2};
    }

    resource function get mapOfString3() returns json|error {
        map<string> person = check clientDBBackendClient->get("/backend/getFormData3");
        string? val1 = person["first Name"];
        string? val2 = person["tea$*m"];
        return {key1: val1, key2: val2};
    }

    resource function get mapOfString4() returns json|error {
        map<string> person = check clientDBBackendClient->get("/backend/getFormData4");
        string? val1 = person["first Name"];
        string? val2 = person["tea$*m"];
        return {key1: val1, key2: val2};
    }

    resource function get mapOfString5() returns json|error {
        map<string> person = check clientDBBackendClient->get("/backend/getFormData5");
        string? val1 = person["first Name"];
        string? val2 = person["tea$*m"];
        return {key1: val1, key2: val2};
    }

    resource function get mapOfString6() returns json|error {
        map<string> person = check clientDBBackendClient->get("/backend/getFormData6");
        string? val1 = person["first Name"];
        string? val2 = person["tea$*m"];
        return {key1: val1, key2: val2};
    }
}

service /backend on clientDBBackendListener {
    resource function 'default getJson(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setJsonPayload({id: "chamil", values: {a: 2, b: 45, c: {x: "mnb", y: "uio"}}});
        check caller->respond(response);
    }

    resource function 'default getXml(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        xml xmlStr = xml `<name>Ballerina</name>`;
        response.setXmlPayload(xmlStr);
        check caller->respond(response);
    }

    resource function 'default getString(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setTextPayload("This is my @4491*&&#$^($@");
        check caller->respond(response);
    }

    resource function 'default getByteArray(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setBinaryPayload("BinaryPayload is textVal".toBytes());
        check caller->respond(response);
    }

    resource function 'default getRecord(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setJsonPayload({name: "chamil", age: 15});
        check caller->respond(response);
    }

    resource function 'default getRecordArr(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setJsonPayload([{name: "wso2", age: 12}, {name: "ballerina", age: 3}]);
        check caller->respond(response);
    }

    resource function 'default getNil() {
    }

    resource function post getResponse(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setJsonPayload({id: "hello"});
        response.setHeader("x-fact", "data-binding");
        check caller->respond(response);
    }

    resource function 'default getRetryResponse(http:Caller caller, http:Request req) returns error? {
        int count = 0;
        lock {
            clientDBCounter = clientDBCounter + 1;
            count = clientDBCounter;
        }
        if count == 1 {
            runtime:sleep(5);
            check caller->respond("Not received");
        } else {
            check caller->respond("Hello World!!!");
        }
    }

    resource function post get5XX(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.statusCode = 501;
        response.setTextPayload("data-binding-failed-with-501");
        response.setHeader("X-Type", "test");
        check caller->respond(response);
    }

    resource function get get4XX(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.statusCode = 400;
        response.setTextPayload("data-binding-failed-due-to-bad-request");
        check caller->respond(response);
    }

    resource function get xmltype() returns http:NotFound {
        xml payload = xml `<test>Bad Request</test>`;
        return {body: payload};
    }

    resource function get jsontype() returns http:InternalServerError {
        json j = {id: "hello"};
        return {body: j};
    }

    resource function get binarytype() returns http:ServiceUnavailable {
        byte[] b = "ballerina".toBytes();
        return {body: b};
    }

    resource function 'default getErrorResponseWithErrorContentType() returns http:BadRequest {
        return {body: {name: "hello", age: 15}, mediaType: "application/xml"};
    }

    resource function get getFormData1() returns http:Ok|error {
        string encodedPayload1 = check url:encode("value 1", "UTF-8");
        string encodedPayload2 = check url:encode("value 2", "UTF-8");
        string payload = string `key1=${encodedPayload1}&key2=${encodedPayload2}`;
        return {body: payload, mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getFormData2() returns http:Ok|error {
        return {body: "first%20Name=WS%20O2&tea%24%2Am=Bal%40Dance", mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getFormData3() returns http:Ok|error {
        return {body: "first%20Name=WS%20O2&tea%24%2Am=", mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getFormData4() returns http:Ok|error {
        return {body: "first%20Name=WS%20O2&=Bal%40Dance", mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getFormData5() returns http:Ok|error {
        return {body: "", mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getFormData6() returns http:Ok|error {
        return {body: "first%20Name=WS%20O2", mediaType: "application/x-www-form-urlencoded"};
    }
}

service /redirect1 on clientDBBackendListener2 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_SEE_OTHER_303,
                        ["http://localhost:" + clientDatabindingTestPort2.toString() + "/backend/getJson"]);
    }
}

// Test HTTP basic client with all binding data types(targetTypes)
@test:Config {
    groups: ["dataBinding"]
}
function testAllBindingDataTypes() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/allTypes");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "{\"id\":\"chamil\", \"values\":{\"a\":2, \"b\":45, " +
                "\"c\":{\"x\":\"mnb\", \"y\":\"uio\"}}} | \"chamil\" | <name>Ballerina</name> | " +
                "This is my @4491*&&#$^($@ | BinaryPayload is textVal | chamil | wso2 | 3 | data-binding");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {
    groups: ["dataBinding"]
}
function testAllBindingNillableTypes() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/nillableTypes");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "{\"id\":\"chamil\", \"values\":{\"a\":2, \"b\":45, " +
                "\"c\":{\"x\":\"mnb\", \"y\":\"uio\"}}} | \"chamil\" | <name>Ballerina</name> | " +
                "This is my @4491*&&#$^($@ | BinaryPayload is textVal");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {
    groups: ["dataBinding"]
}
function testAllBindingNillableDataTypes() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/nillableRecordTypes");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "chamil | wso2 | 3");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {
    groups: ["dataBinding"]
}
function testAllBindingNilTypes() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/nilTypes");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Nil Json | Nil Map Json | Nil XML | Nil String | Nil Bytes");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {
    groups: ["dataBinding"]
}
function testAllBindingNilRecords() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/nilRecords");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "NilRecord | NilRecordArr");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {
    groups: ["dataBinding"]
}
function testAllBindingErrorReturns() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/errorReturns");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "No content | No content | No content");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {
    groups: ["dataBinding"]
}
function testUnionBinding() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/runtimeErrors");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(),
            "{\"id\":\"chamil\",\"values\":{\"a\":2,\"b\":45,\"c\":{\"x\":\"mnb\",\"y\":\"uio\"}}}|This is my @4491*&&#$^($@");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {
    groups: ["dataBinding"]
}
function testAllBindingErrorsWithNillableTypes() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/runtimeErrorsNillable");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(),
            "Payload binding failed: incompatible expected type 'xml<(lang.xml:Element|lang.xml:Comment|" +
            "lang.xml:ProcessingInstruction|lang.xml:Text)>?' for value " +
            "'{\"id\":\"chamil\",\"values\":{\"a\":2,\"b\":45,\"c\":{\"x\":\"mnb\",\"y\":\"uio\"}}}'|incompatible typedesc int? found for 'text/plain' mime type");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

// Test basic client with all HTTP request methods
@test:Config {
    groups: ["dataBinding"]
}
function testDifferentMethods() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/allMethods");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "{\"id\":\"chamil\", \"values\":{\"a\":2, \"b\":45, " +
                "\"c\":{\"x\":\"mnb\", \"y\":\"uio\"}}} | application/xml | This is my @4491*&&#$^($@ | BinaryPayload" +
                " is textVal | chamil | wso2 | 3");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test HTTP redirect client data binding
@test:Config {}
function testRedirectClientDataBinding() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/redirect");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {id: "chamil", values: {a: 2, b: 45, c: {x: "mnb", y: "uio"}}};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test HTTP retry client data binding
@test:Config {}
function testRetryClientDataBinding() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/retry");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 500 error panic
@test:Config {}
function test5XXErrorPanic() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/500");
    if response is http:Response {
        test:assertEquals(response.statusCode, 501, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertHeaderValue(check response.getHeader("X-Type"), "test");
        common:assertTextPayload(response.getTextPayload(), "data-binding-failed-with-501");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 500 error handle
@test:Config {}
function test5XXHandleError() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/500handle");
    if response is http:Response {
        test:assertEquals(response.statusCode, 501, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertHeaderValue(check response.getHeader("X-Type"), "test");
        common:assertTextPayload(response.getTextPayload(), "data-binding-failed-with-501");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 404 error panic
@test:Config {}
function test4XXErrorPanic() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/404");
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "no matching resource found for path",
                    "Not Found", 404, "/backend/getIncorrectPath404", "POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 404 error handle
@test:Config {}
function test4XXHandleError() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/404/handle");
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "no matching resource found for path",
                    "Not Found", 404, "/backend/handle", "POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 405 error handle
@test:Config {}
function test405HandleError() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/404/get4XX");
    if response is http:Response {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "Method not allowed", "Method Not Allowed", 405,
                   "/backend/get4XX", "POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function test405AsApplicationResponseError() returns error? {
    json|error response = clientDBTestClient->post("/passthrough/allMethods", "hi");
    if response is http:ApplicationResponseError {
        test:assertEquals(response.detail().statusCode, 405, msg = "Found unexpected output");
        common:assertErrorHeaderValue(response.detail().headers[common:CONTENT_TYPE], common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(<json>response.detail().body, "Method not allowed", "Method Not Allowed", 405,
                   "/passthrough/allMethods", "POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: json");
    }
}

@test:Config {}
function testXmlErrorSerialize() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/testBody/xmltype");
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>Bad Request</test>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testJsonErrorSerialize() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/testBody/jsontype");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {id: "hello"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBinaryErrorSerialize() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/testBody/binarytype");
    if response is http:Response {
        test:assertEquals(response.statusCode, 503, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), mime:APPLICATION_OCTET_STREAM);
        var blobValue = response.getBinaryPayload();
        if (blobValue is byte[]) {
            test:assertEquals(strings:fromBytes(blobValue), "ballerina", msg = "Payload mismatched");
        } else {
            test:assertFail(msg = "Found unexpected output: " + blobValue.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

type ClientDBErrorPerson record {|
    string name;
    int age;
    float weight;
|};

@test:Config {}
function testDetailBodyCreationFailure() {
    string|error response = clientDBBackendClient->get("/backend/getErrorResponseWithErrorContentType");
    if (response is error) {
        test:assertEquals(response.message(),
            "http:ApplicationResponseError creation failed: 400 response payload extraction failed");
    } else {
        test:assertFail(msg = "Found unexpected output type: string");
    }
}

@test:Config {}
function testDBRecordErrorNegative() {
    ClientDBErrorPerson|error response = clientDBBackendClient->post("/backend/getRecord", "want record");
    if (response is error) {
        common:assertTrueTextPayload(response.message(),
            "Payload binding failed: required field 'weight' not present in JSON");
        // common:assertTrueTextPayload(response.message(),
        //     "missing required field 'weight' of type 'float' in record 'http_client_tests:ClientDBErrorPerson'");
    } else {
        test:assertFail(msg = "Found unexpected output type: ClientDBErrorPerson");
    }
}

@test:Config {}
function testDBRecordArrayNegative() {
    ClientDBErrorPerson[]|error response = clientDBBackendClient->post("/backend/getRecordArr", "want record arr");
    if (response is error) {
        common:assertTrueTextPayload(response.message(),
            "Payload binding failed: required field 'weight' not present in JSON");
    } else {
        test:assertFail(msg = "Found unexpected output type: ClientDBErrorPerson[]");
    }
}

@test:Config {}
function testMapOfStringDataBinding() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/mapOfString1");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {"key1": "value 1", "key2": "value 2"};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMapOfStringDataBindingWithJsonPayload() {
    map<string>|error response = clientDBBackendClient->get("/backend/getJson");
    if (response is error) {
        common:assertTrueTextPayload(response.message(),
            "Payload binding failed: incompatible expected type 'string' for value '{\"a\":2,\"b\":45,\"c\":{\"x\":\"mnb\",\"y\":\"uio\"}}'");
    } else {
        test:assertFail(msg = "Found unexpected output type: map<string>");
    }
}

@test:Config {}
function testMapOfStringDataBindingWithEncodedKey() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/mapOfString2");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {"key1": "WS O2", "key2": "Bal@Dance"};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMapOfStringDataBindingWithEmptyValue() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/mapOfString3");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {"key1": "WS O2", "key2": ""};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMapOfStringDataBindingWithEmptyKey() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/mapOfString4");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {"key1": "WS O2", "key2": ()};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMapOfStringDataBindingWithEmptyPayload() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/mapOfString5");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "No content",
                    "Internal Server Error", 500, "/passthrough/mapOfString5", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMapOfStringDataBindingWithSinglePair() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/mapOfString6");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {"key1": "WS O2", "key2": ()};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNilableMapOfStringDataBindingWithEmptyPayload() {
    map<string>?|error response = clientDBBackendClient->get("/backend/getFormData5");
    test:assertTrue(response is (), msg = "Found unexpected output");
}
