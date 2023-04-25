// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

// Positive Cases

class HelloWorld {
    string hello = "HelloWorld";

    function greeting() returns string{
        return self.hello;
    }
}

service class InterceptorService0 {

    resource function get greeting(http:RequestContext ctx, http:Request req, http:Caller caller) returns string {
        req.setTextPayload("interceptor");
        return "HelloWorld";
    }
}

service class InterceptorService1 {
    *http:RequestInterceptor;

    resource function get greeting(http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService2 {
    *http:RequestInterceptor;

    resource function post [string... path](http:Caller caller, http:Request req) returns error? {
        req.setTextPayload("interceptor");
        check caller->respond(path);
    }
}

service class InterceptorService3 {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:Caller caller, http:RequestContext ctx, http:Request req) {
        req.setTextPayload("interceptor");
    }
}

service class InterceptorService4 {
    *http:RequestInterceptor;

    resource function get [string... path](http:Caller caller, http:RequestContext ctx, http:Request req) returns error {
        return error("new error");
    }
}

service class InterceptorService5 {
    *http:RequestErrorInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService6 {
    *http:RequestInterceptor;

    resource function post [string... path](string q1, int q2, @http:Payload string payload, @http:Header string foo, http:Caller caller) returns error? {
        check caller->respond(payload);
    }
}

service class RequestInterceptor1 {
    *http:RequestInterceptor;

    resource function get greeting(http:RequestContext ctx, http:Request req, http:Caller caller) returns string {
        req.setTextPayload("interceptor");
        return "HelloWorld";
    }
}

service class ResponseInterceptor1 {
    *http:ResponseInterceptor;

    remote function interceptResponse() {
    }
}

service class ResponseInterceptor2 {
    *http:ResponseInterceptor;

    remote function interceptResponse (http:RequestContext ctx) returns http:NextService|error? {
        return ctx.next();
    }
}

service class ResponseInterceptor3 {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, http:Response res) returns http:NextService|error? {
        res.setHeader("response-interceptor", "hello-world");
        return ctx.next();
    }
}

service class ResponseInterceptor4 {
    *http:ResponseInterceptor;

    remote function interceptResponse (http:Response res) {
        res.setHeader("response-interceptor", "hello-world");
    }
}

service class ResponseInterceptor5 {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:Caller caller, http:Response res) returns error? {
        res.setHeader("response-interceptor", "hello-world");
        check caller->respond(res);
    }
}

service class ResponseInterceptor6 {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:Caller caller, http:Response res) returns error? {
        res.setHeader("response-interceptor", "hello-world");
        return caller->respond(res);
    }
}

service class ResponseInterceptor7 {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, http:Caller caller) returns http:NextService|error? {
        check caller->respond("greetings");
        return ctx.next();
    }
}

service class ResponseErrorInterceptorService1 {
    *http:ResponseErrorInterceptor;

    remote function interceptResponseError (error err, http:RequestContext ctx) returns http:NextService|error? {
        return ctx.next();
    }
}

service class ResponseInterceptor11 {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, http:Request req) returns http:NextService|error? {
        return ctx.next();
    }
}

// Negative Cases

service class InterceptorService7 {
    *http:RequestInterceptor;
    *http:RequestErrorInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService8 {
    *http:RequestErrorInterceptor;

    resource function 'default foo(http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService9 {
    *http:RequestErrorInterceptor;

    resource function get [string... path](http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService10 {
    *http:RequestErrorInterceptor;

    resource function get foo(http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService11 {
    *http:RequestInterceptor;

    resource function get greeting() returns error[] {
        error e1 = error http:ListenerError("hello1");
        error e2 = error http:ListenerError("hello2");
        return [e1, e2];
    }
}

service class InterceptorService12 {
    *http:RequestInterceptor;

    resource function get greeting1(http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }

    resource function get greeting2(http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService13 {
    *http:RequestInterceptor;

    @http:ResourceConfig{}
    resource function get greeting1(http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService14 {
    *http:RequestErrorInterceptor;

    resource function 'default [string path](http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService15 {
    *http:RequestInterceptor;

    resource function get greeting(http:RequestContext ctx, @http:Payload string abc) returns http:NextService|error? {
        return ctx.next();
    }
}

service class InterceptorService16 {
    *http:RequestInterceptor;
}

service class InterceptorService17 {
    *http:RequestErrorInterceptor;
}

service class InterceptorService18 {
    *http:ResponseInterceptor;
}

service class RequestInterceptorService1 {
    *http:RequestInterceptor;

    remote function interceptResponse(http:RequestContext ctx) returns http:NextService|error? {
        return ctx.next();
    }
}

service class RequestErrorInterceptorService1 {
    *http:RequestErrorInterceptor;

    remote function interceptResponse(http:RequestContext ctx) returns http:NextService|error? {
        return ctx.next();
    }
}

service class ResponseInterceptor8 {
    *http:ResponseInterceptor;

    resource function post [string... path](http:Caller caller, http:Request req) returns error? {
        req.setTextPayload("interceptor");
        check caller->respond(path);
    }
}

service class ResponseInterceptor9 {
    *http:ResponseInterceptor;

    remote function returnResponse(http:RequestContext ctx, http:Response res) returns http:NextService|error? {
        res.setHeader("response-interceptor", "hello-world");
        return ctx.next();
    }
}

service class ResponseInterceptor10 {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, http:Response res1, http:Response res2) returns http:NextService|error? {
        res1.setHeader("response-interceptor", "hello-world");
        return ctx.next();
    }
}

service class ResponseInterceptor12 {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, string payload) returns http:NextService|error? {
        return ctx.next();
    }
}

service class ResponseInterceptor13 {
    *http:ResponseInterceptor;

    remote function interceptResponse() returns http:Client {
        http:Client httpClient = checkpanic new("path");
        return httpClient;
    }
}

service class ResponseInterceptor14 {
    *http:ResponseInterceptor;

    remote function interceptResponse() returns @http:Payload string {
        return "hello";
    }
}

service class RequestInterceptor2 {
    *http:RequestInterceptor;

    resource function post [string... path]() returns @http:Cache string {
        return "hello";
    }
}

service class ResponseErrorInterceptorService2 {
    *http:ResponseErrorInterceptor;

    remote function interceptError(error err, http:RequestContext ctx) returns http:NextService|error? {
        return ctx.next();
    }
}

service class ResponseErrorInterceptorService3 {
    *http:ResponseErrorInterceptor;

    remote function interceptResponseError(http:RequestContext ctx) returns http:NextService|error? {
        return ctx.next();
    }
}
