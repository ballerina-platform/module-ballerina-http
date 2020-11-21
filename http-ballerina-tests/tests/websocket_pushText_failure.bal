// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
////www.apache.org/licenses/LICENSE-2.0
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

service pushTextFailureService on new http:Listener(21008) {
    resource function onOpen(http:WebSocketCaller caller) {
        http:WebSocketError? err1 = caller->close(timeoutInSeconds = 0);
        var err = caller->pushText("hey");
        if (err is http:WebSocketError) {
            errorMsg = <@untainted>err.message();
        }
    }
}

// Checks for the log that is printed when pushText fails.
@test:Config {}
public function pushTextFailure() {
    http:WebSocketClient wsClient = new ("ws://localhost:21008/pushTextFailureService");
    runtime:sleep(500);
    test:assertEquals(errorMsg, "ConnectionClosureError: Close frame already sent. Cannot push text data!",
        msg = "Data mismatched");
}
