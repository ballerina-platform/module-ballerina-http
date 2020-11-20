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

import ballerina/test;
import ballerina/http;

// Test case for bearer auth header interceptor canProcess method, without bearer auth header
@test:Config {}
function testCanProcessHttpBearerAuthWithoutHeader() {
    CustomAuthProvider customAuthProvider = new;
    http:BearerAuthHandler handler = new(customAuthProvider);
    http:Request inRequest = createRequest();
    string bearerAuthHeaderValue = "123Bearer xxxxxx";
    inRequest.setHeader("123Authorization", bearerAuthHeaderValue);
    test:assertFalse(handler.canProcess(inRequest));
}

// Test case for bearer auth header interceptor canProcess method
@test:Config {}
function testCanProcessHttpBearerAuth() {
    CustomAuthProvider customAuthProvider = new;
    http:BearerAuthHandler handler = new(customAuthProvider);
    http:Request inRequest = createRequest();
    string bearerAuthHeaderValue = "Bearer xxxxxx";
    inRequest.setHeader("Authorization", bearerAuthHeaderValue);
    test:assertTrue(handler.canProcess(inRequest));
}

// Test case for bearer auth header interceptor authentication failure
@test:Config {}
function testHandleHttpBearerAuthFailure() {
    CustomAuthProvider customAuthProvider = new;
    http:BearerAuthHandler handler = new(customAuthProvider);
    http:Request inRequest = createRequest();
    string bearerAuthHeaderValue = "Bearer YW1pbGE6cHFy";
    inRequest.setHeader("Authorization", bearerAuthHeaderValue);
    boolean|http:AuthenticationError result = handler.process(inRequest);
    if (result is boolean) {
        test:assertFalse(result);
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}

// Test case for bearer auth header interceptor authentication success
@test:Config {}
function testHandleHttpBearerAuth() {
    CustomAuthProvider customAuthProvider = new;
    http:BearerAuthHandler handler = new(customAuthProvider);
    http:Request inRequest = createRequest();
    string bearerAuthHeaderValue = "Bearer aXN1cnU6eHh4";
    inRequest.setHeader("Authorization", bearerAuthHeaderValue);
    boolean|http:AuthenticationError result = handler.process(inRequest);
    if (result is boolean) {
        test:assertTrue(result);
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}
