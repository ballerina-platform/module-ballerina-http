// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/auth;
import ballerina/test;
import ballerina/http;

// Test case for basic auth header interceptor canProcess method, without the basic auth header
@test:Config {}
function testCanProcessHttpBasicAuthWithoutHeader() {
    CustomAuthProvider customAuthProvider = new;
    http:BasicAuthHandler handler = new(customAuthProvider);
    http:Request inRequest = createRequest();
    string basicAuthHeaderValue = "123Basic xxxxxx";
    inRequest.setHeader("123Authorization", basicAuthHeaderValue);
    test:assertFalse(handler.canProcess(inRequest));
}
// Test case for basic auth header interceptor canProcess method
@test:Config {}
function testCanProcessHttpBasicAuth() {
    CustomAuthProvider customAuthProvider = new;
    http:BasicAuthHandler handler = new(customAuthProvider);
    http:Request inRequest = createRequest();
    string basicAuthHeaderValue = "Basic xxxxxx";
    inRequest.setHeader("Authorization", basicAuthHeaderValue);
    test:assertTrue(handler.canProcess(inRequest));
}

// Test case for basic auth header interceptor authentication failure
@test:Config {}
function testHandleHttpBasicAuthFailure() {
    CustomAuthProvider customAuthProvider = new;
    http:BasicAuthHandler handler = new(customAuthProvider);
    http:Request inRequest = createRequest();
    string basicAuthHeaderValue = "Basic YW1pbGE6cHFy";
    inRequest.setHeader("Authorization", basicAuthHeaderValue);
    boolean|http:AuthenticationError result = handler.process(inRequest);
    if (result is boolean) {
        test:assertFalse(result);
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}

// Test case for basic auth header interceptor authentication success
@test:Config {}
function testHandleHttpBasicAuth() {
    CustomAuthProvider customAuthProvider = new;
    http:BasicAuthHandler handler = new(customAuthProvider);
    http:Request inRequest = createRequest();
    string basicAuthHeaderValue = "Basic aXN1cnU6eHh4";
    inRequest.setHeader("Authorization", basicAuthHeaderValue);
    boolean|http:AuthenticationError result = handler.process(inRequest);
    if (result is boolean) {
        test:assertTrue(result);
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}

function createRequest() returns http:Request {
    http:Request inRequest = new;
    inRequest.rawPath = "/helloWorld/sayHello";
    inRequest.method = "GET";
    inRequest.httpVersion = "1.1";
    return inRequest;
}

public class CustomAuthProvider {

    *auth:InboundAuthProvider;

    public isolated function authenticate(string credential) returns boolean|auth:Error {
        return credential == "aXN1cnU6eHh4";
    }
}
