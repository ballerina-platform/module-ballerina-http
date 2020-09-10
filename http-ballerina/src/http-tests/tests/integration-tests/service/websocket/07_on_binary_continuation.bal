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
import http;

byte[] content = [];
@http:WebSocketServiceConfig {
    path: "/onBinaryContinuation"
}
service onBinaryContinuation on new http:Listener(21007) {
    resource function onBinary(http:WebSocketCaller caller, byte[] data, boolean finalFrame) {
        var returnVal = caller->pushBinary(data);
        if (returnVal is http:WebSocketError) {
            panic <error>returnVal;
        }
    }
}

service continuationService = @http:WebSocketServiceConfig {} service {

    resource function onBinary(http:WebSocketClient caller, byte[] data, boolean finalFrame) {
        expectedBinaryData = <@untainted>data;
    }
};

// Tests binary continuation frame
@test:Config {}
public function testBinaryContinuation() {
    string msg = "<note><to>Tove</to></note>";
    byte[] data = msg.toBytes();
    http:WebSocketClient wsClient = new ("ws://localhost:21007/onBinaryContinuation",
        {callbackService: continuationService});
    checkpanic wsClient->pushBinary(data, true);
    runtime:sleep(500);
    test:assertEquals(expectedBinaryData, data, msg = "Data mismatched");
    checkpanic wsClient->close(statusCode = 1000, reason = "Close the connection");
}
