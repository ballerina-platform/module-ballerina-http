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
http:Client compressionAnnotClient = new("http://localhost:" + compressionAnnotationTestPort.toString());

@http:ServiceConfig {basePath:"/autoCompress", compression: {enable: http:COMPRESSION_AUTO}}
service compressionAnnotAutoCompress on compressionAnnotListenerEP {
    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource function test1(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {basePath:"/alwaysCompress", compression: {enable: http:COMPRESSION_ALWAYS}}
service compressionAnnotAlwaysCompress on compressionAnnotListenerEP {
    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource function test2(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {basePath:"/neverCompress", compression: {enable: http:COMPRESSION_NEVER}}
service compressionAnnotNeverCompress on compressionAnnotListenerEP {
    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource function test3(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {basePath:"/userOverridenValue", compression: {enable: http:COMPRESSION_NEVER}}
service CompressionAnnotUserOverridenValue on compressionAnnotListenerEP {
    @http:ResourceConfig {
        methods:["GET"],
        path:"/"
    }
    resource function test3(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setTextPayload("Hello World!!!");
        res.setHeader("content-encoding", "deflate");
        checkpanic caller->respond(res);
    }
}

//Test Compression.AUTO, with no Accept-Encoding header.
@test:Config {}
function testCompressionAnnotAutoCompress() {
    var response = compressionAnnotClient->get("/autoCompress");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        test:assertFalse(response.hasHeader(CONTENT_ENCODING));
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.AUTO, with Accept-Encoding header.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testCompressionAnnotAutoCompressWithAcceptEncoding() {
    http:Request req = new;
    req.setHeader(ACCEPT_ENCODING, ENCODING_GZIP);
    var response = compressionAnnotClient->get("/autoCompress", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(response.getHeader(CONTENT_ENCODING), ENCODING_GZIP);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Accept-Encoding header with a q value of 0, which means not acceptable
@test:Config {}
function testAcceptEncodingWithQValueZero() {
    http:Request req = new;
    req.setHeader(ACCEPT_ENCODING, "gzip;q=0");
    var response = compressionAnnotClient->get("/autoCompress", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        test:assertFalse(response.hasHeader(CONTENT_ENCODING));
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.ALWAYS, with no Accept-Encoding header.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testCompressionAnnotAlwaysCompress() {
    var response = compressionAnnotClient->get("/alwaysCompress");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(response.getHeader(CONTENT_ENCODING), ENCODING_GZIP);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.ALWAYS, with Accept-Encoding header.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testCompressionAnnotAlwaysCompressWithAcceptEncoding() {
    http:Request req = new;
    req.setHeader(ACCEPT_ENCODING, "deflate;q=1.0, gzip;q=0.8");
    var response = compressionAnnotClient->get("/alwaysCompress", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(response.getHeader(CONTENT_ENCODING), ENCODING_DEFLATE);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.NEVER, with no Accept-Encoding header.
@test:Config {}
function testCompressionAnnotNeverCompress() {
    var response = compressionAnnotClient->get("/neverCompress");
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        test:assertFalse(response.hasHeader(CONTENT_ENCODING));
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.NEVER, with Accept-Encoding header.
@test:Config {}
function testCompressionAnnotNeverCompressWithAcceptEncoding() {
    http:Request req = new;
    req.setHeader(ACCEPT_ENCODING, "deflate;q=1.0, gzip;q=0.8");
    var response = compressionAnnotClient->get("/neverCompress", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        test:assertFalse(response.hasHeader(CONTENT_ENCODING));
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Compression.NEVER, with Accept-Encoding header and user overridden content-encoding.
// disabled due to https://github.com/ballerina-platform/ballerina-lang/issues/25428
@test:Config {enable: false}
function testCompressionAnnotNeverCompressWithUserOverridenValue() {
    http:Request req = new;
    req.setHeader(ACCEPT_ENCODING, "deflate;q=1.0, gzip;q=0.8");
    var response = compressionAnnotClient->get("/userOverridenValue", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertHeaderValue(response.getHeader(CONTENT_ENCODING), ENCODING_DEFLATE);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
