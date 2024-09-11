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
function testResponseSetPayloadWithString() returns error? {
    http:Response res = new;
    res.setPayload("test");
    test:assertEquals(res.getContentType(), "text/plain", msg = "Found unexpected headerValue");
    res.setPayload("test", "text/test1");
    test:assertEquals(res.getContentType(), "text/test1", msg = "Found unexpected headerValue");
    check res.setContentType("text/test2");
    res.setPayload("test");
    test:assertEquals(res.getContentType(), "text/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testResponseSetPayloadWithXml() returns error? {
    http:Response res = new;
    xml testValue = xml `<test><name>ballerina</name></test>`;
    res.setPayload(testValue);
    test:assertEquals(res.getContentType(), "application/xml", msg = "Found unexpected headerValue");
    res.setPayload(testValue, "xml/test1");
    test:assertEquals(res.getContentType(), "xml/test1", msg = "Found unexpected headerValue");
    check res.setContentType("xml/test2");
    res.setPayload(testValue);
    test:assertEquals(res.getContentType(), "xml/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testResponseSetPayloadWithJson() returns error? {
    http:Response res = new;
    res.setPayload({"payload": "test"});
    test:assertEquals(res.getContentType(), "application/json", msg = "Found unexpected headerValue");
    res.setPayload({"payload": "test"}, "json/test1");
    test:assertEquals(res.getContentType(), "json/test1", msg = "Found unexpected headerValue");
    check res.setContentType("json/test2");
    res.setPayload({"payload": "test"});
    test:assertEquals(res.getContentType(), "json/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testResponseSetPayloadWithByteArray() returns error? {
    http:Response res = new;
    res.setPayload("test".toBytes());
    test:assertEquals(res.getContentType(), "application/octet-stream", msg = "Found unexpected headerValue");
    res.setPayload("test".toBytes(), "binary/test1");
    test:assertEquals(res.getContentType(), "binary/test1", msg = "Found unexpected headerValue");
    check res.setContentType("binary/test2");
    res.setPayload("test".toBytes());
    test:assertEquals(res.getContentType(), "binary/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testResponseSetPayloadWithByteStream() returns error? {
    http:Response res = new;
    io:ReadableByteChannel byteChannel = check io:openReadableFile(common:TMP_FILE);
    stream<io:Block, io:Error?> blockStream = check byteChannel.blockStream(8192);
    res.setPayload(blockStream);
    test:assertEquals(res.getContentType(), "application/octet-stream", msg = "Found unexpected headerValue");
    res.setPayload(blockStream, "stream/test1");
    test:assertEquals(res.getContentType(), "stream/test1", msg = "Found unexpected headerValue");
    check res.setContentType("stream/test2");
    res.setPayload(blockStream);
    test:assertEquals(res.getContentType(), "stream/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testResponseSetPayloadWithEntityArray() returns error? {
    http:Response res = new;
    io:ReadableByteChannel byteChannel = check io:openReadableFile (common:TMP_FILE);
    stream<io:Block, io:Error?> blockStream = check byteChannel.blockStream(8192);
    mime:Entity binaryFilePart = new;
    binaryFilePart.setByteStream(blockStream);
    mime:Entity[] bodyParts = [binaryFilePart];
    res.setPayload(bodyParts);
    test:assertEquals(res.getContentType(), "multipart/form-data", msg = "Found unexpected headerValue");
    res.setPayload(bodyParts, "entity/test1");
    test:assertEquals(res.getContentType(), "entity/test1", msg = "Found unexpected headerValue");
    check res.setContentType("entity/test2");
    res.setPayload(bodyParts);
    test:assertEquals(res.getContentType(), "entity/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config{}
function testResponseSetFileAsPayload() returns error? {
    http:Response res = new;
    res.setFileAsPayload(common:TEXT_FILE);
    test:assertEquals(res.getContentType(), "application/octet-stream", msg = "Found unexpected headerValue");
    res.setFileAsPayload(common:TEXT_FILE, "file/test1");
    test:assertEquals(res.getContentType(), "file/test1", msg = "Found unexpected headerValue");
    check res.setContentType("file/test2");
    res.setFileAsPayload(common:TEXT_FILE);
    test:assertEquals(res.getContentType(), "file/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testResponseSetXmlPayload() returns error? {
    http:Response res = new;
    xml testValue = xml `<test><name>ballerina</name></test>`;
    res.setXmlPayload(testValue);
    test:assertEquals(res.getContentType(), "application/xml", msg = "Found unexpected headerValue");
    res.setXmlPayload(testValue, "xml/test1");
    test:assertEquals(res.getContentType(), "xml/test1", msg = "Found unexpected headerValue");
    check res.setContentType("xml/test2");
    res.setXmlPayload(testValue);
    test:assertEquals(res.getContentType(), "xml/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testResponseSetBinaryPayload() returns error? {
    http:Response res = new;
    res.setBinaryPayload("test".toBytes());
    test:assertEquals(res.getContentType(), "application/octet-stream", msg = "Found unexpected headerValue");
    res.setBinaryPayload("test".toBytes(), "binary/test1");
    test:assertEquals(res.getContentType(), "binary/test1", msg = "Found unexpected headerValue");
    check res.setContentType("binary/test2");
    res.setBinaryPayload("test".toBytes());
    test:assertEquals(res.getContentType(), "binary/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testResponseSetTextPayload() returns error? {
    http:Response res = new;
    res.setTextPayload("test");
    test:assertEquals(res.getContentType(), "text/plain", msg = "Found unexpected headerValue");
    res.setTextPayload("test", "text/test1");
    test:assertEquals(res.getContentType(), "text/test1", msg = "Found unexpected headerValue");
    check res.setContentType("text/test2");
    res.setTextPayload("test");
    test:assertEquals(res.getContentType(), "text/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testResponseSetJsonPayload() returns error? {
    http:Response res = new;
    res.setJsonPayload({"payload": "test"});
    test:assertEquals(res.getContentType(), "application/json", msg = "Found unexpected headerValue");
    res.setJsonPayload({"payload": "test"}, "json/test1");
    test:assertEquals(res.getContentType(), "json/test1", msg = "Found unexpected headerValue");
    check res.setContentType("json/test2");
    res.setJsonPayload({"payload": "test"});
    test:assertEquals(res.getContentType(), "json/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testResponseSetByteStream() returns error? {
    http:Response res = new;
    io:ReadableByteChannel byteChannel = check io:openReadableFile(common:TMP_FILE);
    stream<io:Block, io:Error?> blockStream = check byteChannel.blockStream(8192);
    res.setByteStream(blockStream);
    test:assertEquals(res.getContentType(), "application/octet-stream", msg = "Found unexpected headerValue");
    res.setByteStream(blockStream, "stream/test1");
    test:assertEquals(res.getContentType(), "stream/test1", msg = "Found unexpected headerValue");
    check res.setContentType("stream/test2");
    res.setByteStream(blockStream);
    test:assertEquals(res.getContentType(), "stream/test2", msg = "Found unexpected headerValue");
    return;
}

@test:Config {}
function testResponseSetAnydataPayload() returns error? {
    http:Response res = new;
    AnydataRecord testValue = {a: "ballerina", b: 1};
    res.setPayload(testValue);
    test:assertEquals(res.getContentType(), "application/json", msg = "Found unexpected headerValue");
    json payload = check res.getJsonPayload();
    test:assertEquals(payload, testValue.toJson(), msg = "Found unexpected payload");
}
