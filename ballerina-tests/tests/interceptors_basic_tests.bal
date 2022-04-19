// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/test;

final http:Client interceptorsBasicTestsClientEP1 = check new("http://localhost:" + interceptorBasicTestsPort1.toString());

listener http:Listener interceptorsBasicTestsServerEP1 = new(interceptorBasicTestsPort1);

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor(), new LastRequestInterceptor(), new DefaultRequestErrorInterceptor()]
}
service /defaultRequestInterceptor on interceptorsBasicTestsServerEP1 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        string lastInterceptor = req.hasHeader("default-request-error-interceptor") ? "default-request-error-interceptor" : check req.getHeader("last-interceptor");
        res.setHeader("last-interceptor", lastInterceptor);
        check caller->respond(res);
    }
}

@test:Config{}
function testDefaultRequestInterceptor() returns error? {
    http:Response res = check interceptorsBasicTestsClientEP1->get("/defaultRequestInterceptor");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check interceptorsBasicTestsClientEP1->post("/defaultRequestInterceptor", "testMessage");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

@http:ServiceConfig {
    interceptors : [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultResponseInterceptor()]
}
service /defaultResponseInterceptor on interceptorsBasicTestsServerEP1 {

    resource function 'default .(http:Request req) returns string {
        string|error payload = req.getTextPayload();
        if payload is error {
            return "Greetings!";
        } else {
            return payload;
        }
    }
}

@test:Config{}
function testDefaultResponseInterceptor() returns error? {
    http:Response res = check interceptorsBasicTestsClientEP1->get("/defaultResponseInterceptor");
    assertTextPayload(res.getTextPayload(), "Greetings!");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-interceptor");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");

    res = check interceptorsBasicTestsClientEP1->post("/defaultResponseInterceptor", "testMessage");
    assertTextPayload(res.getTextPayload(), "testMessage");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-interceptor");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
}

@http:ServiceConfig {
    interceptors : [
        new LastResponseInterceptor(), new DefaultRequestInterceptor(), new DefaultResponseInterceptor(), 
        new RequestInterceptorReturnsError(), new LastRequestInterceptor()
    ]
}
service /requestInterceptorReturnsError on interceptorsBasicTestsServerEP1 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorReturnsError() returns error? {
    http:Response res = check interceptorsBasicTestsClientEP1->get("/requestInterceptorReturnsError");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "Request interceptor returns an error");
}

final http:Client responseInterceptorReturnsErrorTestClientEP = check new("http://localhost:" + responseInterceptorReturnsErrorTestPort.toString());

listener http:Listener responseInterceptorReturnsErrorTestServerEP = new(responseInterceptorReturnsErrorTestPort, config = {
    interceptors : [new LastResponseInterceptor(), new ResponseInterceptorReturnsError(), new DefaultResponseInterceptor()]
});

service / on responseInterceptorReturnsErrorTestServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testResponseInterceptorReturnsError() returns error? {
    http:Response res = check responseInterceptorReturnsErrorTestClientEP->get("/");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "Response interceptor returns an error");
}

final http:Client interceptorsBasicTestsClientEP2 = check new("http://localhost:" + interceptorBasicTestsPort2.toString());

listener http:Listener interceptorsBasicTestsServerEP2 = new(interceptorBasicTestsPort2);

@http:ServiceConfig {
    interceptors : [
        new RequestInterceptorReturnsError(), new DefaultRequestInterceptor(), new DefaultRequestErrorInterceptor(), 
        new LastRequestInterceptor()
    ]
}
service /requestErrorInterceptor1 on interceptorsBasicTestsServerEP2 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        string default_interceptor_header = req.hasHeader("default-request-interceptor") ? "true" : "false";
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", default_interceptor_header);
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("request-interceptor-error", check req.getHeader("request-interceptor-error"));
        res.setHeader("default-request-error-interceptor", check req.getHeader("default-request-error-interceptor"));
        check caller->respond(res);
    }
}

@http:ServiceConfig {
    interceptors : [
        new RequestInterceptorReturnsError(), new RequestErrorInterceptorReturnsError(), new DefaultRequestInterceptor(), 
        new DefaultRequestErrorInterceptor(), new LastRequestInterceptor()
    ]
}
service /requestErrorInterceptor2 on interceptorsBasicTestsServerEP2 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        string default_interceptor_header = req.hasHeader("default-request-interceptor") ? "true" : "false";
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", default_interceptor_header);
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("request-interceptor-error", check req.getHeader("request-interceptor-error"));
        res.setHeader("request-error-interceptor-error", check req.getHeader("request-error-interceptor-error"));
        res.setHeader("default-request-error-interceptor", check req.getHeader("default-request-error-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestErrorInterceptor1() returns error? {
    http:Response res = check interceptorsBasicTestsClientEP2->get("/requestErrorInterceptor1");
    test:assertEquals(res.statusCode, 200);
    assertTextPayload(check res.getTextPayload(), "Request interceptor returns an error");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-error-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "false");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-error"), "true");
    assertHeaderValue(check res.getHeader("default-request-error-interceptor"), "true");
}

@test:Config{}
function testRequestErrorInterceptor2() returns error? {
    http:Response res = check interceptorsBasicTestsClientEP2->get("/requestErrorInterceptor2");
    test:assertEquals(res.statusCode, 200);
    assertTextPayload(check res.getTextPayload(), "Request error interceptor returns an error");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-error-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "false");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-error"), "true");
    assertHeaderValue(check res.getHeader("request-error-interceptor-error"), "true");
    assertHeaderValue(check res.getHeader("default-request-error-interceptor"), "true");
}

@http:ServiceConfig{
    interceptors: [
        new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultResponseInterceptor(),
        new ResponseInterceptorReturnsError()
    ]
}
service /responseErrorInterceptor1 on interceptorsBasicTestsServerEP2 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@http:ServiceConfig{
    interceptors: [
        new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultResponseInterceptor(), 
        new RequestInterceptorReturnsError(), new DefaultRequestInterceptor(), new LastRequestInterceptor()
    ]
}
service /responseErrorInterceptor2 on interceptorsBasicTestsServerEP2 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testResponseErrorInterceptor() returns error? {
    http:Response res = check interceptorsBasicTestsClientEP2->get("/responseErrorInterceptor1");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "Response interceptor returns an error");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");

    res = check interceptorsBasicTestsClientEP2->get("/responseErrorInterceptor2");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "Request interceptor returns an error");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
}

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorSetPayload(), new LastRequestInterceptor()]
}
service /requestInterceptorSetPayload on interceptorsBasicTestsServerEP2 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("request-interceptor-setpayload", check req.getHeader("request-interceptor-setpayload"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorSetPayload() returns error? {
    http:Request req = new();
    req.setHeader("interceptor", "databinding-interceptor");
    req.setTextPayload("Request from Client");
    http:Response res = check interceptorsBasicTestsClientEP2->post("/requestInterceptorSetPayload", req);
    assertTextPayload(check res.getTextPayload(), "Text payload from request interceptor");
    assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-setpayload");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-setpayload"), "true");
}

final http:Client interceptorsBasicTestsClientEP3 = check new("http://localhost:" + interceptorBasicTestsPort3.toString());

listener http:Listener interceptorsBasicTestsServerEP3 = new(interceptorBasicTestsPort3);

@http:ServiceConfig {
    interceptors : [new LastResponseInterceptor(), new ResponseInterceptorSetPayload(), new DefaultResponseInterceptor()]
}
service /responseInterceptorSetPayload on interceptorsBasicTestsServerEP3 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        check caller->respond(res);
    }
}

@test:Config{}
function testResponseInterceptorSetPayload() returns error? {
    http:Request req = new();
    req.setTextPayload("Request from Client");
    http:Response res = check interceptorsBasicTestsClientEP3->post("/responseInterceptorSetPayload", req);
    assertTextPayload(check res.getTextPayload(), "Text payload from response interceptor");
    assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-setpayload");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-setpayload"), "true");
}

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorReturnsResponse(), new LastRequestInterceptor()]
}
service /request on interceptorsBasicTestsServerEP3 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorReturnsResponse() returns error? {
    http:Request req = new();
    req.setTextPayload("Request from Client");
    http:Response res = check interceptorsBasicTestsClientEP3->post("/request", req);
    assertTextPayload(check res.getTextPayload(), "Response from Interceptor : Request from Client");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    assertHeaderValue(check res.getHeader("request-interceptor-returns-response"), "true");
}

@http:ServiceConfig {
    interceptors : [new LastResponseInterceptor(), new ResponseInterceptorReturnsResponse(), new DefaultResponseInterceptor()]
}
service /response on interceptorsBasicTestsServerEP3 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testResponseInterceptorReturnsResponse() returns error? {
    http:Response res = check interceptorsBasicTestsClientEP3->get("/response");
    assertTextPayload(check res.getTextPayload(), "Response from Interceptor : Response from resource - test");
    assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-returns-response");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-returns-response"), "true");
}

@http:ServiceConfig {
    interceptors : [
        new DefaultRequestInterceptor(), new GetRequestInterceptor(), new PostRequestInterceptor(), 
        new LastRequestInterceptor()
    ]
}
service /requestInterceptorHttpVerb on interceptorsBasicTestsServerEP3 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorHttpVerb() returns error? {
    http:Response res = check interceptorsBasicTestsClientEP3->get("/requestInterceptorHttpVerb");
    assertHeaderValue(check res.getHeader("last-interceptor"), "get-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check interceptorsBasicTestsClientEP3->post("/requestInterceptorHttpVerb", "testMessage");
    assertHeaderValue(check res.getHeader("last-interceptor"), "post-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

final http:Client requestInterceptorBasePathClientEP = check new("http://localhost:" + requestInterceptorBasePathTestPort.toString());

listener http:Listener requestInterceptorBasePathServerEP = new(requestInterceptorBasePathTestPort);

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor(), new DefaultRequestInterceptorBasePath(), new LastRequestInterceptor()]
}
service / on requestInterceptorBasePathServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }

    resource function 'default foo(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorBasePath() returns error? {
    http:Response res = check requestInterceptorBasePathClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check requestInterceptorBasePathClientEP->post("/foo", "testMessage");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-base-path-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

final http:Client getRequestInterceptorBasePathClientEP = check new("http://localhost:" + getRequestInterceptorBasePathTestPort.toString());

listener http:Listener getRequestInterceptorBasePathServerEP = new(getRequestInterceptorBasePathTestPort);

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor(), new GetRequestInterceptorBasePath(), new LastRequestInterceptor()]
}
service /foo on getRequestInterceptorBasePathServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }

    resource function 'default bar(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testGetRequestInterceptorBasePath() returns error? {
    http:Response res = check getRequestInterceptorBasePathClientEP->get("/foo");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check getRequestInterceptorBasePathClientEP->get("/foo/bar");
    assertHeaderValue(check res.getHeader("last-interceptor"), "get-base-path-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check getRequestInterceptorBasePathClientEP->post("/foo/bar", "testMessage");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}
