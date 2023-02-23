// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

type Person record {|
    readonly int id;
|};

class HelloWorld {
    string hello = "HelloWorld";

    function greeting() returns string{
        return self.hello;
    }
}

service class SClass {
   *http:Service;
   resource function post foo(map<json> p) returns string {
       return "done";
   }
}

service class InterceptorService {
    *http:RequestInterceptor;

    resource function post [string... path](string q1, int q2, Person payload, @http:Header string foo, http:Caller caller) returns error? {
        check caller->respond(payload);
    }
}

service class ErrorInterceptorService {
    *http:RequestErrorInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req, Person payload, error err) returns http:NextService|error? {
        req.setTextPayload("interceptor");
        return ctx.next();
    }
}

service http:Service on new http:Listener(9090) {

    resource function post singleStructured(Person p) returns string {
        return "done"; // p is payload param
    }
}
