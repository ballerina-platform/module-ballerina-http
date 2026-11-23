// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/test;

const CUSTOM_HEADER_ACCESS_PREFIX = "custom-header-access";
const REQUEST_ID = "abc123";
const FIRST_REQUEST_ID = "id-1";
const SECOND_REQUEST_ID = "id-2";

// A custom header attribute (`http_<header-name>`) is logged for both the inbound request and its upstream call. The
// values of a header sent more than once are joined with commas, and a missing header is logged as "-".
@test:Config {
    serialExecution: true
}
function testCustomHeaderAttributes() returns error? {
    string logFile = "./build/tmp/output/custom-header-access.log";
    string configFile = "tests/resources/samples/config/custom-header-attributes.toml";
    Process result = check exec(bal_exec_path, {BAL_CONFIG_FILES: configFile}, (), "run", string `${temp_dir_path}/service`);
    runtime:sleep(15); // Wait to up the service

    http:Client 'client = check new ("http://localhost:9797");
    record {}[] _ = check 'client->get("/upstream/albums", {"X-Request-ID": REQUEST_ID});
    record {}[] _ = check 'client->get("/upstream/albums", {"X-Request-ID": [FIRST_REQUEST_ID, SECOND_REQUEST_ID]});
    record {}[] _ = check 'client->get("/upstream/albums");
    runtime:sleep(1); // Wait for the service to complete requests

    boolean hasTerminated = result.stop();
    runtime:sleep(1); // Ensure all file handles are released before verification
    test:assertTrue(hasTerminated, "Process should be stopped successfully");

    string content = check io:fileReadString(logFile);
    string[] upstreamLines = from string line in re `\n`.split(content)
        where line.includes("/upstream/albums")
        select line.trim();
    test:assertEquals(upstreamLines.length(), 3, string `Expected one access log line per request in: ${content}`);
    assertCustomHeaderValue(upstreamLines, string `"${REQUEST_ID}"`);
    assertCustomHeaderValue(upstreamLines, string `"${FIRST_REQUEST_ID},${SECOND_REQUEST_ID}"`);
    assertCustomHeaderValue(upstreamLines, "\"-\"");
}

// Checks that exactly one of the flat access log lines has an inbound entry that ends with the expected value of the
// custom header attribute, which is rendered after the built-in attributes, and that its upstream entry ends with the
// same value.
isolated function assertCustomHeaderValue(string[] lines, string expectedValue) {
    string[][] matches = from string line in lines
        let string[] entries = re ` "~" `.split(line)
        where entries[0].endsWith(expectedValue)
        select entries;
    test:assertEquals(matches.length(), 1,
        string `Expected one line whose inbound entry ends with ${expectedValue} in: ${lines.toString()}`);
    string[] entries = matches[0];
    test:assertEquals(entries.length(), 2,
        string `Expected an inbound and an upstream entry in: ${entries.toString()}`);
    test:assertTrue(entries[1].endsWith(expectedValue),
        string `The upstream entry should end with ${expectedValue}: ${entries.toString()}`);
}
