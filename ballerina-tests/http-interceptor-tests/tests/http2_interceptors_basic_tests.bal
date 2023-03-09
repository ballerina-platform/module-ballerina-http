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
import ballerina/jwt;
import ballerina/test;
import ballerina/http_test_common as common;

int http2InterceptorBasicTestsPort1 = common:getHttp2Port(interceptorBasicTestsPort1);

[jwt:Header, jwt:Payload] reqCtxJwtValues = [];
error? reqCtxJwtDecodeError = ();

final http:Client http2InterceptorsBasicTestsClientEP1 = check new ("http://localhost:" + http2InterceptorBasicTestsPort1.toString(),
    http2Settings = {http2PriorKnowledge: true});

listener http:Listener http2InterceptorsBasicTestsServerEP1 = new (http2InterceptorBasicTestsPort1);

@http:ServiceConfig {
    interceptors: [new DefaultRequestInterceptor(), new LastRequestInterceptor(), new DefaultRequestErrorInterceptor()]
}
service /defaultRequestInterceptor on http2InterceptorsBasicTestsServerEP1 {

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

@http:ServiceConfig {
    interceptors: [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultResponseInterceptor()]
}
service /defaultResponseInterceptor on http2InterceptorsBasicTestsServerEP1 {

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

@http:ServiceConfig {
    interceptors: [
        new LastResponseInterceptor(),
        new DefaultRequestInterceptor(),
        new DefaultResponseInterceptor(),
        new RequestInterceptorReturnsError(),
        new LastRequestInterceptor()
    ]
}
service /requestInterceptorReturnsError on http2InterceptorsBasicTestsServerEP1 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config {}
function tesHttp2RequestInterceptorReturnsError() returns error? {
    http:Response res = check http2InterceptorsBasicTestsClientEP1->get("/requestInterceptorReturnsError");
    test:assertEquals(res.statusCode, 500);
    common:assertTextPayload(check res.getTextPayload(), "Request interceptor returns an error");
}

int http2ResponseInterceptorReturnsErrorTestPort = common:getHttp2Port(responseInterceptorReturnsErrorTestPort);

final http:Client http2ResponseInterceptorReturnsErrorTestClientEP = check new ("http://localhost:" + http2ResponseInterceptorReturnsErrorTestPort.toString(),
    http2Settings = {http2PriorKnowledge: true});

listener http:Listener http2ResponseInterceptorReturnsErrorTestServerEP = new (http2ResponseInterceptorReturnsErrorTestPort, config = {
    interceptors: [new LastResponseInterceptor(), new ResponseInterceptorReturnsError(), new DefaultResponseInterceptor()]
});

service / on http2ResponseInterceptorReturnsErrorTestServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config {}
function tesHttp2ResponseInterceptorReturnsError() returns error? {
    http:Response res = check http2ResponseInterceptorReturnsErrorTestClientEP->get("/");
    test:assertEquals(res.statusCode, 500);
    common:assertTextPayload(check res.getTextPayload(), "Response interceptor returns an error");
}

int http2InterceptorBasicTestsPort2 = common:getHttp2Port(interceptorBasicTestsPort2);

final http:Client http2InterceptorsBasicTestsClientEP2 = check new ("http://localhost:" + http2InterceptorBasicTestsPort2.toString(),
    http2Settings = {http2PriorKnowledge: true});

listener http:Listener http2InterceptorsBasicTestsServerEP2 = new (http2InterceptorBasicTestsPort2);

@http:ServiceConfig {
    interceptors: [
        new RequestInterceptorReturnsError(),
        new DefaultRequestInterceptor(),
        new DefaultRequestErrorInterceptor(),
        new LastRequestInterceptor()
    ]
}
service /requestErrorInterceptor1 on http2InterceptorsBasicTestsServerEP2 {

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

@http:ServiceConfig {
    interceptors: [
        new RequestInterceptorReturnsError(),
        new RequestErrorInterceptorReturnsError(),
        new DefaultRequestInterceptor(),
        new DefaultRequestErrorInterceptor(),
        new LastRequestInterceptor()
    ]
}
service /requestErrorInterceptor2 on http2InterceptorsBasicTestsServerEP2 {

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

@http:ServiceConfig {
    interceptors: [
        new LastResponseInterceptor(),
        new DefaultResponseErrorInterceptor(),
        new DefaultResponseInterceptor(),
        new ResponseInterceptorReturnsError()
    ]
}
service /responseErrorInterceptor1 on http2InterceptorsBasicTestsServerEP2 {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@http:ServiceConfig {
    interceptors: [
        new LastResponseInterceptor(),
        new DefaultResponseErrorInterceptor(),
        new DefaultResponseInterceptor(),
        new RequestInterceptorReturnsError(),
        new DefaultRequestInterceptor(),
        new LastRequestInterceptor()
    ]
}
service /responseErrorInterceptor2 on http2InterceptorsBasicTestsServerEP2 {

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

@http:ServiceConfig {
    interceptors: [new DefaultRequestInterceptor(), new RequestInterceptorSetPayload(), new LastRequestInterceptor()]
}
service /requestInterceptorSetPayload on http2InterceptorsBasicTestsServerEP2 {

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

@http:ServiceConfig {
    interceptors: [new LastResponseInterceptor(), new ResponseInterceptorSetPayload(), new DefaultResponseInterceptor()]
}
service /responseInterceptorSetPayload on http2InterceptorsBasicTestsServerEP3 {

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

@http:ServiceConfig {
    interceptors: [new DefaultRequestInterceptor(), new RequestInterceptorReturnsResponse(), new LastRequestInterceptor()]
}
service /request on http2InterceptorsBasicTestsServerEP3 {

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

@http:ServiceConfig {
    interceptors: [new LastResponseInterceptor(), new ResponseInterceptorReturnsResponse(), new DefaultResponseInterceptor()]
}
service /response on http2InterceptorsBasicTestsServerEP3 {

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

@http:ServiceConfig {
    interceptors: [
        new DefaultRequestInterceptor(),
        new GetRequestInterceptor(),
        new PostRequestInterceptor(),
        new LastRequestInterceptor()
    ]
}
service /requestInterceptorHttpVerb on http2InterceptorsBasicTestsServerEP3 {

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

@http:ServiceConfig {
    interceptors: [
        new DefaultRequestInterceptor(),
        new GetFooRequestInterceptor(),
        new LastResponseInterceptor(),
        new DefaultResponseErrorInterceptor()
    ]
}
service /interceptorPathAndVerb on http2InterceptorsBasicTestsServerEP3 {

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

@http:ServiceConfig {
    interceptors: [new DefaultRequestInterceptor(), new DefaultRequestInterceptorBasePath(), new LastRequestInterceptor()]
}
service / on http2RequestInterceptorBasePathServerEP {

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

@http:ServiceConfig {
    interceptors: [new DefaultRequestInterceptor(), new GetRequestInterceptorBasePath(), new LastRequestInterceptor()]
}
service /foo on http2GetRequestInterceptorBasePathServerEP {

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

@http:ServiceConfig {
    interceptors : [new RequestInterceptorJwtInformation()]
}
service /requestInterceptorJwtInformation on new http:Listener(jwtInformationInReqCtxtTestPort, secureSocket = {
        key: {
            certFile: common:CERT_FILE,
            keyFile: common:KEY_FILE
        }
    }) {
    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Hello client");
    }
}

@test:Config{}
function testJwtInformationInRequestContext() returns error? {
    http:Client jwtClient = check new("https://localhost:" + jwtInformationInReqCtxtTestPort.toString(),
    secureSocket = {
        cert: common:CERT_FILE
    },
    auth = {
        username: "ballerina",
        issuer: "wso2",
        audience: ["ballerina", "ballerina.org", "ballerina.io"],
        keyId: "5a0b754-895f-4279-8843-b745e11a57e9",
        jwtId: "JlbmMiOiJBMTI4Q0JDLUhTMjU2In",
        customClaims: { "scp": "admin" },
        expTime: 3600,
        signatureConfig: {
            config: {
                keyFile: common:KEY_FILE
            }
        }
    });
    string response = check jwtClient->get("/requestInterceptorJwtInformation");
    test:assertEquals(response, "Hello client");
    test:assertEquals(reqCtxJwtValues[0], {"alg":"RS256","typ":"JWT","kid":"5a0b754-895f-4279-8843-b745e11a57e9"});
    test:assertEquals(reqCtxJwtValues[1].iss, "wso2");
    test:assertEquals(reqCtxJwtValues[1].sub, "ballerina");
    test:assertEquals(reqCtxJwtValues[1].aud, ["ballerina","ballerina.org","ballerina.io"]);
    test:assertEquals(reqCtxJwtValues[1].jti, "JlbmMiOiJBMTI4Q0JDLUhTMjU2In");
    test:assertEquals(reqCtxJwtValues[1]["scp"], "admin");
}

@test:Config{}
function testJwtInformationDecodeErrorInRequestContext() returns error? {
    http:Client jwtClient = check new("https://localhost:" + jwtInformationInReqCtxtTestPort.toString(),
        secureSocket = {
            cert: common:CERT_FILE
        });
    string response = check jwtClient->get("/requestInterceptorJwtInformation", {"authorization": "Bearer abcd"});
    test:assertEquals(response, "Hello client");
    if reqCtxJwtDecodeError is http:ListenerAuthError {
        test:assertEquals((<http:ListenerAuthError>reqCtxJwtDecodeError).message(), "an error occured while decoding jwt string.");
        error? cause = (<http:ListenerAuthError>reqCtxJwtDecodeError).cause();
        if cause is error {
            test:assertEquals(cause.message(), "Invalid JWT.");
        } else {
            test:assertFail("Expected a ListenerAuthError");
        }
    } else {
        test:assertFail("Expected a ListenerAuthError");
    }
}

@test:Config{
    dependsOn: [testJwtInformationDecodeErrorInRequestContext]
}
function testNilJwtInformationValueInRequestContext() returns error? {
    http:Client jwtClient = check new("https://localhost:" + jwtInformationInReqCtxtTestPort.toString(),
        secureSocket = {
            cert: common:CERT_FILE
        });
    string response = check jwtClient->get("/requestInterceptorJwtInformation");
    test:assertEquals(response, "Hello client");
    test:assertTrue(reqCtxJwtDecodeError is ());
}
