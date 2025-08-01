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
import ballerina/lang.runtime;
import ballerina/test;
import ballerina/http_test_common as common;

// HTTPS listener for H2 tests
listener http:Listener httpsBackendListener = new (backend_https_port, secureSocket = {
    'key: {
        certFile: common:CERT_FILE,
        'keyFile: common:KEY_FILE
    }
});

// HTTP listener for H2C tests
listener http:Listener httpBackendListener = new (backend_http_port);

// HTTP/1.1 HTTPS listener for H1 tests
listener http:Listener https11BackendListener = new (backend_http11_https_port,
    httpVersion = http:HTTP_1_1,
    secureSocket = {
        'key: {
            certFile: common:CERT_FILE,
            'keyFile: common:KEY_FILE
        }
    }
);

// HTTP/1.1 HTTP listener for H1C tests
listener http:Listener http11BackendListener = new (backend_http11_http_port, httpVersion = http:HTTP_1_1);

service /api on httpsBackendListener, httpBackendListener, https11BackendListener, http11BackendListener {
    resource function get path() returns json => {message: "Hello from backend!"};
}

// Passthrough listeners on different ports and protocols
listener http:Listener passthroughH2Listener = new (https_passthrough_port, secureSocket = {
    'key: {
        certFile: common:CERT_FILE,
        'keyFile: common:KEY_FILE
    }
});

listener http:Listener passthroughH2CListener = new (http_passthrough_port);

listener http:Listener passthroughH1Listener = new (http11_https_passthrough_port,
    httpVersion = http:HTTP_1_1,
    secureSocket = {
        'key: {
            certFile: common:CERT_FILE,
            'keyFile: common:KEY_FILE
        }
    }
);

listener http:Listener passthroughH1CListener = new (http11_http_passthrough_port, httpVersion = http:HTTP_1_1);

// Pool configuration for backend clients inside passthrough services
http:PoolConfiguration passthroughPoolConfig = {
    maxActiveConnections: 5,
    maxIdleConnections: 2,
    waitTime: 5,
    maxActiveStreamsPerConnection: 2,
    minEvictableIdleTime: 5,
    timeBetweenEvictionRuns: 2
};

// Clients for passthrough services to connect to backends
final http:Client backendH2Client = check new (string `https://localhost:${backend_https_port}/api`, config = {
    poolConfig: passthroughPoolConfig,
    secureSocket: {
        cert: common:CERT_FILE
    }
});

final http:Client backendH2CClient = check new (string `http://localhost:${backend_http_port}/api`, config = {
    poolConfig: passthroughPoolConfig
});

final http:Client backendH1Client = check new (string `https://localhost:${backend_http11_https_port}/api`, config = {
    httpVersion: http:HTTP_1_1,
    poolConfig: passthroughPoolConfig,
    secureSocket: {
        cert: common:CERT_FILE
    }
});

final http:Client backendH1CClient = check new (string `http://localhost:${backend_http11_http_port}/api`, config = {
    httpVersion: http:HTTP_1_1,
    poolConfig: passthroughPoolConfig
});

// Passthrough service on H2 (HTTPS) connecting to H2 backend
service /passthrough on passthroughH2Listener, passthroughH2CListener, passthroughH1Listener, passthroughH1CListener {
    resource function get h2() returns json|error {
        return backendH2Client->/path;
    }

    resource function get h2c() returns json|error {
        return backendH2CClient->/path;
    }

    resource function get h1() returns json|error {
        return backendH1Client->/path;
    }

    resource function get h1c() returns json|error {
        return backendH1CClient->/path;
    }
}

// Test clients to connect to passthrough services
final http:Client passthroughH2TestClient = check new (string `https://localhost:${https_passthrough_port}/passthrough`, config = {
    secureSocket: {
        cert: common:CERT_FILE
    }
});

final http:Client passthroughH2CTestClient = check new (string `http://localhost:${http_passthrough_port}/passthrough`, config = {});

final http:Client passthroughH1TestClient = check new (string `https://localhost:${http11_https_passthrough_port}/passthrough`, config = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        cert: common:CERT_FILE
    }
});

final http:Client passthroughH1CTestClient = check new (string `http://localhost:${http11_http_passthrough_port}/passthrough`, config = {
    httpVersion: http:HTTP_1_1
});

// Test cases for H2 passthrough service connecting to all backend types
@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH2PassthroughToH2Backend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH2TestClient->/h2;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH2TestClient->/h2;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH2PassthroughToH2CBackend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH2TestClient->/h2c;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH2TestClient->/h2c;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH2PassthroughToH1Backend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH2TestClient->/h1;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH2TestClient->/h1;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH2PassthroughToH1CBackend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH2TestClient->/h1c;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH2TestClient->/h1c;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

// Test cases for H2C passthrough service connecting to all backend types
@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH2CPassthroughToH2Backend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH2CTestClient->/h2;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH2CTestClient->/h2;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH2CPassthroughToH2CBackend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH2CTestClient->/h2c;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH2CTestClient->/h2c;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH2CPassthroughToH1Backend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH2CTestClient->/h1;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH2CTestClient->/h1;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH2CPassthroughToH1CBackend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH2CTestClient->/h1c;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH2CTestClient->/h1c;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

// Test cases for H1 passthrough service connecting to all backend types
@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH1PassthroughToH2Backend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH1TestClient->/h2;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH1TestClient->/h2;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH1PassthroughToH2CBackend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH1TestClient->/h2c;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH1TestClient->/h2c;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH1PassthroughToH1Backend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH1TestClient->/h1;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH1TestClient->/h1;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH1PassthroughToH1CBackend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH1TestClient->/h1c;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH1TestClient->/h1c;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

// Test cases for H1C passthrough service connecting to all backend types
@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH1CPassthroughToH2Backend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH1CTestClient->/h2;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH1CTestClient->/h2;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH1CPassthroughToH2CBackend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH1CTestClient->/h2c;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH1CTestClient->/h2c;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH1CPassthroughToH1Backend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH1CTestClient->/h1;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH1CTestClient->/h1;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH1CPassthroughToH1CBackend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH1CTestClient->/h1c;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = passthroughH1CTestClient->/h1c;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }

    test:assertEquals(response, {message: "Hello from backend!"});
}
