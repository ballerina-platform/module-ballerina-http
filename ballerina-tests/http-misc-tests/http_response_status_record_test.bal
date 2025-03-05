// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

@test:Config
function testGetStatusRecWithSuccessRes() returns error? {
    http:Response res = new;
    res.statusCode = 200;
    res.setTextPayload("Hello, World!");
    res.setHeader("Server", "Ballerina");
    res.setHeader("Header-1", "Value-1");
    res.setHeader("Header-2", "Value-2");

    http:StatusCodeRecord statusRec = check res.getStatusCodeRecord();
    test:assertEquals(statusRec.status, 200, msg = "Status code mismatched");
    test:assertEquals(statusRec.headers, {
                                             "content-type": "text/plain",
                                             "Server": "Ballerina",
                                             "Header-1": "Value-1",
                                             "Header-2": "Value-2"
                                         }, msg = "Headers mismatched");
    test:assertEquals(statusRec?.body, "Hello, World!", msg = "Payload mismatched");
}

@test:Config
function testGetStatusRecWithNoContent() returns error? {
    http:Response res = new;
    res.statusCode = 204;
    res.setHeader("Server", "Ballerina");
    res.setHeader("Header-1", "Value-1");
    res.setHeader("Header-2", "Value-2");

    http:StatusCodeRecord statusRec = check res.getStatusCodeRecord();
    test:assertEquals(statusRec.status, 204, msg = "Status code mismatched");
    test:assertEquals(statusRec.headers, {
                                             "Server": "Ballerina",
                                             "Header-1": "Value-1",
                                             "Header-2": "Value-2"
                                         }, msg = "Headers mismatched");
    test:assertEquals(statusRec?.body, (), msg = "Payload mismatched");
}

@test:Config
function testGetStatusRecWithNoContentAndNoHeaders() returns error? {
    http:Response res = new;
    res.statusCode = 204;

    http:StatusCodeRecord statusRec = check res.getStatusCodeRecord();
    test:assertEquals(statusRec.status, 204, msg = "Status code mismatched");
    test:assertEquals(statusRec.headers, {}, msg = "Headers mismatched");
    test:assertEquals(statusRec?.body, (), msg = "Payload mismatched");
}

@test:Config
function testGetStatusRecWithFailureRes() returns error? {
    http:Response res = new;
    res.statusCode = 500;
    res.setTextPayload("Internal Server Error");
    res.setHeader("Server", "Ballerina");
    res.setHeader("Header-1", "Value-1");
    res.setHeader("Header-2", "Value-2");

    http:StatusCodeRecord statusRec = check res.getStatusCodeRecord();
    test:assertEquals(statusRec.status, 500, msg = "Status code mismatched");
    test:assertEquals(statusRec.headers, {
                                             "content-type": "text/plain",
                                             "Server": "Ballerina",
                                             "Header-1": "Value-1",
                                             "Header-2": "Value-2"
                                         }, msg = "Headers mismatched");
    test:assertEquals(statusRec?.body, "Internal Server Error", msg = "Payload mismatched");
}
