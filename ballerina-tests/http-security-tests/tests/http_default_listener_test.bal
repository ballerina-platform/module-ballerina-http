// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerina/http_test_common as common;
import ballerina/http_test_common.service1 as _;
import ballerina/http_test_common.service2 as _;
import ballerina/test;

listener http:Listener defaultListener = http:getDefaultListener();

service /api/v3 on defaultListener {

    resource function get greeting() returns string {
        return "Hello, World from service 3!";
    }
}

service /api/v4 on defaultListener {

    resource function get greeting() returns string {
        return "Hello, World from service 4!";
    }
}

listener http:Listener defaultListenerNew = http:getDefaultListener();

service /api/v5 on defaultListenerNew {

    resource function get greeting() returns string {
        return "Hello, World from service 5!";
    }
}

final http:Client defaultListenerClient = check new(string `localhost:${http:defaultListenerPort}/api`,
    secureSocket = {
        cert: {
            path: common:TRUSTSTORE_PATH,
            password: "ballerina"
        }
    },
    httpVersion = "1.1"
);

@test:Config {}
function testDefaultListenerWithConfiguration() returns error? {
    foreach int i in 1...5 {
        string response = check defaultListenerClient->/[string `v${i}`]/greeting;
        test:assertEquals(response, string `Hello, World from service ${i}!`);
    }
}
