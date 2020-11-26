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

import ballerina/runtime;
import ballerina/test;
import ballerina/http;

listener http:Listener clientDBProxyListener = new(clientDatabindingTestPort1);
listener http:Listener clientDBBackendListener = new(clientDatabindingTestPort2);
listener http:Listener clientDBBackendListener2 = new(clientDatabindingTestPort3);
http:Client clientDBTestClient = new("http://localhost:" + clientDatabindingTestPort1.toString());
http:Client clientDBBackendClient = new("http://localhost:" + clientDatabindingTestPort2.toString());

type ClientDBPerson record {|
    string name;
    int age;
|};

int clientDBCounter = 0;

// Need to define a type due to https://github.com/ballerina-platform/ballerina-lang/issues/26253
type ByteArray byte[];
type ClientDBPersonArray ClientDBPerson[];
type MapOfJson map<json>;

@http:ServiceConfig {
    basePath: "/call"
}
service passthrough on clientDBProxyListener {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/allTypes"
    }
    resource function checkAllDataBindingTypes(http:Caller caller, http:Request request) returns @tainted error? {
        string payload = "";

        var res = clientDBBackendClient->post("/backend/getJson", "want json", targetType = json);
        json p = <json>res;
        payload = payload + p.toJsonString();

        res = clientDBBackendClient->post("/backend/getJson", "want json", MapOfJson);
        map<json> p1 = <map<json>>res;
        json name = check p1.id;
        payload = payload + " | " + name.toJsonString();

        res = clientDBBackendClient->post("/backend/getXml", "want xml", xml);
        xml q = <xml>res;
        payload = payload + " | " + q.toString();

        res = clientDBBackendClient->post("/backend/getString", "want string", targetType = string);
        string r = <string>res;
        payload = payload + " | " + r;

        res = clientDBBackendClient->post("/backend/getByteArray", "want byte[]", ByteArray);
        byte[] val = <byte[]>res;
        string s = check <@untainted>'string:fromBytes(val);
        payload = payload + " | " + s;

        res = clientDBBackendClient->post("/backend/getRecord", "want record", targetType = ClientDBPerson);
        ClientDBPerson t = <ClientDBPerson>res;
        payload = payload + " | " + t.name;

        res = clientDBBackendClient->post("/backend/getRecordArr", "want record[]", targetType = ClientDBPersonArray);
        ClientDBPerson[] u = <ClientDBPerson[]>res;
        payload = payload + " | " + u[0].name + " | " + u[1].age.toString();

        res = clientDBBackendClient->post("/backend/getResponse", "want record[]", targetType = http:Response);
        http:Response v = <http:Response>res;
        payload = payload + " | " + v.getHeader("x-fact");

        var result = caller->respond(<@untainted>payload);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/allMethods"
    }
    resource function checkAllRequestMethods(http:Caller caller, http:Request request) returns error? {
        string payload = "";

        var res = clientDBBackendClient->get("/backend/getJson", targetType = json);
        json p = <json>res;
        payload = payload + p.toJsonString();

        res = clientDBBackendClient->head("/backend/getXml", "want xml");
        http:Response v = <http:Response>res;
        payload = payload + " | " + v.getHeader("Content-type");

        res = clientDBBackendClient->delete("/backend/getString", "want string", targetType = string);
        string r = <string>res;
        payload = payload + " | " + r;

        res = clientDBBackendClient->put("/backend/getByteArray", "want byte[]", ByteArray);
        byte[] val = <byte[]>res;
        string s = check <@untainted>'string:fromBytes(val);
        payload = payload + " | " + s;

        res = clientDBBackendClient->execute("POST", "/backend/getRecord", "want record", targetType = ClientDBPerson);
        ClientDBPerson t = <ClientDBPerson>res;
        payload = payload + " | " + t.name;

        res = clientDBBackendClient->forward("/backend/getRecordArr", request, targetType = ClientDBPersonArray);
        ClientDBPerson[] u = <ClientDBPerson[]>res;
        payload = payload + " | " + u[0].name + " | " + u[1].age.toString();

        var result = caller->respond(<@untainted>payload);
    }

     @http:ResourceConfig {
        methods: ["GET"],
        path: "/redirect"
    }
    resource function checkJsonDatabinding(http:Caller caller, http:Request req) {
        http:Client redirectClient = new("http://localhost:" + clientDatabindingTestPort3.toString(),
                                                        {followRedirects: {enabled: true, maxCount: 5}});
        var res = redirectClient->post("/redirect1/", "want json", targetType = json);
        json p = <json>res;
        var result = caller->respond(<@untainted>p);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/retry"
    }
    resource function invokeEndpoint(http:Caller caller, http:Request request) {
        http:Client retryClient = new ("http://localhost:" + clientDatabindingTestPort2.toString(), {
                retryConfig: { intervalInMillis: 3000, count: 3, backOffFactor: 2.0,
                maxWaitIntervalInMillis: 20000 },  timeoutInMillis: 2000
            }
        );
        var backendResponse = retryClient->forward("/backend/getRetryResponse", request, targetType = string);
        string r = <string>backendResponse;
        var responseToCaller = caller->respond(<@untainted>r);
    }

    @http:ResourceConfig {
        path: "/cast"
    }
    resource function checkCastError(http:Caller caller, http:Request request) {
        var res = clientDBBackendClient->post("/backend/getJson", "want json", targetType = json);
        xml p = <xml>res;
        var responseToCaller = caller->respond(<@untainted>p);
    }

    @http:ResourceConfig {
        path: "/500"
    }
    resource function check500Error(http:Caller caller, http:Request request) {
        var res = clientDBBackendClient->post("/backend/get5XX", "want 500", targetType = json);
        json p = <json>res;
        var responseToCaller = caller->respond(<@untainted>p);
    }

    @http:ResourceConfig {
        path: "/500handle"
    }
    resource function handle500Error(http:Caller caller, http:Request request) {
        var res = clientDBBackendClient->post("/backend/get5XX", "want 500", targetType = json);
        if res is http:RemoteServerError {
            http:Response resp = new;
            resp.statusCode = res.detail()?.statusCode ?: 500;
            resp.setPayload(<@untainted>res.message());
            var responseToCaller = caller->respond(<@untainted>resp);
        } else {
            json p = <json>res;
            var responseToCaller = caller->respond(<@untainted>p);
        }
    }

    @http:ResourceConfig {
        path: "/404"
    }
    resource function check404Error(http:Caller caller, http:Request request) {
        var res = clientDBBackendClient->post("/backend/getIncorrectPath404", "want 500", targetType = json);
        json p = <json>res;
        var responseToCaller = caller->respond(<@untainted>p);
    }

    @http:ResourceConfig {
        path: "/404/{path}"
    }
    resource function handle404Error(http:Caller caller, http:Request request, string path) {
        var res = clientDBBackendClient->post("/backend/" + <@untainted>path, "want 500", targetType = json);
        if res is http:ClientRequestError {
            http:Response resp = new;
            resp.statusCode = res.detail()?.statusCode ?: 400;
            resp.setPayload(<@untainted>res.message());
            var responseToCaller = caller->respond(<@untainted>resp);
        } else {
            json p = <json>res;
            var responseToCaller = caller->respond(<@untainted>p);
        }
    }
}

@http:ServiceConfig {
    basePath: "/backend"
}
service mockHelloServiceDB on clientDBBackendListener {
    resource function getJson(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload({id: "chamil", values: {a: 2, b: 45, c: {x: "mnb", y: "uio"}}});
        var result = caller->respond(response);
    }

    resource function getXml(http:Caller caller, http:Request req) {
        http:Response response = new;
        xml xmlStr = xml `<name>Ballerina</name>`;
        response.setXmlPayload(xmlStr);
        var result = caller->respond(response);
    }

    resource function getString(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setTextPayload("This is my @4491*&&#$^($@");
        var result = caller->respond(response);
    }

    resource function getByteArray(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setBinaryPayload("BinaryPayload is textVal".toBytes());
        var result = caller->respond(response);
    }

    resource function getRecord(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload({name: "chamil", age: 15});
        var result = caller->respond(response);
    }

    resource function getRecordArr(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload([{name: "wso2", age: 12}, {name: "ballerina", age: 3}]);
        var result = caller->respond(response);
    }

    resource function getResponse(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload({id: "hello"});
        response.setHeader("x-fact", "data-binding");
        var result = caller->respond(response);
    }

    resource function getRetryResponse(http:Caller caller, http:Request req) {
        clientDBCounter = clientDBCounter + 1;
        if (clientDBCounter == 1) {
            runtime:sleep(5000);
            var responseToCaller = caller->respond("Not received");
        } else {
            var responseToCaller = caller->respond("Hello World!!!");
        }
    }

    resource function get5XX(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.statusCode = 501;
        response.setTextPayload("data-binding-failed-with-501");
        var result = caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"]
    }
    resource function get4XX(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.statusCode = 400;
        response.setTextPayload("data-binding-failed-due-to-bad-request");
        var result = caller->respond(response);
    }
}

@http:ServiceConfig {
    basePath: "/redirect1"
}
service redirect1DB on clientDBBackendListener2 {
    @http:ResourceConfig {
        path: "/"
    }
    resource function redirect1(http:Caller caller, http:Request req) {
        http:Response res = new;
        var result = caller->redirect(res, http:REDIRECT_SEE_OTHER_303,
                        ["http://localhost:" + clientDatabindingTestPort2.toString() + "/backend/getJson"]);
    }
}

// Test HTTP basic client with all binding data types(targetTypes)
@test:Config {}
function testAllBindingDataTypes() {
    var response = clientDBTestClient->get("/call/allTypes");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "{\"id\":\"chamil\", \"values\":{\"a\":2, \"b\":45, " +
                 "\"c\":{\"x\":\"mnb\", \"y\":\"uio\"}}} | chamil | <name>Ballerina</name> | " +
                 "This is my @4491*&&#$^($@ | BinaryPayload is textVal | chamil | wso2 | 3 | data-binding");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test basic client with all HTTP request methods
@test:Config {}
function testDifferentMethods() {
    var response = clientDBTestClient->get("/call/allMethods");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "{\"id\":\"chamil\", \"values\":{\"a\":2, \"b\":45, " +
                "\"c\":{\"x\":\"mnb\", \"y\":\"uio\"}}} | application/xml | This is my @4491*&&#$^($@ | BinaryPayload" +
                " is textVal | chamil | wso2 | 3");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test HTTP redirect client data binding
@test:Config {groups: ["now"]}
function testRedirectClientDataBinding() {
    var response = clientDBTestClient->get("/call/redirect");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        json j = {id:"chamil", values:{a:2, b:45, c:{x:"mnb", y:"uio"}}};
        assertJsonPayload(response.getJsonPayload(), j);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test HTTP retry client data binding
@test:Config {}
function testRetryClientDataBinding() {
    var response = clientDBTestClient->get("/call/retry");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test cast error panic for incompatible types
@test:Config {}
function testCastError() {
    var response = clientDBTestClient->get("/call/cast");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "incompatible types: 'map<json>' cannot be cast to " +
                            "'xml<lang.xml:Element|lang.xml:Comment|lang.xml:ProcessingInstruction|lang.xml:Text>'");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 500 error panic
@test:Config {}
function test5XXErrorPanic() {
    var response = clientDBTestClient->get("/call/500");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "incompatible types: 'http:RemoteServerError' cannot be cast to 'json'");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 500 error handle
@test:Config {}
function test5XXHandleError() {
    var response = clientDBTestClient->get("/call/500handle");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 501, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "data-binding-failed-with-501");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 404 error panic
@test:Config {}
function test4XXErrorPanic() {
    var response = clientDBTestClient->get("/call/404");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "incompatible types: 'http:ClientRequestError' cannot be cast to 'json'");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 404 error handle
@test:Config {}
function test4XXHandleError() {
    var response = clientDBTestClient->get("/call/404/handle");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "no matching resource found for path : /backend/handle , method : POST");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 405 error handle
@test:Config {}
function test405HandleError() {
    var response = clientDBTestClient->get("/call/404/get4XX");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "method not allowed");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
