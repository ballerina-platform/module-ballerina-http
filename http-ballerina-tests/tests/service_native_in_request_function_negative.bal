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

import ballerina/lang.'string as strings;
import ballerina/mime;
import ballerina/test;
import ballerina/http;

// Test when the content length header is not set
@test:Config {}
function negativeTestGetContentLength() {
    http:Request req = new;
    test:assertFalse(req.hasHeader("content-legth"));
}

// "Test when the content type header is not set"
@test:Config {}
function negativeTestGetHeader() {
    http:Request req = new;
    test:assertFalse(req.hasHeader("Content-Type"));
}

// Test method without json payload
@test:Config {}
function negativeTestGetJsonPayload() {
    http:Request req = new;
    json|error jsonPayload = req.getJsonPayload();
    if (jsonPayload is error) {
        test:assertEquals(jsonPayload.message(), "No payload");
    }
}

@test:Config {}
function negativeTestGetMethod() {
    http:Request req = new;
    test:assertEquals(req.method, "");
}

@test:Config {}
function testGetRequestURL() {
    http:Request req = new;
    test:assertEquals(req.rawPath, "");
}

@test:Config {}
function negativeTestGetTextPayload() {
    http:Request req = new;
    string|error textPayload = req.getTextPayload();
    if (textPayload is error) {
        test:assertEquals(textPayload.message(), "No payload");
    } else {
        test:assertFail("Mismatched payload");
    }
}

@test:Config {}
function negativeTestGetBinaryPayload() {
    http:Request req = new;
    byte[]|error binaryPayload = req.getBinaryPayload();
    if (binaryPayload is error) {
        test:assertFail("Mismatched payload");
    } else {
        test:assertEquals(strings:fromBytes(binaryPayload), "", msg = "Payload mismatched");
    }
}

@test:Config {}
function negativeTestGetXmlPayload() {
    http:Request req = new;
    xml|error xmlPayload = req.getXmlPayload();
    if (xmlPayload is error) {
        test:assertEquals(xmlPayload.message(), "No payload");
    } else {
        test:assertFail("Payload mismatched");
    }
}

@test:Config {}
function testGetEntity() {
    http:Request req = new;
    mime:Entity|error entity = req.getEntity();
    if (entity is error) {
        test:assertFail("Test failed.");
    }
}

@test:Config {}
function testRemoveHeader() {
    http:Request req = new;
    error? output = req.removeHeader("key");
    if (output is error) {
        test:assertFail("Test failed.");
    }
}

function testRemoveAllHeaders() {
    http:Request req = new;
    error? output = req.removeAllHeaders();
    if (output is error) {
        test:assertFail("Test failed.");
    }
}
