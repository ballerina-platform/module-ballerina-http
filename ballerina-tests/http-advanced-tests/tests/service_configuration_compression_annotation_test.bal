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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener compressionTestEP = new (compressionConfigTestPort, httpVersion = http:HTTP_1_1);
final http:Client compressionClient = check new ("http://localhost:" + compressionConfigTestPort.toString(), httpVersion = http:HTTP_1_1);

@http:ServiceConfig {compression: {enable: http:COMPRESSION_AUTO}}
service /autoCompress on compressionTestEP {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        check caller->respond(res);
    }
}

@http:ServiceConfig {compression: {contentTypes: ["text/plain"]}}
service /autoCompressWithContentType on compressionTestEP {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        check caller->respond(res);
    }
}

@http:ServiceConfig {compression: {enable: http:COMPRESSION_ALWAYS}}
service /alwaysCompress on compressionTestEP {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        check caller->respond(res);
    }
}

@http:ServiceConfig {compression: {enable: http:COMPRESSION_ALWAYS, contentTypes: ["text/plain", "Application/Json"]}}
service /alwaysCompressWithContentType on compressionTestEP {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setJsonPayload({test: "testValue"}, "application/json");
        check caller->respond(res);
    }
}

@http:ServiceConfig {compression: {enable: http:COMPRESSION_NEVER}}
service /neverCompress on compressionTestEP {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        check caller->respond(res);
    }
}

@http:ServiceConfig {compression: {enable: http:COMPRESSION_NEVER, contentTypes: ["text/plain", "application/xml"]}}
service /neverCompressWithContentType on compressionTestEP {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        check caller->respond(res);
    }
}

@http:ServiceConfig {compression: {enable: http:COMPRESSION_NEVER}}
service /userOverridenValue on compressionTestEP {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        res.setHeader("content-encoding", "deflate");
        check caller->respond(res);
    }
}

@http:ServiceConfig {compression: {contentTypes: ["text/plain"]}}
service /autoCompressWithInCompatibleContentType on compressionTestEP {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setJsonPayload({test: "testValue"}, "application/json");
        check caller->respond(res);
    }
}

@http:ServiceConfig {compression: {enable: http:COMPRESSION_ALWAYS, contentTypes: []}}
service /alwaysCompressWithEmptyContentType on compressionTestEP {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        check caller->respond(res);
    }
}

//Test Compression.AUTO, with no Accept-Encoding header. 
//The response here means the one that should be sent to transport, not to end user.
@test:Config {}
function testAutoCompress() {
    http:Response|error response = compressionClient->get("/autoCompress");
    if response is http:Response {
        test:assertFalse(response.hasHeader(common:CONTENT_ENCODING),
            msg = "The content-encoding header should be null and the identity which means no compression " +
                        "should be done to the response");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.AUTO, with Accept-Encoding header. 
//The response here means the one that should be sent to transport, not to end user.
@test:Config {}
function testAutoCompressWithAcceptEncoding() {
    http:Response|error response = compressionClient->get("/autoCompress", {[common:ACCEPT_ENCODING] : [common:ENCODING_GZIP]});
    if response is http:Response {
        test:assertFalse(response.hasHeader(common:CONTENT_ENCODING),
            msg = "The content-encoding header should be null and the original value of Accept-Encoding should " +
                        "be used for compression from the backend");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.AUTO, with contentTypes and without Accept-Encoding header. 
//The response here means the one that should be sent to transport, not to end user.
@test:Config {}
function testAutoCompressWithContentTypes() {
    http:Response|error response = compressionClient->get("/autoCompressWithContentType");
    if response is http:Response {
        test:assertFalse(response.hasHeader(common:CONTENT_ENCODING),
            msg = "The content-encoding header should be null and the identity which means no compression " +
                                "should be done to the response");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.ALWAYS, with no Accept-Encoding header. 
//The response here means the one that should be sent to transport, not to end user.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testAlwaysCompress() returns error? {
    http:Response|error response = compressionClient->get("/alwaysCompress");
    if response is http:Response {
        test:assertEquals(check response.getHeader(common:CONTENT_ENCODING), common:ENCODING_GZIP,
            msg = "The content-encoding header should be gzip.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.ALWAYS, with Accept-Encoding header. 
//The response here means the one that should be sent to transport, not to end user.
@test:Config {}
function testAlwaysCompressWithAcceptEncoding() {
    http:Request req = new;
    req.setTextPayload("hello");
    req.setHeader(common:ACCEPT_ENCODING, common:ENCODING_DEFLATE);
    http:Response|error response = compressionClient->post("/alwaysCompress", req);
    if response is http:Response {
        test:assertFalse(response.hasHeader(common:CONTENT_ENCODING),
            msg = "The content-encoding header should be set to null and the transport will use the original" +
                        "Accept-Encoding value for compression.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.ALWAYS, with contentTypes and without Accept-Encoding header. 
//The response here means the one that should be sent to transport, not to end user.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testAlwaysCompressWithContentTypes() returns error? {
    http:Response|error response = compressionClient->get("/alwaysCompressWithContentType");
    if response is http:Response {
        test:assertEquals(check response.getHeader(common:CONTENT_ENCODING), common:ENCODING_GZIP,
            msg = "The content-encoding header should be gzip.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.NEVER, with no Accept-Encoding header. 
//The response here means the one that should be sent to transport, not to end user.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testNeverCompress() returns error? {
    http:Response|error response = compressionClient->get("/neverCompress");
    if response is http:Response {
        test:assertEquals(check response.getHeader(common:CONTENT_ENCODING), common:HTTP_TRANSFER_ENCODING_IDENTITY,
            msg = "The content-encoding header of the response that was sent " +
                        "to transport should be set to identity.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.NEVER, with a user overridden content-encoding header. 
//The response here means the one that should be sent to transport, not to end user.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testNeverCompressWithAcceptEncoding() returns error? {
    http:Request req = new;
    req.setTextPayload("hello");
    req.setHeader(common:ACCEPT_ENCODING, common:ENCODING_GZIP);
    http:Response|error response = compressionClient->post("/userOverridenValue", req);
    if response is http:Response {
        test:assertEquals(check response.getHeader(common:CONTENT_ENCODING), common:ENCODING_DEFLATE,
            msg = "The content-encoding header of the response that was sent " +
                        "to transport should be set to identity.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.NEVER, with contentTypes. 
//The response here means the one that should be sent to transport, not to end user.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testNeverCompressWithContentTypes() returns error? {
    http:Response|error response = compressionClient->get("/neverCompressWithContentType");
    if response is http:Response {
        test:assertEquals(check response.getHeader(common:CONTENT_ENCODING), common:HTTP_TRANSFER_ENCODING_IDENTITY,
            msg = "The content-encoding header of the response that was sent to transport should be set to identity.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.AUTO, with incompatible contentTypes.
//The response here means the one that should be sent to transport, not to end user.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testAutoCompressWithIncompatibleContentTypes() returns error? {
    http:Response|error response = compressionClient->get("/autoCompressWithInCompatibleContentType");
    if response is http:Response {
        test:assertEquals(check response.getHeader(common:CONTENT_ENCODING), common:HTTP_TRANSFER_ENCODING_IDENTITY,
            msg = "The content-encoding header of the response that was sent to transport should be set to identity.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.ALWAYS, with empty contentTypes.
//The response here means the one that should be sent to transport, not to end user.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testAlwaysCompressWithEmptyContentTypes() returns error? {
    http:Response|error response = compressionClient->get("/alwaysCompressWithEmptyContentType");
    if response is http:Response {
        test:assertEquals(check response.getHeader(common:CONTENT_ENCODING), common:ENCODING_GZIP,
            msg = "The content-encoding header should be gzip.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
