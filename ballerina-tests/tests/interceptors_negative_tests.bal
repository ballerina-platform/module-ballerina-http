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

final http:Client requestInterceptorNegativeClientEP = check new("http://localhost:" + requestInterceptorNegativeTestPort.toString());

listener http:Listener requestInterceptorNegativeServerEP = new(requestInterceptorNegativeTestPort);

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorNegative1(), new LastRequestInterceptor()]
}
service /negative1 on requestInterceptorNegativeServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative1() returns error? {
    http:Response res = check requestInterceptorNegativeClientEP->get("/negative1");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "request context object does not contain the configured interceptors");
}

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorNegative2(), new LastRequestInterceptor()]
}
service /negative2 on requestInterceptorNegativeServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative2() returns error? {
    http:Response res = check requestInterceptorNegativeClientEP->get("/negative2");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "next interceptor service did not match with the configuration");
}

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor()]
}
service /negative3 on requestInterceptorNegativeServerEP {

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
    http:Response res = check requestInterceptorNegativeClientEP->get("/negative3");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    assertTextPayload(check res.getTextPayload(), "no next service to be returned");
}

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorSkip()]
}
service /negative4 on requestInterceptorNegativeServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative4() returns error? {
    http:Response res = check requestInterceptorNegativeClientEP->get("/negative4");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "no next service to be returned");
}

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor(), new LastRequestInterceptor(), new RequestErrorInterceptorReturnsErrorMsg()]
}
service /neagtive5 on requestInterceptorNegativeServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative5() returns error? {
    http:Response res = check requestInterceptorNegativeClientEP->get("/");
    assertTextPayload(check res.getTextPayload(), "no matching service found for path : /");
}

@http:ServiceConfig {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorNegative3()]
}
service /negative6 on requestInterceptorNegativeServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative6() returns error? {
    http:Response res = check requestInterceptorNegativeClientEP->get("/negative6");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "target service did not match with the configuration");
}
