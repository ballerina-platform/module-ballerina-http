// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
public function testHttp2WithSystemDefaultCerts() returns error? {
    http:Client httpClient = check new("https://www.google.com");
    string|error resp = httpClient->get("/");
    if resp is error {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testHttp2PriorKnowledgeWithSystemDefaultCerts() returns error? {
    http:Client httpClient = check new("https://www.google.com", http2Settings = { http2PriorKnowledge: true });
    string|error resp = httpClient->get("/");
    if resp is error {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
