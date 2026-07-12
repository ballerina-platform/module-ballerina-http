// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com).
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
import ballerina/test;

// End-to-end test: an `http:Client` reaches a backend through a real SOCKS5 proxy. The proxy
// (Dante) and the backend (http-echo) are started from the Gradle build as a docker compose
// stack (startSocksServer/stopSocksServer; see tests/resources/socks/compose.yml). SOCKS5 remote
// DNS resolves the in-compose `backend` service name on the proxy side, so the client never
// resolves it locally. SOCKS4, proxy authentication, and TLS are covered by the native tests.

const int SOCKS5_PROXY_PORT = 9913;
const string SOCKS_BACKEND_URL = "http://backend:5678";
const string SOCKS_BACKEND_RESPONSE = "Response from backend through SOCKS proxy";

@test:Config {
    groups: ["disabledOnWindows"]
}
function testSocks5ProxyOverHttp() returns error? {
    http:Client clientEP = check new (SOCKS_BACKEND_URL, {
        proxy: {
            host: "localhost",
            port: SOCKS5_PROXY_PORT,
            protocol: http:SOCKS5
        }
    });
    string response = check clientEP->get("/");
    test:assertEquals(response.trim(), SOCKS_BACKEND_RESPONSE);
}
