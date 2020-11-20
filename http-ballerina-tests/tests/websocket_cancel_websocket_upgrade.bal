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

import ballerina/runtime;
import ballerina/test;
import ballerina/http;

listener http:Listener ep1 = new (21009);
string errorMsg = "";
service simpleProxy1 = @http:WebSocketServiceConfig {} service {

    resource function onOpen(http:WebSocketCaller wsEp) {
    }
};

service simple on ep1 {

    @http:ResourceConfig {
        webSocketUpgrade: {
            upgradePath: "/cancel",
            upgradeService: simpleProxy1
        }
    }
    resource function websocketProxy(http:Caller httpEp, http:Request req) {
        var returnVal = httpEp->cancelWebSocketUpgrade(404, "Cannot proceed");
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }
}

service cannotcancel on ep1 {

    @http:ResourceConfig {
        webSocketUpgrade: {
            upgradePath: "/cannot/cancel",
            upgradeService: simpleProxy1
        }
    }
    resource function websocketProxy(http:Caller httpEp, http:Request req) {
        var returnVal = httpEp->cancelWebSocketUpgrade(200, "Cannot proceed");
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }
}

service resourceNotFoundCallbackService = @http:WebSocketServiceConfig {} service {

    resource function onError(http:WebSocketClient wsEp, error err) {
        errorMsg = <@untainted>err.message();
    }
};

// Tests resource not found scenario.
@test:Config {}
public function testResourceNotFound() {
    http:WebSocketClient wsClient = new ("ws://localhost:21009/proxy/cancell",
        {callbackService: resourceNotFoundCallbackService});
    runtime:sleep(500);
    test:assertEquals(errorMsg, "InvalidHandshakeError: Invalid handshake response getStatus: 404 Not Found");

}

// Tests the cancelWebSocketUpgrade method.
@test:Config {}
public function testCancelUpgrade() {
    http:WebSocketClient wsClient = new ("ws://localhost:21009/simple/cancel",
        {callbackService: resourceNotFoundCallbackService});
    runtime:sleep(500);
    test:assertEquals(errorMsg, "InvalidHandshakeError: Invalid handshake response getStatus: 404 Not Found");
}

// Tests the cancelWebSocketUpgrade method with a success status code.
@test:Config {}
public function testCancelUpgradeSuccessStatusCode() {
    http:WebSocketClient wsClient = new ("ws://localhost:21009/cannotcancel/cannot/cancel",
        {callbackService: resourceNotFoundCallbackService});
    runtime:sleep(500);
    test:assertEquals(errorMsg, "InvalidHandshakeError: Invalid handshake response getStatus: 400 Bad Request");
}
