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

@test:Config {}
function testPushPromiseAddHeader() {
    string key = "header1";
    string value = "value1";
    http:PushPromise promise = new;
    promise.addHeader(key, value);
    test:assertEquals(promise.getHeader(key), value, msg = "Found unexpected output");
}

@test:Config {}
function testPushPromiseGetHeader() {
    string key = "header1";
    string value = "value1";
    http:PushPromise promise = new;
    promise.addHeader(key, value);
    test:assertEquals(promise.getHeader(key), value, msg = "Found unexpected output");
}

@test:Config {}
function testPushPromiseHasHeader() {
    string headerName = "header1";
    string headerValue = "value1";

    http:PushPromise promise = new;
    promise.addHeader(headerName, headerValue);
    
    test:assertTrue(promise.hasHeader(headerName), msg = "Found unexpected output");
}

@test:Config {}
function testPushPromiseGetHeaderNames() {
    string headerName1 = "header1";
    string headerName2 = "header2";

    http:PushPromise promise = new;
    promise.addHeader(headerName1, "value1");
    promise.addHeader(headerName2, "value2");
    string[] values = promise.getHeaderNames();

    test:assertEquals(values[0], headerName1, msg = "Found unexpected output");
    test:assertEquals(values[1], headerName2, msg = "Found unexpected output");
}

@test:Config {}
function testPushPromiseGetHeaders() {
    string headerName = "header";
    string headerValue1 = "value1";
    string headerValue2 = "value2";

    http:PushPromise promise = new;
    promise.addHeader(headerName, headerValue1);
    promise.addHeader(headerName, headerValue2);
    string[] values = promise.getHeaders(headerName);

    test:assertEquals(values[0], headerValue1, msg = "Found unexpected output");
    test:assertEquals(values[1], headerValue2, msg = "Found unexpected output");
}

@test:Config {}
function testPushPromiseRemoveHeader() {
    string headerName = "header1";
    string headerValue = "value1";

    http:PushPromise promise = new;
    promise.addHeader(headerName, headerValue);    
    
    promise.removeHeader(headerName);
    test:assertFalse(promise.hasHeader(headerName), msg = "Found unexpected output");
}

@test:Config {}
function testPushPromiseRemoveAllHeaders() {
    http:PushPromise promise = new;
    string header1Name = "header1";
    string header1Value = "value1";
    promise.addHeader(header1Name, header1Value);
    string header2Name = "header2";
    string header2Value = "value2";
    promise.addHeader(header2Name, header2Value);
    
    promise.removeAllHeaders();
    test:assertFalse(promise.hasHeader(header1Name), msg = "Found unexpected output");
    test:assertFalse(promise.hasHeader(header2Name), msg = "Found unexpected output");
}

@test:Config {}
function testPushPromiseSetHeader() {
    http:PushPromise promise = new;
    string headerName = "header1";
    string headerValue = "value1";
    promise.addHeader(headerName, headerValue);
    
    string headerValue2 = "value2";
    promise.setHeader(headerName, headerValue2);
    test:assertEquals(promise.getHeader(headerName), headerValue2, msg = "Found unexpected output");
}
