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
import ballerina/lang.runtime;
import ballerina/lang.'string as strings;
import ballerina/http_test_common as common;

final http:Client requestInterceptorWithCallerRespondClientEP = check new("http://localhost:" + requestInterceptorWithCallerRespondTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorWithCallerRespondServerEP = new(requestInterceptorWithCallerRespondTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on requestInterceptorWithCallerRespondServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, LastResponseInterceptor, DefaultResponseInterceptor,
                RequestInterceptorCallerRespond, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new LastResponseInterceptor(), new DefaultResponseInterceptor(),
                        new RequestInterceptorCallerRespond(), new LastRequestInterceptor()];
    }

    resource function 'default test() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorWithCallerRespond() returns error? {
    http:Response res = check requestInterceptorWithCallerRespondClientEP->get("/");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("request-interceptor-caller-respond"), "true");
    common:assertTextPayload(check res.getTextPayload(), "Response from caller inside interceptor");
}

final http:Client responseInterceptorWithCallerRespondClientEP = check new("http://localhost:" + responseInterceptorWithCallerRespondTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener responseInterceptorWithCallerRespondServerEP = new(responseInterceptorWithCallerRespondTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on responseInterceptorWithCallerRespondServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, ResponseInterceptorCallerRespond, DefaultResponseInterceptor] {
        return [new LastResponseInterceptor(), new ResponseInterceptorCallerRespond(), new DefaultResponseInterceptor()];
    }

    resource function 'default test() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testResponseInterceptorWithCallerRespond() returns error? {
    http:Response res = check responseInterceptorWithCallerRespondClientEP->get("/test");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("response-interceptor-caller-respond"), "true");
    common:assertTextPayload(check res.getTextPayload(), "Response from caller inside response interceptor");
}

final http:Client requestInterceptorCallerRespondErrorTestClientEP = check new("http://localhost:" + requestInterceptorCallerRespondErrorTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorCallerRespondErrorTestServerEP = new(requestInterceptorCallerRespondErrorTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on requestInterceptorCallerRespondErrorTestServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor, DefaultResponseInterceptor,
                RequestInterceptorReturnsError, DefaultRequestInterceptor, LastRequestInterceptor] {
        return [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultResponseInterceptor(),
                        new RequestInterceptorReturnsError(), new DefaultRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorCallerRespondsError() returns error? {
    http:Response res = check requestInterceptorCallerRespondErrorTestClientEP->get("/responseErrorInterceptor2");
    test:assertEquals(res.statusCode, 500);
    common:assertTextPayload(check res.getTextPayload(), "Request interceptor returns an error");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "NormalError");
}


final http:Client responseInterceptorCallerRespondErrorTestClientEP = check new("http://localhost:" + responseInterceptorCallerRespondErrorTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener responseInterceptorCallerRespondErrorTestServerEP = new(responseInterceptorCallerRespondErrorTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on responseInterceptorCallerRespondErrorTestServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, DefaultResponseErrorInterceptor, DefaultResponseInterceptor,
            ResponseInterceptorCallerRespondError] {
        return [new LastResponseInterceptor(), new DefaultResponseErrorInterceptor(), new DefaultResponseInterceptor(),
                        new ResponseInterceptorCallerRespondError()];
    }

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testResponseInterceptorCallerRespondsError() returns error? {
    http:Response res = check responseInterceptorCallerRespondErrorTestClientEP->get("/");
    test:assertEquals(res.statusCode, 500);
    common:assertTextPayload(check res.getTextPayload(), "Response interceptor returns an error");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-error-interceptor");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("default-response-error-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("error-type"), "NormalError");
}

final http:Client requestInterceptorDataBindingClientEP1 = check new("http://localhost:" + requestInterceptorDataBindingTestPort1.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorDataBindingServerEP1 = new(requestInterceptorDataBindingTestPort1, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on requestInterceptorDataBindingServerEP1 {

    public function createInterceptors() returns [DefaultRequestInterceptor, DataBindingRequestInterceptor,
            RequestErrorInterceptorReturnsErrorMsg, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new DataBindingRequestInterceptor(), new RequestErrorInterceptorReturnsErrorMsg(),
                new LastRequestInterceptor()];
    }

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

final http:Client requestInterceptorDataBindingClientEP2 = check new("http://localhost:" + requestInterceptorDataBindingTestPort2.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorDataBindingServerEP2 = new(requestInterceptorDataBindingTestPort2, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on requestInterceptorDataBindingServerEP2 {

    public function createInterceptors() returns [DataBindingRequestInterceptor, LastRequestInterceptor] {
        return [new DataBindingRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorDataBinding() returns error? {
    http:Request req = new();
    req.setHeader("interceptor", "databinding-interceptor");
    req.setTextPayload("Request from requestInterceptorDataBindingClient");
    http:Response res = check requestInterceptorDataBindingClientEP1->post("/", req);
    common:assertTextPayload(check res.getTextPayload(), "Request from requestInterceptorDataBindingClient");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check requestInterceptorDataBindingClientEP1->post("/", "payload");
    test:assertEquals(res.statusCode, 200);
    common:assertTextPayload(res.getTextPayload(), "no header value found for 'interceptor'");

    res = check requestInterceptorDataBindingClientEP1->get("/");
    test:assertEquals(res.statusCode, 200);
    common:assertTrueTextPayload(res.getTextPayload(), "data binding failed");

    res = check requestInterceptorDataBindingClientEP2->post("/", req);
    common:assertTextPayload(check res.getTextPayload(), "Request from requestInterceptorDataBindingClient");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

@test:Config{}
function testRequestInterceptorDataBindingWithLargePayload() returns error? {
    http:Request req = new();
    string payload = "";
    int i = 0;
    while (i < 10) {
        payload += largePayload;
        i += 1;
    }
    req.setHeader("interceptor", "databinding-interceptor");
    req.setTextPayload(payload);
    http:Response res = check requestInterceptorDataBindingClientEP1->post("/", req);
    common:assertTextPayload(check res.getTextPayload(), payload);
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check requestInterceptorDataBindingClientEP2->post("/", req);
    common:assertTextPayload(check res.getTextPayload(), payload);
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

final http:Client requestInterceptorWithoutCtxNextClientEP = check new("http://localhost:" + requestInterceptorWithoutCtxNextTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorWithoutCtxNextServerEP = new(requestInterceptorWithoutCtxNextTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on requestInterceptorWithoutCtxNextServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, RequestInterceptorWithoutCtxNext,
            LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new RequestInterceptorWithoutCtxNext(), new LastRequestInterceptor()];
    }

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorWithoutCtxNext() returns error? {
    http:Response res = check requestInterceptorWithoutCtxNextClientEP->get("/");
    test:assertEquals(res.statusCode, 202);
}

final http:Client responseInterceptorWithoutCtxNextClientEP = check new("http://localhost:" + responseInterceptorWithoutCtxNextTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener responseInterceptorWithoutCtxNextServerEP = new(responseInterceptorWithoutCtxNextTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on responseInterceptorWithoutCtxNextServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, ResponseInterceptorWithoutCtxNext,
                DefaultResponseInterceptor] {
        return [new LastResponseInterceptor(), new ResponseInterceptorWithoutCtxNext(), new DefaultResponseInterceptor()];
    }

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testResponseInterceptorWithoutCtxNext() returns error? {
    http:Response res = check responseInterceptorWithoutCtxNextClientEP->get("/");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-interceptor");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    test:assertEquals(res.statusCode, 202);
}

final http:Client requestInterceptorSkipClientEP = check new("http://localhost:" + requestInterceptorSkipTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorSkipServerEP = new(requestInterceptorSkipTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on requestInterceptorSkipServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, RequestInterceptorSkip, RequestInterceptorWithoutCtxNext,
                LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new RequestInterceptorSkip(), new RequestInterceptorWithoutCtxNext(),
                    new LastRequestInterceptor()];
    }

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorSkip() returns error? {
    http:Response res = check requestInterceptorSkipClientEP->get("/");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "skip-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

final http:Client responseInterceptorSkipClientEP = check new("http://localhost:" + responseInterceptorSkipTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener responseInterceptorSkipServerEP = new(responseInterceptorSkipTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on responseInterceptorSkipServerEP {

    public function createInterceptors() returns [LastResponseInterceptor, ResponseInterceptorWithoutCtxNext, ResponseInterceptorSkip,
              DefaultResponseInterceptor] {
        return [new LastResponseInterceptor(), new ResponseInterceptorWithoutCtxNext(), new ResponseInterceptorSkip(),
                new DefaultResponseInterceptor()];
    }

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testResponseInterceptorSkip() returns error? {
    http:Response res = check responseInterceptorSkipClientEP->get("/");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "skip-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("skip-interceptor"), "true");
}

final http:Client requestInterceptorCallerRespondContinueClientEP = check new("http://localhost:" + requestInterceptorCallerRespondContinueTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorCallerRespondContinueServerEP = new(requestInterceptorCallerRespondContinueTestPort, httpVersion = http:HTTP_1_1);

isolated string message1 = "Greetings from client1";

service http:InterceptableService / on requestInterceptorCallerRespondContinueServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, RequestInterceptorCallerRespondContinue,
            LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new RequestInterceptorCallerRespondContinue(), new LastRequestInterceptor()];
    }

    resource function 'default .() returns string {
        lock {
            message1 = "Hello from main service";
        }
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorCallerRespondContinue() returns error? {
    http:Response res = check requestInterceptorCallerRespondContinueClientEP->get("/");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-caller-respond");
    common:assertTextPayload(check res.getTextPayload(), "Response from caller inside interceptor");
    runtime:sleep(5);
    lock {
        test:assertEquals(message1, "Hello from main service");
    }
}

final http:Client responseInterceptorCallerRespondContinueClientEP = check new("http://localhost:" + responseInterceptorCallerRespondContinueTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener responseInterceptorCallerRespondContinueServerEP = new(responseInterceptorCallerRespondContinueTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on responseInterceptorCallerRespondContinueServerEP {

    public function createInterceptors() returns [LastResponseInterceptor,  ResponseInterceptorCallerRespondContinue,
            DefaultResponseInterceptor] {
        return [new LastResponseInterceptor(), new ResponseInterceptorCallerRespondContinue(), new DefaultResponseInterceptor()];
    }

    resource function 'default test() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testResponseInterceptorCallerRespondContinue() returns error? {
    http:Response res = check responseInterceptorCallerRespondContinueClientEP->get("/test");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "default-response-interceptor");
    common:assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-response-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("response-interceptor-caller-respond-continue"), "true");
    common:assertTextPayload(check res.getTextPayload(), "Response from caller inside response interceptor");
}

final http:Client requestInterceptorCtxNextClientEP = check new("http://localhost:" + requestInterceptorCtxNextTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorCtxNextServerEP = new(requestInterceptorCtxNextTestPort, httpVersion = http:HTTP_1_1);

isolated string message2 = "Greetings from client2";

service http:InterceptableService / on requestInterceptorCtxNextServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, RequestInterceptorCtxNext, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new RequestInterceptorCtxNext(), new LastRequestInterceptor()];
    }

    resource function 'default .() returns string {
        lock{
            message2 = "Hello from main service";
        }
        return "Response from resource - test";
    }
}

@test:Config {}
function testRequestInterceptorCtxNext() returns error? {
    http:Response res = check requestInterceptorCtxNextClientEP->get("/");
    test:assertEquals(res.statusCode, 202);
    runtime:sleep(5);
    lock{
        test:assertEquals(message2, "Hello from main service");
    }
}

final http:Client requestInterceptorStringPayloadBindingClientEP = check new("http://localhost:" + requestInterceptorStringPayloadBindingTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorStringPayloadBindingServerEP = new(requestInterceptorStringPayloadBindingTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on requestInterceptorStringPayloadBindingServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, StringPayloadBindingRequestInterceptor,
            LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new StringPayloadBindingRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function 'default .(http:RequestContext ctx, @http:Payload string payload, http:Caller caller) returns error? {
        http:Response res = new();
        res.setTextPayload(payload);
        string|error val = ctx.get("request-payload").ensureType(string);
        if val is string {
            res.setHeader("request-payload", val);
        }
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorStringPayloadBinding() returns error? {
    http:Response res = check requestInterceptorStringPayloadBindingClientEP->post("/", "request from client");
    common:assertTextPayload(check res.getTextPayload(), "request from client");
    common:assertHeaderValue(check res.getHeader("request-payload"), "request from client");
}

final http:Client requestInterceptorRecordPayloadBindingClientEP = check new("http://localhost:" + requestInterceptorRecordPayloadBindingTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorRecordPayloadBindingServerEP = new(requestInterceptorRecordPayloadBindingTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on requestInterceptorRecordPayloadBindingServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, RecordPayloadBindingRequestInterceptor,
            LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new RecordPayloadBindingRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function 'default .(http:RequestContext ctx, @http:Payload Person person, http:Caller caller) returns error? {
        http:Response res = new();
        res.setJsonPayload(person);
        Person|error val = ctx.get("request-payload").ensureType(Person);
        if val is Person {
            res.setHeader("request-payload", val.toJsonString());
        }
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorRecordPayloadBinding() returns error? {
    json person = {name:"wso2",age:12};
    http:Response res = check requestInterceptorRecordPayloadBindingClientEP->post("/", person);
    common:assertJsonPayload(check res.getJsonPayload(), person);
    common:assertHeaderValue(check res.getHeader("request-payload"), person.toJsonString());
}

final http:Client requestInterceptorRecordArrayPayloadBindingClientEP = check new("http://localhost:" + requestInterceptorRecordArrayPayloadBindingTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorRecordArrayPayloadBindingServerEP = new(requestInterceptorRecordArrayPayloadBindingTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on requestInterceptorRecordArrayPayloadBindingServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, RecordArrayPayloadBindingRequestInterceptor,
            LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new RecordArrayPayloadBindingRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function 'default .(http:RequestContext ctx, @http:Payload Person[] persons, http:Caller caller) returns error? {
        http:Response res = new();
        res.setJsonPayload(persons);
        string|error val = ctx.get("request-payload").ensureType(string);
        if val is string {
            res.setHeader("request-payload", val);
        }
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorRecordArrayPayloadBinding() returns error? {
    json persons = [{name:"wso2",age:12}, {name:"ballerina",age:3}];
    http:Response res = check requestInterceptorRecordArrayPayloadBindingClientEP->post("/", persons);
    common:assertJsonPayload(check res.getJsonPayload(), persons);
    common:assertHeaderValue(check res.getHeader("request-payload"), persons.toJsonString());
}

final http:Client requestInterceptorByteArrayPayloadBindingClientEP = check new("http://localhost:" + requestInterceptorByteArrayPayloadBindingTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorByteArrayPayloadBindingServerEP = new(requestInterceptorByteArrayPayloadBindingTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on requestInterceptorByteArrayPayloadBindingServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, ByteArrayPayloadBindingRequestInterceptor,
            LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new ByteArrayPayloadBindingRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function 'default .(http:RequestContext ctx, @http:Payload byte[] person, http:Caller caller) returns error? {
        http:Response res = new();
        res.setTextPayload(check strings:fromBytes(person));
        string|error val = ctx.get("request-payload").ensureType(string);
        if val is string {
            res.setHeader("request-payload", val);
        }
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorByteArrayPayloadBinding() returns error? {
    http:Request req = new();
    string person = "person";
    req.setBinaryPayload(person.toBytes());
    http:Response res = check requestInterceptorByteArrayPayloadBindingClientEP->post("/", req);
    common:assertJsonPayload(check res.getBinaryPayload(), person.toBytes());
    common:assertHeaderValue(check res.getHeader("request-payload"), person);
}

final http:Client requestInterceptorWithQueryParamClientEP = check new("http://localhost:" + requestInterceptorWithQueryParamTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener requestInterceptorWithQueryParamServerEP = new(requestInterceptorWithQueryParamTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on requestInterceptorWithQueryParamServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, RequestInterceptorWithQueryParam,
            LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new RequestInterceptorWithQueryParam(), new LastRequestInterceptor()];
    }

    resource function 'default get(string q1, int q2, http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("q1", check req.getHeader("q1"));
        res.setHeader("request-interceptor-query-param", check req.getHeader("request-interceptor-query-param"));
        res.setHeader("q2", check req.getHeader("q2"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorWithQueryParam() returns error? {
    http:Response res = check requestInterceptorWithQueryParamClientEP->get("/get?q1=val&q2=6");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-query-param");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("request-interceptor-query-param"), "true");
    common:assertHeaderValue(check res.getHeader("q1"), "val");
    common:assertHeaderValue(check res.getHeader("q2"), "6");
}

final http:Client interceptorReturnsStatusClientEP = check new("http://localhost:" + interceptorReturnsStatusTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener interceptorReturnsStatusServerEP = check new(interceptorReturnsStatusTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService /request on interceptorReturnsStatusServerEP {

    public function createInterceptors() returns [RequestInterceptorReturnsStatusCodeResponse] {
        return [new RequestInterceptorReturnsStatusCodeResponse()];
    }

    resource function get .() returns string {
        return "Response from main resource";
    }
}

service http:InterceptableService /response on interceptorReturnsStatusServerEP {

    public function createInterceptors() returns [ResponseInterceptorReturnsStatusCodeResponse] {
        return [new ResponseInterceptorReturnsStatusCodeResponse()];
    }

    resource function get .(string? header) returns http:Response {
        http:Response res = new;
        if header is string {
            res.setHeader("header", "true");
        }
        return res;
    }
}

@test:Config{}
function testRequestInterceptorReturnsStatus() returns error? {
    http:Response res = check interceptorReturnsStatusClientEP->get("/request");
    test:assertEquals(res.statusCode, 404);
    common:assertTextPayload(res.getTextPayload(), "Header not found in request");

    res = check interceptorReturnsStatusClientEP->get("/request", {"header" : "true"});
    test:assertEquals(res.statusCode, 200);
    common:assertTextPayload(res.getTextPayload(), "Response from Request Interceptor");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-returns-status");
}

@test:Config{}
function testResponseInterceptorReturnsStatus() returns error? {
    http:Response res = check interceptorReturnsStatusClientEP->get("/response");
    test:assertEquals(res.statusCode, 404);
    common:assertTextPayload(res.getTextPayload(), "Header not found in response");

    res = check interceptorReturnsStatusClientEP->get("/response?header=true");
    test:assertEquals(res.statusCode, 200);
    common:assertTextPayload(res.getTextPayload(), "Response from Response Interceptor");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "response-interceptor-returns-status");
}

final http:Client interceptorExecutionOrderClientEP = check new("http://localhost:" + interceptorExecutionOrderTestPort.toString(), httpVersion = http:HTTP_1_1);

listener http:Listener interceptorExecutionOrderServerEP = check new(interceptorExecutionOrderTestPort, httpVersion = http:HTTP_1_1);

service http:InterceptableService / on interceptorExecutionOrderServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, LastResponseInterceptor, RequestInterceptorCheckHeader,
            ResponseInterceptorWithVariable, RequestInterceptorWithVariable] {
        return [new DefaultRequestInterceptor(), new LastResponseInterceptor(), new RequestInterceptorCheckHeader("listener-header"),
                    new ResponseInterceptorWithVariable("listener-response"), new RequestInterceptorWithVariable("listener-request")];
    }

    resource function get .(http:Request req) returns http:Response|error {
        http:Response res = new;
        foreach string reqHeader in req.getHeaderNames() {
            res.setHeader(reqHeader, check req.getHeader(reqHeader));
        }
        res.setTextPayload("Response from main resource");
        return res;
    }
}

service http:InterceptableService /test on interceptorExecutionOrderServerEP {

    public function createInterceptors() returns [DefaultRequestInterceptor, LastResponseInterceptor, RequestInterceptorCheckHeader,
                ResponseInterceptorWithVariable, RequestInterceptorWithVariable, ResponseInterceptorWithVariable,
                RequestInterceptorCheckHeader, RequestInterceptorWithVariable, LastRequestInterceptor, DefaultResponseInterceptor] {
        return [new DefaultRequestInterceptor(), new LastResponseInterceptor(), new RequestInterceptorCheckHeader("listener-header"),
                new ResponseInterceptorWithVariable("listener-response"), new RequestInterceptorWithVariable("listener-request"),
                new ResponseInterceptorWithVariable("service-response"), new RequestInterceptorCheckHeader("service-header"),
                new RequestInterceptorWithVariable("service-request"), new LastRequestInterceptor(), new DefaultResponseInterceptor()];
    }

    resource function get .(http:Request req) returns http:Response|error {
        http:Response res = new;
        foreach string reqHeader in req.getHeaderNames() {
            res.setHeader(reqHeader, check req.getHeader(reqHeader));
        }
        res.setTextPayload("Response from main resource");
        return res;
    }
}

@test:Config{}
function testInterceptorExecutionOrder() returns error? {
    http:Response res = check interceptorExecutionOrderClientEP->get("/");
    test:assertEquals(res.statusCode, 404);
    common:assertTextPayload(res.getTextPayload(), "Header : listener-header not found");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-check-header");
    test:assertFalse(res.hasHeader("listener-request"));
    test:assertFalse(res.hasHeader("listener-response"));

    res = check interceptorExecutionOrderClientEP->get("/", {"listener-header" : "true"});
    test:assertEquals(res.statusCode, 200);
    common:assertTextPayload(res.getTextPayload(), "Response from main resource");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "listener-response");
    common:assertHeaderValue(check res.getHeader("listener-response"), "true");
    common:assertHeaderValue(check res.getHeader("listener-request"), "true");

    res = check interceptorExecutionOrderClientEP->get("/test");
    test:assertEquals(res.statusCode, 404);
    common:assertTextPayload(res.getTextPayload(), "Header : listener-header not found");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-check-header");
    test:assertFalse(res.hasHeader("listener-request"));
    test:assertFalse(res.hasHeader("listener-response"));
    test:assertFalse(res.hasHeader("service-response"));
    test:assertFalse(res.hasHeader("service-request"));
    test:assertFalse(res.hasHeader("last-request-interceptor"));
    test:assertFalse(res.hasHeader("default-response-interceptor"));

    res = check interceptorExecutionOrderClientEP->get("/test", {"listener-header" : "true"});
    test:assertEquals(res.statusCode, 404);
    common:assertTextPayload(res.getTextPayload(), "Header : service-header not found");
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "listener-response");
    common:assertHeaderValue(check res.getHeader("service-response"), "true");
    common:assertHeaderValue(check res.getHeader("listener-response"), "true");
    common:assertHeaderValue(check res.getHeader("listener-request"), "true");
    test:assertFalse(res.hasHeader("service-request"));
    test:assertFalse(res.hasHeader("last-request-interceptor"));
    test:assertFalse(res.hasHeader("default-response-interceptor"));

    res = check interceptorExecutionOrderClientEP->get("/test", {"listener-header" : "true", "service-header" : "true"});
    test:assertEquals(res.statusCode, 200);
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "listener-response");
    common:assertHeaderValue(check res.getHeader("service-response"), "true");
    common:assertHeaderValue(check res.getHeader("listener-response"), "true");
    common:assertHeaderValue(check res.getHeader("listener-request"), "true");
    common:assertHeaderValue(check res.getHeader("service-request"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("default-response-interceptor"), "true");
}

final http:Client interceptorBackendClientEP = check new ("http://localhost:" + interceptorBackendTestPort.toString());
final http:Client interceptorPassthroughClientEP = check new ("http://localhost:" + interceptorPassthroughTestPort.toString());

listener http:Listener interceptorPassthroughServer = check new (interceptorPassthroughTestPort);
listener http:Listener interceptorBackendServer = check new (interceptorBackendTestPort);

service http:InterceptableService /foo on interceptorPassthroughServer {

    public function createInterceptors() returns [RequestInterceptorConsumePayload] {
        return [new RequestInterceptorConsumePayload()];
    }

    resource function post bar(http:Request req, boolean consumePayload) returns json|error {
        if consumePayload {
            json _ = check req.getJsonPayload();
        }
        json res = check interceptorBackendClientEP->forward("/foo/bar", req);
        return { body: res };
    }

    resource function post baz(http:Request req, boolean consumePayload) returns json|error {
        if consumePayload {
            json _ = check req.getJsonPayload();
        }
        json res = check interceptorBackendClientEP->execute(http:POST, "/foo/bar", req);
        return { body: res };
    }
}


service /foo on interceptorBackendServer {

    resource function post bar(@http:Payload json payload) returns json {
        return { echo: payload };
    }
}

function dualBooleanStringValues() returns string[][] {
    return [
        ["true", "true"],
        ["true", "false"],
        ["false", "true"],
        ["false", "false"]
    ];
}

@test:Config{
    dataProvider: dualBooleanStringValues
}
function testInterceptorPassthroughForward(string consumePayload, string consumePayloadInInterceptor) returns error? {
    string path = "/foo/bar?consumePayload=" + consumePayload + "&consumePayloadInInterceptor=" + consumePayloadInInterceptor;
    json payload = check interceptorPassthroughClientEP->post(path, { id: 1010, name: "John" });
    json expectedPayload = { body: { echo: { id: 1010, name: "John" } } };
    test:assertEquals(payload, expectedPayload);
}

@test:Config{
    dataProvider: dualBooleanStringValues
}
function testInterceptorPassthroughExecute(string consumePayload, string consumePayloadInInterceptor) returns error? {
    string path = "/foo/baz?consumePayload=" + consumePayload + "&consumePayloadInInterceptor=" + consumePayloadInInterceptor;
    json payload = check interceptorPassthroughClientEP->post(path, { id: 1010, name: "John" });
    json expectedPayload = { body: { echo: { id: 1010, name: "John" } } };
    test:assertEquals(payload, expectedPayload);
}

final http:Client interceptorUserAgentClientEP = check new("http://localhost:" + interceptorUserAgentTestPort.toString(), httpVersion = http:HTTP_1_1);

service http:InterceptableService on new http:Listener(interceptorUserAgentTestPort) {

    public function createInterceptors() returns [DefaultRequestInterceptor, RequestInterceptorUserAgentField, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new RequestInterceptorUserAgentField(), new LastRequestInterceptor()];
    }

    resource function get test(http:Request req, http:Caller caller) returns error? {
        http:Response res = new();
        res.setHeader("default-request-interceptor", check req.getHeader("default-request-interceptor"));
        res.setHeader("req-interceptor-user-agent", check req.getHeader("req-interceptor-user-agent"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("req-user-agent", req.userAgent);
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testUserAgentHeaderWithInterceptors() returns error? {
    http:Response res = check interceptorUserAgentClientEP->get("/test", {"user-agent": "httpTest/1.0"});
    common:assertHeaderValue(check res.getHeader("last-interceptor"), "user-agent-interceptor");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("req-interceptor-user-agent"), "httpTest/1.0");
    common:assertHeaderValue(check res.getHeader("req-user-agent"), "httpTest/1.0");
}

final http:Client interceptorReqInRespPathClientEP = check new("http://localhost:" + interceptorReqInRespPathTestPort.toString(), httpVersion = http:HTTP_1_1);

service http:InterceptableService on new http:Listener(interceptorReqInRespPathTestPort) {

    public function createInterceptors() returns [ResponseErrorInterceptorWithReq, ResponseInterceptorWithReq,
                                                                    DefaultRequestInterceptor, LastRequestInterceptor] {
        return [new ResponseErrorInterceptorWithReq(), new ResponseInterceptorWithReq(),
                        new DefaultRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function 'default [string... path](boolean err = false) returns string|error {
        return err ? error("Error!") : "Hello, World!";
    }
}

@test:Config{}
function testReqInResponseInterceptor() returns error? {
    http:Response res = check interceptorReqInRespPathClientEP->/test.post("Hi!");
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("response-interceptor-with-req"), "true");
    common:assertHeaderValue(check res.getHeader("request-payload"), "Hi!");

    res = check interceptorReqInRespPathClientEP->/test;
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("response-interceptor-with-req"), "true");
    common:assertHeaderValue(check res.getHeader("request-payload"), "No content");
}

@test:Config{}
function testReqInResponseErrorInterceptor() returns error? {
    http:Response res = check interceptorReqInRespPathClientEP->/test.post("Hi!", err = true);
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("response-error-interceptor-with-req"), "true");
    common:assertHeaderValue(check res.getHeader("request-payload"), "Hi!");

    res = check interceptorReqInRespPathClientEP->/test(err = true);
    common:assertHeaderValue(check res.getHeader("default-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    common:assertHeaderValue(check res.getHeader("response-error-interceptor-with-req"), "true");
    common:assertHeaderValue(check res.getHeader("request-payload"), "No content");
}
