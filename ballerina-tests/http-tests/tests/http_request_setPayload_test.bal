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

import ballerina/io;
import ballerina/http;
import ballerina/mime;
import ballerina/test;
import ballerina/http_test_common as common;

@test:Config {}
function testRequestSetPayloadWithString() returns error? {
    http:Request req = new;
    req.setPayload("test");
    test:assertEquals(req.getContentType(), "text/plain", msg = "Found unexpected headerValue");
    req.setPayload("test", "text/test1");
    test:assertEquals(req.getContentType(), "text/test1", msg = "Found unexpected headerValue");
    check req.setContentType("text/test2");
    req.setPayload("test");
    test:assertEquals(req.getContentType(), "text/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testRequestSetPayloadWithXml() returns error? {
    http:Request req = new;
    xml testValue = xml `<test><name>ballerina</name></test>`;
    req.setPayload(testValue);
    test:assertEquals(req.getContentType(), "application/xml", msg = "Found unexpected headerValue");
    req.setPayload(testValue, "xml/test1");
    test:assertEquals(req.getContentType(), "xml/test1", msg = "Found unexpected headerValue");
    check req.setContentType("xml/test2");
    req.setPayload(testValue);
    test:assertEquals(req.getContentType(), "xml/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testRequestSetPayloadWithJson() returns error? {
    http:Request req = new;
    req.setPayload({"payload": "test"});
    test:assertEquals(req.getContentType(), "application/json", msg = "Found unexpected headerValue");
    req.setPayload({"payload": "test"}, "json/test1");
    test:assertEquals(req.getContentType(), "json/test1", msg = "Found unexpected headerValue");
    check req.setContentType("json/test2");
    req.setPayload({"payload": "test"});
    test:assertEquals(req.getContentType(), "json/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testRequestSetPayloadWithByteArray() returns error? {
    http:Request req = new;
    req.setPayload("test".toBytes());
    test:assertEquals(req.getContentType(), "application/octet-stream", msg = "Found unexpected headerValue");
    req.setPayload("test".toBytes(), "binary/test1");
    test:assertEquals(req.getContentType(), "binary/test1", msg = "Found unexpected headerValue");
    check req.setContentType("binary/test2");
    req.setPayload("test".toBytes());
    test:assertEquals(req.getContentType(), "binary/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testRequestSetPayloadWithByteStream() returns error? {
    http:Request req = new;
    io:ReadableByteChannel byteChannel = check io:openReadableFile(common:TMP_FILE);
    stream<io:Block, io:Error?> blockStream = check byteChannel.blockStream(8192);
    req.setPayload(blockStream);
    test:assertEquals(req.getContentType(), "application/octet-stream", msg = "Found unexpected headerValue");
    req.setPayload(blockStream, "stream/test1");
    test:assertEquals(req.getContentType(), "stream/test1", msg = "Found unexpected headerValue");
    check req.setContentType("stream/test2");
    req.setPayload(blockStream);
    test:assertEquals(req.getContentType(), "stream/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testRequestSetPayloadWithEntityArray() returns error? {
    http:Request req = new;
    io:ReadableByteChannel byteChannel = check io:openReadableFile (common:TMP_FILE);
    stream<io:Block, io:Error?> blockStream = check byteChannel.blockStream(8192);
    mime:Entity binaryFilePart = new;
    binaryFilePart.setByteStream(blockStream);
    mime:Entity[] bodyParts = [binaryFilePart];
    req.setPayload(bodyParts);
    test:assertEquals(req.getContentType(), "multipart/form-data", msg = "Found unexpected headerValue");
    req.setPayload(bodyParts, "entity/test1");
    test:assertEquals(req.getContentType(), "entity/test1", msg = "Found unexpected headerValue");
    check req.setContentType("entity/test2");
    req.setPayload(bodyParts);
    test:assertEquals(req.getContentType(), "entity/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config{}
function testRequestSetFileAsPayload() returns error? {
    http:Request req = new;
    req.setFileAsPayload(common:TEXT_FILE);
    test:assertEquals(req.getContentType(), "application/octet-stream", msg = "Found unexpected headerValue");
    req.setFileAsPayload(common:TEXT_FILE, "file/test1");
    test:assertEquals(req.getContentType(), "file/test1", msg = "Found unexpected headerValue");
    check req.setContentType("file/test2");
    req.setFileAsPayload(common:TEXT_FILE);
    test:assertEquals(req.getContentType(), "file/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testRequestSetXmlPayload() returns error? {
    http:Request req = new;
    xml testValue = xml `<test><name>ballerina</name></test>`;
    req.setXmlPayload(testValue);
    test:assertEquals(req.getContentType(), "application/xml", msg = "Found unexpected headerValue");
    req.setXmlPayload(testValue, "xml/test1");
    test:assertEquals(req.getContentType(), "xml/test1", msg = "Found unexpected headerValue");
    check req.setContentType("xml/test2");
    req.setXmlPayload(testValue);
    test:assertEquals(req.getContentType(), "xml/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testRequestSetBinaryPayload() returns error? {
    http:Request req = new;
    req.setBinaryPayload("test".toBytes());
    test:assertEquals(req.getContentType(), "application/octet-stream", msg = "Found unexpected headerValue");
    req.setBinaryPayload("test".toBytes(), "binary/test1");
    test:assertEquals(req.getContentType(), "binary/test1", msg = "Found unexpected headerValue");
    check req.setContentType("binary/test2");
    req.setBinaryPayload("test".toBytes());
    test:assertEquals(req.getContentType(), "binary/test2", msg = "Found unexpected headerValue");
    return;
}
