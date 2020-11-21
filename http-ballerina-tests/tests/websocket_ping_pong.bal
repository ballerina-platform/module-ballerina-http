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

import ballerina/runtime;
import ballerina/test;
import ballerina/io;
import ballerina/http;

byte[] expectedPongData = [];
byte[] expectedPongData1 = [];
@http:WebSocketServiceConfig {
    path: "/pingpong/ws"
}
service server on new http:Listener(21014) {

    resource function onOpen(http:WebSocketCaller caller) {
    }

    resource function onPing(http:WebSocketCaller caller, byte[] localData) {
        var returnVal = caller->pong(localData);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }

    resource function onPong(http:WebSocketCaller caller, byte[] localData) {
        var returnVal = caller->ping(localData);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }
}

service pingPongCallbackService = @http:WebSocketServiceConfig {} service {

    resource function onPing(http:WebSocketClient wsEp, byte[] localData) {
        expectedPongData1 = <@untainted>localData;
    }

    resource function onPong(http:WebSocketClient wsEp, byte[] localData) {
        expectedPongData = <@untainted>localData;
    }
};

// Tests ping to Ballerina WebSocket server
@test:Config {}
public function testPingToBallerinaServer() {
    http:WebSocketClient wsClient = new ("ws://localhost:21014/pingpong/ws",
        {callbackService: pingPongCallbackService});
    byte[] pongData = [5, 24, 56, 243];
    checkpanic wsClient->ping(pongData);
    runtime:sleep(500);
    test:assertEquals(expectedPongData, pongData);
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}

// Tests pong to Ballerina WebSocket server
@test:Config {}
public function testPingFromRemoteServerToBallerinaClient() {
    http:WebSocketClient wsClient = new ("ws://localhost:21014/pingpong/ws",
        {callbackService: pingPongCallbackService});
    byte[] pongData = [5, 24, 34];
    checkpanic wsClient->pong(pongData);
    runtime:sleep(500);
    test:assertEquals(expectedPongData1, pongData);
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}
