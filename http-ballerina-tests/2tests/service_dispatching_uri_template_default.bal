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

listener http:Listener utdtestEP = new(uriTemplateDefaultTest1);
listener http:Listener utdmockEP1 = new(uriTemplateDefaultTest2);
listener http:Listener utdmockEP2 = new(uriTemplateDefaultTest3);


http:Client utdClient1 = new("http://localhost:" + uriTemplateDefaultTest1.toString());
http:Client utdClient2 = new("http://localhost:" + uriTemplateDefaultTest2.toString());
http:Client utdClient3 = new("http://localhost:" + uriTemplateDefaultTest3.toString());

@http:ServiceConfig {
    cors: {
        allowCredentials: true
    }
}
service serviceName on utdtestEP {

    @http:ResourceConfig {
        methods:["GET"],
        path:""
    }
    resource function test1 (http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"dispatched to service name"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {
    basePath:"/"
}
service serviceEmptyName on utdtestEP {

    resource function test1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"dispatched to empty service name"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/*"
    }
    resource function proxy(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"dispatched to a proxy service"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

service serviceWithNoAnnotation on utdtestEP {

    resource function test1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"dispatched to a service without an annotation"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

service on utdmockEP1 {
    resource function testResource(http:Caller caller, http:Request req) {
        checkpanic caller->respond({"echo":"dispatched to the service that neither has an explicitly defined basepath nor a name"});
    }
}

@http:ServiceConfig {
    compression: {enable: http:COMPRESSION_AUTO}
}
service on utdmockEP2 {
    resource function testResource(http:Caller caller, http:Request req) {
        checkpanic caller->respond("dispatched to the service that doesn't have a name but has a config without a basepath");
    }
}

//Test dispatching with Service name when basePath is not defined and resource path empty
@test:Config {}
function testServiceNameDispatchingWhenBasePathUndefined() {
    var response = utdClient1->get("/serviceName/test1");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "dispatched to service name");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching when resource annotation unavailable
@test:Config {}
function testServiceNameDispatchingWithEmptyBasePath() {
    var response = utdClient1->get("/test1");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "dispatched to empty service name");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with Service name when annotation is not available
@test:Config {}
function testServiceNameDispatchingWhenAnnotationUnavailable() {
    var response = utdClient1->get("/serviceWithNoAnnotation/test1");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "dispatched to a service without an annotation");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPureProxyService() {
    var response = utdClient1->get("/");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "dispatched to a proxy service");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching with default resource
@test:Config {}
function testDispatchingToDefault() {
    var response = utdClient1->get("/serviceEmptyName/hello");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "dispatched to a proxy service");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching to a service with no name and config
@test:Config {}
function testServiceWithNoNameAndNoConfig() {
    var response = utdClient2->get("/testResource");
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", 
                    "dispatched to the service that neither has an explicitly defined basepath nor a name");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test dispatching to a service with no name and no basepath in config
@test:Config {}
function testServiceWithNoName() {
    var response = utdClient3->get("/testResource");
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), 
                    "dispatched to the service that doesn't have a name but has a config without a basepath");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
