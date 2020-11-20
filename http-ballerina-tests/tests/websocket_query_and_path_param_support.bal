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

final string PATH1 = "PATH1";
final string PATH2 = "PATH2";
final string QUERY1 = "QUERY1";
final string QUERY2 = "QUERY2";
final string textMessage = "Websocket upgrade has been successfully";

service pathQuery on new http:Listener(21015) {

    @http:ResourceConfig {
        webSocketUpgrade: {
            upgradePath: "/{path1}/{path2}",
            upgradeService: simpleProxy6
        }
    }
    resource function websocketProxy(http:Caller httpEp, http:Request req, string path1, string path2) {
        data = <@untainted>textMessage;
    }
}

service simpleProxy6 = @http:WebSocketServiceConfig {} service {
};

service pathQueyCallbackService = @http:WebSocketServiceConfig {} service {

    resource function onText(http:WebSocketClient wsEp, string text) {
        data = <@untainted>text;
    }
};

// Tests path and query parameters support for WebSockets in Ballerina.
@test:Config {}
public function testPathAndQueryParams() {
    http:WebSocketClient wsClient = new ("ws://localhost:21015/pathQuery/" + PATH1 + "/" + PATH2 + "?q1=" + QUERY1 +
        "&q2=" + QUERY2, {callbackService: pathQueyCallbackService});
    runtime:sleep(500);
    test:assertEquals(data, textMessage);
}
