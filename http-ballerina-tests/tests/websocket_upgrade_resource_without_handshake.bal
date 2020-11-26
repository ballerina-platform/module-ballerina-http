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
import ballerina/log;
import ballerina/http;

string upgradeServiceExpecteddata = "";
service upgradeService = @http:WebSocketServiceConfig {} service {

    resource function onOpen(http:WebSocketCaller caller) {
        var returnVal = caller->pushText("Handshake check");
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }
};

service UpgradeWithoutHandshake on new http:Listener(21002) {

    @http:ResourceConfig {
        webSocketUpgrade: {
            upgradeService: upgradeService
        }
    }
    resource function websocketProxy(http:Caller caller, http:Request req) {
    }
}

service clientCallbackService = @http:WebSocketServiceConfig {} service {

    resource function onText(http:WebSocketClient wsEp, string text) {
        upgradeServiceExpecteddata = <@untainted>text;
    }
};

// Issue https://github.com/ballerina-platform/ballerina-standard-library/issues/306
@test:Config {enable:false}
public function testUpgradeResourceWithoutHandshake() {
    http:WebSocketClient wsClient = new ("ws://localhost:21002/UpgradeWithoutHandshake",
        {callbackService: clientCallbackService});
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       log:printError("Error occurred when closing connection", result);
    }
    test:assertEquals(upgradeServiceExpecteddata, "Handshake check", msg = "Failed handshake");
}
