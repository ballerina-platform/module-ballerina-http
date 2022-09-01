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

final http:Client noServiceRegisteredClientEP = check new("http://localhost:" + noServiceRegisteredTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener noServiceRegisteredServerEP = new(noServiceRegisteredTestPort,
    httpVersion = http:HTTP_1_1,
    interceptors = [
        new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultRequestInterceptor(),
        new DefaultRequestErrorInterceptor(), new LastRequestInterceptor(), new DefaultResponseInterceptor()
    ]
);

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

final http:Client serviceErrorHandlingClientEP = check new("http://localhost:" + serviceErrorHandlingTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener serviceErrorHandlingServerEP = new(serviceErrorHandlingTestPort,
    httpVersion = http:HTTP_1_1,
    interceptors = [
        new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultRequestInterceptor(),
        new DefaultRequestErrorInterceptor(), new LastRequestInterceptor(), new DefaultResponseInterceptor()
    ]
);

service /foo on serviceErrorHandlingServerEP {

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

    res = check serviceErrorHandlingClientEP->get("/foo/bar1", {"header": "hi"});
    test:assertEquals(res.statusCode, 400);
    assertTextPayload(res.getTextPayload(), "header binding failed for parameter: 'header'");
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
    assertHeaderValue(check res.getHeader("error-type"), "PayloadBindingError");
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

@test:Config{}
function testQueryParamError() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/query");
    test:assertEquals(res.statusCode, 400);
    assertTrueTextPayload(res.getTextPayload(), "no query param value found for 'id'");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "QueryParamBindingError");

    res = check serviceErrorHandlingClientEP->get("/foo/query?id=hello");
    test:assertEquals(res.statusCode, 400);
    assertTrueTextPayload(res.getTextPayload(), "error in casting query param : 'id");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "QueryParamBindingError");
}

@test:Config{}
function testPathParamError() returns error? {
    http:Response res = check serviceErrorHandlingClientEP->get("/foo/person/hello");
    test:assertEquals(res.statusCode, 400);
    assertTrueTextPayload(res.getTextPayload(), "error in casting path parameter : 'id'");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "PathParamBindingError");
}

@test:Config{}
function testConsumesProducesError() returns error? {
    http:Request req = new;
    req.setXmlPayload(xml `<name>john</name>`);
    http:Response res = check serviceErrorHandlingClientEP->post("/foo/info", req);
    test:assertEquals(res.statusCode, 415);
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Resource");

    req = new;
    req.setJsonPayload({name: "john"});
    req.setHeader("accept", "application/json");
    res = check serviceErrorHandlingClientEP->post("/foo/info", req);
    test:assertEquals(res.statusCode, 406);
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "DispatchingError-Resource");
}

listener http:Listener authErrorHandlingServerEP = new(authErrorHandlingTestPort,
    httpVersion = http:HTTP_1_1,
    interceptors = [
        new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultRequestInterceptor(),
        new DefaultRequestErrorInterceptor(), new LastRequestInterceptor(), new DefaultResponseInterceptor()
    ],
    secureSocket = {
        key: {
            path: KEYSTORE_PATH,
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
service /auth on authErrorHandlingServerEP {
    resource function get .() returns string {
        return "Hello World!";
    }
}

@test:Config{}
function testAuthnError() returns error? {
    http:Client clientEP = check new("https://localhost:" + authErrorHandlingTestPort.toString(),
        httpVersion = http:HTTP_1_1,
        auth = {
            username: "peter",
            password: "123"
        },
        secureSocket = {
            cert: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    );
    http:Response res = check clientEP->get("/auth");
    test:assertEquals(res.statusCode, 401);
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "ListenerAuthorizationError");

    clientEP = check new("https://localhost:" + authErrorHandlingTestPort.toString(),
        secureSocket = {
            cert: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    );
    res = check clientEP->get("/auth");
    test:assertEquals(res.statusCode, 401);
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "ListenerAuthorizationError");
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
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    );
    http:Response res = check clientEP->get("/auth");
    test:assertEquals(res.statusCode, 403);
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    assertHeaderValue(check res.getHeader("error-type"), "ListenerAuthorizationError");
}
