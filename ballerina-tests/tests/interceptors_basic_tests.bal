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

final http:Client defaultRequestInterceptorClientEP = check new("http://localhost:" + defaultRequestInterceptorTestPort.toString());

listener http:Listener defaultRequestInterceptorServerEP = new(defaultRequestInterceptorTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new LastRequestInterceptor(), new DefaultRequestErrorInterceptor()]
});

service / on defaultRequestInterceptorServerEP {

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
    http:Response res = check defaultRequestInterceptorClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check defaultRequestInterceptorClientEP->post("/", "testMessage");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

final http:Client defaultResponseInterceptorClientEP = check new("http://localhost:" + defaultResponseInterceptorTestPort.toString());

listener http:Listener defaultResponseInterceptorServerEP = new(defaultResponseInterceptorTestPort, config = {
    interceptors : [new LastResponseInterceptor(), new DefaultResponseInterceptor()]
});

service / on defaultResponseInterceptorServerEP {

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
    http:Response res = check defaultResponseInterceptorClientEP->get("/");
    assertTextPayload(res.getTextPayload(), "Greetings!");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-interceptor");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");

    res = check defaultResponseInterceptorClientEP->post("/", "testMessage");
    assertTextPayload(res.getTextPayload(), "testMessage");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-interceptor");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
}

final http:Client requestInterceptorReturnsErrorClientEP = check new("http://localhost:" + requestInterceptorReturnsErrorTestPort.toString());

listener http:Listener requestInterceptorReturnsErrorServerEP = new(requestInterceptorReturnsErrorTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorReturnsError(), new LastRequestInterceptor()]
});

service / on requestInterceptorReturnsErrorServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorReturnsError() returns error? {
    http:Response res = check requestInterceptorReturnsErrorClientEP->get("/");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "Request interceptor returns an error");
}

final http:Client responseInterceptorReturnsErrorClientEP = check new("http://localhost:" + responseInterceptorReturnsErrorTestPort.toString());

listener http:Listener responseInterceptorReturnsErrorServerEP = new(responseInterceptorReturnsErrorTestPort, config = {
    interceptors : [new LastResponseInterceptor(), new ResponseInterceptorReturnsError(), new DefaultResponseInterceptor()]
});

service / on responseInterceptorReturnsErrorServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testResponseInterceptorReturnsError() returns error? {
    http:Response res = check responseInterceptorReturnsErrorClientEP->get("/");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "Response interceptor returns an error");
}

final http:Client requestErrorInterceptorClientEP = check new("http://localhost:" + requestErrorInterceptorTestPort.toString());

listener http:Listener requestErrorInterceptorServerEP = new(requestErrorInterceptorTestPort, config = {
    interceptors : [new RequestInterceptorReturnsError(), new DefaultRequestInterceptor(), new DefaultRequestErrorInterceptor(), new LastRequestInterceptor()]
});

service / on requestErrorInterceptorServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        string default_interceptor_header = req.hasHeader("default-request-interceptor") ? "true" : "false";
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", default_interceptor_header);
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("request-interceptor-error", check req.getHeader("request-interceptor-error"));
        res.setHeader("default-request-error-interceptor", check req.getHeader("default-request-error-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestErrorInterceptor() returns error? {
    http:Response res = check requestErrorInterceptorClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-error-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "false");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-error"), "true");
    assertHeaderValue(check res.getHeader("default-request-error-interceptor"), "true");
}

final http:Client responseErrorInterceptorClientEP = check new("http://localhost:" + responseErrorInterceptorTestPort.toString());

listener http:Listener responseErrorInterceptorServerEP = new(responseErrorInterceptorTestPort, config = {
    interceptors : [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultResponseInterceptor(), new ResponseInterceptorReturnsError()]
});

service / on responseErrorInterceptorServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testResponseErrorInterceptor() returns error? {
    http:Response res = check responseErrorInterceptorClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
}

final http:Client requestInterceptorSetPayloadClientEP = check new("http://localhost:" + requestInterceptorSetPayloadTestPort.toString());

listener http:Listener requestInterceptorSetPayloadServerEP = new(requestInterceptorSetPayloadTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorSetPayload(), new LastRequestInterceptor()]
});

service / on requestInterceptorSetPayloadServerEP {

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
    http:Response res = check requestInterceptorSetPayloadClientEP->post("/", req);
    assertTextPayload(check res.getTextPayload(), "Text payload from interceptor");
    assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-setpayload");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-setpayload"), "true");
}

final http:Client responseInterceptorSetPayloadClientEP = check new("http://localhost:" + responseInterceptorSetPayloadTestPort.toString());

listener http:Listener responseInterceptorSetPayloadServerEP = new(responseInterceptorSetPayloadTestPort, config = {
    interceptors : [new LastResponseInterceptor(), new ResponseInterceptorSetPayload(), new DefaultResponseInterceptor()]
});

service / on responseInterceptorSetPayloadServerEP {

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
    http:Response res = check responseInterceptorSetPayloadClientEP->post("/", req);
    assertTextPayload(check res.getTextPayload(), "Text payload from interceptor");
    assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-setpayload");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-setpayload"), "true");
}

final http:Client requestInterceptorReturnsResponseClientEP = check new("http://localhost:" + requestInterceptorReturnsResponseTestPort.toString());

listener http:Listener requestInterceptorReturnsResponseServerEP = new(requestInterceptorReturnsResponseTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorReturnsResponse(), new LastRequestInterceptor()]
});

service / on requestInterceptorReturnsResponseServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorReturnsResponse() returns error? {
    http:Request req = new();
    req.setTextPayload("Request from Client");
    http:Response res = check requestInterceptorReturnsResponseClientEP->post("/", req);
    assertTextPayload(check res.getTextPayload(), "Response from Interceptor : Request from Client");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-request-interceptor");
    assertHeaderValue(check res.getHeader("request-interceptor-returns-response"), "true");
}

final http:Client responseInterceptorReturnsResponseClientEP = check new("http://localhost:" + responseInterceptorReturnsResponseTestPort.toString());

listener http:Listener responseInterceptorReturnsResponseServerEP = new(responseInterceptorReturnsResponseTestPort, config = {
    interceptors : [new LastResponseInterceptor(), new ResponseInterceptorReturnsResponse(), new DefaultResponseInterceptor()]
});

service / on responseInterceptorReturnsResponseServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testResponseInterceptorReturnsResponse() returns error? {
    http:Response res = check responseInterceptorReturnsResponseClientEP->get("/");
    assertTextPayload(check res.getTextPayload(), "Response from Interceptor : Response from resource - test");
    assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-returns-response");
    assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("response-interceptor-returns-response"), "true");
}

final http:Client requestInterceptorHttpVerbClientEP = check new("http://localhost:" + requestInterceptorHttpVerbTestPort.toString());

listener http:Listener requestInterceptorHttpVerbServerEP = new(requestInterceptorHttpVerbTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new GetRequestInterceptor(), new PostRequestInterceptor(), new LastRequestInterceptor()]
});

service / on requestInterceptorHttpVerbServerEP {

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
    http:Response res = check requestInterceptorHttpVerbClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "get-interceptor");
    assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check requestInterceptorHttpVerbClientEP->post("/", "testMessage");
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
