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

import ballerina/lang.'string as strings;
import ballerina/url;
import ballerina/mime;
import ballerina/test;
import ballerina/time;

public isolated function getHttp2Port(int port) returns int {
    return HTTP2_PORT_RANGE + port;
}

public isolated function getContentDispositionForFormData(string partName)
                                    returns (mime:ContentDisposition) {
    mime:ContentDisposition contentDisposition = new;
    contentDisposition.name = partName;
    contentDisposition.disposition = "form-data";
    return contentDisposition;
}

public isolated function assertJsonValue(json|error payload, string expectKey, json expectValue) {
    if payload is map<json> {
        test:assertEquals(payload[expectKey], expectValue, msg = "Found unexpected output");
    } else if payload is error {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

public isolated function assertJsonPayload(json|error payload, json expectValue) {
    if payload is json {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

public isolated function assertJsonPayloadtoJsonString(json|error payload, json expectValue) {
    if payload is json {
        test:assertEquals(payload.toJsonString(), expectValue.toJsonString(), msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

public isolated function assertJsonErrorPayload(json payload, string message, string reason, int statusCode, string path, string method) returns error? {
    test:assertTrue((check payload.message).toString().startsWith(message));
    test:assertEquals(payload.reason, reason);
    test:assertEquals(payload.status, statusCode);
    test:assertEquals(payload.path, path);
    test:assertEquals(payload.method, method);
    test:assertTrue(((check payload.timestamp).toString()).startsWith(time:utcToString(time:utcNow()).substring(0, 17)));
}

public isolated function assertJsonErrorPayloadPartialMessage(json payload, string message) returns error? {
    test:assertTrue((check payload.message).toString().includes(message, 0));
}

public isolated function assertXmlPayload(xml|error payload, xml expectValue) {
    if payload is xml {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

public isolated function assertBinaryPayload(byte[]|error payload, byte[] expectValue) {
    if payload is byte[] {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

public isolated function assertTextPayload(string|error payload, string expectValue) {
    if payload is string {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

public isolated function assertUrlEncodedPayload(string payload, map<string> expectedValue) returns error? {
    map<string> retrievedPayload = {};
    string decodedPayload = check url:decode(payload, "UTF-8");
    string[] entries = re`&`.split(decodedPayload);
    foreach string entry in entries {
        int? delimeterIdx = entry.indexOf("=");
        if delimeterIdx is int {
            string name = entry.substring(0, delimeterIdx);
            name = name.trim();
            string value = entry.substring(delimeterIdx + 1);
            value = value.trim();
            retrievedPayload[name] = value;
        }
    }
    test:assertEquals(retrievedPayload, expectedValue, msg = "Found unexpected output");
}

public isolated function assertTrueTextPayload(string|error payload, string expectValue) {
    if payload is string {
        test:assertTrue(strings:includes(payload, expectValue), msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

public isolated function assertTrueTextPayloadWithMutipleOptions(string|error payload, string... expectedValues) {
    if payload is string {
        foreach var value in expectedValues {
            if (strings:includes(payload, value)) {
                return;
            }
        }
        test:assertFail(msg = "Found unexpected output");
    }
    test:assertFail(msg = "Found unexpected output type: " + payload.message());
}

public isolated function assertHeaderValue(string headerKey, string expectValue) {
    test:assertEquals(headerKey, expectValue, msg = "Found unexpected headerValue");
}

public isolated function assertErrorHeaderValue(string[]? headerKey, string expectValue) {
    if (headerKey is string[]) {
        test:assertEquals(headerKey[0], expectValue, msg = "Found unexpected headerValue");
    } else {
        test:assertFail(msg = "Header not found");
    }
}

public isolated function assertErrorMessage(any|error err, string expectValue) {
    if err is error {
        test:assertEquals(err.message(), expectValue, msg = "Found unexpected error message");
    } else {
        test:assertFail(msg = "Found unexpected output");
    }
}

public isolated function assertErrorCauseMessage(any|error err, string expectValue) {
    if err is error {
        error? errorCause = err.cause();
        if errorCause is error {
            test:assertEquals(errorCause.message(), expectValue, msg = "Found unexpected error cause message");
        } else {
            test:assertFail(msg = "Found unexpected error cause");
        }
    } else {
        test:assertFail(msg = "Found unexpected output");
    }
}
