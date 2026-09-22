// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/jballerina.java;
import ballerina/test;
import ballerina/time;

// The servers are Java based because a Ballerina service always sets the content encoding itself, so it cannot
// reply with a body that does not match a gzip content encoding.
const int GZIP_DECODE_H2_PORT = 9761;
const int GZIP_DECODE_H1_PORT = 9762;
const string GZIP_DECODE_GROUP = "gzipDecodeFailure";

const string GZIP_VALID_PATH = "/gzip/valid";
const string GZIP_MALFORMED_PATH = "/gzip/malformed";
const string GZIP_PUSH_PATH = "/gzip/push";
const string GZIP_VALID_CONTENT = "{\"greeting\":\"Hello from a gzip encoded response\"}";

// A failed read used to stay blocked for the 300 second entity wait, so anything close to the client timeout
// below means the failure was not reported when it happened.
const decimal GZIP_FAILURE_REPORT_LIMIT = 20;

final http:Client gzipDecodeH2Client = check new (string `http://localhost:${GZIP_DECODE_H2_PORT}`,
    http2Settings = {http2PriorKnowledge: true}, timeout = 30);

final http:Client gzipDecodeH1Client = check new (string `http://localhost:${GZIP_DECODE_H1_PORT}`,
    httpVersion = http:HTTP_1_1, timeout = 30);

@test:BeforeGroups {value: [GZIP_DECODE_GROUP]}
function startGzipDecodeServers() returns error? {
    check startGzipResponseServer(GZIP_DECODE_H2_PORT, true);
    check startGzipResponseServer(GZIP_DECODE_H1_PORT, false);
}

@test:AfterGroups {value: [GZIP_DECODE_GROUP], alwaysRun: true}
function stopGzipDecodeServers() returns error? {
    check stopGzipResponseServer(GZIP_DECODE_H2_PORT);
    check stopGzipResponseServer(GZIP_DECODE_H1_PORT);
}

function gzipBodyAccessors() returns map<[string]> => {
    "getByteStream": ["byteStream"],
    "getBinaryPayload": ["binaryPayload"],
    "getTextPayload": ["textPayload"],
    "getJsonPayload": ["jsonPayload"],
    "client data binding to byte[]": ["bindBytes"],
    "client data binding to string": ["bindString"],
    "client data binding to json": ["bindJson"]
};

// A body that cannot be decoded must be reported as an error by every way of reading it.
@test:Config {groups: [GZIP_DECODE_GROUP], dataProvider: gzipBodyAccessors}
function testMalformedGzipBodyOverHttp2(string accessor) {
    assertReadFailsPromptly(gzipDecodeH2Client, GZIP_MALFORMED_PATH, accessor);
}

// HTTP/1.1 already reported the failure, so this keeps both protocols behaving the same.
@test:Config {groups: [GZIP_DECODE_GROUP], dataProvider: gzipBodyAccessors}
function testMalformedGzipBodyOverHttp1(string accessor) {
    assertReadFailsPromptly(gzipDecodeH1Client, GZIP_MALFORMED_PATH, accessor);
}

@test:Config {groups: [GZIP_DECODE_GROUP], dataProvider: gzipBodyAccessors}
function testValidGzipBodyOverHttp2(string accessor) returns error? {
    byte[] content = check readBody(gzipDecodeH2Client, GZIP_VALID_PATH, accessor);
    test:assertEquals(string:fromBytes(content), GZIP_VALID_CONTENT);
}

// The failure only resets the affected stream, so the same connection must keep serving requests.
@test:Config {groups: [GZIP_DECODE_GROUP]}
function testHttp2ClientRecoversAfterMalformedGzipBody() returns error? {
    assertReadFailsPromptly(gzipDecodeH2Client, GZIP_MALFORMED_PATH, "binaryPayload");
    string content = check gzipDecodeH2Client->get(GZIP_VALID_PATH);
    test:assertEquals(content, GZIP_VALID_CONTENT);
}

@test:Config {groups: [GZIP_DECODE_GROUP]}
function testMalformedGzipPushedResponseOverHttp2() returns error? {
    http:HttpFuture httpFuture = check gzipDecodeH2Client->submit("GET", GZIP_PUSH_PATH, new http:Request());
    boolean hasPromise = gzipDecodeH2Client->hasPromise(httpFuture);
    test:assertTrue(hasPromise, "Expected a push promise");
    http:PushPromise promise = check gzipDecodeH2Client->getNextPromise(httpFuture);
    http:Response pushedResponse = check gzipDecodeH2Client->getPromisedResponse(promise);

    decimal startTime = time:monotonicNow();
    string|http:ClientError pushedPayload = pushedResponse.getTextPayload();
    test:assertTrue(pushedPayload is error, "Expected the pushed body read to fail");
    test:assertTrue(time:monotonicNow() - startTime < GZIP_FAILURE_REPORT_LIMIT,
        "The pushed body read failure was not reported promptly");

    // The response that carried the promise is unaffected.
    http:Response response = check gzipDecodeH2Client->getResponse(httpFuture);
    test:assertEquals(check response.getTextPayload(), GZIP_VALID_CONTENT);
}

function assertReadFailsPromptly(http:Client clientEP, string path, string accessor) {
    decimal startTime = time:monotonicNow();
    byte[]|error result = readBody(clientEP, path, accessor);
    decimal elapsed = time:monotonicNow() - startTime;
    test:assertTrue(result is error,
        "Expected the body read through " + accessor + " to fail, but it read " + describeRead(result));
    test:assertTrue(elapsed < GZIP_FAILURE_REPORT_LIMIT,
        "The failure of the body read through " + accessor + " was reported after " + elapsed.toString() + "s");
}

function describeRead(byte[]|error result) returns string {
    if result is byte[] {
        string|error text = string:fromBytes(result);
        return result.length().toString() + " bytes: " + (text is string ? text : "<not utf-8>");
    }
    return "nothing";
}

function readBody(http:Client clientEP, string path, string accessor) returns byte[]|error {
    match accessor {
        "bindBytes" => {
            return clientEP->get(path);
        }
        "bindString" => {
            string content = check clientEP->get(path);
            return content.toBytes();
        }
        "bindJson" => {
            json content = check clientEP->get(path);
            return content.toJsonString().toBytes();
        }
    }
    http:Response response = check clientEP->get(path);
    test:assertEquals(response.statusCode, 200);
    match accessor {
        "byteStream" => {
            return readByteStream(response);
        }
        "binaryPayload" => {
            return response.getBinaryPayload();
        }
        "textPayload" => {
            string content = check response.getTextPayload();
            return content.toBytes();
        }
        _ => {
            json content = check response.getJsonPayload();
            return content.toJsonString().toBytes();
        }
    }
}

function readByteStream(http:Response response) returns byte[]|error {
    stream<byte[], error?> byteStream = check response.getByteStream();
    byte[] content = [];
    while true {
        record {|byte[] value;|}|error? chunk = byteStream.next();
        if chunk is error {
            return chunk;
        }
        if chunk is () {
            return content;
        }
        content.push(...chunk.value);
    }
}

function startGzipResponseServer(int port, boolean http2) returns error? = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternGzipResponseTestUtil"
} external;

function stopGzipResponseServer(int port) returns error? = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternGzipResponseTestUtil"
} external;
