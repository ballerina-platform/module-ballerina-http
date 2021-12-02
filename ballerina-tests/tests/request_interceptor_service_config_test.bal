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

final http:Client requestInterceptorServiceConfigClientEP1 = check new("http://localhost:" + requestInterceptorServiceConfigTestPort1.toString());

listener http:Listener requestInterceptorServiceConfigServerEP1 = new(requestInterceptorServiceConfigTestPort1, config = {
    interceptors : [new RequestInterceptorWithVariable("interceptor-listener"), new LastRequestInterceptor()]
});

@http:ServiceConfig {
    interceptors : [new RequestInterceptorWithVariable("interceptor-service-foo"), new LastRequestInterceptor()]
}
service /foo on requestInterceptorServiceConfigServerEP1 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("request-interceptor", check req.getHeader("request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        check caller->respond(res);
    }
}

@http:ServiceConfig {
    interceptors : [new RequestInterceptorReturnsError(), new DefaultRequestErrorInterceptor(), new RequestInterceptorWithVariable("interceptor-service-bar"), new LastRequestInterceptor()]
}
service /bar on requestInterceptorServiceConfigServerEP1 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("request-interceptor", check req.getHeader("request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("request-interceptor-error", check req.getHeader("request-interceptor-error"));
        res.setHeader("default-error-interceptor", check req.getHeader("default-error-interceptor"));
        check caller->respond(res);
    }
}

service /hello on requestInterceptorServiceConfigServerEP1 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("request-interceptor", check req.getHeader("request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{enable : false}
function testRequestInterceptorServiceConfig1() returns error? {
    http:Response res = check requestInterceptorServiceConfigClientEP1->get("/hello");
    assertHeaderValue(check res.getHeader("last-interceptor"), "interceptor-listener");
    assertHeaderValue(check res.getHeader("request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check requestInterceptorServiceConfigClientEP1->get("/foo");
    assertHeaderValue(check res.getHeader("last-interceptor"), "interceptor-service-foo");
    assertHeaderValue(check res.getHeader("request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check requestInterceptorServiceConfigClientEP1->get("/bar");
    assertHeaderValue(check res.getHeader("last-interceptor"), "interceptor-service-bar");
    assertHeaderValue(check res.getHeader("request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-error"), "true");
    assertHeaderValue(check res.getHeader("default-error-interceptor"), "true");
}

final http:Client requestInterceptorServiceConfigClientEP2 = check new("http://localhost:" + requestInterceptorServiceConfigTestPort2.toString());

listener http:Listener requestInterceptorServiceConfigServerEP2 = new(requestInterceptorServiceConfigTestPort2);

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorSetPayload(), new RequestInterceptorWithVariable("interceptor-service-foo"), new LastRequestInterceptor()]
}
service /foo on requestInterceptorServiceConfigServerEP2 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("request-interceptor", check req.getHeader("request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("interceptor-setpayload", check req.getHeader("interceptor-setpayload"));
        res.setHeader("default-interceptor", check req.getHeader("default-interceptor"));
        check caller->respond(res);
    }
}

@http:ServiceConfig {
    interceptors : [new RequestInterceptorWithVariable("interceptor-service-bar"), new LastRequestInterceptor()]
}
service /bar on requestInterceptorServiceConfigServerEP2 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("request-interceptor", check req.getHeader("request-interceptor"));
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

    http:Request req = new();
    req.setHeader("interceptor", "databinding-interceptor");
    req.setTextPayload("Request from Client");
    res = check requestInterceptorServiceConfigClientEP2->post("/foo", req);
    assertTextPayload(check res.getTextPayload(), "Text payload from interceptor");
    assertHeaderValue(check res.getHeader("last-interceptor"), "interceptor-service-foo");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("interceptor-setpayload"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor"), "true");

    res = check requestInterceptorServiceConfigClientEP2->get("/bar");
    assertHeaderValue(check res.getHeader("last-interceptor"), "interceptor-service-bar");
    assertHeaderValue(check res.getHeader("request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}
