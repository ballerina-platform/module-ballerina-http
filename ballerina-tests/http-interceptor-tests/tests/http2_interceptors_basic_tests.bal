// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/http_test_common as common;

int http2InterceptorBasicTestsPort1 = common:getHttp2Port(interceptorBasicTestsPort1);

final http:Client http2InterceptorsBasicTestsClientEP1 = check new ("http://localhost:" + http2InterceptorBasicTestsPort1.toString(),
    http2Settings = {http2PriorKnowledge: true});

listener http:Listener http2InterceptorsBasicTestsServerEP1 = new (http2InterceptorBasicTestsPort1);

service http:InterceptableService /defaultRequestInterceptor on http2InterceptorsBasicTestsServerEP1 {

    public function createInterceptors() returns [DefaultRequestInterceptor, LastRequestInterceptor, DefaultRequestErrorInterceptor] {
        return [new DefaultRequestInterceptor(), new LastRequestInterceptor(), new DefaultRequestErrorInterceptor()];
    }

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new ();
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        string lastInterceptor = req.hasHeader("default-request-error-interceptor") ? "default-request-error-interceptor" : check req.getHeader("last-interceptor");
        res.setHeader("last-interceptor", lastInterceptor);
        check caller->respond(res);
    }
}

@test:Config {}
function tesHttp2DefaultRequestInterceptor() returns error? {
    http:Response res = check http2InterceptorsBasicTestsClientEP1->get("/defaultRequestInterceptor");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check http2InterceptorsBasicTestsClientEP1->post("/defaultRequestInterceptor", "testMessage");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

service http:InterceptableService /defaultResponseInterceptor on http2InterceptorsBasicTestsServerEP1 {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor, DefaultResponseInterceptor] {
        return [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultResponseInterceptor()];
    }

    resource function 'default .(http:Request req) returns string {
        string|error payload = req.getTextPayload();
        if payload is error {
            return "Greetings!";
        } else {
            return payload;
        }
    }
}

@test:Config {}
function tesHttp2tDefaultResponseInterceptor() returns error? {
    http:Response res = check http2InterceptorsBasicTestsClientEP1->get("/defaultResponseInterceptor");
    common:assertTextPayload(res.getTextPayload(), "Greetings!");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");

    res = check http2InterceptorsBasicTestsClientEP1->post("/defaultResponseInterceptor", "testMessage");
    common:assertTextPayload(res.getTextPayload(), "testMessage");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
}

service http:InterceptableService /requestInterceptorReturnsError on http2InterceptorsBasicTestsServerEP1 {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultRequestInterceptor,
                                DefaultResponseInterceptor, RequestInterceptorReturnsError, LastRequestInterceptor] {
        return [new LastResponseInterceptor(), new DefaultRequestInterceptor(), new DefaultResponseInterceptor(),
                        new RequestInterceptorReturnsError(), new LastRequestInterceptor()];
    }

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config {}
function tesHttp2RequestInterceptorReturnsError() returns error? {
    http:Response res = check http2InterceptorsBasicTestsClientEP1->get("/requestInterceptorReturnsError");
    test:assertEquals(res.statusCode, 500);
    check common:assertJsonErrorPayload(check res.getJsonPayload(), "Request interceptor returns an error",
        "Internal Server Error", 500, "/requestInterceptorReturnsError", "GET");
}

int http2ResponseInterceptorReturnsErrorTestPort = common:getHttp2Port(responseInterceptorReturnsErrorTestPort);

final http:Client http2ResponseInterceptorReturnsErrorTestClientEP = check new ("http://localhost:" + http2ResponseInterceptorReturnsErrorTestPort.toString(),
    http2Settings = {http2PriorKnowledge: true});

listener http:Listener http2ResponseInterceptorReturnsErrorTestServerEP = new (http2ResponseInterceptorReturnsErrorTestPort);

service http:InterceptableService / on http2ResponseInterceptorReturnsErrorTestServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, ResponseInterceptorReturnsError, DefaultResponseInterceptor] {
        return [new LastResponseInterceptor(), new ResponseInterceptorReturnsError(), new DefaultResponseInterceptor()];
    }

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config {}
function tesHttp2ResponseInterceptorReturnsError() returns error? {
    http:Response res = check http2ResponseInterceptorReturnsErrorTestClientEP->get("/");
    test:assertEquals(res.statusCode, 500);
    check common:assertJsonErrorPayload(check res.getJsonPayload(), "Response interceptor returns an error",
        "Internal Server Error", 500, "/", "GET");
}

int http2InterceptorBasicTestsPort2 = common:getHttp2Port(interceptorBasicTestsPort2);

final http:Client http2InterceptorsBasicTestsClientEP2 = check new ("http://localhost:" + http2InterceptorBasicTestsPort2.toString(),
    http2Settings = {http2PriorKnowledge: true});

listener http:Listener http2InterceptorsBasicTestsServerEP2 = new (http2InterceptorBasicTestsPort2);

service http:InterceptableService /requestErrorInterceptor1 on http2InterceptorsBasicTestsServerEP2 {

    public function createInterceptors() returns [RequestInterceptorReturnsError, DefaultRequestInterceptor,
                                                            DefaultRequestErrorInterceptor, LastRequestInterceptor] {
        return [new RequestInterceptorReturnsError(), new DefaultRequestInterceptor(), new DefaultRequestErrorInterceptor(),
                        new LastRequestInterceptor()];
    }

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new ();
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

service http:InterceptableService /requestErrorInterceptor2 on http2InterceptorsBasicTestsServerEP2 {

    public function createInterceptors() returns [RequestInterceptorReturnsError, RequestErrorInterceptorReturnsError,
                                    DefaultRequestInterceptor, DefaultRequestErrorInterceptor, LastRequestInterceptor] {
        return [
            new RequestInterceptorReturnsError(),
            new RequestErrorInterceptorReturnsError(),
            new DefaultRequestInterceptor(),
            new DefaultRequestErrorInterceptor(),
            new LastRequestInterceptor()
        ];
    }

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new ();
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

@test:Config {}
function tesHttp2RequestErrorInterceptor1() returns error? {
    http:Response res = check http2InterceptorsBasicTestsClientEP2->get("/requestErrorInterceptor1");
    test:assertEquals(res.statusCode, 200);
    common:assertTextPayload(check res.getTextPayload(), "Request interceptor returns an error");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "false");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("request-interceptor-error"), "true");
    common:assertHeaderValue(check res.getHeader("default-request-error-interceptor"), "true");
}

@test:Config {}
function tesHttp2RequestErrorInterceptor2() returns error? {
    http:Response res = check http2InterceptorsBasicTestsClientEP2->get("/requestErrorInterceptor2");
    test:assertEquals(res.statusCode, 200);
    common:assertTextPayload(check res.getTextPayload(), "Request error interceptor returns an error");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "false");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("request-interceptor-error"), "true");
    common:assertHeaderValue(check res.getHeader("request-error-interceptor-error"), "true");
    common:assertHeaderValue(check res.getHeader("default-request-error-interceptor"), "true");
}

service http:InterceptableService /responseErrorInterceptor1 on http2InterceptorsBasicTestsServerEP2 {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor,
                                                        DefaultResponseInterceptor, ResponseInterceptorReturnsError] {
        return [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(),
                        new DefaultResponseInterceptor(), new ResponseInterceptorReturnsError()];
    }

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

service http:InterceptableService /responseErrorInterceptor2 on http2InterceptorsBasicTestsServerEP2 {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor,
                                    DefaultResponseInterceptor, RequestInterceptorReturnsError, DefaultRequestInterceptor,
                                    LastRequestInterceptor] {
        return [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultResponseInterceptor(),
                        new RequestInterceptorReturnsError(), new DefaultRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config {}
function tesHttp2ResponseErrorInterceptor() returns error? {
    http:Response res = check http2InterceptorsBasicTestsClientEP2->get("/responseErrorInterceptor1");
    test:assertEquals(res.statusCode, 500);
    common:assertTextPayload(check res.getTextPayload(), "Response interceptor returns an error");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "NormalError");

    res = check http2InterceptorsBasicTestsClientEP2->get("/responseErrorInterceptor2");
    test:assertEquals(res.statusCode, 500);
    common:assertTextPayload(check res.getTextPayload(), "Request interceptor returns an error");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "NormalError");
}

service http:InterceptableService /requestInterceptorSetPayload on http2InterceptorsBasicTestsServerEP2 {

    public function createInterceptors() returns [DefaultRequestInterceptor, RequestInterceptorSetPayload, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new RequestInterceptorSetPayload(), new LastRequestInterceptor()];
    }

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new ();
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("request-interceptor-setpayload", check req.getHeader("request-interceptor-setpayload"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config {}
function tesHttp2RequestInterceptorSetPayload() returns error? {
    http:Request req = new ();
    req.setHeader("interceptor", "databinding-interceptor");
    req.setTextPayload("Request from Client");
    http:Response res = check http2InterceptorsBasicTestsClientEP2->post("/requestInterceptorSetPayload", req);
    common:assertTextPayload(check res.getTextPayload(), "Text payload from request interceptor");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-setpayload");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("request-interceptor-setpayload"), "true");
}

int http2InterceptorBasicTestsPort3 = common:getHttp2Port(interceptorBasicTestsPort3);

final http:Client http2InterceptorsBasicTestsClientEP3 = check new ("http://localhost:" + http2InterceptorBasicTestsPort3.toString(),
    http2Settings = {http2PriorKnowledge: true});

listener http:Listener http2InterceptorsBasicTestsServerEP3 = new (http2InterceptorBasicTestsPort3);

service http:InterceptableService /responseInterceptorSetPayload on http2InterceptorsBasicTestsServerEP3 {

    public function createInterceptors() returns [LastResponseInterceptor, ResponseInterceptorSetPayload, DefaultResponseInterceptor] {
        return [new LastResponseInterceptor(), new ResponseInterceptorSetPayload(), new DefaultResponseInterceptor()];
    }

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new ();
        res.setTextPayload(check req.getTextPayload());
        check caller->respond(res);
    }
}

@test:Config {}
function tesHttp2ResponseInterceptorSetPayload() returns error? {
    http:Request req = new ();
    req.setTextPayload("Request from Client");
    http:Response res = check http2InterceptorsBasicTestsClientEP3->post("/responseInterceptorSetPayload", req);
    common:assertTextPayload(check res.getTextPayload(), "Text payload from response interceptor");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-setpayload");
    common:assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("response-interceptor-setpayload"), "true");
}

service http:InterceptableService /request on http2InterceptorsBasicTestsServerEP3 {

    public function createInterceptors() returns [DefaultRequestInterceptor, RequestInterceptorReturnsResponse, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new RequestInterceptorReturnsResponse(), new LastRequestInterceptor()];
    }

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config {}
function tesHttp2RequestInterceptorReturnsResponse() returns error? {
    http:Request req = new ();
    req.setTextPayload("Request from Client");
    http:Response res = check http2InterceptorsBasicTestsClientEP3->post("/request", req);
    common:assertTextPayload(check res.getTextPayload(), "Response from Interceptor : Request from Client");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    common:assertHeaderValue(check res.getHeader("request-interceptor-returns-response"), "true");
}

service http:InterceptableService /response on http2InterceptorsBasicTestsServerEP3 {

    public function createInterceptors() returns [LastResponseInterceptor, ResponseInterceptorReturnsResponse, DefaultResponseInterceptor] {
        return [new LastResponseInterceptor(), new ResponseInterceptorReturnsResponse(), new DefaultResponseInterceptor()];
    }

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config {}
function tesHttp2ResponseInterceptorReturnsResponse() returns error? {
    http:Response res = check http2InterceptorsBasicTestsClientEP3->get("/response");
    common:assertTextPayload(check res.getTextPayload(), "Response from Interceptor : Response from resource - test");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-returns-response");
    common:assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("response-interceptor-returns-response"), "true");
}

service http:InterceptableService /requestInterceptorHttpVerb on http2InterceptorsBasicTestsServerEP3 {

    public function createInterceptors() returns [DefaultRequestInterceptor, GetRequestInterceptor,
                                                                     PostRequestInterceptor, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new GetRequestInterceptor(), new PostRequestInterceptor(),
                        new LastRequestInterceptor()];
    }

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new ();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config {}
function tesHttp2RequestInterceptorHttpVerb() returns error? {
    http:Response res = check http2InterceptorsBasicTestsClientEP3->get("/requestInterceptorHttpVerb");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "get-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check http2InterceptorsBasicTestsClientEP3->post("/requestInterceptorHttpVerb", "testMessage");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "post-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

service http:InterceptableService /interceptorPathAndVerb on http2InterceptorsBasicTestsServerEP3 {

    public function createInterceptors() returns [DefaultRequestInterceptor, GetFooRequestInterceptor,
                                                        LastResponseInterceptor, DefaultResponseErrorInterceptor] {
        return [new DefaultRequestInterceptor(), new GetFooRequestInterceptor(),
                        new LastResponseInterceptor(), new DefaultResponseErrorInterceptor()];
    }

    resource function 'default foo(http:Caller caller, http:Request req) returns error? {
        http:Response res = new ();
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config {}
function tesHttp2RequestInterceptorPathAndVerb() returns error? {
    http:Response res = check http2InterceptorsBasicTestsClientEP3->post("/interceptorPathAndVerb/foo", "testMessage");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");

    res = check http2InterceptorsBasicTestsClientEP3->get("/interceptorPathAndVerb/bar");
    test:assertEquals(res.statusCode, 404);
    common:assertTextPayload(res.getTextPayload(), "no matching resource found for path : /interceptorPathAndVerb/bar , method : GET");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Resource");
}

int http2RequestInterceptorBasePathTestPort = common:getHttp2Port(requestInterceptorBasePathTestPort);

final http:Client http2RequestInterceptorBasePathClientEP = check new ("http://localhost:" + http2RequestInterceptorBasePathTestPort.toString(),
    http2Settings = {http2PriorKnowledge: true});

listener http:Listener http2RequestInterceptorBasePathServerEP = new (http2RequestInterceptorBasePathTestPort);

service http:InterceptableService / on http2RequestInterceptorBasePathServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, DefaultRequestInterceptorBasePath, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new DefaultRequestInterceptorBasePath(), new LastRequestInterceptor()];
    }

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new ();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }

    resource function 'default foo(http:Caller caller, http:Request req) returns error? {
        http:Response res = new ();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config {}
function tesHttp2RequestInterceptorBasePath() returns error? {
    http:Response res = check http2RequestInterceptorBasePathClientEP->get("/");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check http2RequestInterceptorBasePathClientEP->post("/foo", "testMessage");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-base-path-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

int http2GetRequestInterceptorBasePathTestPort = common:getHttp2Port(getRequestInterceptorBasePathTestPort);

final http:Client http2GetRequestInterceptorBasePathClientEP = check new ("http://localhost:" + http2GetRequestInterceptorBasePathTestPort.toString(),
    http2Settings = {http2PriorKnowledge: true});

listener http:Listener http2GetRequestInterceptorBasePathServerEP = new (http2GetRequestInterceptorBasePathTestPort);

service http:InterceptableService /foo on http2GetRequestInterceptorBasePathServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, GetRequestInterceptorBasePath, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new GetRequestInterceptorBasePath(), new LastRequestInterceptor()];
    }

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new ();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }

    resource function 'default bar(http:Caller caller, http:Request req) returns error? {
        http:Response res = new ();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config {}
function tesHttp2GetRequestInterceptorBasePath() returns error? {
    http:Response res = check http2GetRequestInterceptorBasePathClientEP->get("/foo");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check http2GetRequestInterceptorBasePathClientEP->get("/foo/bar");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "get-base-path-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check http2GetRequestInterceptorBasePathClientEP->post("/foo/bar", "testMessage");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}
