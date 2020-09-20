// Copyright (c) 2020 WSO2 Inc. (//www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// //www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import http;

int expectedStatusCode = 0;
@http:WebSocketServiceConfig {
    path: "/"
}
service clientClose on new http:Listener(21004) {
    resource function onClose(http:WebSocketCaller wsEp, int statusCode, string reason) {
        expectedStatusCode = <@untainted>statusCode;
    }

}

// Test client closing the connection with a close code
@test:Config {}
public function testCloseWithCloseCode() {
    http:WebSocketClient wsClient = new ("ws://localhost:21004");
    checkpanic wsClient->close(1001, "Close the connection", timeoutInSeconds = 120);
    test:assertEquals(expectedStatusCode, 1001, msg = "status code mismatched");
}

// Test client sending a close frame without a close code
@test:Config {}
public function testCloseWithoutCloseCode() {
    http:WebSocketClient wsClient = new ("ws://localhost:21004");
    checkpanic wsClient->close(statusCode = 1000, reason = "Close the connection", timeoutInSeconds = 120);
    test:assertEquals(expectedStatusCode, 1000, msg = "status code mismatched");
}
