// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// under the License.package http2;

import ballerina/http;
import ballerina/test;
import ballerina/http_test_common as common;

listener http:Listener generalSSLListener = new (httpSslGeneralPort, {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

final http:Client fallbackClient = check new ("http://localhost:" + generalPort.toString());
final http:Client fallbackSslClient = check new ("https://localhost:" + httpSslGeneralPort.toString(), http2SslClientConf1);
const string version_1_1 = "Version: 1.1";

service /helloWorldWithoutSSL on generalListener {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Version: " + req.httpVersion);
    }
}

service /helloWorldWithSSL on generalSSLListener {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        check caller->respond("Version: " + req.httpVersion);
    }
}

@test:Config {}
public function testClientFallbackFromH2ToH1() returns error? {
    string payload = check fallbackClient->get("/helloWorldWithoutSSL");
    test:assertEquals(payload, version_1_1, msg = "Found unexpected output");

    payload = check fallbackClient->get("/helloWorldWithoutSSL");
    test:assertEquals(payload, version_1_1, msg = "Found unexpected output");
}

// TODO disabled due to https://github.com/ballerina-platform/ballerina-standard-library/issues/3250
@test:Config {enable: false}
public function testSslClientFallbackFromH2ToH1() returns error? {
    string payload = check fallbackSslClient->get("/helloWorldWithSSL");
    test:assertEquals(payload, version_1_1, msg = "Found unexpected output");
}

// TODO disabled due to https://github.com/ballerina-platform/ballerina-standard-library/issues/3250
@test:Config {enable: false, dependsOn: [testSslClientFallbackFromH2ToH1]}
public function testSslClientFallbackFromH2ToH1Subsequent() returns error? {
    string payload = check fallbackSslClient->get("/helloWorldWithSSL");
    test:assertEquals(payload, version_1_1, msg = "Found unexpected output");
}
