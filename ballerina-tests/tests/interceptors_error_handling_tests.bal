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

final http:Client noServiceRegisteredClientEP = check new("http://localhost:" + noServiceRegisteredTestPort.toString());

listener http:Listener noServiceRegisteredServerEP = new(noServiceRegisteredTestPort, config = {
    interceptors : [
        new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultRequestInterceptor(), 
        new DefaultRequestErrorInterceptor(), new LastRequestInterceptor(), new DefaultResponseInterceptor()
    ]
});

@test:Config{}
function testNoServiceRegistered() returns error? {
    http:Response res = check noServiceRegisteredClientEP->get("/");
    test:assertEquals(res.statusCode, 404);
    assertTrueTextPayload(res.getTextPayload(), "no service has registered for listener");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Service");
}

final http:Client serviceErrorHandlingClientEP = check new("http://localhost:" + serviceErrorHandlingTestPort.toString());

listener http:Listener serviceErrorHandlingServerEP = new(serviceErrorHandlingTestPort, config = {
    interceptors : [
        new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultRequestInterceptor(), 
        new DefaultRequestErrorInterceptor(), new LastRequestInterceptor(), new DefaultResponseInterceptor()
    ]
});

service /foo on serviceErrorHandlingServerEP {

    resource function get bar1(@http:Header string header) returns string {
        return header;
    }

    resource function get bar2(http:Request req) returns string|error {
        string header = check req.getHeader("header");
        return header;
    }

    resource function post baz(@http:Payload Person person) returns Person {
        return person;
    }

    resource function get 'error() returns error {
        return error("Error from resource");
    }

    resource function get callerError(http:Caller caller) returns error? {
        check caller->respond(error("Error from resource"));
    }
}

@test:Config{}
function testNoMatchingServiceRegistered() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/");
    test:assertEquals(res.statusCode, 404);
    assertTrueTextPayload(res.getTextPayload(), "no matching service found for path : /");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Service");
}

@test:Config{}
function testNoMatchingResourceFound() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/new");
    test:assertEquals(res.statusCode, 404);
    assertTextPayload(res.getTextPayload(), "no matching resource found for path : /foo/new , method : GET");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Resource");
}

@test:Config{}
function testHeaderNotFound() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/bar1");
    test:assertEquals(res.statusCode, 400);
    assertTextPayload(res.getTextPayload(), "no header value found for 'header'");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "HeaderBindingError");

    res = check serviceErrorHandlingClientEP->get("/foo/bar2");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(res.getTextPayload(), "Http header does not exist");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "HeaderNotFoundError");
}

@test:Config{}
function testMethodNotAllowed() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/baz");
    test:assertEquals(res.statusCode, 405);
    assertTextPayload(res.getTextPayload(), "Method not allowed");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Resource");
}

@test:Config{}
function testDataBindingFailed() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->post("/foo/baz", "HelloWorld");
    test:assertEquals(res.statusCode, 400);
    assertTrueTextPayload(res.getTextPayload(), "data binding failed");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "PayloadBindingError-Listener");
}

@test:Config{}
function testResourceReturnsError() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/error");
    test:assertEquals(res.statusCode, 500);
    assertTrueTextPayload(res.getTextPayload(), "Error from resource");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "NormalError");
}

@test:Config{}
function testResourceCallerRespondsError() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/callerError");
    test:assertEquals(res.statusCode, 500);
    assertTrueTextPayload(res.getTextPayload(), "Error from resource");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "NormalError");
}
