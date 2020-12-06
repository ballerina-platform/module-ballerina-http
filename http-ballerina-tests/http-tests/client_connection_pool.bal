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

import ballerina/test;
import ballerina/http;

http:PoolConfiguration sharedPoolConfig = {};

@test:Config {}
function testGlobalPoolConfig() {
    http:Client httpClient1 = new("http://localhost:8080");
    http:Client httpClient2 = new("http://localhost:8080");
    http:Client httpClient3 = new("http://localhost:8081");
    http:Client[] clients = [httpClient1, httpClient2, httpClient3];
    test:assertEquals(clients.length(), 3);
    test:assertEquals(clients[0].config.poolConfig.toString(), "");
    test:assertEquals(clients[1].config.poolConfig.toString(), "");
    test:assertEquals(clients[2].config.poolConfig.toString(), "");
}

@test:Config {}
function testSharedConfig() {
    http:Client httpClient1 = new("http://localhost:8080", { poolConfig: sharedPoolConfig });
    http:Client httpClient2 = new("http://localhost:8080", { poolConfig: sharedPoolConfig });
    http:Client[] clients = [httpClient1, httpClient2];
    test:assertEquals(clients.length(), 2);
    test:assertEquals(clients[0].config.poolConfig, clients[1].config.poolConfig,
                      msg = "Both the clients should have same connection manager");
}

@test:Config {}
function testPoolPerClient() {
    http:Client httpClient1 = new("http://localhost:8080", { poolConfig: { maxActiveConnections: 50 } });
    http:Client httpClient2 = new("http://localhost:8080", { poolConfig: { maxActiveConnections: 25 } });
    http:Client[] clients = [httpClient1, httpClient2];
    test:assertEquals(clients.length(), 2);
    test:assertNotEquals(clients[0].config.poolConfig, clients[1].config.poolConfig,
                         msg = "Both the clients should have their own connection manager");
}
