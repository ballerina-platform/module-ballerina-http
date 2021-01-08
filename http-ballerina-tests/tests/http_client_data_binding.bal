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

service /passthrough on clientDBProxyListener {

    resource function get allTypes(http:Caller caller, http:Request request) returns @tainted error? {
        string payload = "";

        var res = clientDBBackendClient->post("/backend/getJson", "want json", targetType = json);
        json p = <json> checkpanic res;
        payload = payload + p.toJsonString();

        res = clientDBBackendClient->post("/backend/getJson", "want json", MapOfJson);
        map<json> p1 = <map<json>> checkpanic res;
        json name = check p1.id;
        payload = payload + " | " + name.toJsonString();

        res = clientDBBackendClient->post("/backend/getXml", "want xml", xml);
        xml q = <xml> checkpanic res;
        payload = payload + " | " + q.toString();

        res = clientDBBackendClient->post("/backend/getString", "want string", targetType = string);
        string r = <string> checkpanic res;
        payload = payload + " | " + r;

        res = clientDBBackendClient->post("/backend/getByteArray", "want byte[]", ByteArray);
        byte[] val = <byte[]> checkpanic res;
        string s = check <@untainted>'string:fromBytes(val);
        payload = payload + " | " + s;

        res = clientDBBackendClient->post("/backend/getRecord", "want record", targetType = ClientDBPerson);
        ClientDBPerson t = <ClientDBPerson> checkpanic res;
        payload = payload + " | " + t.name;

        res = clientDBBackendClient->post("/backend/getRecordArr", "want record[]", targetType = ClientDBPersonArray);
        ClientDBPerson[] u = <ClientDBPerson[]> checkpanic res;
        payload = payload + " | " + u[0].name + " | " + u[1].age.toString();

        res = clientDBBackendClient->post("/backend/getResponse", "want record[]", targetType = http:Response);
        http:Response v = <http:Response> checkpanic res;
        payload = payload + " | " + v.getHeader("x-fact");

        var result = caller->respond(<@untainted>payload);
    }

    resource function get allMethods(http:Caller caller, http:Request request) returns error? {
        string payload = "";

        var res = clientDBBackendClient->get("/backend/getJson", targetType = json);
        json p = <json> checkpanic res;
        payload = payload + p.toJsonString();

        res = clientDBBackendClient->head("/backend/getXml", "want xml");
        http:Response v = <http:Response> checkpanic res;
        payload = payload + " | " + v.getHeader("Content-type");

        res = clientDBBackendClient->delete("/backend/getString", "want string", targetType = string);
        string r = <string> checkpanic res;
        payload = payload + " | " + r;

        res = clientDBBackendClient->put("/backend/getByteArray", "want byte[]", ByteArray);
        byte[] val = <byte[]> checkpanic res;
        string s = check <@untainted>'string:fromBytes(val);
        payload = payload + " | " + s;

        res = clientDBBackendClient->execute("POST", "/backend/getRecord", "want record", targetType = ClientDBPerson);
        ClientDBPerson t = <ClientDBPerson> checkpanic res;
        payload = payload + " | " + t.name;

        res = clientDBBackendClient->forward("/backend/getRecordArr", request, targetType = ClientDBPersonArray);
        ClientDBPerson[] u = <ClientDBPerson[]> checkpanic res;
        payload = payload + " | " + u[0].name + " | " + u[1].age.toString();

        var result = caller->respond(<@untainted>payload);
    }

    resource function get redirect(http:Caller caller, http:Request req) {
        http:Client redirectClient = new("http://localhost:" + clientDatabindingTestPort3.toString(),
                                                        {followRedirects: {enabled: true, maxCount: 5}});
        var res = redirectClient->post("/redirect1/", "want json", targetType = json);
        json p = <json> checkpanic res;
        var result = caller->respond(<@untainted>p);
    }

    resource function get 'retry(http:Caller caller, http:Request request) {
        http:Client retryClient = new ("http://localhost:" + clientDatabindingTestPort2.toString(), {
                retryConfig: { intervalInMillis: 3000, count: 3, backOffFactor: 2.0,
                maxWaitIntervalInMillis: 20000 },  timeoutInMillis: 2000
            }
        );
        var backendResponse = retryClient->forward("/backend/getRetryResponse", request, targetType = string);
        string r = <string> checkpanic backendResponse;
        var responseToCaller = caller->respond(<@untainted>r);
    }

    resource function 'default cast(http:Caller caller, http:Request request) {
        var res = clientDBBackendClient->post("/backend/getJson", "want json", targetType = json);
        xml p = <xml> checkpanic res;
        var responseToCaller = caller->respond(<@untainted>p);
    }

    resource function 'default '500(http:Caller caller, http:Request request) {
        var res = clientDBBackendClient->post("/backend/get5XX", "want 500", targetType = json);
        json p = <json> checkpanic res;
        var responseToCaller = caller->respond(<@untainted>p);
    }

    resource function 'default '500handle(http:Caller caller, http:Request request) {
        var res = clientDBBackendClient->post("/backend/get5XX", "want 500", targetType = json);
        if res is http:RemoteServerError {
            http:Response resp = new;
            resp.statusCode = res.detail()?.statusCode ?: 500;
            resp.setPayload(<@untainted>res.message());
            var responseToCaller = caller->respond(<@untainted>resp);
        } else {
            json p = <json> checkpanic res;
            var responseToCaller = caller->respond(<@untainted>p);
        }
    }

    resource function 'default '404(http:Caller caller, http:Request request) {
        var res = clientDBBackendClient->post("/backend/getIncorrectPath404", "want 500", targetType = json);
        json p = <json> checkpanic res;
        var responseToCaller = caller->respond(<@untainted>p);
    }

    resource function  'default '404/[string path](http:Caller caller, http:Request request) {
        var res = clientDBBackendClient->post("/backend/" + <@untainted>path, "want 500", targetType = json);
        if res is http:ClientRequestError {
            http:Response resp = new;
            resp.statusCode = res.detail()?.statusCode ?: 400;
            resp.setPayload(<@untainted>res.message());
            var responseToCaller = caller->respond(<@untainted>resp);
        } else {
            json p = <json> checkpanic res;
            var responseToCaller = caller->respond(<@untainted>p);
        }
    }
}

service /backend on clientDBBackendListener {
    resource function 'default getJson(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload({id: "chamil", values: {a: 2, b: 45, c: {x: "mnb", y: "uio"}}});
        var result = caller->respond(response);
    }

    resource function 'default getXml(http:Caller caller, http:Request req) {
        http:Response response = new;
        xml xmlStr = xml `<name>Ballerina</name>`;
        response.setXmlPayload(xmlStr);
        var result = caller->respond(response);
    }

    resource function 'default getString(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setTextPayload("This is my @4491*&&#$^($@");
        var result = caller->respond(response);
    }

    resource function 'default getByteArray(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setBinaryPayload("BinaryPayload is textVal".toBytes());
        var result = caller->respond(response);
    }

    resource function 'default getRecord(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload({name: "chamil", age: 15});
        var result = caller->respond(response);
    }

    resource function 'default getRecordArr(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload([{name: "wso2", age: 12}, {name: "ballerina", age: 3}]);
        var result = caller->respond(response);
    }

    resource function post getResponse(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.setJsonPayload({id: "hello"});
        response.setHeader("x-fact", "data-binding");
        var result = caller->respond(response);
    }

    resource function 'default getRetryResponse(http:Caller caller, http:Request req) {
        clientDBCounter = clientDBCounter + 1;
        if (clientDBCounter == 1) {
            runtime:sleep(5000);
            var responseToCaller = caller->respond("Not received");
        } else {
            var responseToCaller = caller->respond("Hello World!!!");
        }
    }

    resource function post get5XX(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.statusCode = 501;
        response.setTextPayload("data-binding-failed-with-501");
        var result = caller->respond(response);
    }

    resource function get get4XX(http:Caller caller, http:Request req) {
        http:Response response = new;
        response.statusCode = 400;
        response.setTextPayload("data-binding-failed-due-to-bad-request");
        var result = caller->respond(response);
    }
}

service /redirect1 on clientDBBackendListener2 {

    resource function 'default .(http:Caller caller, http:Request req) {
        http:Response res = new;
        var result = caller->redirect(res, http:REDIRECT_SEE_OTHER_303,
                        ["http://localhost:" + clientDatabindingTestPort2.toString() + "/backend/getJson"]);
    }
}

// Test HTTP basic client with all binding data types(targetTypes)
@test:Config {}
function testAllBindingDataTypes() {
    var response = clientDBTestClient->get("/passthrough/allTypes");
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
    var response = clientDBTestClient->get("/passthrough/allMethods");
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
    var response = clientDBTestClient->get("/passthrough/redirect");
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
    var response = clientDBTestClient->get("/passthrough/retry");
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
    var response = clientDBTestClient->get("/passthrough/cast");
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
    var response = clientDBTestClient->get("/passthrough/500");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 501, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "data-binding-failed-with-501");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 500 error handle
@test:Config {}
function test5XXHandleError() {
    var response = clientDBTestClient->get("/passthrough/500handle");
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
    var response = clientDBTestClient->get("/passthrough/404");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), 
            "no matching resource found for path : /backend/getIncorrectPath404 , method : POST");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 404 error handle
@test:Config {}
function test4XXHandleError() {
    var response = clientDBTestClient->get("/passthrough/404/handle");
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
    var response = clientDBTestClient->get("/passthrough/404/get4XX");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "method not allowed");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
