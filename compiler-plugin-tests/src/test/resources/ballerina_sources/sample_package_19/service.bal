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

public type RequestInterceptorType1 service object {
    *http:RequestInterceptor;
};

public type RequestInterceptorType2 service object {
    *RequestInterceptorType1;
};

public type RequestErrorInterceptorType1 service object {
    *http:RequestErrorInterceptor;
};

public type RequestErrorInterceptorType2 service object {
    *RequestErrorInterceptorType1;
};

public type MixedInterceptorType service object {
    *RequestInterceptorType2;
    *RequestErrorInterceptorType1;
};

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

    resource function default [string... path](http:Caller caller, http:RequestContext ctx, http:Request req) {
        req.setTextPayload("interceptor");
    }
}

service class InterceptorService4 {
    *http:RequestInterceptor;

    resource function get [string... path](http:Caller caller, http:RequestContext ctx, http:Request req) returns error{
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

    resource function get [string... path](string q1, int q2, @http:Payload string payload, @http:Header string foo, http:Caller caller) returns error? {
        check caller->respond(payload);
    }
}

service class InterceptorService7 {
    *RequestInterceptorType1;

    resource function get greeting(http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService8 {
    *RequestInterceptorType2;

    resource function get greeting(http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService9 {
    *RequestErrorInterceptorType1;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService10 {
    *RequestErrorInterceptorType2;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

// Negative Cases

service class InterceptorService11 {
    *http:RequestInterceptor;
    *http:RequestErrorInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService12 {
    *http:RequestErrorInterceptor;

    resource function 'default foo(http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService13 {
    *http:RequestErrorInterceptor;

    resource function get [string... path](http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService14 {
    *http:RequestErrorInterceptor;

    resource function get foo(http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService15 {
    *http:RequestInterceptor;

    resource function get greeting(http:RequestContext ctx, http:Request req, http:Caller caller) returns string {
        req.setTextPayload("interceptor");
        return "HelloWorld";
    }
}

service class InterceptorService16 {
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

service class InterceptorService17 {
    *http:RequestInterceptor;

    @http:ResourceConfig{}
    resource function get greeting1(http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService18 {
    *http:RequestErrorInterceptor;

    resource function 'default [string path](http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService19 {
    *RequestErrorInterceptorType2;

    resource function get [string... path](http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service class InterceptorService20 {
    *MixedInterceptorType;

    resource function get [string... path](http:RequestContext ctx, http:Request req, http:Caller caller) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}
