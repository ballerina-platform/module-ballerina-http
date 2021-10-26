// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

listener http:Listener compressionAnnotListenerEP = new(compressionAnnotationTestPort);
final http:Client compressionAnnotClient = check new("http://localhost:" + compressionAnnotationTestPort.toString());

@http:ServiceConfig {compression: {enable: http:COMPRESSION_AUTO}}
service /autoCompress on compressionAnnotListenerEP {

    resource function get .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {compression: {enable: http:COMPRESSION_ALWAYS}}
service /alwaysCompress on compressionAnnotListenerEP {

    resource function get .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {compression: {enable: http:COMPRESSION_NEVER}}
service /neverCompress on compressionAnnotListenerEP {

    resource function get .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {compression: {enable: http:COMPRESSION_NEVER}}
service /userOverridenValue on compressionAnnotListenerEP {

    resource function get .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        res.setHeader("content-encoding", "deflate");
        checkpanic caller->respond(res);
    }
}

//Test Compression.AUTO, with no Accept-Encoding header.
@test:Config {}
function testCompressionAnnotAutoCompress() {
    http:Response|error response = compressionAnnotClient->get("/autoCompress");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        test:assertFalse(response.hasHeader(CONTENT_ENCODING));
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.AUTO, with Accept-Encoding header.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testCompressionAnnotAutoCompressWithAcceptEncoding() {
    http:Response|error response = compressionAnnotClient->get("/autoCompress", {[ACCEPT_ENCODING]:[ENCODING_GZIP]});
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(checkpanic response.getHeader(CONTENT_ENCODING), ENCODING_GZIP);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Accept-Encoding header with a q value of 0, which means not acceptable
@test:Config {}
function testAcceptEncodingWithQValueZero() {
    http:Response|error response = compressionAnnotClient->get("/autoCompress", {[ACCEPT_ENCODING]:"gzip;q=0"});
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        test:assertFalse(response.hasHeader(CONTENT_ENCODING));
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.ALWAYS, with no Accept-Encoding header.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testCompressionAnnotAlwaysCompress() {
    http:Response|error response = compressionAnnotClient->get("/alwaysCompress");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(checkpanic response.getHeader(CONTENT_ENCODING), ENCODING_GZIP);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.ALWAYS, with Accept-Encoding header.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testCompressionAnnotAlwaysCompressWithAcceptEncoding() {
    http:Response|error response = compressionAnnotClient->get("/alwaysCompress", {[ACCEPT_ENCODING]:"deflate;q=1.0, gzip;q=0.8"});
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(checkpanic response.getHeader(CONTENT_ENCODING), ENCODING_DEFLATE);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.NEVER, with no Accept-Encoding header.
@test:Config {}
function testCompressionAnnotNeverCompress() {
    http:Response|error response = compressionAnnotClient->get("/neverCompress");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        test:assertFalse(response.hasHeader(CONTENT_ENCODING));
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.NEVER, with Accept-Encoding header.
@test:Config {}
function testCompressionAnnotNeverCompressWithAcceptEncoding() {
    http:Response|error response = compressionAnnotClient->get("/neverCompress", {[ACCEPT_ENCODING]:"deflate;q=1.0, gzip;q=0.8"});
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        test:assertFalse(response.hasHeader(CONTENT_ENCODING));
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.NEVER, with Accept-Encoding header and user overridden content-encoding.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testCompressionAnnotNeverCompressWithUserOverridenValue() {
    http:Response|error response = compressionAnnotClient->get("/userOverridenValue", {[ACCEPT_ENCODING]:"deflate;q=1.0, gzip;q=0.8"});
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(checkpanic response.getHeader(CONTENT_ENCODING), ENCODING_DEFLATE);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
