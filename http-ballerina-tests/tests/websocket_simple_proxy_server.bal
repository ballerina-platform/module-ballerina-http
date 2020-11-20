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

string proxyData = "";

@http:WebSocketServiceConfig {
}
service on new http:Listener(21018) {

    resource function onOpen(http:WebSocketCaller wsEp) {
        http:WebSocketClient wsClientEp = new ("ws://localhost:21019/websocket", {
                callbackService:
                    clientCallbackService9,
                readyOnConnect: false
            });
        var returnVal = wsClientEp->ready();
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }

    resource function onText(http:WebSocketCaller wsEp, string text) {
        var returnVal = wsEp->pushText(text);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }

    resource function onBinary(http:WebSocketCaller wsEp, byte[] data) {
        var returnVal = wsEp->pushBinary(data);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }

    resource function onClose(http:WebSocketCaller wsEp, int statusCode, string reason) {
        var returnVal = wsEp->close(statusCode = statusCode, reason = reason);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }

}

@http:WebSocketServiceConfig {
    path: "/websocket"
}
service proxyServer on new http:Listener(21019) {

    resource function onOpen(http:WebSocketCaller caller) {
        log:printInfo("The Connection ID: " + caller.getConnectionId());
    }

    resource function onText(http:WebSocketCaller caller, string text, boolean finalFrame) {
        var err = caller->pushText(text, finalFrame);
        if (err is http:WebSocketError) {
            log:printError("Error occurred when sending text message", err);
        }
    }

    resource function onBinary(http:WebSocketCaller caller, byte[] data) {
        var returnVal = caller->pushBinary(data);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }
}

service clientCallbackService9 = @http:WebSocketServiceConfig {} service {
    resource function onText(http:WebSocketClient wsEp, string text) {
        //http:WebSocketCaller serviceEp = getAssociatedListener(wsEp);
        var returnVal = wsEp->pushText(text);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }

    resource function onBinary(http:WebSocketClient wsEp, byte[] data) {
        var returnVal = wsEp->pushBinary(data);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }

    resource function onClose(http:WebSocketClient wsEp, int statusCode, string reason) {
        var returnVal = wsEp->close(statusCode = statusCode, reason = reason);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }
};

service proxyCallbackService = @http:WebSocketServiceConfig {} service {
    resource function onText(http:WebSocketClient wsEp, string text) {
        proxyData = <@untainted>text;
    }

    resource function onBinary(http:WebSocketClient wsEp, byte[] data) {
        expectedBinaryData = <@untainted>data;
    }

    resource function onClose(http:WebSocketClient wsEp, int statusCode, string reason) {
        var returnVal = wsEp->close(statusCode = statusCode, reason = reason);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }
};

// Tests sending and receiving of text frames in WebSockets.
@test:Config {}
public function testSendText() {
    http:WebSocketClient wsClient = new ("ws://localhost:21018", {callbackService: proxyCallbackService});
    checkpanic wsClient->pushText("Hi kalai");
    runtime:sleep(500);
    test:assertEquals(proxyData, "Hi kalai", msg = "Data mismatched");
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       log:printError("Error occurred when closing connection", result);
    }
}

// Tests sending and receiving of binary frames in WebSocket.
@test:Config {}
public function testSendBinary() {
    http:WebSocketClient wsClient = new ("ws://localhost:21018", {callbackService: proxyCallbackService});
    byte[] binaryData = [5, 24, 56, 243];
    checkpanic wsClient->pushBinary(binaryData);
    runtime:sleep(500);
    test:assertEquals(expectedBinaryData, binaryData, msg = "Data mismatched");
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       log:printError("Error occurred when closing connection", result);
    }
}
