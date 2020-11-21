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
import ballerina/http;

int expectedCode = 0;
string expectedReason = "";

service resourceFailue on new http:Listener(21016) {

    @http:ResourceConfig {
        webSocketUpgrade: {
            upgradeService: castErrror
        }
    }
    resource function websocketProxy(http:Caller httpEp, http:Request req) {
        http:WebSocketCaller|http:WebSocketError wsServiceEp =
            httpEp->acceptWebSocketUpgrade({"X-some-header": "some-header-value"});
        if (wsServiceEp is http:WebSocketCaller) {
            var queryParam = req.getQueryParamValue("q1");
            if (queryParam == ()) {
                panic error("Query param not set");
            }
            wsServiceEp.setAttribute("Query1", queryParam);
        } else {
            panic wsServiceEp;
        }
    }
}

service castErrror = @http:WebSocketServiceConfig {idleTimeoutInSeconds: 10} service {

    resource function onText(http:WebSocketCaller wsEp, string text) {
    }

    resource function onBinary(http:WebSocketCaller wsEp, byte[] data) {
    }

    resource function onPing(http:WebSocketCaller wsEp, byte[] data) {
    }

    resource function onIdleTimeout(http:WebSocketCaller wsEp) {
    }

    resource function onClose(http:WebSocketCaller wsEp, int code, string reason) {
    }

    resource function onError(http:WebSocketCaller wsEp, error err) {
    }
};

service resourceFailureService = @http:WebSocketServiceConfig {} service {

    resource function onError(http:WebSocketClient wsEp, error err) {
        errorMsg = <@untainted>err.message();
    }

    resource function onClose(http:WebSocketClient wsEp, int code, string reason) {
        expectedCode = <@untainted>code;
        expectedReason = <@untainted>reason;
    }
};

// Tests failure of upgrade resource
@test:Config {}
public function testUpgradeResourceFailure() {
    http:WebSocketClient wsClient = new ("ws://localhost:21016/resourceFailue",
        {callbackService: resourceFailureService});
    runtime:sleep(500);
    test:assertEquals(expectedCode, 1011);
    test:assertEquals(expectedReason, "Unexpected condition");
}

// Tests failure of onText resource
@test:Config {}
public function testOnTextResource() {
    http:WebSocketClient wsClient = new ("ws://localhost:21016/resourceFailue?q1=name",
        {callbackService: resourceFailureService});
    runtime:sleep(500);
    test:assertEquals(expectedCode, 1011);
    test:assertEquals(expectedReason, "Unexpected condition");
}

// Tests failure of onBinary resource
@test:Config {}
public function testOnBinaryResource() {
    http:WebSocketClient wsClient = new ("ws://localhost:21016/resourceFailue?q1=name",
        {callbackService: resourceFailureService});
    runtime:sleep(500);
    test:assertEquals(expectedCode, 1011);
    test:assertEquals(expectedReason, "Unexpected condition");
}

// Tests failure of onPing resource
@test:Config {}
public function testOnPingResource() {
    http:WebSocketClient wsClient = new ("ws://localhost:21016/resourceFailue?q1=name",
        {callbackService: resourceFailureService});
    runtime:sleep(500);
    test:assertEquals(expectedCode, 1011);
    test:assertEquals(expectedReason, "Unexpected condition");
}

// Tests failure of onIdleTimeout resource
@test:Config {}
public function testOnIdleTimeoutResource() {
    http:WebSocketClient wsClient = new ("ws://localhost:21016/resourceFailue?q1=name",
        {callbackService: resourceFailureService});
    runtime:sleep(500);
    test:assertEquals(expectedCode, 1011);
    test:assertEquals(expectedReason, "Unexpected condition");
}

// Tests failure of onClose resource
@test:Config {}
public function testOnCloseResource() {
    http:WebSocketClient wsClient = new ("ws://localhost:21016/resourceFailue?q1=name",
        {callbackService: resourceFailureService});
    runtime:sleep(500);
    test:assertEquals(expectedCode, 1011);
    test:assertEquals(expectedReason, "Unexpected condition");
}
