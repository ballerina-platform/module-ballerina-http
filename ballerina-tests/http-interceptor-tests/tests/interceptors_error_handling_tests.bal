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

final http:Client serviceErrorHandlingClientEP = check new("http://localhost:" + serviceErrorHandlingTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener serviceErrorHandlingServerEP = new(serviceErrorHandlingTestPort,
    httpVersion = http:HTTP_1_1
);

service http:InterceptableService /foo on serviceErrorHandlingServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor, DefaultRequestInterceptor,
        DefaultRequestErrorInterceptor, LastRequestInterceptor, DefaultResponseInterceptor] {
        return [
            new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultRequestInterceptor(),
            new DefaultRequestErrorInterceptor(), new LastRequestInterceptor(), new DefaultResponseInterceptor()
        ];
    }

    resource function get bar1(@http:Header int header) returns int {
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

    resource function get query(int id) returns string {
        return "hello world";
    }

    resource function get person/[int id]() returns int {
        return id;
    }

    @http:ResourceConfig {
        consumes: ["application/json"],
        produces: ["application/xml"]
    }
    resource function post info(@http:Payload json msg) returns xml {
        return xml `<greeting>hello</greeting>`;
    }
}

@test:Config{}
function testNoMatchingServiceRegistered() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/");
    test:assertEquals(res.statusCode, 404);
    common:assertTrueTextPayload(res.getTextPayload(), "no matching service found for path");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Service");
}

@test:Config{}
function testNoMatchingResourceFound() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/new");
    test:assertEquals(res.statusCode, 404);
    common:assertTextPayload(res.getTextPayload(), "no matching resource found for path : /foo/new , method : GET");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Resource");
}

@test:Config{}
function testHeaderNotFound() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/bar1");
    test:assertEquals(res.statusCode, 400);
    common:assertTextPayload(res.getTextPayload(), "no header value found for 'header'");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "HeaderBindingError");

    res = check serviceErrorHandlingClientEP->get("/foo/bar1", {"header": "hi"});
    test:assertEquals(res.statusCode, 400);
    common:assertTextPayload(res.getTextPayload(), "header binding failed for parameter: 'header'");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "HeaderBindingError");

    res = check serviceErrorHandlingClientEP->get("/foo/bar2");
    test:assertEquals(res.statusCode, 500);
    common:assertTextPayload(res.getTextPayload(), "Http header does not exist");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "HeaderNotFoundError");
}

@test:Config{}
function testMethodNotAllowed() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/baz");
    test:assertEquals(res.statusCode, 405);
    common:assertTextPayload(res.getTextPayload(), "Method not allowed");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Resource");
}

@test:Config{}
function testDataBindingFailed() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->post("/foo/baz", "HelloWorld");
    test:assertEquals(res.statusCode, 400);
    common:assertTrueTextPayload(res.getTextPayload(), "data binding failed");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "PayloadBindingError");
}

@test:Config{}
function testResourceReturnsError() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/error");
    test:assertEquals(res.statusCode, 500);
    common:assertTrueTextPayload(res.getTextPayload(), "Error from resource");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "NormalError");
}

@test:Config{}
function testResourceCallerRespondsError() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/callerError");
    test:assertEquals(res.statusCode, 500);
    common:assertTrueTextPayload(res.getTextPayload(), "Error from resource");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "NormalError");
}

@test:Config{}
function testQueryParamError() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/query");
    test:assertEquals(res.statusCode, 400);
    common:assertTrueTextPayload(res.getTextPayload(), "no query param value found for 'id'");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "QueryParamBindingError");

    res = check serviceErrorHandlingClientEP->get("/foo/query?id=hello");
    test:assertEquals(res.statusCode, 400);
    common:assertTrueTextPayload(res.getTextPayload(), "error in casting query param : 'id");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "QueryParamBindingError");
}

@test:Config{}
function testPathParamError() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/person/hello");
    test:assertEquals(res.statusCode, 400);
    common:assertTrueTextPayload(res.getTextPayload(), "error in casting path parameter : 'id'");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "PathParamBindingError");
}

@test:Config{}
function testConsumesProducesError() returns error? {
    http:Request req = new;
    req.setXmlPayload(xml `<name>john</name>`);
    http:Response res = check serviceErrorHandlingClientEP->post("/foo/info", req);
    test:assertEquals(res.statusCode, 415);
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Resource");

    req = new;
    req.setJsonPayload({name: "john"});
    req.setHeader("accept", "application/json");
    res = check serviceErrorHandlingClientEP->post("/foo/info", req);
    test:assertEquals(res.statusCode, 406);
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Resource");
}

listener http:Listener authErrorHandlingServerEP = new(authErrorHandlingTestPort,
    httpVersion = http:HTTP_1_1,
    secureSocket = {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
);

// Basic auth (file user store) secured service
@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["write", "update"]
        }
    ]
}
service http:InterceptableService /auth on authErrorHandlingServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor, DefaultRequestInterceptor,
        DefaultRequestErrorInterceptor, LastRequestInterceptor, DefaultResponseInterceptor] {
        return [
            new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultRequestInterceptor(),
            new DefaultRequestErrorInterceptor(), new LastRequestInterceptor(), new DefaultResponseInterceptor()
        ];
    }

    resource function get .() returns string {
        return "Hello World!";
    }
}

// Disabled due to https://github.com/ballerina-platform/ballerina-standard-library/issues/3318
@test:Config{enable: false}
function testAuthnError() returns error? {
    http:Client clientEP = check new("https://localhost:" + authErrorHandlingTestPort.toString(),
        httpVersion = http:HTTP_1_1,
        auth = {
            username: "peter",
            password: "123"
        },
        secureSocket = {
            cert: {
                path: common:TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    );
    http:Response res = check clientEP->get("/auth");
    test:assertEquals(res.statusCode, 401);
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "ListenerAuthorizationError");

    clientEP = check new("https://localhost:" + authErrorHandlingTestPort.toString(),
        secureSocket = {
            cert: {
                path: common:TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    );
    res = check clientEP->get("/auth");
    test:assertEquals(res.statusCode, 401);
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "ListenerAuthorizationError");
}

@test:Config{}
function testAuthzError() returns error? {
    http:Client clientEP = check new("https://localhost:" + authErrorHandlingTestPort.toString(),
        httpVersion = http:HTTP_1_1,
        auth = {
            username: "bob",
            password: "yyy"
        },
        secureSocket = {
            cert: {
                path: common:TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    );
    http:Response res = check clientEP->get("/auth");
    test:assertEquals(res.statusCode, 403);
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "ListenerAuthorizationError");
}

listener http:Listener singleServiceRegisteredServerEP = new(singleServiceRegisteredTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService /path1 on singleServiceRegisteredServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor] {
        return [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor()];
    }

    resource function get .() returns string {
        return "Hello Path1!";
    }
}

@test:Config{}
function testInvalidPathWithSingleService() returns error? {
    http:Client singleServiceRegisteredClientEP = check new("http://localhost:" + singleServiceRegisteredTestPort.toString(), httpVersion = http:HTTP_1_1);
    http:Response res = check singleServiceRegisteredClientEP->get("/path2");
    test:assertEquals(res.statusCode, 404);
    test:assertEquals(res.getTextPayload(), "no matching service found for path: /path2");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Service");
}

listener http:Listener multipleServiceRegisteredServerEP = new(multipleServiceRegisteredTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService /path1 on multipleServiceRegisteredServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor] {
        return [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor()];
    }

    resource function get .() returns string {
        return "Hello Path1!";
    }
}

service http:InterceptableService /path2 on multipleServiceRegisteredServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor] {
        return [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor()];
    }

    resource function get .() returns string {
        return "Hello Path2!";
    }
}

@test:Config{}
function testInvalidPathWithMultipleService() returns error? {
    http:Client multipleServiceRegisteredClientEP = check new("http://localhost:" + multipleServiceRegisteredTestPort.toString(), httpVersion = http:HTTP_1_1);
    http:Response res = check multipleServiceRegisteredClientEP->get("/path3");
    test:assertEquals(res.statusCode, 404);
    check common:assertJsonErrorPayload(check res.getJsonPayload(), "no matching service found for path", "Not Found", 404, "/path3", "GET");
    test:assertFalse(res.hasHeader("last-interceptor"));
    test:assertFalse(res.hasHeader("default-response-error-interceptor"));
    test:assertFalse(res.hasHeader("last-response-interceptor"));
    test:assertFalse(res.hasHeader("error-type"));
}

listener http:Listener rootServiceRegisteredServerEP = new(rootServiceRegisteredTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService /path1 on rootServiceRegisteredServerEP {

    public function createInterceptors() returns DefaultResponseErrorInterceptor {
        return new DefaultResponseErrorInterceptor();
    }

    resource function get .() returns string {
        return "Hello Path1!";
    }
}

service http:InterceptableService / on rootServiceRegisteredServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor] {
        return [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor()];
    }

    resource function get .() returns string {
        return "Hello Root!";
    }
}

@test:Config{}
function testInvalidPathWithRootService() returns error? {
    http:Client rootServiceRegisteredClientEP = check new("http://localhost:" + rootServiceRegisteredTestPort.toString(), httpVersion = http:HTTP_1_1);
    http:Response res = check rootServiceRegisteredClientEP->get("/path2");
    test:assertEquals(res.statusCode, 404);
    test:assertEquals(res.getTextPayload(), "no matching resource found for path : /path2 , method : GET");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Resource");
}

listener http:Listener singleServiceWithListenerInterceptorsEP = new(singleServiceWithListenerInterceptorsTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService /path1 on singleServiceWithListenerInterceptorsEP {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor, ResponseInterceptorReturnsResponse, ResponseErrorInterceptorWithReq] {
        return [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new ResponseInterceptorReturnsResponse(), new ResponseErrorInterceptorWithReq()];
    }

    resource function get .() returns string {
        return "Hello Path1!";
    }
}

@test:Config{enable:false}
function testInvalidPathWithSingleServiceContainingListenerInterceptors() returns error? {
    http:Client singleServiceWithListenerInterceptorsClientEp = check new("http://localhost:" + singleServiceWithListenerInterceptorsTestPort.toString(),
            httpVersion = http:HTTP_1_1);
    http:Response res = check singleServiceWithListenerInterceptorsClientEp->get("/path2");
    test:assertEquals(res.statusCode, 404);
    test:assertEquals(res.getTextPayload(), "no matching service found for path : /path2");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Service");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
}
