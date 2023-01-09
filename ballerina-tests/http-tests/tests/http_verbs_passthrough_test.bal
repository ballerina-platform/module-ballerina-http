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
import ballerina/http_test_common as common;

listener http:Listener httpVerbListenerEP = new (httpVerbTestPort, httpVersion = http:HTTP_1_1);
final http:Client httpVerbClient = check new ("http://localhost:" + httpVerbTestPort.toString(), httpVersion = http:HTTP_1_1);
final http:Client endPoint = check new ("http://localhost:" + httpVerbTestPort.toString(), httpVersion = http:HTTP_1_1);

service /headQuote on httpVerbListenerEP {

    resource function 'default 'default(http:Caller caller, http:Request req) returns error? {
        string method = req.method;
        http:Request clientRequest = new;

        http:Response|error response = endPoint->execute(method, "/getQuote/stocks", clientRequest);
        if response is http:Response {
            check caller->respond(response);
        } else {
            json errMsg = {"error": "error occurred while invoking the service"};
            check caller->respond(errMsg);
        }
    }

    resource function 'default forward11(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint->forward("/getQuote/stocks", req);
        if response is http:Response {
            check caller->respond(response);
        } else {
            json errMsg = {"error": "error occurred while invoking the service"};
            check caller->respond(errMsg);
        }
    }

    resource function 'default forward22(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint->forward("/getQuote/stocks", req);
        if response is http:Response {
            check caller->respond(response);
        } else {
            json errMsg = {"error": "error occurred while invoking the service"};
            check caller->respond(errMsg);
        }
    }

    resource function 'default getStock/[string method](http:Caller caller, http:Request req) returns error? {
        http:Request clientRequest = new;
        http:Response|error response = endPoint->execute(method, "/getQuote/stocks", clientRequest);
        if response is http:Response {
            check caller->respond(response);
        } else {
            json errMsg = {"error": "error occurred while invoking the service"};
            check caller->respond(errMsg);
        }
    }

    resource function 'default empty(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint->execute("", "/getQuote/stocks", req);
        if response is http:Response {
            check caller->respond(response);
        } else {
            json errMsg = {"error": "error occurred while invoking the service"};
            check caller->respond(errMsg);
        }
    }

    resource function 'default emptyErr(http:Caller caller, http:Request req) returns error? {
        http:Request clientRequest = new;
        http:Response|error response = endPoint->execute("", "/getQuote/stocks", clientRequest);
        if response is http:Response {
            check caller->respond(response);
        } else {
            check caller->respond(response.message());
        }
    }
}

service /sampleHead on httpVerbListenerEP {

    resource function head .(http:Caller caller, http:Request req) returns error? {
        http:Response|error response = endPoint->get("/getQuote/stocks");
        if response is http:Response {
            check caller->respond(response);
        } else {
            json errMsg = {"error": "error occurred while invoking the service"};
            check caller->respond(errMsg);
        }
    }
}

service /getQuote on httpVerbListenerEP {

    resource function get stocks(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("wso2");
        check caller->respond(res);
    }

    resource function post stocks(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("ballerina");
        check caller->respond(res);
    }

    resource function 'default stocks(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("Method", "any");
        res.setTextPayload("default");
        check caller->respond(res);
    }

    resource function post employee(http:Caller caller, http:Request req, @http:Payload {} json person) returns error? {
        http:Response res = new;
        res.setJsonPayload(person);
        check caller->respond(res);
    }
}

//Test simple passthrough test case For HEAD with URL. /sampleHead
@test:Config {}
function testPassthroughSampleForHEAD() {
    http:Response|error response = httpVerbClient->head("/sampleHead");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        test:assertTrue(response.hasHeader(common:CONTENT_LENGTH));
        common:assertTextPayload(response.getTextPayload(), "");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case For GET with URL. /headQuote/default
@test:Config {}
function testPassthroughSampleForGET() returns error? {
    http:Response|error response = httpVerbClient->get("/headQuote/default");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "wso2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case For POST
@test:Config {}
function testPassthroughSampleForPOST() returns error? {
    http:Response|error response = httpVerbClient->post("/headQuote/default", "test");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "ballerina");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case with default resource
@test:Config {}
function testPassthroughSampleWithDefaultResource() returns error? {
    http:Response|error response = httpVerbClient->head("/headQuote/default");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader("Method"), "any");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test default resource for outbound PUT with URL. /headQuote/getStock/PUT
@test:Config {}
function testOutboundPUT() returns error? {
    http:Response|error response = httpVerbClient->get("/headQuote/getStock/PUT");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader("Method"), "any");
        common:assertTextPayload(response.getTextPayload(), "default");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case with 'forward' For GET with URL. /headQuote/forward11
@test:Config {}
function testForwardActionWithGET() {
    http:Response|error response = httpVerbClient->get("/headQuote/forward11");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "wso2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case with 'forward' For POST with URL. /headQuote/forward22
@test:Config {}
function testForwardActionWithPOST() {
    http:Response|error response = httpVerbClient->post("/headQuote/forward22", "test");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(), "ballerina");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test HTTP data binding with JSON payload with URL. /getQuote/employee
@test:Config {}
function testDataBindingJsonPayload() {
    json payload = {name: "WSO2", team: "ballerina"};
    http:Response|error response = httpVerbClient->post("/getQuote/employee", payload);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertJsonPayload(response.getJsonPayload(), payload);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test HTTP data binding with incompatible payload with URL. /getQuote/employee
@test:Config {}
function testDataBindingWithIncompatiblePayload() returns error? {
    string payload = "name:WSO2,team:ballerina";
    http:Response response = check httpVerbClient->post("/getQuote/employee", payload);
    test:assertEquals(response.statusCode, 400, msg = "Found unexpected output");
    common:assertTextPayload(response.getTextPayload(),
        "data binding failed: incompatible type found: 'json'");
}

//Test with empty method in execute remote method uses the inbound verb
@test:Config {}
function testEmptyVerb() returns error? {
    http:Response|error response = httpVerbClient->get("/headQuote/empty");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "wso2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test with empty method and new request to result in error
@test:Config {}
function testEmptyVerbError() returns error? {
    http:Response|error response = httpVerbClient->get("/headQuote/emptyErr");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "client method invocation failed: HTTP Verb cannot be empty");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
