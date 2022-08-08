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

final http:Client requestInterceptorServiceConfigClientEP1 = check new("http://localhost:" + requestInterceptorServiceConfigTestPort1.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorServiceConfigServerEP1 = new(requestInterceptorServiceConfigTestPort1, 
    httpVersion = http:HTTP_1_1,
    interceptors = [
        new DefaultRequestInterceptor(), new LastResponseInterceptor(), new RequestInterceptorWithVariable("request-interceptor-listener"), 
        new ResponseInterceptorWithVariable("response-interceptor-listener"), new DefaultResponseInterceptor()
    ]
);

@http:ServiceConfig {
    interceptors : [
        new RequestInterceptorWithVariable("request-interceptor-service-foo"), new LastRequestInterceptor(), 
        new ResponseInterceptorWithVariable("response-interceptor-service-foo")
    ]
}
service /foo on requestInterceptorServiceConfigServerEP1 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("request-interceptor-listener", check req.getHeader("request-interceptor-listener"));
        res.setHeader("request-interceptor-service-foo", check req.getHeader("request-interceptor-service-foo"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        check caller->respond(res);
    }
}

@http:ServiceConfig {
    interceptors : [
        new RequestInterceptorReturnsError(), new DefaultRequestErrorInterceptor(), new RequestInterceptorWithVariable("request-interceptor-service-bar"), 
        new LastRequestInterceptor(), new ResponseInterceptorWithVariable("response-interceptor-service-bar"), new DefaultResponseErrorInterceptor()
    ]
}
service /bar on requestInterceptorServiceConfigServerEP1 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("request-interceptor-listener", check req.getHeader("request-interceptor-listener"));
        res.setHeader("request-interceptor-service-bar", check req.getHeader("request-interceptor-service-bar"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("request-interceptor-error", check req.getHeader("request-interceptor-error"));
        res.setHeader("default-request-error-interceptor", check req.getHeader("default-request-error-interceptor"));
        check caller->respond(res);
    }
}

service /hello on requestInterceptorServiceConfigServerEP1 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("request-interceptor-listener", check req.getHeader("request-interceptor-listener"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorServiceConfig1() returns error? {
    http:Response res = check requestInterceptorServiceConfigClientEP1->get("/hello");
    assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-listener");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-listener"), "true");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-listener"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");

    res = check requestInterceptorServiceConfigClientEP1->get("/foo");
    assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-listener");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-listener"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-service-foo"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-listener"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-service-foo"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");

    res = check requestInterceptorServiceConfigClientEP1->get("/bar");
    assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-listener");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-listener"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-service-bar"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-error"), "true");
    assertHeaderValue(check res.getHeader("default-request-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-listener"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-service-bar"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
}

final http:Client requestInterceptorServiceConfigClientEP2 = check new("http://localhost:" + requestInterceptorServiceConfigTestPort2.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorServiceConfigServerEP2 = new(requestInterceptorServiceConfigTestPort2, httpVersion = http:HTTP_1_1);

@http:ServiceConfig {
    interceptors : [
        new DefaultRequestInterceptor(), new RequestInterceptorSetPayload(), new LastResponseInterceptor(), new ResponseInterceptorWithVariable("response-interceptor-service-foo"), 
        new RequestInterceptorWithVariable("request-interceptor-service-foo"), new LastRequestInterceptor(), new DefaultResponseInterceptor()
    ]
}
service /foo on requestInterceptorServiceConfigServerEP2 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("request-interceptor-service-foo", check req.getHeader("request-interceptor-service-foo"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("request-interceptor-setpayload", check req.getHeader("request-interceptor-setpayload"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        check caller->respond(res);
    }
}

@http:ServiceConfig {
    interceptors : [
        new LastResponseInterceptor(), new ResponseInterceptorWithVariable("response-interceptor-service-bar"), 
        new RequestInterceptorWithVariable("request-interceptor-service-bar"), new LastRequestInterceptor(), new ResponseInterceptorSetPayload()
    ]
}
service /bar on requestInterceptorServiceConfigServerEP2 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("request-interceptor-service-bar", check req.getHeader("request-interceptor-service-bar"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        check caller->respond(res);
    }
}

service /hello on requestInterceptorServiceConfigServerEP2 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorServiceConfig2() returns error? {
    http:Response res = check requestInterceptorServiceConfigClientEP2->get("/hello");
    test:assertFalse(res.hasHeader("last-interceptor"));
    test:assertFalse(res.hasHeader("request-interceptor"));
    test:assertFalse(res.hasHeader("last-request-interceptor"));
    assertTextPayload(res.getTextPayload(), "Response from resource - test");

    res = check requestInterceptorServiceConfigClientEP2->post("/foo", "Request from Client");
    assertTextPayload(check res.getTextPayload(), "Text payload from request interceptor");
    assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-service-foo");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-setpayload"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-service-foo"), "true");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-service-foo"), "true");

    res = check requestInterceptorServiceConfigClientEP2->get("/bar");
    assertTextPayload(check res.getTextPayload(), "Text payload from response interceptor");
    assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-service-bar");
    assertHeaderValue(check res.getHeader("request-interceptor-service-bar"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-service-bar"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-setpayload"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
}

@http:ServiceConfig {
    interceptors: [new RequestIntercepterReturnsString()]
}
service /defaultStatusCode on requestInterceptorServiceConfigServerEP2 {

    resource function get .() returns string {
        return "Hello, World!";
    }
}

@test:Config {}
function testDefaultStatusCodesWithInterceptors() returns error? {
    // test original resource function
    http:Response res = check requestInterceptorServiceConfigClientEP2->get("/defaultStatusCode");
    test:assertEquals(res.statusCode, 200, "Invalid status code received");
    assertTextPayload(res.getTextPayload(), "Hello, World!");
    // test interceptor resource function
    res = check requestInterceptorServiceConfigClientEP2->post("/defaultStatusCode", "Hello, World!");
    test:assertEquals(res.statusCode, 201, "Invalid status code received");
    assertTextPayload(res.getTextPayload(), "Hello, World!");
}
