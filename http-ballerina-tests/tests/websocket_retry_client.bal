// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

string expectedOutput34 = "";

listener http:Listener retryEP = new (21034);

service wsUpgradedRetryService = @http:ServiceConfig {basePath: "/retry"} service {
    @http:ResourceConfig {
        webSocketUpgrade: {
            upgradePath: "/ws",
            upgradeService: wsUpgradeRetryService
        }
    }
    resource function upgrader(http:Caller caller, http:Request req) {
    }
};

service wsUpgradeRetryService = @http:WebSocketServiceConfig {} service {
    resource function onOpen(http:WebSocketCaller caller) {
        io:println("onOpen: " + caller.getConnectionId());
    }

    resource function onText(http:WebSocketCaller caller, string text, boolean finalFrame) {
        checkpanic caller->pushText(text);
    }
};

service retryClientCallbackService = @http:WebSocketServiceConfig {} service {
    resource function onText(http:WebSocketClient wsEp, string text) {
        expectedOutput34 = <@untainted>text;
    }
};

@http:WebSocketServiceConfig {
    path: "/retry"
}
service retryService on new http:Listener(21035) {
    resource function onOpen(http:WebSocketCaller wsEp) {
        http:WebSocketClient wsClientEp = new ("ws://localhost:21034/retry/ws", {
                callbackService:
                    retryClientCallbackService,
                retryConfig: {}
            });
        var returnVal = wsClientEp->pushText("Hi madam");
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

// Tests the retry function using the WebSocket client (Server starts after the client starts)
@test:Config {}
public function testRetry() {
    checkpanic retryEP.__gracefulStop();
    runtime:sleep(1500);
    http:WebSocketClient wsClientEp = new ("ws://localhost:21035/retry");
    runtime:sleep(1500);
    checkpanic retryEP.__attach(wsUpgradedRetryService);
    runtime:sleep(1500);
    checkpanic retryEP.__start();
    runtime:sleep(5000);
    test:assertEquals(expectedOutput34, "Hi madam");
    error? result = wsClientEp->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}
