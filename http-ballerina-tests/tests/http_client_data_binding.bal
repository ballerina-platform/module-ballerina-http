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
import ballerina/http;
import ballerina/mime;
import ballerina/lang.'string as strings;

listener http:Listener clientDBProxyListener = new(clientDatabindingTestPort1);
listener http:Listener clientDBBackendListener = new(clientDatabindingTestPort2);
listener http:Listener clientDBBackendListener2 = new(clientDatabindingTestPort3);
http:Client clientDBTestClient = check new("http://localhost:" + clientDatabindingTestPort1.toString());
http:Client clientDBBackendClient = check new("http://localhost:" + clientDatabindingTestPort2.toString());

type ClientDBPerson record {|
    string name;
    int age;
|};

type ClientDBPersonOtp ClientDBPerson?;

type ClientDBPersonArrOtp ClientDBPerson[]?;

type StringOpt string?;
type XmlOpt xml?;
type ByteOpt byte[]?;

int clientDBCounter = 0;

service /passthrough on clientDBProxyListener {

    resource function get allTypes(http:Caller caller, http:Request request) returns error? {
        string payload = "";

        json p = check clientDBBackendClient->post("/backend/getJson", "want json");
        payload = payload + p.toJsonString();

        map<json> p1 = check clientDBBackendClient->post("/backend/getJson", "want json");
        json name = check p1.id;
        payload = payload + " | " + name.toJsonString();

        xml q = check clientDBBackendClient->post("/backend/getXml", "want xml");
        payload = payload + " | " + q.toString();

        string r = check clientDBBackendClient->post("/backend/getString", "want string");
        payload = payload + " | " + r;

        byte[] val = check clientDBBackendClient->post("/backend/getByteArray", "want byte[]");
        string s = check <@untainted>'string:fromBytes(val);
        payload = payload + " | " + s;

        ClientDBPerson t = check clientDBBackendClient->post("/backend/getRecord", "want record");
        payload = payload + " | " + t.name;

        ClientDBPerson[] u = check clientDBBackendClient->post("/backend/getRecordArr", "want record[]");
        payload = payload + " | " + u[0].name + " | " + u[1].age.toString();

        http:Response v = check clientDBBackendClient->post("/backend/getResponse", "want record[]");
        payload = payload + " | " + check v.getHeader("x-fact");

        error? result = caller->respond(<@untainted>payload);
    }

    resource function get nillableTypes() returns string|error {
        string payload = "";

        xml? q = check clientDBBackendClient->post("/backend/getXml", "want xml", targetType = XmlOpt);
        if q is xml {
            payload = payload + q.toString();
        }

        string? r = check clientDBBackendClient->post("/backend/getString", "want string", targetType = StringOpt);
        if r is string {
            payload = payload + " | " + r;
        }

        byte[]? val = check clientDBBackendClient->post("/backend/getByteArray", "want byte[]", targetType = ByteOpt);
        if val is byte[] {
            string s = check <@untainted>'string:fromBytes(val);
            payload = payload + " | " + s;
        }

        return payload;
    }

    resource function get nillableRecordTypes() returns string|error {
        string payload = "";

        ClientDBPerson? t = check clientDBBackendClient->post("/backend/getRecord", "want record", targetType = ClientDBPersonOtp);
        if t is ClientDBPerson {
            payload = payload + t.name;
        }

        ClientDBPerson[]? u = check clientDBBackendClient->post("/backend/getRecordArr", "want record[]", targetType = ClientDBPersonArrOtp);
        if u is ClientDBPerson[] {
            payload = payload + " | " + u[0].name + " | " + u[1].age.toString();
        }

        return payload;
    }

    resource function get nilTypes() returns string|error {
        string payload = "";
        xml? q = check clientDBBackendClient->post("/backend/getNil", "want xml", targetType = XmlOpt);
        if q is () {
            payload = payload + "Nil XML";
        }

        string? r = check clientDBBackendClient->post("/backend/getNil", "want string", targetType = StringOpt);
        if r is () {
            payload = payload + " | " + "Nil String";
        }

        byte[]? val = check clientDBBackendClient->post("/backend/getNil", "want byte[]", targetType = ByteOpt);
        if val is () || (val is byte[] && val.length() == 0) {
            payload = payload + " | " + "Nil Bytes";
        }

        return payload;
    }

    resource function get nilRecords() returns string|error {
        string payload = "";
        
        ClientDBPerson? t = check clientDBBackendClient->post("/backend/getNil", "want record", targetType = ClientDBPersonOtp);
        if t is () {
            payload = payload + "NilRecord";
        }

        ClientDBPerson[]? u = check clientDBBackendClient->post("/backend/getNil", "want record[]", targetType = ClientDBPersonArrOtp);
        if u is () {
            payload = payload + " | " + "NilRecordArr";
        }

        return payload;
    }

    resource function get allMethods(http:Caller caller, http:Request request) returns error? {
        string payload = "";

        // This is to check any compile failures with multiple default-able args
        json hello = check clientDBBackendClient->get("/backend/getJson");

        json p = check clientDBBackendClient->get("/backend/getJson");
        payload = payload + p.toJsonString();

        http:Response v = check clientDBBackendClient->head("/backend/getXml");
        payload = payload + " | " + check v.getHeader("Content-type");

        string r = check clientDBBackendClient->delete("/backend/getString", "want string");
        payload = payload + " | " + r;

        byte[] val = check clientDBBackendClient->put("/backend/getByteArray", "want byte[]");
        string s = check <@untainted>'string:fromBytes(val);
        payload = payload + " | " + s;

        ClientDBPerson t = check clientDBBackendClient->execute("POST", "/backend/getRecord", "want record");
        payload = payload + " | " + t.name;

        ClientDBPerson[] u = check clientDBBackendClient->forward("/backend/getRecordArr", request);
        payload = payload + " | " + u[0].name + " | " + u[1].age.toString();

        error? result = caller->respond(<@untainted>payload);
    }

    resource function get redirect(http:Caller caller, http:Request req) returns error? {
        http:Client redirectClient = check new("http://localhost:" + clientDatabindingTestPort3.toString(),
                                                        {followRedirects: {enabled: true, maxCount: 5}});
        json p = check redirectClient->post("/redirect1/", "want json", targetType = json);
        error? result = caller->respond(<@untainted>p);
    }

    resource function get 'retry(http:Caller caller, http:Request request) returns error? {
        http:Client retryClient = check new("http://localhost:" + clientDatabindingTestPort2.toString(), {
                retryConfig: { interval: 3, count: 3, backOffFactor: 2.0,
                maxWaitInterval: 2 },  timeout: 2
            }
        );
        string r = check retryClient->forward("/backend/getRetryResponse", request);
        error? responseToCaller = caller->respond(<@untainted>r);
    }

    resource function 'default '500(http:Caller caller, http:Request request) returns error? {
        json p = check clientDBBackendClient->post("/backend/get5XX", "want 500");
        error? responseToCaller = caller->respond(<@untainted>p);
    }

    resource function 'default '500handle(http:Caller caller, http:Request request) returns error? {
        json|error res = clientDBBackendClient->post("/backend/get5XX", "want 500");
        if res is http:RemoteServerError {
            http:Response resp = new;
            resp.statusCode = res.detail().statusCode;
            resp.setPayload(<string>res.detail().body);
            string[] val = res.detail().headers.get("X-Type");
            resp.setHeader("X-Type", val[0]);
            error? responseToCaller = caller->respond(<@untainted>resp);
        } else {
            json p = check res;
            error? responseToCaller = caller->respond(<@untainted>p);
        }
    }

    resource function 'default '404(http:Caller caller, http:Request request) returns error? {
        json p = check clientDBBackendClient->post("/backend/getIncorrectPath404", "want 500");
        error? responseToCaller = caller->respond(<@untainted>p);
    }

    resource function  'default '404/[string path](http:Caller caller, http:Request request) returns error? {
        json|error res = clientDBBackendClient->post("/backend/" + <@untainted>path, "want 500");
        if res is http:ClientRequestError {
            http:Response resp = new;
            resp.statusCode = res.detail().statusCode;
            resp.setPayload(<string>res.detail().body);
            error? responseToCaller = caller->respond(<@untainted>resp);
        } else {
            json p = check res;
            error? responseToCaller = caller->respond(<@untainted>p);
        }
    }

    resource function get testBody/[string path](http:Caller caller, http:Request request) returns error? {
        json p = check clientDBBackendClient->get("/backend/" + <@untainted>path);
        error? responseToCaller = caller->respond(<@untainted>p);
    }
}

service /backend on clientDBBackendListener {
    resource function 'default getJson(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload({id: "chamil", values: {a: 2, b: 45, c: {x: "mnb", y: "uio"}}});
        error? result = caller->respond(response);
    }

    resource function 'default getXml(http:Caller caller, http:Request req) {
        http:Response response = new;
        xml xmlStr = xml `<name>Ballerina</name>`;
        response.setXmlPayload(xmlStr);
        error? result = caller->respond(response);
    }

    resource function 'default getString(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setTextPayload("This is my @4491*&&#$^($@");
        error? result = caller->respond(response);
    }

    resource function 'default getByteArray(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setBinaryPayload("BinaryPayload is textVal".toBytes());
        error? result = caller->respond(response);
    }

    resource function 'default getRecord(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload({name: "chamil", age: 15});
        error? result = caller->respond(response);
    }

    resource function 'default getRecordArr(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload([{name: "wso2", age: 12}, {name: "ballerina", age: 3}]);
        error? result = caller->respond(response);
    }

    resource function 'default getNil() {
    }

    resource function post getResponse(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload({id: "hello"});
        response.setHeader("x-fact", "data-binding");
        error? result = caller->respond(response);
    }

    resource function 'default getRetryResponse(http:Caller caller, http:Request req) {
        clientDBCounter = clientDBCounter + 1;
        if (clientDBCounter == 1) {
            runtime:sleep(5);
            error? responseToCaller = caller->respond("Not received");
        } else {
            error? responseToCaller = caller->respond("Hello World!!!");
        }
    }

    resource function post get5XX(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.statusCode = 501;
        response.setTextPayload("data-binding-failed-with-501");
        response.setHeader("X-Type", "test");
        error? result = caller->respond(response);
    }

    resource function get get4XX(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.statusCode = 400;
        response.setTextPayload("data-binding-failed-due-to-bad-request");
        error? result = caller->respond(response);
    }

    resource function get xmltype() returns http:NotFound {
        return {body: xml `<test>Bad Request</test>`};
    }

    resource function get jsontype() returns http:InternalServerError {
        json j = {id:"hello"};
        return {body: j};
    }

    resource function get binarytype() returns http:ServiceUnavailable {
        byte[] b = "ballerina".toBytes();
        return {body: b};
    }

    resource function 'default getErrorResponseWithErrorContentType() returns http:BadRequest {
        return { body : {name: "hello", age: 15}, mediaType : "application/xml"};
    }
}

service /redirect1 on clientDBBackendListener2 {

    resource function 'default .(http:Caller caller, http:Request req) {
        http:Response res = new;
        error? result = caller->redirect(res, http:REDIRECT_SEE_OTHER_303,
                        ["http://localhost:" + clientDatabindingTestPort2.toString() + "/backend/getJson"]);
    }
}

// Test HTTP basic client with all binding data types(targetTypes)
@test:Config {
    groups: ["dataBinding"]
}
function testAllBindingDataTypes() {
    http:Response|error response = clientDBTestClient->get("/passthrough/allTypes");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "{\"id\":\"chamil\", \"values\":{\"a\":2, \"b\":45, " +
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
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "<name>Ballerina</name> | This is my @4491*&&#$^($@ | BinaryPayload is textVal");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {
    groups: ["dataBinding"]
}
function testAllBindingNillableDataTypes() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/nillableRecordTypes");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "chamil | wso2 | 3");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {
    groups: ["dataBinding"]
}
function testAllBindingNilTypes() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/nilTypes");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Nil XML | Nil String | Nil Bytes");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {
    groups: ["dataBinding"]
}
function testAllBindingNilRecords() returns error? {
    http:Response|error response = clientDBTestClient->get("/passthrough/nilRecords");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "NilRecord | NilRecordArr");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test basic client with all HTTP request methods
@test:Config {
    groups: ["dataBinding"]
}
function testDifferentMethods() {
    http:Response|error response = clientDBTestClient->get("/passthrough/allMethods");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "{\"id\":\"chamil\", \"values\":{\"a\":2, \"b\":45, " +
                "\"c\":{\"x\":\"mnb\", \"y\":\"uio\"}}} | application/xml | This is my @4491*&&#$^($@ | BinaryPayload" +
                " is textVal | chamil | wso2 | 3");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test HTTP redirect client data binding
@test:Config {}
function testRedirectClientDataBinding() {
    http:Response|error response = clientDBTestClient->get("/passthrough/redirect");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        json j = {id:"chamil", values:{a:2, b:45, c:{x:"mnb", y:"uio"}}};
        assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test HTTP retry client data binding
@test:Config {}
function testRetryClientDataBinding() {
    http:Response|error response = clientDBTestClient->get("/passthrough/retry");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 500 error panic
@test:Config {}
function test5XXErrorPanic() {
    http:Response|error response = clientDBTestClient->get("/passthrough/500");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 501, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(checkpanic response.getHeader("X-Type"), "test");
        assertTextPayload(response.getTextPayload(), "data-binding-failed-with-501");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 500 error handle
@test:Config {}
function test5XXHandleError() {
    http:Response|error response = clientDBTestClient->get("/passthrough/500handle");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 501, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(checkpanic response.getHeader("X-Type"), "test");
        assertTextPayload(response.getTextPayload(), "data-binding-failed-with-501");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 404 error panic
@test:Config {}
function test4XXErrorPanic() {
    http:Response|error response = clientDBTestClient->get("/passthrough/404");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), 
            "no matching resource found for path : /backend/getIncorrectPath404 , method : POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 404 error handle
@test:Config {}
function test4XXHandleError() {
    http:Response|error response = clientDBTestClient->get("/passthrough/404/handle");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "no matching resource found for path : /backend/handle , method : POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 405 error handle
@test:Config {}
function test405HandleError() {
    http:Response|error response = clientDBTestClient->get("/passthrough/404/get4XX");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Method not allowed");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function test405AsApplicationResponseError() {
    json|error response = clientDBTestClient->post("/passthrough/allMethods", "hi");
    if (response is http:ApplicationResponseError) {
        test:assertEquals(response.detail().statusCode, 405, msg = "Found unexpected output");
        assertErrorHeaderValue(response.detail().headers[CONTENT_TYPE], TEXT_PLAIN);
        assertTextPayload(<string> response.detail().body, "Method not allowed");
    } else {
        test:assertFail(msg = "Found unexpected output type: json");
    }
}

@test:Config {}
function testXmlErrorSerialize() {
    http:Response|error response = clientDBTestClient->get("/passthrough/testBody/xmltype");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>Bad Request</test>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testJsonErrorSerialize() {
    http:Response|error response = clientDBTestClient->get("/passthrough/testBody/jsontype");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), {id:"hello"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testBinaryErrorSerialize() {
    http:Response|error response = clientDBTestClient->get("/passthrough/testBody/binarytype");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 503, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), mime:APPLICATION_OCTET_STREAM);
        var blobValue = response.getBinaryPayload();
        if (blobValue is byte[]) {
            test:assertEquals(strings:fromBytes(blobValue), "ballerina", msg = "Payload mismatched");
        } else {
            test:assertFail(msg = "Found unexpected output: " +  blobValue.message());
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
    ClientDBErrorPerson|error response =  clientDBBackendClient->post("/backend/getRecord", "want record");
    if (response is error) {
        test:assertEquals(response.message(),
            "Payload binding failed: 'map<json>' value cannot be converted to 'http_tests:ClientDBErrorPerson'");
    } else {
        test:assertFail(msg = "Found unexpected output type: ClientDBErrorPerson");
    }
}

@test:Config {}
function testDBRecordArrayNegative() {
    ClientDBErrorPerson[]|error response =  clientDBBackendClient->post("/backend/getRecordArr", "want record arr");
    if (response is error) {
        test:assertEquals(response.message(),
            "Payload binding failed: 'json[]' value cannot be converted to 'http_tests:ClientDBErrorPerson[]'");
    } else {
        test:assertFail(msg = "Found unexpected output type: ClientDBErrorPerson[]");
    }
}
