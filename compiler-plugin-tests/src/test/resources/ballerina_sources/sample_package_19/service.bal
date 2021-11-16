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

service class interceptorService0 {

    resource function get greeting(http:RequestContext ctx, http:Request req, http:Caller caller) returns string {
        req.setTextPayload("interceptor");
        return "HelloWorld";
    }
}

service class interceptorService1 {
    *http:RequestInterceptor;

    resource function get greeting(http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class interceptorService2 {
    *http:RequestInterceptor;

    resource function post [string... path](http:Caller caller, http:Request req) returns error? {
        req.setTextPayload("interceptor");
        check caller->respond(path);
    }
}

service class interceptorService3 {
    *http:RequestInterceptor;

    resource function default [string... path](http:Caller caller, http:RequestContext ctx, http:Request req) {
        req.setTextPayload("interceptor");
    }
}

service class interceptorService4 {
    *http:RequestInterceptor;

    resource function get [string... path](http:Caller caller, http:RequestContext ctx, http:Request req) returns error{
        return error("new error");
    }
}

service class interceptorService5 {
    *http:RequestErrorInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

// Negative Cases

service class interceptorService6 {
    *http:RequestInterceptor;
    *http:RequestErrorInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class interceptorService7 {
    *http:RequestErrorInterceptor;

    resource function 'default foo(http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class interceptorService8 {
    *http:RequestErrorInterceptor;

    resource function get [string... path](http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class interceptorService9 {
    *http:RequestErrorInterceptor;

    resource function get foo(http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class interceptorService10 {
    *http:RequestInterceptor;

    resource function get greeting(http:RequestContext ctx, http:Request req, http:Caller caller) returns string {
        req.setTextPayload("interceptor");
        return "HelloWorld";
    }
}

service class interceptorService11 {
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

service class interceptorService12 {
    *http:RequestInterceptor;

    @http:ResourceConfig{}
    resource function get greeting1(http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}
