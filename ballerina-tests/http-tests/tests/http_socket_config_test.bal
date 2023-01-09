// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/test;

listener http:Listener socketConfigListener = new (socketConfigListenerPort,
    httpVersion = http:HTTP_1_1,
    socketConfig = {
    soBackLog: 100,
    connectTimeOut: 15,
    receiveBufferSize: 1048576,
    sendBufferSize: 1048576,
    tcpNoDelay: true,
    socketReuse: false,
    keepAlive: true
});

final http:Client socketConfigClient = check new ("http://localhost:" + socketConfigListenerPort.toString(),
    httpVersion = http:HTTP_1_1,
    socketConfig = {
    connectTimeOut: 15,
    receiveBufferSize: 1048576,
    sendBufferSize: 1048576,
    tcpNoDelay: true,
    socketReuse: false,
    keepAlive: true
}
);

service /serviceTestPort1 on socketConfigListener {
    resource function get .() returns string {
        return "Success";
    }
}

@test:Config {}
function testSocketConfig() returns error? {
    string payload = check socketConfigClient->get("/serviceTestPort1");
    test:assertEquals(payload, "Success", msg = "Found unexpected output");
}
