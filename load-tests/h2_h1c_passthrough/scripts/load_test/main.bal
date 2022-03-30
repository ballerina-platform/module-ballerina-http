// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/time;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/http;

public function main(string label, string output_csv_path) returns error? {
    http:Client loadTestClient = check new ("https://h2-h1c-passthro-svc.default.svc.cluster.local:9090/passthrough",
        httpVersion = "2.0",
        http2Settings = {
            http2PriorKnowledge: true
        },
        secureSocket = {
            enable: false
        }
    );
    int sentCount = 0;
    int errorCount = 0;
    int receivedCount = 0;
    time:Utc startedTime = time:utcNow();
    time:Utc expiryTime = time:utcAddSeconds(startedTime, 600);
    json payload = {event: "event"};
    while time:utcDiffSeconds(expiryTime, time:utcNow()) > 0D {
        json|error response = loadTestClient->post("", payload);
        sentCount += 1;
        if response is error {
            log:printError("Error received: ", errorMessage = response.message(), 'error = response);
            errorCount += 1;
        } else {
            log:printInfo("Response received: ", payload = response);
            receivedCount += 1;
        }
        runtime:sleep(0.1);
    }
    decimal time = time:utcDiffSeconds(time:utcNow(), startedTime);
    log:printInfo("Test summary: ", sent = sentCount, received = receivedCount, errors = errorCount, duration = time);
    float average = receivedCount == 0 ? 0 : <float>time / <float>receivedCount;
    any[] results = [label, sentCount, average, 0, 0, 0, 0, 0, 0, <float>errorCount/<float>sentCount, 
        <float>receivedCount/<float>time, 0, 0, time:utcNow()[0], 0, 1];
    check writeResultsToCsv(results, output_csv_path);

}

function writeResultsToCsv(any[] results, string output_path) returns error? {
    string[][] summary_data = check io:fileReadCsv(output_path);
    string[] final_results = [];
    foreach var result in results {
        final_results.push(result.toString());
    }
    summary_data.push(final_results);
    check io:fileWriteCsv(output_path, summary_data);
}
