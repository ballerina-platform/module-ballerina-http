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

final string CUSTOM_HEADER = "X-some-header";

service customHeader on new http:Listener(21012) {

    @http:ResourceConfig {
        webSocketUpgrade: {
            upgradePath: "/custom/header/server",
            upgradeService: simpleProxy
        }
    }
    resource function websocketProxy(http:Caller httpEp, http:Request req) {
        http:WebSocketCaller|http:WebSocketError wsServiceEp =
            httpEp->acceptWebSocketUpgrade({"X-some-header": "some-header-value"});
        if (wsServiceEp is http:WebSocketCaller) {
            wsServiceEp.setAttribute("X-some-header", req.getHeader("X-some-header"));
        } else {
            panic wsServiceEp;
        }
    }
}

service simpleProxy = @http:WebSocketServiceConfig {} service {
    resource function onText(http:WebSocketCaller wsEp, string text) {
        var returnVal = wsEp->pushText(<string>wsEp.getAttribute("X-some-header"));
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }
};

service customServerHeaderService = @http:WebSocketServiceConfig {} service {

    resource function onText(http:WebSocketClient wsEp, string text) {
        expextedValue = <@untainted>text;
    }
};

// Tests custom header sent by the server
@test:Config {}
public function testServerSentCustomHeader() {
    http:WebSocketClient wsClient = new ("ws://localhost:21012/customHeader/custom/header/server",
        {customHeaders: {"X-some-header": "some-header-value"}});
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

// Tests reception of custom header by the server
@test:Config {}
public function testServerReceivedCustomHeader() {
    http:WebSocketClient wsClient = new ("ws://localhost:21012/customHeader/custom/header/server",
        {
            callbackService: customServerHeaderService,
            customHeaders: {"X-some-header": "some-header-value"}
        });
    checkpanic wsClient->pushText("HI");
    runtime:sleep(500);
    test:assertEquals(expextedValue, "some-header-value");
    error? result = wsClient->close(statusCode = 1000, reason = "Close the connection");
    if (result is http:WebSocketError) {
       io:println("Error occurred when closing connection", result);
    }
}
