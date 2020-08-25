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

import ballerina/stringutils;
import ballerina/test;

function assertJsonValue(json|error payload, string expectKey, json expectValue) {
    if payload is map<json> {
        test:assertEquals(payload[expectKey], expectValue, msg = "Found unexpected output");
    } else if payload is error {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

function assertJsonPayload(json|error payload, json expectValue) {
    if payload is json {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

function assertTextPayload(string|error payload, string expectValue) {
    if payload is string {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

function assertTrueTextPayload(string|error payload, string expectValue) {
    if payload is string {
        test:assertTrue(stringutils:contains(payload, expectValue), msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}
