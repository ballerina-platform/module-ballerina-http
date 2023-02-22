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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener utdtestEP = new (uriTemplateDefaultTestPort1, httpVersion = http:HTTP_1_1);
listener http:Listener utdmockEP1 = new (uriTemplateDefaultTestPort2, httpVersion = http:HTTP_1_1);
listener http:Listener utdmockEP2 = new (uriTemplateDefaultTestPort3, httpVersion = http:HTTP_1_1);

final http:Client utdClient1 = check new ("http://localhost:" + uriTemplateDefaultTestPort1.toString(), httpVersion = http:HTTP_1_1);
final http:Client utdClient2 = check new ("http://localhost:" + uriTemplateDefaultTestPort2.toString(), httpVersion = http:HTTP_1_1);
final http:Client utdClient3 = check new ("http://localhost:" + uriTemplateDefaultTestPort3.toString(), httpVersion = http:HTTP_1_1);

@http:ServiceConfig {
    cors: {
        allowCredentials: true
    }
}
service /serviceName on utdtestEP {

    resource function get test1(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"echo": "dispatched to service name"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }
}

service "/" on utdtestEP {

    resource function 'default test1(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"echo": "dispatched to empty service name"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }

    // proxy
    resource function 'default [string... s](http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"echo": "dispatched to a proxy service"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }
}

service /serviceWithNoAnnotation on utdtestEP {

    resource function 'default test1(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        json responseJson = {"echo": "dispatched to a service without an annotation"};
        res.setJsonPayload(responseJson);
        check caller->respond(res);
    }
}

service on utdmockEP1 {
    resource function 'default testResource(http:Caller caller, http:Request req) returns error? {
        check caller->respond({"echo": "dispatched to the service that neither has an explicitly defined basepath nor a name"});
    }
}

@http:ServiceConfig {
    compression: {enable: http:COMPRESSION_AUTO}
}
service on utdmockEP2 {
    resource function 'default testResource(http:Caller caller, http:Request req) returns error? {
        check caller->respond("dispatched to the service that doesn't have a name but has a config without a basepath");
    }
}

service /call on utdtestEP {

    resource function get abc() returns string {
        return "abc";
    }

    resource function get abc/[string bc]() returns string {
        return "abc/path";
    }

    resource function get abcd() returns string {
        return "abcd";
    }

    resource function get bar/[string... a]() returns string {
        return "First response!";
    }
}

//Test dispatching with Service name when basePath is not defined and resource path empty
@test:Config {}
function testServiceNameDispatchingWhenBasePathUndefined() {
    http:Response|error response = utdClient1->get("/serviceName/test1");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo", "dispatched to service name");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching when resource annotation unavailable
@test:Config {}
function testServiceNameDispatchingWithEmptyBasePath() {
    http:Response|error response = utdClient1->get("/test1");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo", "dispatched to empty service name");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with Service name when annotation is not available
@test:Config {}
function testServiceNameDispatchingWhenAnnotationUnavailable() {
    http:Response|error response = utdClient1->get("/serviceWithNoAnnotation/test1");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo", "dispatched to a service without an annotation");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPureProxyService() {
    http:Response|error response = utdClient1->get("/");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo", "dispatched to a proxy service");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with default resource
@test:Config {}
function testDispatchingToDefault() {
    http:Response|error response = utdClient1->get("/serviceEmptyName/hello");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo", "dispatched to a proxy service");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching to a service with no name and config
@test:Config {}
function testServiceWithNoNameAndNoConfig() {
    http:Response|error response = utdClient2->get("/testResource");
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "echo",
                    "dispatched to the service that neither has an explicitly defined basepath nor a name");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching to a service with no name and no basepath in config
@test:Config {}
function testServiceWithNoName() {
    http:Response|error response = utdClient3->get("/testResource");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(),
                    "dispatched to the service that doesn't have a name but has a config without a basepath");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testUnmatchedURIPathGettingMatchedToPathParam() {
    string|error response = utdClient1->get("/call/abcde");
    if response is http:ClientRequestError {
        test:assertEquals(response.message(), "Not Found", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected type");
    }

    response = utdClient1->get("/call/abcd");
    if response is string {
        test:assertEquals(response, "abcd", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found error: " + response.message());
    }

    response = utdClient1->get("/call/abc/d");
    if response is string {
        test:assertEquals(response, "abc/path", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found error: " + response.message());
    }
}

@test:Config {}
function testUnmatchedURIPathGettingMatchedToRestParam() {
    string|error response = utdClient1->get("/call/barrr/baz");
    if (response is http:ClientRequestError) {
        test:assertEquals(response.message(), "Not Found", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected type");
    }
}
