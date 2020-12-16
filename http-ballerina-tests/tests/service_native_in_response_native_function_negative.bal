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

@test:Config {}
function negativeTestResponseGetHeader() {
    http:Response res = new;
    error|string output = trap res.getHeader("key");
    if (output is error) {
        test:assertEquals(output.message(), "Http header does not exist", msg = "Outptut mismatched");
    } else {
        test:assertFail("Test failed");
    }
}

@test:Config {}
function negativeTestResponseGetJsonPayload() {
    http:Response res = new;
    json|error jsonPayload = res.getJsonPayload();
    if (jsonPayload is error) {
        test:assertEquals(jsonPayload.message(), "No payload");
    } else {
        test:assertFail("Test failed");
    }
}

@test:Config {}
function negativeTestResponseGetTextPayload() {
    http:Response res = new;
    string|error textPayload = res.getTextPayload();
    if (textPayload is error) {
        test:assertEquals(textPayload.message(), "No payload");
    } else {
        test:assertFail("Test failed");
    }
}

@test:Config {}
function negativeTestResponseGetBinaryPayload()  {
    http:Response res = new;
    byte[]|error binaryPayload = res.getBinaryPayload();
     if (binaryPayload is error) {
         test:assertFail("Mismatched payload");
     } else {
         test:assertEquals(strings:fromBytes(binaryPayload), "", msg = "Payload mismatched");
     }
}

@test:Config {}
function negativeTestResponseGetXmlPayload() {
    http:Response res = new;
    xml|error xmlPayload = res.getXmlPayload();
    if (xmlPayload is error) {
        test:assertEquals(xmlPayload.message(), "No payload");
    } else {
        test:assertFail("Payload mismatched");
    }
}

@test:Config {}
function negativeTestResponseGetEntity() {
    http:Response res = new;
    mime:Entity|error entity = res.getEntity();
    if (entity is error) {
        test:assertFail("Test failed.");
    }
}

@test:Config {}
function negativeTestResponseRemoveHeader() {
    http:Response res = new;
    error? output = res.removeHeader("key");
    if (output is error) {
        test:assertFail("Test failed.");
    }
}

@test:Config {}
function negativeTestResponseRemoveAllHeaders() {
    http:Response res = new;
    error? output = res.removeAllHeaders();
    if (output is error) {
        test:assertFail("Test failed.");
    }
}

@test:Config {}
function negativeTestResponseAddCookieWithInvalidName() {
    http:Response res = new;
    http:Cookie cookie = new("    ", "AD4567323");
    cookie.path = "/sample";
    cookie.expires = "2017-06-26 05:46:22";
    res.addCookie(cookie);
    test:assertEquals(res.getCookies().length(), 0, msg = "Output mismatched");
}

@test:Config {}
function negativeTestAddCookieWithInvalidPath1() {
    http:Response res = new;
    http:Cookie cookie = new("SID002", "AD4567323");
    cookie.path = "sample";
    cookie.expires = "2017-06-26 05:46:22";
    res.addCookie(cookie);
    test:assertEquals(res.getCookies().length(), 0, msg = "Output mismatched");
}

@test:Config {}
function negativeTestAddCookieWithInvalidPath2() {
    http:Response res = new;
    http:Cookie cookie = new("SID002", "AD4567323");
    cookie.path = "/sample?test=123";
    cookie.expires = "2017-06-26 05:46:22";
    res.addCookie(cookie);
    test:assertEquals(res.getCookies().length(), 0, msg = "Output mismatched");
}

@test:Config {}
function negativeTestAddCookieWithInvalidPath3() {
    http:Response res = new;
    http:Cookie cookie = new("SID002", "AD4567323");
    cookie.path = " ";
    cookie.expires = "2017-06-26 05:46:22";
    res.addCookie(cookie);
    test:assertEquals(res.getCookies().length(), 0, msg = "Output mismatched");
}

@test:Config {}
function negativeTestAddCookieWithInvalidDomain() {
    http:Response res = new;
    http:Cookie cookie = new("SID002", "AD4567323");
    cookie.domain = " ";
    cookie.path = "/sample";
    cookie.expires = "2017-06-26 05:46:22";
    res.addCookie(cookie);
    test:assertEquals(res.getCookies().length(), 0, msg = "Output mismatched");
}

@test:Config {}
function negativeTestAddCookieWithInvalidExpires1() {
    http:Response res = new;
    http:Cookie cookie = new("SID002", "AD4567323");
    cookie.path = "/sample";
    cookie.expires = "2017 13 42 05:70:22";
    res.addCookie(cookie);
    test:assertEquals(res.getCookies().length(), 0, msg = "Output mismatched");
}

@test:Config {}
function negativeTestAddCookieWithInvalidExpires2() {
    http:Response res = new;
    http:Cookie cookie = new("SID002", "AD4567323");
    cookie.path = "/sample";
    cookie.expires = " ";
    res.addCookie(cookie);
    test:assertEquals(res.getCookies().length(), 0, msg = "Output mismatched");
}

@test:Config {}
function negativeTestAddCookieWithInvalidMaxAge() {
    http:Response res = new;
    http:Cookie cookie = new("SID002", "AD4567323");
    cookie.path = "/sample";
    cookie.expires = "2017-06-26 05:46:22";
    cookie.maxAge = -3600;
    res.addCookie(cookie);
    test:assertEquals(res.getCookies().length(), 0, msg = "Output mismatched");
}
