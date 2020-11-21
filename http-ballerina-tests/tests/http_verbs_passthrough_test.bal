// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;
import ballerina/http;

listener http:Listener httpVerbListenerEP = new(httpVerbTestPort);
http:Client httpVerbClient = new("http://localhost:" + httpVerbTestPort.toString());

http:Client endPoint = new("http://localhost:" + httpVerbTestPort.toString());

@http:ServiceConfig {
    basePath:"/headQuote"
}
service headQuoteService on httpVerbListenerEP {

    @http:ResourceConfig {
        path:"/default"
    }
    resource function defaultResource (http:Caller caller, http:Request req) {
        string method = req.method;
        http:Request clientRequest = new;

        var response = endPoint -> execute(<@untainted> method, "/getQuote/stocks", clientRequest);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            json errMsg = {"error":"error occurred while invoking the service"};
           checkpanic caller->respond(errMsg);
        }
    }

    @http:ResourceConfig {
        path:"/forward11"
    }
    resource function forwardRes11 (http:Caller caller, http:Request req) {
        var response = endPoint -> forward("/getQuote/stocks", req);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            json errMsg = {"error":"error occurred while invoking the service"};
           checkpanic caller->respond(errMsg);
        }
    }

    @http:ResourceConfig {
        path:"/forward22"
    }
    resource function forwardRes22 (http:Caller caller, http:Request req) {
        var response = endPoint -> forward("/getQuote/stocks", req);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            json errMsg = {"error":"error occurred while invoking the service"};
           checkpanic caller->respond(errMsg);
        }
    }

    @http:ResourceConfig {
        path:"/getStock/{method}"
    }
    resource function commonResource (http:Caller caller, http:Request req, string method) {
        http:Request clientRequest = new;
        var response = endPoint -> execute(<@untainted> method, "/getQuote/stocks", clientRequest);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            json errMsg = {"error":"error occurred while invoking the service"};
           checkpanic caller->respond(errMsg);
        }
    }
}

@http:ServiceConfig {
    basePath:"/sampleHead"
}
service testClientConHEAD on httpVerbListenerEP {

    @http:ResourceConfig {
        methods:["HEAD"],
        path:"/"
    }
    resource function passthrough (http:Caller caller, http:Request req) {
        http:Request clientRequest = new;
        var response = endPoint -> get("/getQuote/stocks", clientRequest);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            json errMsg = {"error":"error occurred while invoking the service"};
           checkpanic caller->respond(errMsg);
        }
    }
}

@http:ServiceConfig {
    basePath:"/getQuote"
}
service quoteService2 on httpVerbListenerEP {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/stocks"
    }
    resource function company (http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("wso2");
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/stocks"
    }
    resource function product (http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("ballerina");
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        path:"/stocks"
    }
    resource function defaultStock (http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setHeader("Method", "any");
        res.setTextPayload("default");
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["POST"],
        body:"person"
    }
    resource function employee (http:Caller caller, http:Request req, json person) {
        http:Response res = new;
        res.setJsonPayload(<@untainted> person);
        checkpanic caller->respond(res);
    }
}

//Test simple passthrough test case For HEAD with URL. /sampleHead
@test:Config {}
function testPassthroughSampleForHEAD() {
    var response = httpVerbClient->head("/sampleHead");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertTrue(response.hasHeader(CONTENT_LENGTH));
        assertTextPayload(response.getTextPayload(), "");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case For GET with URL. /headQuote/default
@test:Config {}
function testPassthroughSampleForGET() {
    var response = httpVerbClient->get("/headQuote/default");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "wso2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case For POST
@test:Config {}
function testPassthroughSampleForPOST() {
    var response = httpVerbClient->post("/headQuote/default", "test");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "ballerina");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case with default resource
@test:Config {}
function testPassthroughSampleWithDefaultResource() {
    var response = httpVerbClient->head("/headQuote/default");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader("Method"), "any");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test default resource for outbound PUT with URL. /headQuote/getStock/PUT
@test:Config {}
function testOutboundPUT() {
    var response = httpVerbClient->get("/headQuote/getStock/PUT");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader("Method"), "any");
        assertTextPayload(response.getTextPayload(), "default");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case with 'forward' For GET with URL. /headQuote/forward11
@test:Config {}
function testForwardActionWithGET() {
    var response = httpVerbClient->get("/headQuote/forward11");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "wso2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case with 'forward' For POST with URL. /headQuote/forward22
@test:Config {}
function testForwardActionWithPOST() {
    var response = httpVerbClient->post("/headQuote/forward22", "test");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "ballerina");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test HTTP data binding with JSON payload with URL. /getQuote/employee
@test:Config {}
function testDataBindingJsonPayload() {
    json payload = {name:"WSO2", team:"ballerina"};
    var response = httpVerbClient->post("/getQuote/employee", payload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertJsonPayload(response.getJsonPayload(), payload);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test HTTP data binding with incompatible payload with URL. /getQuote/employee
@test:Config {}
function testDataBindingWithIncompatiblePayload() {
    string payload = "name:WSO2,team:ballerina";
    var response = httpVerbClient->post("/getQuote/employee", payload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
        assertTrueTextPayload(response.getTextPayload(), "data binding failed: error(\"unrecognized token 'name:WSO2,team:ballerina'");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

