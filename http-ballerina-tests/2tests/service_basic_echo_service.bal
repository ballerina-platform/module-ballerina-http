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

import ballerina/mime;
import ballerina/test;
import ballerina/http;

final string constPath = getConstPath();

listener http:Listener serviceTestEP = new(serviceTest);
http:Client stClient = new("http://localhost:" + serviceTest.toString());

string globalLevelStr = "";

@http:ServiceConfig {basePath:"/echo"}
service echoService on serviceTestEP {

    @http:ResourceConfig {
        methods:["GET"],
        path:"/message"
    }
    resource function echo(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/message_worker"
    }
    resource function message_worker(http:Caller caller, http:Request req) {
        //worker w1 {
            http:Response res = new;
            checkpanic caller->respond(res);
        //}
        //worker w2 {
        //    int x = 0;
        //    int a = x + 1;
        //}
    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/setString"
    }
    resource function setString(http:Caller caller, http:Request req) {
        http:Response res = new;
        string payloadData = "";
        var payload = req.getTextPayload();
        if (payload is error) {
            return;
        } else {
            payloadData = payload;
        }
        globalLevelStr = <@untainted string> payloadData;
        checkpanic caller->respond(globalLevelStr);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/getString"
    }
    resource function getString(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload(<@untainted> globalLevelStr);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"]
    }
    resource function removeHeaders(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setHeader("header1", "wso2");
        res.setHeader("header2", "ballerina");
        res.setHeader("header3", "hello");
        res.removeAllHeaders();
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:constPath
    }
    resource function connstValueAsAttributeValue(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("constant path test");
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["GET"],
        path:"/testEmptyResourceBody"
    }
    resource function testEmptyResourceBody(http:Caller caller, http:Request req) {
    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/getFormParams"
    }
    resource function getFormParams(http:Caller caller, http:Request req) {
        var params = req.getFormParams();
        http:Response res = new;
        if (params is map<string>) {
            string? name = params["firstName"];
            string? team = params["team"];
            json responseJson = {"Name":(name is string ? name : "") , "Team":(team is string ? team : "")};
            res.setJsonPayload(<@untainted json> responseJson);
        } else {
            if (params is http:GenericClientError) {
                error? cause = params.cause();
                string? errorMsg;
                if (cause is error) {
                    errorMsg = cause.message();
                } else {
                    errorMsg = params.message();
                }
                if (errorMsg is string) {
                    res.setPayload(<@untainted string> errorMsg);
                } else {
                    res.setPayload("Error occrred");
                }
            } else {
                error err = params;
                string? errMsg = <string> err.message();
                res.setPayload(errMsg is string ? <@untainted string> errMsg : "Error in parsing form params");
            }
        }
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["PATCH"],
        path:"/modify"
    }
    resource function modify11(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.statusCode = 204;
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        methods:["POST"],
        path:"/parseJSON"
    }
    resource function errorReturn(http:Caller caller, http:Request req) returns @tainted error? {
        json payload = check req.getJsonPayload();
        http:Response res = new;
        res.setPayload(<@untainted json> payload);
        res.statusCode = 200;
        checkpanic caller->respond(res);
    }
}

function getConstPath() returns(string) {
    return "/constantPath";
}

@http:ServiceConfig {}
service hello on serviceTestEP {

    @http:ResourceConfig {}
    resource function echo(http:Caller caller, http:Request req) {
        checkpanic caller->respond("Uninitialized configs");
    }

    resource function testFunctionCall(http:Caller caller, http:Request req) {
        checkpanic caller->respond(<@untainted> self.nonRemoteFunctionCall());
    }

    function nonRemoteFunctionCall() returns string {
        return "Non remote function invoked";
    }
}

@test:Config {}
function testServiceDispatching() {
    var response = stClient->get("/echo/message");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMostSpecificBasePathIdentificationWithDuplicatedPath() {
    var response = stClient->get("/echo/message/echo/message");
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), 
                "no matching resource found for path : /echo/message/echo/message , method : GET");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMostSpecificBasePathIdentificationWithUnmatchedBasePath() {
    var response = stClient->get("/abcd/message/echo/message");
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), 
                "no matching service found for path : /abcd/message/echo/message");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testServiceDispatchingWithWorker() {
    var response = stClient->get("/echo/message_worker");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testServiceAvailabilityCheck() {
    var response = stClient->get("/foo/message");
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), 
                "no matching service found for path : /foo/message");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testResourceAvailabilityCheck() {
    var response = stClient->get("/echo/bar");
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), 
                "no matching resource found for path : /echo/bar , method : GET");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSetString() {
    http:Request req = new;
    req.setTextPayload("hello");
    req.setHeader(mime:CONTENT_TYPE, mime:TEXT_PLAIN);
    var response = stClient->post("/echo/setString", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "hello");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn : ["testSetString"]}
function testGetString() {
    var response = stClient->get("/echo/getString");
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "hello");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testConstantValueAsAnnAttributeVal() {
    var response = stClient->get("/echo/constantPath");
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "constant path test");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testRemoveHeadersNativeFunction() {
    var response = stClient->get("/echo/removeHeaders");
    if (response is http:Response) {
        test:assertFalse(response.hasHeader("header1"));
        test:assertFalse(response.hasHeader("header2"));
        test:assertFalse(response.hasHeader("header3"));
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsNativeFunction() {
    http:Request req = new;
    req.setTextPayload("firstName=WSO2&team=BalDance");
    req.setHeader(mime:CONTENT_TYPE, mime:APPLICATION_FORM_URLENCODED);
    var response = stClient->post("/echo/getFormParams", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Name", "WSO2");
        assertJsonValue(response.getJsonPayload(), "Team", "BalDance");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsForUndefinedKey() {
    http:Request req = new;
    req.setTextPayload("firstName=WSO2&company=BalDance");
    req.setHeader(mime:CONTENT_TYPE, mime:APPLICATION_FORM_URLENCODED);
    var response = stClient->post("/echo/getFormParams", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "Team", "");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsEmptyResponseMsgPayload() {
    http:Request req = new;
    req.setTextPayload("");
    req.setHeader(mime:CONTENT_TYPE, mime:APPLICATION_FORM_URLENCODED);
    var response = stClient->post("/echo/getFormParams", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "Error occurred while extracting text data from entity");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsWithUnsupportedMediaType() {
    http:Request req = new;
    req.setTextPayload("firstName=WSO2&company=BalDance");
    req.setHeader(mime:CONTENT_TYPE, mime:APPLICATION_JSON);
    var response = stClient->post("/echo/getFormParams", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "Invalid content type : expected 'application/x-www-form-urlencoded'");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsWithDifferentMediaTypeMutations() {
    http:Request req = new;
    req.setTextPayload("firstName=WSO2&company=BalDance");
    req.setHeader(mime:CONTENT_TYPE, mime:APPLICATION_FORM_URLENCODED + "; charset=UTF-8");
    var response = stClient->post("/echo/getFormParams", req);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {Name:"WSO2", Team:""});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    http:Request newReq = new;
    newReq.setTextPayload("firstName=WSO2&company=BalDance");
    newReq.setHeader(mime:CONTENT_TYPE, "Application/x-www-Form-urlencoded; ");
    response = stClient->post("/echo/getFormParams", newReq);
    if (response is http:Response) {
        assertJsonPayload(response.getJsonPayload(), {Name:"WSO2", Team:""});
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsWithoutContentType() {
    http:Request req = new;
    req.setTextPayload("firstName=WSO2&company=BalDance");
    var response = stClient->post("/echo/getFormParams", req);
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "Invalid content type : expected 'application/x-www-form-urlencoded'");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPATCHMethodWithBody() {
    var response = stClient->patch("/echo/modify", "WSO2");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected output");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testUninitializedAnnotations() {
    var response = stClient->get("/hello/echo");
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "Uninitialized configs");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNonRemoteFunctionInvocation() {
    var response = stClient->get("/hello/testFunctionCall");
    if (response is http:Response) {
        assertTextPayload(response.getTextPayload(), "Non remote function invoked");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testErrorReturn() {
    http:Request req = new;
    req.setTextPayload("name:WSO2eam:ballerina");
    var response = stClient->post("/echo/parseJSON", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertTextPayload(response.getTextPayload(), "error occurred while retrieving the json payload from the request");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
