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
http:Client httpVerbClient = check new("http://localhost:" + httpVerbTestPort.toString());

http:Client endPoint = check new("http://localhost:" + httpVerbTestPort.toString());

service /headQuote on httpVerbListenerEP {

    resource function 'default 'default(http:Caller caller, http:Request req) {
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

    resource function 'default forward11(http:Caller caller, http:Request req) {
        var response = endPoint -> forward("/getQuote/stocks", req);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            json errMsg = {"error":"error occurred while invoking the service"};
           checkpanic caller->respond(errMsg);
        }
    }

    resource function 'default forward22(http:Caller caller, http:Request req) {
        var response = endPoint -> forward("/getQuote/stocks", req);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            json errMsg = {"error":"error occurred while invoking the service"};
           checkpanic caller->respond(errMsg);
        }
    }

    resource function 'default getStock/[string method](http:Caller caller, http:Request req) {
        http:Request clientRequest = new;
        var response = endPoint -> execute(<@untainted> method, "/getQuote/stocks", clientRequest);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            json errMsg = {"error":"error occurred while invoking the service"};
           checkpanic caller->respond(errMsg);
        }
    }

    resource function 'default empty(http:Caller caller, http:Request req) {
        var response = endPoint -> execute("", "/getQuote/stocks", req);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            json errMsg = {"error":"error occurred while invoking the service"};
            checkpanic caller->respond(errMsg);
        }
    }

    resource function 'default emptyErr(http:Caller caller, http:Request req) {
        http:Request clientRequest = new;
        var response = endPoint -> execute("", "/getQuote/stocks", clientRequest);
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            checkpanic caller->respond(response.message());
        }
    }
}

service /sampleHead on httpVerbListenerEP {

    resource function head .(http:Caller caller, http:Request req) {
        var response = endPoint -> get("/getQuote/stocks");
        if (response is http:Response) {
            checkpanic caller->respond(<@untainted> response);
        } else {
            json errMsg = {"error":"error occurred while invoking the service"};
           checkpanic caller->respond(errMsg);
        }
    }
}

service /getQuote on httpVerbListenerEP {

    resource function get stocks(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("wso2");
        checkpanic caller->respond(res);
    }

    resource function post stocks(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("ballerina");
        checkpanic caller->respond(res);
    }

    resource function 'default stocks (http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setHeader("Method", "any");
        res.setTextPayload("default");
        checkpanic caller->respond(res);
    }

    resource function post employee (http:Caller caller, http:Request req, @http:Payload {} json person) {
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
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "wso2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case For POST
@test:Config {}
function testPassthroughSampleForPOST() {
    var response = httpVerbClient->post("/headQuote/default", "test");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "ballerina");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple passthrough test case with default resource
@test:Config {}
function testPassthroughSampleWithDefaultResource() {
    var response = httpVerbClient->head("/headQuote/default");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader("Method"), "any");
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
        assertHeaderValue(checkpanic response.getHeader("Method"), "any");
        assertTextPayload(response.getTextPayload(), "default");
    } else {
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
    } else {
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
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test HTTP data binding with JSON payload with URL. /getQuote/employee
@test:Config {}
function testDataBindingJsonPayload() {
    json payload = {name:"WSO2", team:"ballerina"};
    var response = httpVerbClient->post("/getQuote/employee", payload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertJsonPayload(response.getJsonPayload(), payload);
    } else {
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
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test with empty method in execute remote method uses the inbound verb
@test:Config {}
function testEmptyVerb() {
    var response = httpVerbClient->get("/headQuote/empty");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "wso2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test with empty method and new request to result in error
@test:Config {}
function testEmptyVerbError() {
    var response = httpVerbClient->get("/headQuote/emptyErr");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "client method invocation failed: HTTP Verb cannot be empty");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
