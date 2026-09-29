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
import ballerina/io;

// The SOCKS proxy server to tunnel the HTTP traffic through.
configurable string proxyHost = "localhost";
configurable int proxyPort = 1080;

// Credentials for the SOCKS5 proxy. SOCKS5 supports username/password
// authentication, so these are sent to the proxy during the handshake.
// (SOCKS4 does not support password authentication.)
configurable string proxyUser = "ballerina";
configurable string proxyPassword = "ballerina";

public function main() returns error? {

    // Configure an `http:Client` to route all requests through a SOCKS5 proxy.
    // The proxy is set via the top-level `proxy` field with `protocol: http:SOCKS5`.
    //
    // With SOCKS5, DNS resolution of the target host is performed remotely
    // (on the proxy side), so the destination host name is sent to the proxy
    // as-is and resolved there.
    final http:Client httpbin = check new ("https://httpbin.org", {
        proxy: {
            host: proxyHost,
            port: proxyPort,
            userName: proxyUser,
            password: proxyPassword,
            protocol: http:SOCKS5
        }
    });

    // The request is sent through the SOCKS5 proxy. From the perspective of
    // the application code, the call is identical to any other HTTP request.
    json response = check httpbin->get("/ip");
    io:println("Response received through the SOCKS5 proxy: ", response);
}
