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

import ballerina/log;
import ballerina/runtime;
import ballerina/test;
import ballerina/http;

string expectedOutput43 = "";

@http:WebSocketServiceConfig {
    path: "/websocket"
}
service failoverServer on new http:Listener(21043) {

    resource function onOpen(http:WebSocketCaller caller) {
        log:printInfo("The Connection ID: " + caller.getConnectionId());
    }

    resource function onText(http:WebSocketCaller caller, string text, boolean finalFrame) {
        var err = caller->pushText(text, finalFrame);
        if (err is http:WebSocketError) {
            log:printError("Error occurred when sending text message", err);
        }
    }

    resource function onBinary(http:WebSocketCaller caller, byte[] data, boolean finalFrame) {
        var err = caller->pushBinary(data, finalFrame);
        if (err is http:WebSocketError) {
            log:printError("Error occurred when sending text message", err);
        }
    }

    resource function onError(http:WebSocketCaller caller, error err) {
        errMessage = <@untainted>err.message();
    }
}

service failoverClientCallbackService = @http:WebSocketServiceConfig {} service {

    resource function onText(http:WebSocketFailoverClient wsEp, string text) {
        expectedOutput43 = <@untainted>text;
    }

    resource function onBinary(http:WebSocketFailoverClient wsEp, byte[] data) {
        expectedBinaryData = <@untainted>data;
    }

    resource function onClose(http:WebSocketFailoverClient wsEp, int statusCode, string reason) {
        checkpanic wsEp->close(statusCode = statusCode, reason = reason);
    }
};

// Tests the failover webSocket client by starting the third server in the target URLs.
// https://github.com/ballerina-platform/module-ballerina-http/issues/71
@test:Config {enable : false}
public function testBinaryFrameWithThirdServer() {
    http:WebSocketFailoverClient wsClientEp = new ({
        callbackService: failoverClientCallbackService,
        targetUrls: [
            "ws://localhost:21045/websocket",
            "ws://localhost:21046/websocket",
            "ws://localhost:21043/websocket"
        ],
        failoverIntervalInMillis: 3000
    });
    checkpanic wsClientEp->pushText("Hello");
    runtime:sleep(500);
    test:assertEquals(expectedOutput43, "Hello");
    error? result = wsClientEp->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       log:printError("Error occurred when closing connection", result);
    }
}

// Tests the failover webSocket client by starting the second server in the target URLs.
// https://github.com/ballerina-platform/module-ballerina-http/issues/71
@test:Config {enable : false}
public function testTextFrameWithSecondServer() {
    http:WebSocketFailoverClient wsClientEp = new ({
        callbackService: failoverClientCallbackService,
        targetUrls: [
            "ws://localhost:21045/websocket",
            "ws://localhost:21043/websocket",
            "ws://localhost:21046/websocket"
        ],
        failoverIntervalInMillis: 3000
    });
    checkpanic wsClientEp->pushText("Hello");
    runtime:sleep(500);
    test:assertEquals(expectedOutput43, "Hello");
    error? result = wsClientEp->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       log:printError("Error occurred when closing connection", result);
    }
}

// Tests the failover webSocket client by starting the first server in the target URLs.
// https://github.com/ballerina-platform/module-ballerina-http/issues/71
@test:Config {enable : false}
public function testBinaryFrameWithFirstServer() {
    http:WebSocketFailoverClient wsClientEp = new ({
        callbackService: failoverClientCallbackService,
        targetUrls: [
            "ws://localhost:21043/websocket",
            "ws://localhost:21046/websocket",
            "ws://localhost:21045/websocket"
        ],
        failoverIntervalInMillis: 3000
    });
    byte[] pingData = [5, 24, 56, 243];
    checkpanic wsClientEp->pushBinary(pingData);
    runtime:sleep(500);
    test:assertEquals(expectedBinaryData, pingData);
    error? result = wsClientEp->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       log:printError("Error occurred when closing connection", result);
    }
}

// Tests the failover client when getting a handshake timeout
// https://github.com/ballerina-platform/module-ballerina-http/issues/71
@test:Config {enable : false}
public function testHandshakeTimeout() {
    http:WebSocketFailoverClient wsClientEp = new ({
        callbackService: failoverClientCallbackService,
        targetUrls: [
            "ws://localhost:21044/basic/ws",
            "ws://localhost:21046/websocket",
            "ws://localhost:21043/websocket"
        ],
        handShakeTimeoutInSeconds: 7
    });
    checkpanic wsClientEp->pushText("Hello everyone");
    runtime:sleep(500);
    test:assertEquals(expectedOutput43, "Hello everyone");
    error? result = wsClientEp->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       log:printError("Error occurred when closing connection", result);
    }
}
