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
import ballerina/http_test_common as common;

listener http:Listener serviceTestPortEP = new (serviceTestPort, httpVersion = http:HTTP_1_1);
final http:Client stClient = check new ("http://localhost:" + serviceTestPort.toString(), httpVersion = http:HTTP_1_1);

isolated string globalLevelStr = "";

isolated function setGlobalValue(string payload) {
    lock {
        globalLevelStr = payload;
    }
}

isolated function getGlobalValue() returns string {
    lock {
        return globalLevelStr;
    }
}

service /echo on serviceTestPortEP {

    resource function get message(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->respond(res);
    }

    resource function get message_worker(http:Caller caller, http:Request req) returns error? {
        //worker w1 {
        http:Response res = new;
        check caller->respond(res);
        //}
        //worker w2 {
        //    int x = 0;
        //    int a = x + 1;
        //}
    }

    resource function post setString(http:Caller caller, http:Request req) returns error? {
        string payloadData = "";
        var payload = req.getTextPayload();
        if (payload is error) {
            return;
        } else {
            payloadData = payload;
        }
        setGlobalValue(payloadData);
        check caller->respond(payloadData);
        return;
    }

    resource function get getString(http:Caller caller, http:Request req) returns error? {
        lock {
            http:Response res = new;
            res.setTextPayload(getGlobalValue());
            check caller->respond(res);
            return;
        }
    }

    resource function get removeHeaders(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("header1", "wso2");
        res.setHeader("header2", "ballerina");
        res.setHeader("header3", "hello");
        res.removeAllHeaders();
        check caller->respond(res);
    }

    resource function get testEmptyResourceBody(http:Caller caller, http:Request req) {
    }

    resource function post getFormParams(http:Caller caller, http:Request req) returns error? {
        var params = req.getFormParams();
        http:Response res = new;
        if (params is map<string>) {
            string? name = params["firstName"];
            string? team = params["team"];
            json responseJson = {"Name": (name is string ? name : ""), "Team": (team is string ? team : "")};
            res.setJsonPayload(responseJson);
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
                    res.setPayload(errorMsg);
                } else {
                    res.setPayload("Error occrred");
                }
            } else {
                error err = params;
                string? errMsg = <string>err.message();
                res.setPayload(errMsg is string ? errMsg : "Error in parsing form params");
            }
        }
        check caller->respond(res);
    }

    resource function post formData(http:Request request) returns string|error {
        string payload = "";
        map<string> requestBody = check request.getFormParams();
        if (requestBody.length() < 1) {
            payload = "Received request body is empty";
        } else {
            foreach var ['key, value] in requestBody.entries() {
                payload += string `[${'key}] -> [${value}]`;
            }
        }
        return payload;
    }

    resource function patch modify(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.statusCode = 204;
        check caller->respond(res);
    }

    resource function post parseJSON(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();
        http:Response res = new;
        res.setPayload(payload);
        res.statusCode = 200;
        check caller->respond(res);
    }
}

@http:ServiceConfig {}
service /hello on serviceTestPortEP {

    @http:ResourceConfig {}
    resource function 'default echo(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Uninitialized configs");
    }

    resource function 'default testFunctionCall(http:Caller caller, http:Request req) returns error? {
        string str;
        lock {
            str = self.nonRemoteFunctionCall();
        }
        check caller->respond(str);
    }

    isolated function nonRemoteFunctionCall() returns string {
        return "Non remote function invoked";
    }
}

@test:Config {}
function testServiceDispatching() {
    http:Response|error response = stClient->get("/echo/message");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMostSpecificBasePathIdentificationWithDuplicatedPath() {
    http:Response|error response = stClient->get("/echo/message/echo/message");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(),
                "no matching resource found for path : /echo/message/echo/message , method : GET");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testMostSpecificBasePathIdentificationWithUnmatchedBasePath() {
    http:Response|error response = stClient->get("/abcd/message/echo/message");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(),
                "no matching service found for path : /abcd/message/echo/message");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testServiceDispatchingWithWorker() {
    http:Response|error response = stClient->get("/echo/message_worker");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testServiceAvailabilityCheck() {
    http:Response|error response = stClient->get("/foo/message");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(),
                "no matching service found for path : /foo/message");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testResourceAvailabilityCheck() {
    http:Response|error response = stClient->get("/echo/bar");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(),
                "no matching resource found for path : /echo/bar , method : GET");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testSetString() {
    http:Request req = new;
    req.setTextPayload("hello");
    req.setHeader(mime:CONTENT_TYPE, mime:TEXT_PLAIN);
    http:Response|error response = stClient->post("/echo/setString", req);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {dependsOn: [testSetString]}
function testGetString() {
    http:Response|error response = stClient->get("/echo/getString");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "hello");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testRemoveHeadersNativeFunction() {
    http:Response|error response = stClient->get("/echo/removeHeaders");
    if response is http:Response {
        test:assertFalse(response.hasHeader("header1"));
        test:assertFalse(response.hasHeader("header2"));
        test:assertFalse(response.hasHeader("header3"));
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsNativeFunction() {
    http:Request req = new;
    req.setTextPayload("firstName=WSO2&team=BalDance");
    req.setHeader(mime:CONTENT_TYPE, mime:APPLICATION_FORM_URLENCODED);
    http:Response|error response = stClient->post("/echo/getFormParams", req);
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "Name", "WSO2");
        common:assertJsonValue(response.getJsonPayload(), "Team", "BalDance");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsForUndefinedKey() {
    http:Request req = new;
    req.setTextPayload("firstName=WSO2&company=BalDance");
    req.setHeader(mime:CONTENT_TYPE, mime:APPLICATION_FORM_URLENCODED);
    http:Response|error response = stClient->post("/echo/getFormParams", req);
    if response is http:Response {
        common:assertJsonValue(response.getJsonPayload(), "Team", "");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsEmptyResponseMsgPayload() {
    http:Request req = new;
    req.setTextPayload("");
    req.setHeader(mime:CONTENT_TYPE, mime:APPLICATION_FORM_URLENCODED);
    http:Response|error response = stClient->post("/echo/getFormParams", req);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "Error occurred while extracting text data from entity");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsWithUnsupportedMediaType() {
    http:Request req = new;
    req.setTextPayload("firstName=WSO2&company=BalDance");
    req.setHeader(mime:CONTENT_TYPE, mime:APPLICATION_JSON);
    http:Response|error response = stClient->post("/echo/getFormParams", req);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "Invalid content type : expected 'application/x-www-form-urlencoded'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsWithDifferentMediaTypeMutations() {
    http:Request req = new;
    req.setTextPayload("firstName=WSO2&company=BalDance");
    req.setHeader(mime:CONTENT_TYPE, mime:APPLICATION_FORM_URLENCODED + "; charset=UTF-8");
    http:Response|error response = stClient->post("/echo/getFormParams", req);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {Name: "WSO2", Team: ""});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    http:Request newReq = new;
    newReq.setTextPayload("firstName=WSO2&company=BalDance");
    newReq.setHeader(mime:CONTENT_TYPE, "Application/x-www-Form-urlencoded; ");
    response = stClient->post("/echo/getFormParams", newReq);
    if response is http:Response {
        common:assertJsonPayload(response.getJsonPayload(), {Name: "WSO2", Team: ""});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testGetFormParamsWithoutContentType() {
    http:Request req = new;
    req.setTextPayload("firstName=WSO2&company=BalDance");
    http:Response|error response = stClient->post("/echo/getFormParams", req);
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "Invalid content type : expected 'application/x-www-form-urlencoded'");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testPATCHMethodWithBody() {
    http:Response|error response = stClient->patch("/echo/modify", "WSO2");
    if response is http:Response {
        test:assertEquals(response.statusCode, 204, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testUninitializedAnnotations() {
    http:Response|error response = stClient->get("/hello/echo");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "Uninitialized configs");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testNonRemoteFunctionInvocation() {
    http:Response|error response = stClient->get("/hello/testFunctionCall");
    if response is http:Response {
        common:assertTextPayload(response.getTextPayload(), "Non remote function invoked");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testErrorReturn() {
    http:Request req = new;
    req.setTextPayload("name:WSO2eam:ballerina");
    http:Response|error response = stClient->post("/echo/parseJSON", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertTextPayload(response.getTextPayload(),
            "Error occurred while retrieving the json payload from the request");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testEncodedFormParam() returns error? {
    http:Request req = new;
    req.setTextPayload("first%20Name=WS%20O2&tea%24%2Am=Bal%40Dance", contentType = mime:APPLICATION_FORM_URLENCODED);
    string response = check stClient->post("/echo/formData", req);
    test:assertEquals(response, "[first Name] -> [WS O2][tea$*m] -> [Bal@Dance]", msg = "Found unexpected output");
    return;
}

@test:Config {}
function testPlusEncodedFormParam() returns error? {
    http:Request req = new;
    req.setTextPayload("first+Name=WS+O2&tea%24%2Am=Bal%40Dance", contentType = mime:APPLICATION_FORM_URLENCODED);
    string response = check stClient->post("/echo/formData", req);
    test:assertEquals(response, "[first Name] -> [WS O2][tea$*m] -> [Bal@Dance]", msg = "Found unexpected output");
    return;
}

@test:Config {}
function testEncodedFormData() returns error? {
    http:Request req = new;
    req.setTextPayload("first%20Name%3DWS%20O2%26tea%24%2Am%3DBal%40Dance", contentType = mime:APPLICATION_FORM_URLENCODED);
    string response = check stClient->post("/echo/formData", req);
    test:assertEquals(response, "[first Name] -> [WS O2][tea$*m] -> [Bal@Dance]", msg = "Found unexpected output");
    return;
}
