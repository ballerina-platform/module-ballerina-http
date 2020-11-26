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

import ballerina/io;
import ballerina/runtime;
import ballerina/test;
import ballerina/http;

byte[] expectedAutoPongData = [];

service on new http:Listener(21020) {
    resource function onOpen(http:WebSocketCaller wsEp) {
        io:println("New Client Connected");
    }
}

service pongService = @http:WebSocketServiceConfig {} service {

    resource function onPong(http:WebSocketClient wsEp, byte[] data) {
        expectedAutoPongData = <@untainted>data;
    }
};

// Tests the auto ping pong support in Ballerina if there is no onPing resource
// Issue https://github.com/ballerina-platform/ballerina-standard-library/issues/306
@test:Config {enable:false}
public function testAutoPingPongSupport() {
    http:WebSocketClient wsClient = new ("ws://localhost:21020", {callbackService: pongService});
    byte[] pingData = [5, 24, 56, 243];
    checkpanic wsClient->ping(pingData);
    runtime:sleep(500);
    test:assertEquals(expectedAutoPongData, pingData, msg = "Data mismatched");
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
        io:println("Error occurred when closing connection", result);
    }
}
