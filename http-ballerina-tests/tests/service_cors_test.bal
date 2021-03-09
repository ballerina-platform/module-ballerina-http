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

listener http:Listener corsConfigEP = new(corsConfigTest);
http:Client corsClient = check new("http://localhost:" + corsConfigTest.toString());

@http:ServiceConfig {
    cors:{
        allowOrigins:["http://www.m3.com", "http://www.hello.com"],
        allowCredentials:true,
        allowHeaders:["CORELATION_ID"],
        exposeHeaders:["CORELATION_ID"],
        maxAge:1
    }
}
service /hello1 on corsConfigEP {

    @http:ResourceConfig {
        cors: {
            allowOrigins :["http://www.wso2.com", "http://www.facebook.com"],
            allowCredentials : true,
            allowHeaders:["X-Content-Type-Options", "X-PINGOTHER"]
        }
    }
    resource function post test1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"resCors"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    resource function get test2(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"serCors"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        cors:{
            allowOrigins :["http://www.wso2.com", "http://facebook.com", "http://www.amazon.com"],
            allowCredentials:true
        }
    }
    resource function post test3(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"moreOrigins"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        cors:{
            allowOrigins :["*"],
            allowMethods: ["*"],
            allowCredentials:true
        }
    }
    resource function put test4(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"moreOrigins"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

service /hello2 on corsConfigEP {

    @http:ResourceConfig {
         cors: {
            allowOrigins :["http://www.hello.com", " http://www.facebook.com  "],
            exposeHeaders:["X-Content-Type-Options", "X-PINGOTHER"]
        }
    }
    resource function post test1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"resOnlyCors"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        cors:{
            allowMethods :["HEAD", "PUT"],
            allowOrigins:["http://www.bbc.com", " http://www.amazon.com  "],
            exposeHeaders:["X-Content-Type-Options", "X-PINGOTHER"]
        }
    }
    resource function put test2(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"optionsOnly"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {
    cors:{
        allowCredentials : true,
        allowMethods:["GET", "PUT"],
        allowOrigins:["http://www.m3.com", "http://www.facebook.com"],
        allowHeaders:["X-Content-Type-Options", "X-PINGOTHER"],
        maxAge:1
    }
}
service /hello3 on corsConfigEP {

    resource function put info1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"cors"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

service /echo4 on corsConfigEP {

    resource function post info1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"noCors"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    resource function options info2(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"noCorsOPTIONS"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }

    @http:ResourceConfig {
        cors:{
            allowOrigins:["*"],
            allowMethods: ["*"],
            allowCredentials : true,
            exposeHeaders:["X-Content-Type-Options", "X-PINGOTHER"]
        }
    }
    resource function post info3(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"resourceDefaults"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {
    cors:{
        allowOrigins:["*"],
        allowMethods: ["*"]
    }
}
service /hello5 on corsConfigEP {

    resource function post info1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = {"echo":"serviceDefaults"};
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

//Test for CORS override at two levels for simple requests
@test:Config {}
function testSimpleReqServiceResourceCorsOverride() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2.com");
    var response = corsClient->post("/hello1/test1", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "resCors");
        assertHeaderValue(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_ORIGIN), "http://www.wso2.com");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for simple request service CORS
@test:Config {}
function testSimpleReqServiceCors() {
    http:Request req = new;
    req.setHeader(ORIGIN, "http://www.hello.com");
    var response = corsClient->get("/hello1/test2", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "serCors");
        assertHeaderValue(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_ORIGIN), "http://www.hello.com");
        assertHeaderValue(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_CREDENTIALS), "true");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for resource only CORS declaration
@test:Config {}
function testSimpleReqResourceOnlyCors() {
    http:Request req = new;
    req.setTextPayload("hello");
    req.setHeader(ORIGIN, "http://www.hello.com");
    var response = corsClient->post("/hello2/test1", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "resOnlyCors");
        assertHeaderValue(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_ORIGIN), "http://www.hello.com");
        test:assertFalse(response.hasHeader(ACCESS_CONTROL_ALLOW_CREDENTIALS));
        assertHeaderValue(checkpanic response.getHeader(ACCESS_CONTROL_EXPOSE_HEADERS), "X-Content-Type-Options, X-PINGOTHER");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple request with multiple origins
@test:Config {}
function testSimpleReqMultipleOrigins() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2.com http://www.amazon.com");
    var response = corsClient->post("/hello1/test3", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "moreOrigins");
        assertHeaderValue(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_ORIGIN), "http://www.wso2.com http://www.amazon.com");
        test:assertTrue(response.hasHeader(ACCESS_CONTROL_ALLOW_CREDENTIALS));
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple request for invalid origins
@test:Config {}
function testSimpleReqInvalidOrigin() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "www.wso2.com");
    var response = corsClient->post("/hello1/test1", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "resCors");
        test:assertFalse(response.hasHeader(ACCESS_CONTROL_ALLOW_ORIGIN));
        test:assertFalse(response.hasHeader(ACCESS_CONTROL_ALLOW_CREDENTIALS));
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test simple request for null origins
@test:Config {}
function testSimpleReqWithNullOrigin() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "");
    var response = corsClient->post("/hello1/test1", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "resCors");
        test:assertFalse(response.hasHeader(ACCESS_CONTROL_ALLOW_ORIGIN));
        test:assertFalse(response.hasHeader(ACCESS_CONTROL_ALLOW_CREDENTIALS));
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for values with extra white spaces
@test:Config {}
function testSimpleReqwithExtraWS() {
    http:Request req = new;
    req.setTextPayload("hello");
    req.setHeader(ORIGIN, "http://www.facebook.com");
    var response = corsClient->post("/hello2/test1", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "resOnlyCors");
        assertHeaderValue(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_ORIGIN), "http://www.facebook.com");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for CORS override at two levels with preflight
@test:Config {}
function testPreFlightReqServiceResourceCorsOverride() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_POST);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-PINGOTHER");
    var response = corsClient->options("/hello1/test1", req);
    if (response is http:Response) {
        assertEqualsCorsResponse(response, 200, "http://www.wso2.com", "true", "X-PINGOTHER", HTTP_METHOD_POST, "-1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preflight without origin header considered as a normal options request
@test:Config {}
function testPreFlightReqwithNoOrigin() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_POST);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-PINGOTHER");
    var response = corsClient->options("/hello1/test1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected statusCode");
        test:assertEquals(checkpanic response.getHeader(ALLOW), "POST, OPTIONS", msg = "Found unexpected Header");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preflight without Request Method header considered as a normal options request
@test:Config {}
function testPreFlightReqwithNoMethod() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-PINGOTHER");
    var response = corsClient->options("/hello1/test1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected statusCode");
        test:assertEquals(checkpanic response.getHeader(ALLOW), "POST, OPTIONS", msg = "Found unexpected Header");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preflight with unavailable HTTP method breaks the success criteria hence considered as a normal options request
@test:Config {}
function testPreFlightReqwithUnavailableMethod() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_PUT);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-PINGOTHER");
    var response = corsClient->options("/hello1/test1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected statusCode");
        test:assertEquals(checkpanic response.getHeader(ALLOW), "POST, OPTIONS", msg = "Found unexpected Header");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for preflight with Head as request method to a GET method annotated resource
@test:Config {}
function testPreFlightReqwithHeadMethod() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.m3.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_HEAD);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "CORELATION_ID");
    var response = corsClient->options("/hello1/test2", req);
    if (response is http:Response) {
        assertEqualsCorsResponse(response, 200, "http://www.m3.com", "true", "CORELATION_ID", HTTP_METHOD_HEAD, "1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preflight for invalid headers
@test:Config {}
function testPreFlightReqwithInvalidHeaders() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_POST);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "WSO2");
    var response = corsClient->options("/hello1/test1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected statusCode");
        test:assertEquals(checkpanic response.getHeader(ALLOW), "POST, OPTIONS", msg = "Found unexpected Header");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preflight without headers
@test:Config {}
function testPreFlightReqwithNoHeaders() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_POST);
    var response = corsClient->options("/hello1/test1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200);
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_ORIGIN), "http://www.wso2.com");
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_CREDENTIALS), "true");
        test:assertFalse(response.hasHeader(ACCESS_CONTROL_ALLOW_HEADERS));
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_METHODS), HTTP_METHOD_POST);
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_MAX_AGE), "-1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preflight with method restriction at service level
@test:Config {}
function testPreFlightReqwithRestrictedMethodsServiceLevel() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.m3.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_POST);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-PINGOTHER");
    var response = corsClient->options("/hello3/info1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected statusCode");
        test:assertEquals(checkpanic response.getHeader(ALLOW), "PUT, OPTIONS", msg = "Found unexpected Header");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preflight with method restriction at resource level
@test:Config {}
function testPreFlightReqwithRestrictedMethodsResourceLevel() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.bbc.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_DELETE);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-PINGOTHER");
    var response = corsClient->options("/hello2/test2", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected statusCode");
        test:assertEquals(checkpanic response.getHeader(ALLOW), "PUT, OPTIONS", msg = "Found unexpected Header");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preflight with allowed method at service level
@test:Config {}
function testPreFlightReqwithAllowedMethod() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.m3.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_PUT);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-PINGOTHER");
    var response = corsClient->options("/hello3/info1", req);
    if (response is http:Response) {
        assertEqualsCorsResponse(response, 200, "http://www.m3.com", "true", "X-PINGOTHER", HTTP_METHOD_PUT, "1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preflight with missing headers at resource level
@test:Config {}
function testPreFlightReqwithMissingHeadersAtResourceLevel() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.bbc.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_PUT);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-PINGOTHER");
    var response = corsClient->options("/hello2/test2", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200);
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_ORIGIN), "http://www.bbc.com");
        test:assertFalse(response.hasHeader(ACCESS_CONTROL_ALLOW_CREDENTIALS));
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_HEADERS), "X-PINGOTHER");
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_METHODS), HTTP_METHOD_PUT);
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_MAX_AGE), "-1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test preflight without CORS headers
@test:Config {}
function testPreFlightReqNoCorsResource() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_POST);
    var response = corsClient->options("/echo4/info1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected statusCode");
        test:assertEquals(checkpanic response.getHeader(ALLOW), "POST, OPTIONS", msg = "Found unexpected Header");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for simple OPTIONS request
@test:Config {}
function testSimpleOPTIONSReq() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2.com");
    var response = corsClient->options("/echo4/info2", req);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", "noCorsOPTIONS");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for case insensitive origin
@test:Config {}
function testPreFlightReqwithCaseInsensitiveOrigin() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.Wso2.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_POST);
    var response = corsClient->options("/hello1/test1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected statusCode");
        test:assertEquals(checkpanic response.getHeader(ALLOW), "POST, OPTIONS", msg = "Found unexpected Header");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for case insensitive header
@test:Config {}
function testPreFlightReqwithCaseInsensitiveHeader() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_POST);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-pingOTHER");
    var response = corsClient->options("/hello1/test1", req);
    if (response is http:Response) {
        assertEqualsCorsResponse(response, 200, "http://www.wso2.com", "true", "X-pingOTHER", HTTP_METHOD_POST, "-1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for serviceLevel wildcard/default CORS configs
@test:Config {}
function testPreFlightReqwithWildCardServiceConfigs() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2Ballerina.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_POST);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-PINGOTHER");
    var response = corsClient->options("/hello5/info1", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200);
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_ORIGIN), "http://www.wso2Ballerina.com");
        test:assertFalse(response.hasHeader(ACCESS_CONTROL_ALLOW_CREDENTIALS));
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_HEADERS), "X-PINGOTHER");
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_METHODS), HTTP_METHOD_POST);
        test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_MAX_AGE), "-1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for resource Level wildcard/default CORS configs
@test:Config {}
function testPreFlightReqwithWildCardResourceConfigs() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2Ballerina456.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_POST);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-PINGOTHER");
    var response = corsClient->options("/echo4/info3", req);
    if (response is http:Response) {
        assertEqualsCorsResponse(response, 200, "http://www.wso2Ballerina456.com", "true", "X-PINGOTHER", "POST", "-1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for resource Level wildcard/default CORS configs override
@test:Config {}
function testPreFlightReqwithWildCardResourceConfigsOverride() {
    http:Request req = new;
    req.setTextPayload("Hello there");
    req.setHeader(ORIGIN, "http://www.wso2Ballerina123.com");
    req.setHeader(ACCESS_CONTROL_REQUEST_METHOD, HTTP_METHOD_PUT);
    req.setHeader(ACCESS_CONTROL_REQUEST_HEADERS, "X-PONGOTHER");
    var response = corsClient->options("/hello1/test4", req);
    if (response is http:Response) {
        assertEqualsCorsResponse(response, 200, "http://www.wso2Ballerina123.com", "true", "X-PONGOTHER", 
            HTTP_METHOD_PUT, "-1");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function assertEqualsCorsResponse(http:Response response, int statusCode, string origin, string credentials, 
        string headers, string methods, string maxAge) {
    test:assertEquals(response.statusCode, statusCode, msg = "Found unexpected statusCode");
    test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_ORIGIN), origin, msg = "Found unexpected Header");
    test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_CREDENTIALS), credentials, msg = "Found unexpected Header");
    test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_HEADERS), headers, msg = "Found unexpected Header");
    test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_ALLOW_METHODS), methods, msg = "Found unexpected Header");
    test:assertEquals(checkpanic response.getHeader(ACCESS_CONTROL_MAX_AGE), maxAge, msg = "Found unexpected Header");
}
