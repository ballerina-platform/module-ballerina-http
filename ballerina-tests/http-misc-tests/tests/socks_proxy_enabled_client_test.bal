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

// SOCKS4/SOCKS5 are binary transport-layer protocols, so (unlike the HTTP-proxy test in
// `proxy_enabled_client_test.bal`, which uses a plain Ballerina service as a forward proxy)
// these tests need a real SOCKS proxy server. A Dante SOCKS container and an HTTP backend are
// started from the Gradle build (`startSocksServer`/`stopSocksServer`, see compose.yml under
// resources/socks). The proxy listens on `socksProxyServerTestPort` and relays to the in-compose
// `backend` service; SOCKS5 remote DNS resolves the `backend` host name on the proxy side, so
// the client never resolves it locally.
//
// The proxy runs with no authentication. SOCKS5 username/password auth, SOCKS4 user-id auth, the
// SOCKS4 client-side-DNS path, and TLS are all covered by the native tests
// (Socks4ProxyServerTestCase / Socks5ProxyServerTestCase).

const string SOCKS_BACKEND_URL = "http://backend:5678";
const string SOCKS_BACKEND_RESPONSE = "Backend server sent the response";

// SOCKS5 client routed through the SOCKS proxy to the backend -> expect a successful response.
@test:Config {
    groups: ["disabledOnWindows"]
}
public function testSocks5Client() returns error? {
    http:Client clientEP = check new (SOCKS_BACKEND_URL, {
        proxy: {
            host: "localhost",
            port: socksProxyServerTestPort,
            protocol: http:SOCKS5
        }
    });
    string response = check clientEP->get("/");
    test:assertEquals(response.trim(), SOCKS_BACKEND_RESPONSE);
}

// SOCKS4 does not support password authentication. Setting a password is not a configuration
// error — the password is ignored with a warning log. This test verifies that client creation
// succeeds and no error is returned when a password is provided with SOCKS4.
@test:Config {}
public function testSocks4ClientIgnoresPassword() returns error? {
    http:Client _ = check new (SOCKS_BACKEND_URL, {
        proxy: {
            host: "localhost",
            port: socksProxyServerTestPort,
            userName: "ballerina",
            password: "ballerina",
            protocol: http:SOCKS4
        }
    });
}
