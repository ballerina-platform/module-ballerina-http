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

import ballerina/http;
import ballerina/test;

@test:Config {}
isolated function testEncode() {
    string[] urls = [
        "http://localhost:9090",
        "http://localhost:9090/echoService/hello world/",
        "http://localhost:9090/echoService?type=string&value=hello world",
        "http://localhost:9090/echoService#abc",
        "http://localhost:9090/echoService:abc",
        "http://localhost:9090/echoService+abc",
        "http://localhost:9090/echoService*abc",
        "http://localhost:9090/echoService%abc",
        "http://localhost:9090/echoService~abc"
    ];

    foreach var url in urls {
        string|http:Error result = http:encode(url, "UTF-8");
        if (result is string) {
            test:assertFalse(result.includes(" "), msg = "Unexpected character.");
            test:assertFalse(result.includes("*"), msg = "Unexpected character.");
            test:assertFalse(result.includes("+"), msg = "Unexpected character.");
            test:assertFalse(result.includes("%7E"), msg = "Unexpected character.");
        } else {
            test:assertFail(msg = "Error while encode. " + result.message());
        }
    }
}

@test:Config {}
isolated function testInvalidEncode() {
    string url = "http://localhost:9090/echoService#abc";
    string|http:Error result = http:encode(url, "abc");
    if (result is http:Error) {
        string expectedErrMsg = "Error occurred while encoding the URL component. abc";
        test:assertEquals(result.message(), expectedErrMsg, "Unexpected error message.");
    } else {
        test:assertFail(msg = "Expected error not found.");
    }
}

@test:Config {}
isolated function testSimpleUrlDecode() {
    string encodedUrlValue = "http%3A%2F%2Flocalhost%3A9090";
    string|http:Error result = http:decode(encodedUrlValue, "UTF-8");
    if (result is string) {
        string expectedUrl = "http://localhost:9090";
        test:assertEquals(result, expectedUrl, msg = "Decoded URL string is not correct.");
    } else {
        test:assertFail(msg = "Error in decode. " + result.message());
    }
}

@test:Config {}
isolated function testUrlDecodeWithSpaces() {
    string encodedUrlValue = "http%3A%2F%2Flocalhost%3A9090%2FechoService%2Fhello%20world%2F";
    string|http:Error result = http:decode(encodedUrlValue, "UTF-8");
    if (result is string) {
        string expectedUrl = "http://localhost:9090/echoService/hello world/";
        test:assertEquals(result, expectedUrl, msg = "Decoded URL string is not correct.");
        test:assertTrue(result.includes(" "), msg = "Decoded URL string doesn't contain spaces.");
    } else {
        test:assertFail(msg = "Error in decode. " + result.message());
    }
}

@test:Config {}
isolated function testUrlDecodeWithHashSign() {
    string encodedUrlValue = "http%3A%2F%2Flocalhost%3A9090%2FechoService%23abc";
    string|http:Error result = http:decode(encodedUrlValue, "UTF-8");
    if (result is string) {
        string expectedUrl = "http://localhost:9090/echoService#abc";
        test:assertEquals(result, expectedUrl, msg = "Decoded URL string is not correct.");
        test:assertTrue(result.includes("#"), msg = "Decoded URL string doesn't contain # character.");
    } else {
        test:assertFail(msg = "Error in decode. " + result.message());
    }
}

@test:Config {}
isolated function testUrlDecodeWithColon() {
    string encodedUrlValue = "http%3A%2F%2Flocalhost%3A9090%2FechoService%3Aabc";
    string|http:Error result = http:decode(encodedUrlValue, "UTF-8");
    if (result is string) {
        string expectedUrl = "http://localhost:9090/echoService:abc";
        test:assertEquals(result, expectedUrl, msg = "Decoded URL string is not correct.");
        test:assertTrue(result.includes(":"), msg = "Decoded URL string doesn't contain : character.");
    } else {
        test:assertFail(msg = "Error in decode. " + result.message());
    }
}

@test:Config {}
isolated function testUrlDecodeWithPlusSign() {
    string encodedUrlValue = "http%3A%2F%2Flocalhost%3A9090%2FechoService%2Babc";
    string|http:Error result = http:decode(encodedUrlValue, "UTF-8");
    if (result is string) {
        string expectedUrl = "http://localhost:9090/echoService+abc";
        test:assertEquals(result, expectedUrl, msg = "Decoded URL string is not correct.");
        test:assertTrue(result.includes("+"), msg = "Decoded URL string doesn't contain + character.");
    } else {
        test:assertFail(msg = "Error in decode. " + result.message());
    }
}

@test:Config {}
isolated function testUrlDecodeWithAsterisk() {
    string encodedUrlValue = "http%3A%2F%2Flocalhost%3A9090%2FechoService%2Aabc";
    string|http:Error result = http:decode(encodedUrlValue, "UTF-8");
    if (result is string) {
        string expectedUrl = "http://localhost:9090/echoService*abc";
        test:assertEquals(result, expectedUrl, msg = "Decoded URL string is not correct.");
        test:assertTrue(result.includes("*"), msg = "Decoded URL string doesn't contain * character.");
    } else {
        test:assertFail(msg = "Error in decode. " + result.message());
    }
}

@test:Config {}
isolated function testUrlDecodeWithPercentageMark() {
    string encodedUrlValue = "http%3A%2F%2Flocalhost%3A9090%2FechoService%25abc";
    string|http:Error result = http:decode(encodedUrlValue, "UTF-8");
    if (result is string) {
        string expectedUrl = "http://localhost:9090/echoService%abc";
        test:assertEquals(result, expectedUrl, msg = "Decoded URL string is not correct.");
        test:assertTrue(result.includes("%"), msg = "Decoded URL string doesn't contain % character.");
    } else {
        test:assertFail(msg = "Error in decode. " + result.message());
    }
}

@test:Config {}
isolated function testUrlDecodeWithTilde() {
    string encodedUrlValue = "http%3A%2F%2Flocalhost%3A9090%2FechoService~abc";
    string|http:Error result = http:decode(encodedUrlValue, "UTF-8");
    if (result is string) {
        string expectedUrl = "http://localhost:9090/echoService~abc";
        test:assertEquals(result, expectedUrl, msg = "Decoded URL string is not correct.");
        test:assertTrue(result.includes("~"), msg = "Decoded URL string doesn't contain ~ character.");
    } else {
        test:assertFail(msg = "Error in decode. " + result.message());
    }
}

@test:Config {}
isolated function testInvalidDecode() {
    string url = "http%3A%2F%2Flocalhost%3A9090%2FechoService~abc";
    string|http:Error result = http:decode(url, "abc");
    if (result is http:Error) {
        string expectedErrMsg = "Error occurred while decoding the URL component. abc";
        test:assertEquals(result.message(), expectedErrMsg, "Unexpected error message.");
    } else {
        test:assertFail(msg = "Expected error not found.");
    }
}
