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

final http:Client requestInterceptorWithCallerRespondClientEP = check new("http://localhost:" + requestInterceptorWithCallerRespondTestPort.toString());

listener http:Listener requestInterceptorWithCallerRespondServerEP = new(requestInterceptorWithCallerRespondTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorCallerRespond(), new LastRequestInterceptor()]
});

service http:Service / on requestInterceptorWithCallerRespondServerEP {

    resource function 'default test() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorWithCallerRespond() returns error? {
    http:Response res = check requestInterceptorWithCallerRespondClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-caller-respond");
    assertTextPayload(check res.getTextPayload(), "Response from caller inside interceptor");
}

final http:Client requestInterceptorDataBindingClientEP1 = check new("http://localhost:" + requestInterceptorDataBindingTestPort1.toString());

listener http:Listener requestInterceptorDataBindingServerEP1 = new(requestInterceptorDataBindingTestPort1, config = {
    interceptors : [new DefaultRequestInterceptor(), new DataBindingRequestInterceptor(), new LastRequestInterceptor()]
});

service http:Service / on requestInterceptorDataBindingServerEP1 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-interceptor", check req.getHeader("default-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

final http:Client requestInterceptorDataBindingClientEP2 = check new("http://localhost:" + requestInterceptorDataBindingTestPort2.toString());

listener http:Listener requestInterceptorDataBindingServerEP2 = new(requestInterceptorDataBindingTestPort2, config = {
    interceptors : [new DataBindingRequestInterceptor(), new LastRequestInterceptor()]
});

service http:Service / on requestInterceptorDataBindingServerEP2 {

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
    assertTextPayload(check res.getTextPayload(), "Request from requestInterceptorDataBindingClient");
    assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check requestInterceptorDataBindingClientEP2->post("/", req);
    assertTextPayload(check res.getTextPayload(), "Request from requestInterceptorDataBindingClient");
    assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
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
    assertTextPayload(check res.getTextPayload(), payload);
    assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check requestInterceptorDataBindingClientEP2->post("/", req);
    assertTextPayload(check res.getTextPayload(), payload);
    assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

final http:Client requestInterceptorWithoutCtxNextClientEP = check new("http://localhost:" + requestInterceptorWithoutCtxNextTestPort.toString());

listener http:Listener requestInterceptorWithoutCtxNextServerEP = new(requestInterceptorWithoutCtxNextTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorWithoutCtxNext(), new LastRequestInterceptor()]
});

service http:Service / on requestInterceptorWithoutCtxNextServerEP {

    resource function 'default .() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorWithoutCtxNext() returns error? {
    http:Response res = check requestInterceptorWithoutCtxNextClientEP->get("/");
    test:assertEquals(res.statusCode, 202);
}

final http:Client requestInterceptorSkipClientEP = check new("http://localhost:" + requestInterceptorSkipTestPort.toString());

listener http:Listener requestInterceptorSkipServerEP = new(requestInterceptorSkipTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorSkip(), new RequestInterceptorWithoutCtxNext(), new LastRequestInterceptor()]
});

service http:Service / on requestInterceptorSkipServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-interceptor", check req.getHeader("default-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorSkip() returns error? {
    http:Response res = check requestInterceptorSkipClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "skip-interceptor");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

final http:Client requestInterceptorCallerRespondContinueClientEP = check new("http://localhost:" + requestInterceptorCallerRespondContinueTestPort.toString());

listener http:Listener requestInterceptorCallerRespondContinueServerEP = new(requestInterceptorCallerRespondContinueTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorCallerRespondContinue(), new LastRequestInterceptor()]
});

string message = "Greetings from client";

service http:Service / on requestInterceptorCallerRespondContinueServerEP {

    resource function 'default .() returns string {
        message = "Hello from main service";
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorCallerRespondContinue() returns error? {
    http:Response res = check requestInterceptorCallerRespondContinueClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-caller-respond");
    assertTextPayload(check res.getTextPayload(), "Response from caller inside interceptor");
    runtime:sleep(5);
    test:assertEquals(message, "Hello from main service");
}

final http:Client requestInterceptorStringPayloadBindingClientEP = check new("http://localhost:" + requestInterceptorStringPayloadBindingTestPort.toString());

listener http:Listener requestInterceptorStringPayloadBindingServerEP = new(requestInterceptorStringPayloadBindingTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new StringPayloadBindingRequestInterceptor(), new LastRequestInterceptor()]
});

service http:Service / on requestInterceptorStringPayloadBindingServerEP {

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
    assertTextPayload(check res.getTextPayload(), "request from client");
    assertHeaderValue(check res.getHeader("request-payload"), "request from client");
}

final http:Client requestInterceptorRecordPayloadBindingClientEP = check new("http://localhost:" + requestInterceptorRecordPayloadBindingTestPort.toString());

listener http:Listener requestInterceptorRecordPayloadBindingServerEP = new(requestInterceptorRecordPayloadBindingTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new RecordPayloadBindingRequestInterceptor(), new LastRequestInterceptor()]
});

service http:Service / on requestInterceptorRecordPayloadBindingServerEP {

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
    assertJsonPayload(check res.getJsonPayload(), person);
    assertHeaderValue(check res.getHeader("request-payload"), person.toJsonString());
}

final http:Client requestInterceptorRecordArrayPayloadBindingClientEP = check new("http://localhost:" + requestInterceptorRecordArrayPayloadBindingTestPort.toString());

listener http:Listener requestInterceptorRecordArrayPayloadBindingServerEP = new(requestInterceptorRecordArrayPayloadBindingTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new RecordArrayPayloadBindingRequestInterceptor(), new LastRequestInterceptor()]
});

service http:Service / on requestInterceptorRecordArrayPayloadBindingServerEP {

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
    assertJsonPayload(check res.getJsonPayload(), persons);
    assertHeaderValue(check res.getHeader("request-payload"), persons.toJsonString());
}

final http:Client requestInterceptorByteArrayPayloadBindingClientEP = check new("http://localhost:" + requestInterceptorByteArrayPayloadBindingTestPort.toString());

listener http:Listener requestInterceptorByteArrayPayloadBindingServerEP = new(requestInterceptorByteArrayPayloadBindingTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new ByteArrayPayloadBindingRequestInterceptor(), new LastRequestInterceptor()]
});

service http:Service / on requestInterceptorByteArrayPayloadBindingServerEP {

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
    assertJsonPayload(check res.getBinaryPayload(), person.toBytes());
    assertHeaderValue(check res.getHeader("request-payload"), person);
}

final http:Client requestInterceptorWithQueryParamClientEP = check new("http://localhost:" + requestInterceptorWithQueryParamTestPort.toString());

listener http:Listener requestInterceptorWithQueryParamServerEP = new(requestInterceptorWithQueryParamTestPort, config = {
    interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorWithQueryParam(), new LastRequestInterceptor()]
});

service http:Service / on requestInterceptorWithQueryParamServerEP {

    resource function 'default get(string q1, int q2, http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-interceptor", check req.getHeader("default-interceptor"));
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
    assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-query-param");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-query-param"), "true");
    assertHeaderValue(check res.getHeader("q1"), "val");
    assertHeaderValue(check res.getHeader("q2"), "6");
}
