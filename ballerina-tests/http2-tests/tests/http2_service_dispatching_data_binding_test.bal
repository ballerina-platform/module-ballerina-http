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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/test;
import ballerina/http_test_common as common;

final http:Client http2DataBindingClient = check new("http://localhost:" + http2GeneralPort.toString());

http:ClientConfiguration http2SslClientConf1 = {
    secureSocket: {
        cert: {
            path: common:TRUSTSTORE_PATH,
            password: "ballerina"
        }
    }
};

final http:Client http2SslDataBindingClient = check new("https://localhost:" + http2SslGeneralPort.toString(), http2SslClientConf1);

service /databinding on generalHTTP2Listener {

    resource function post person(@http:Payload Person person) returns json {
        return { 'key: person.name, age: person.age };
    }
}

service /databinding on generalHTTPS2Listener {

    resource function post person(@http:Payload Person person) returns json {
        return { 'key: person.name, age: person.age };
    }
}

@test:Config {}
function testHTTP2DataBinding() returns error? {
    http:Request req = new;
    req.setJsonPayload({name:"wso2",age:12});
    json payload = check http2DataBindingClient->post("/databinding/person", req);
    test:assertEquals(payload, {'key:"wso2",age:12});
}

@test:Config {}
function testHTTPS2DataBinding() returns error? {
    http:Request req = new;
    req.setJsonPayload({name:"wso2",age:12});
    json payload = check http2SslDataBindingClient->post("/databinding/person", req);
    test:assertEquals(payload, {'key:"wso2",age:12});
}

service http:InterceptableService /interceptor1 on generalHTTP2Listener {

    public function createInterceptors() returns [DefaultRequestInterceptor, DataBindingRequestInterceptor, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new DataBindingRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function post databinding(@http:Payload string payload) returns string {
        return "Response : " + payload;
    }
}

service http:InterceptableService /interceptor2 on generalHTTP2Listener {

    public function createInterceptors() returns [DefaultRequestInterceptor, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function post databinding(@http:Payload string payload) returns string {
        return "Response : " + payload;
    }
}

service http:InterceptableService /interceptor1 on generalHTTPS2Listener {

    public function createInterceptors() returns [DefaultRequestInterceptor, DataBindingRequestInterceptor, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new DataBindingRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function post databinding(@http:Payload string payload) returns string {
        return "Response : " + payload;
    } 
}

service http:InterceptableService /interceptor2 on generalHTTPS2Listener {

    public function createInterceptors() returns [DefaultRequestInterceptor, LastRequestInterceptor] {
        return [new DefaultRequestInterceptor(), new LastRequestInterceptor()];
    }

    resource function post databinding(@http:Payload string payload) returns string {
        return "Response : " + payload;
    }
}

@test:Config {}
function testHTTP2DataBindingWithInterceptor1() returns error? {
    http:Request req = new;
    req.setTextPayload("Hello World!");
    req.setHeader("interceptor", "databinding-interceptor");
    string payload = check http2DataBindingClient->post("/interceptor1/databinding", req);
    test:assertEquals(payload, "Response : Hello World!");
}

@test:Config {}
function testHTTP2DataBindingWithInterceptor2() returns error? {
    http:Request req = new;
    req.setTextPayload("Hello World!");
    req.setHeader("interceptor", "databinding-interceptor");
    string payload = check http2DataBindingClient->post("/interceptor2/databinding", req);
    test:assertEquals(payload, "Response : Hello World!");
}

@test:Config {}
function testHTTPS2DataBindingWithInterceptor1() returns error? {
    http:Request req = new;
    req.setTextPayload("Hello World!");
    req.setHeader("interceptor", "databinding-interceptor");
    string payload = check http2SslDataBindingClient->post("/interceptor1/databinding", req);
    test:assertEquals(payload, "Response : Hello World!");
}

@test:Config {}
function testHTTPS2DataBindingWithInterceptor2() returns error? {
    http:Request req = new;
    req.setTextPayload("Hello World!");
    req.setHeader("interceptor", "databinding-interceptor");
    string payload = check http2SslDataBindingClient->post("/interceptor2/databinding", req);
    test:assertEquals(payload, "Response : Hello World!");
}
