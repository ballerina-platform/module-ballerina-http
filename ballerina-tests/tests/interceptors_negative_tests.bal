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

final http:Client interceptorNegativeClientEP1 = check new("http://localhost:" + interceptorNegativeTestPort1.toString());

listener http:Listener interceptorNegativeServerEP1 = new(interceptorNegativeTestPort1, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorNegative1(), new LastRequestInterceptor()]
});

@test:Config{}
function testRequestInterceptorNegative1() returns error? {
    http:Response res = check interceptorNegativeClientEP1->get("/");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "request context object does not contain the configured interceptors");
}

final http:Client interceptorNegativeClientEP2 = check new("http://localhost:" + interceptorNegativeTestPort.toString());

listener http:Listener interceptorNegativeServerEP2 = new(interceptorNegativeTestPort, config = {
    interceptors : [new DefaultRequestInterceptor()]
});

@http:ServiceConfig {
    interceptors: [new RequestInterceptorNegative2(), new LastRequestInterceptor()]
}
service /request on interceptorNegativeServerEP2 {
    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@http:ServiceConfig {
    interceptors: [new ResponseInterceptorNegative1(), new LastRequestInterceptor(), new DefaultResponseInterceptor()]
}
service /response on interceptorNegativeServerEP2 {
    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative2() returns error? {
    http:Response res = check interceptorNegativeClientEP2->get("/request");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "next interceptor service did not match with the configuration");
}

@test:Config{}
function testResponseInterceptorNegative1() returns error? {
    http:Response res = check interceptorNegativeClientEP2->get("/response");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "next interceptor service did not match with the configuration");
}

final http:Client interceptorNegativeClientEP3 = check new("http://localhost:" + interceptorNegativeTestPort3.toString());

listener http:Listener interceptorNegativeServerEP3 = new(interceptorNegativeTestPort3, config = {
    interceptors : [new DefaultRequestInterceptor()]
});

service / on interceptorNegativeServerEP3 {

    resource function 'default .(http:RequestContext ctx, http:Caller caller) returns error? {
       string|error val = ctx.get("last-interceptor").ensureType(string);
       string header = val is string ? val : "main-service";
       http:Response res = new();
       res.setHeader("last-interceptor", header);
       http:NextService|error? nextService = ctx.next();
       if nextService is error {
           res.setTextPayload(nextService.message());
       } else {
           res.setTextPayload("Response from resource - test");
       }
       check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorNegative3() returns error? {
    http:Response res = check interceptorNegativeClientEP3->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    assertTextPayload(check res.getTextPayload(), "no next service to be returned");
}

final http:Client interceptorNegativeClientEP4 = check new("http://localhost:" + interceptorNegativeTestPort4.toString());

listener http:Listener interceptorNegativeServerEP4 = new(interceptorNegativeTestPort4, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorSkip()]
});

service / on interceptorNegativeServerEP4 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative4() returns error? {
    http:Response res = check interceptorNegativeClientEP4->get("/");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "no next service to be returned");
}

final http:Client interceptorNegativeClientEP5 = check new("http://localhost:" + interceptorNegativeTestPort5.toString());

listener http:Listener interceptorNegativeServerEP5 = new(interceptorNegativeTestPort5, config = {
    interceptors : [new DefaultRequestInterceptor(), new LastRequestInterceptor(), new RequestErrorInterceptorReturnsErrorMsg()]
});

service /hello on interceptorNegativeServerEP5 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative5() returns error? {
    http:Response res = check interceptorNegativeClientEP5->get("/");
    assertTextPayload(check res.getTextPayload(), "no matching service found for path : /");
}

final http:Client interceptorNegativeClientEP6 = check new("http://localhost:" + interceptorNegativeTestPort6.toString());

listener http:Listener interceptorNegativeServerEP6 = new(interceptorNegativeTestPort6, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorNegative3()]
});

service / on interceptorNegativeServerEP6 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative6() returns error? {
    http:Response res = check interceptorNegativeClientEP6->get("/");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "target service did not match with the configuration");
}
