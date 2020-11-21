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

string expextedValue = "";

@http:ServiceConfig {
    basePath: "/pingpong"
}
service httpService on new http:Listener(21011) {
    @http:ResourceConfig {
        webSocketUpgrade: {
            upgradePath: "/ws",
            upgradeService: wsService
        }
    }
    resource function upgrader(http:Caller caller, http:Request req) {
        if (req.getHeader("X-some-header") == "some-header-value") {
            http:WebSocketCaller|http:WebSocketError wsServiceEp =
                caller->acceptWebSocketUpgrade({"X-some-header": "some-header-value"});
        } else {
            checkpanic caller->cancelWebSocketUpgrade(401, "Unauthorized request. Please login");
        }
    }
}
service wsService = @http:WebSocketServiceConfig {} service {
    resource function onOpen(http:WebSocketCaller caller) {
        checkpanic caller->pushText("some-header-value");
    }
};

service customHeaderService = @http:WebSocketServiceConfig {} service {

    resource function onText(http:WebSocketClient wsEp, string text) {
        expextedValue = <@untainted>text;
    }
};

// Tests when the client sends custom headers to the server.
@test:Config {}
public function testClientSentCustomHeader() {
    http:WebSocketClient wsClientEp = new ("ws://localhost:21011/pingpong/ws", {
            callbackService:
                customHeaderService,
            customHeaders: {"X-some-header": "some-header-value"}
        });
    runtime:sleep(500);
    test:assertEquals(expextedValue, "some-header-value");
    error? result = wsClientEp->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}

// Tests the client receiving custom headers from the server.
@test:Config {}
public function testClientReceivedCustomHeader() {
    http:WebSocketClient wsClient = new ("ws://localhost:21011/pingpong/ws", {
            callbackService:
                customHeaderService,
            customHeaders: {"X-some-header": "some-header-value"}
        });
    runtime:sleep(500);
    var resp = wsClient.getHttpResponse();
    if (resp is http:Response) {
        test:assertEquals(resp.getHeader("X-some-header"), "some-header-value");
    } else {
        test:assertFail("Couldn't find the expected values");
    }
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}
