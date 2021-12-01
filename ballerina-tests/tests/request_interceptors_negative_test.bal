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

final http:Client requestInterceptorNegativeClientEP1 = check new("http://localhost:" + requestInterceptorNegativeTestPort1.toString());

listener http:Listener requestInterceptorNegativeServerEP1 = new(requestInterceptorNegativeTestPort1, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorNegative1(), new LastRequestInterceptor()]
});

service / on requestInterceptorNegativeServerEP1 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative1() returns error? {
    http:Response res = check requestInterceptorNegativeClientEP1->get("/");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "request context object does not contain the configured interceptors");
}

final http:Client requestInterceptorNegativeClientEP2 = check new("http://localhost:" + requestInterceptorNegativeTestPort2.toString());

listener http:Listener requestInterceptorNegativeServerEP2 = new(requestInterceptorNegativeTestPort2, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorNegative2(), new LastRequestInterceptor()]
});

service / on requestInterceptorNegativeServerEP2 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative2() returns error? {
    http:Response res = check requestInterceptorNegativeClientEP2->get("/");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "next interceptor service did not match with the configuration");
}

final http:Client requestInterceptorNegativeClientEP3 = check new("http://localhost:" + requestInterceptorNegativeTestPort3.toString());

listener http:Listener requestInterceptorNegativeServerEP3 = new(requestInterceptorNegativeTestPort3, config = {
    interceptors : [new DefaultRequestInterceptor()]
});

service / on requestInterceptorNegativeServerEP3 {

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
    http:Response res = check requestInterceptorNegativeClientEP3->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-interceptor");
    assertTextPayload(check res.getTextPayload(), "no next service to be returned");
}

final http:Client requestInterceptorNegativeClientEP4 = check new("http://localhost:" + requestInterceptorNegativeTestPort4.toString());

listener http:Listener requestInterceptorNegativeServerEP4 = new(requestInterceptorNegativeTestPort4, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorSkip()]
});

service / on requestInterceptorNegativeServerEP4 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorNegative4() returns error? {
    http:Response res = check requestInterceptorNegativeClientEP4->get("/");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "no next service to be returned");
}
