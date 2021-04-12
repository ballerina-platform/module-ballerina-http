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

listener http:Listener clientDBProxyListener = new(clientDatabindingTestPort1);
listener http:Listener clientDBBackendListener = new(clientDatabindingTestPort2);
listener http:Listener clientDBBackendListener2 = new(clientDatabindingTestPort3);
http:Client clientDBTestClient = check new("http://localhost:" + clientDatabindingTestPort1.toString());
http:Client clientDBBackendClient = check new("http://localhost:" + clientDatabindingTestPort2.toString());

type ClientDBPerson record {|
    string name;
    int age;
|};

int clientDBCounter = 0;

// Need to define a type due to https://github.com/ballerina-platform/ballerina-lang/issues/26253
type ByteArray byte[];
type ClientDBPersonArray ClientDBPerson[];
type MapOfJson map<json>;
type XmlType xml;

service /passthrough on clientDBProxyListener {

    resource function get allTypes(http:Caller caller, http:Request request) returns @tainted error? {
        string payload = "";

        json p = checkpanic clientDBBackendClient->post("/backend/getJson", "want json", targetType = json);
        payload = payload + p.toJsonString();

        map<json> p1 = checkpanic clientDBBackendClient->post("/backend/getJson", "want json", targetType = MapOfJson);
        json name = check p1.id;
        payload = payload + " | " + name.toJsonString();

        xml q = checkpanic clientDBBackendClient->post("/backend/getXml", "want xml", targetType = XmlType);
        payload = payload + " | " + q.toString();

        string r = checkpanic clientDBBackendClient->post("/backend/getString", "want string", targetType = string);
        payload = payload + " | " + r;

        byte[] val = checkpanic clientDBBackendClient->post("/backend/getByteArray", "want byte[]", targetType = ByteArray);
        string s = check <@untainted>'string:fromBytes(val);
        payload = payload + " | " + s;

        ClientDBPerson t = checkpanic clientDBBackendClient->post("/backend/getRecord", "want record", targetType = ClientDBPerson);
        payload = payload + " | " + t.name;

        ClientDBPerson[] u = checkpanic clientDBBackendClient->post("/backend/getRecordArr", "want record[]", targetType = ClientDBPersonArray);
        payload = payload + " | " + u[0].name + " | " + u[1].age.toString();

        http:Response v = checkpanic clientDBBackendClient->post("/backend/getResponse", "want record[]", targetType = http:Response);
        payload = payload + " | " + checkpanic v.getHeader("x-fact");

        error? result = caller->respond(<@untainted>payload);
    }

    resource function get allMethods(http:Caller caller, http:Request request) returns error? {
        string payload = "";

        // This is to check any compile failures with multiple default-able args
        json hello = checkpanic clientDBBackendClient->get("/backend/getJson", targetType = json);

        json p = checkpanic clientDBBackendClient->get("/backend/getJson", targetType = json);
        payload = payload + p.toJsonString();

        http:Response v = checkpanic clientDBBackendClient->head("/backend/getXml");
        payload = payload + " | " + checkpanic v.getHeader("Content-type");

        string r = checkpanic clientDBBackendClient->delete("/backend/getString", "want string", targetType = string);
        payload = payload + " | " + r;

        byte[] val = checkpanic clientDBBackendClient->put("/backend/getByteArray", "want byte[]", targetType = ByteArray);
        string s = check <@untainted>'string:fromBytes(val);
        payload = payload + " | " + s;

        ClientDBPerson t = checkpanic clientDBBackendClient->execute("POST", "/backend/getRecord", "want record", targetType = ClientDBPerson);
        payload = payload + " | " + t.name;

        ClientDBPerson[] u = checkpanic clientDBBackendClient->forward("/backend/getRecordArr", request, targetType = ClientDBPersonArray);
        payload = payload + " | " + u[0].name + " | " + u[1].age.toString();

        error? result = caller->respond(<@untainted>payload);
    }

    resource function get redirect(http:Caller caller, http:Request req) {
        http:Client redirectClient = checkpanic new("http://localhost:" + clientDatabindingTestPort3.toString(),
                                                        {followRedirects: {enabled: true, maxCount: 5}});
        json p = checkpanic redirectClient->post("/redirect1/", "want json", targetType = json);
        error? result = caller->respond(<@untainted>p);
    }

    resource function get 'retry(http:Caller caller, http:Request request) {
        http:Client retryClient = checkpanic new("http://localhost:" + clientDatabindingTestPort2.toString(), {
                retryConfig: { interval: 3, count: 3, backOffFactor: 2.0,
                maxWaitInterval: 2 },  timeout: 2
            }
        );
        string r = checkpanic retryClient->forward("/backend/getRetryResponse", request, targetType = string);
        error? responseToCaller = caller->respond(<@untainted>r);
    }

    resource function 'default '500(http:Caller caller, http:Request request) {
        json p = checkpanic clientDBBackendClient->post("/backend/get5XX", "want 500", targetType = json);
        error? responseToCaller = caller->respond(<@untainted>p);
    }

    resource function 'default '500handle(http:Caller caller, http:Request request) {
        var res = clientDBBackendClient->post("/backend/get5XX", "want 500", targetType = json);
        if res is http:RemoteServerError {
            http:Response resp = new;
            resp.statusCode = res.detail()?.statusCode ?: 500;
            resp.setPayload(<@untainted>res.message());
            error? responseToCaller = caller->respond(<@untainted>resp);
        } else {
            json p = checkpanic res;
            error? responseToCaller = caller->respond(<@untainted>p);
        }
    }

    resource function 'default '404(http:Caller caller, http:Request request) {
        json p = checkpanic clientDBBackendClient->post("/backend/getIncorrectPath404", "want 500", targetType = json);
        error? responseToCaller = caller->respond(<@untainted>p);
    }

    resource function  'default '404/[string path](http:Caller caller, http:Request request) {
        var res = clientDBBackendClient->post("/backend/" + <@untainted>path, "want 500", targetType = json);
        if res is http:ClientRequestError {
            http:Response resp = new;
            resp.statusCode = res.detail()?.statusCode ?: 400;
            resp.setPayload(<@untainted>res.message());
            error? responseToCaller = caller->respond(<@untainted>resp);
        } else {
            json p = checkpanic res;
            error? responseToCaller = caller->respond(<@untainted>p);
        }
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
        error? result = caller->respond(response);
    }

    resource function get get4XX(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.statusCode = 400;
        response.setTextPayload("data-binding-failed-due-to-bad-request");
        error? result = caller->respond(response);
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
@test:Config {}
function testAllBindingDataTypes() {
    var response = clientDBTestClient->get("/passthrough/allTypes");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "{\"id\":\"chamil\", \"values\":{\"a\":2, \"b\":45, " +
                 "\"c\":{\"x\":\"mnb\", \"y\":\"uio\"}}} | chamil | <name>Ballerina</name> | " +
                 "This is my @4491*&&#$^($@ | BinaryPayload is textVal | chamil | wso2 | 3 | data-binding");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test basic client with all HTTP request methods
@test:Config {}
function testDifferentMethods() {
    var response = clientDBTestClient->get("/passthrough/allMethods");
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
@test:Config {groups: ["now"]}
function testRedirectClientDataBinding() {
    var response = clientDBTestClient->get("/passthrough/redirect");
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
    var response = clientDBTestClient->get("/passthrough/retry");
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
    var response = clientDBTestClient->get("/passthrough/500");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 501, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "data-binding-failed-with-501");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 500 error handle
@test:Config {}
function test5XXHandleError() {
    var response = clientDBTestClient->get("/passthrough/500handle");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 501, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "data-binding-failed-with-501");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 404 error panic
@test:Config {}
function test4XXErrorPanic() {
    var response = clientDBTestClient->get("/passthrough/404");
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
    var response = clientDBTestClient->get("/passthrough/404/handle");
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
    var response = clientDBTestClient->get("/passthrough/404/get4XX");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Method not allowed");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
