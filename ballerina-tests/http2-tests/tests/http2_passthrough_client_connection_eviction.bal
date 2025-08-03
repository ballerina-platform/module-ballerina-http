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

listener http:Listener httpsBackendListener = new (backend_https_port, secureSocket = {
    'key: {
        certFile: common:CERT_FILE,
        'keyFile: common:KEY_FILE
    }
});

listener http:Listener httpBackendListener = new (backend_http_port);

service /api on httpsBackendListener, httpBackendListener {
    resource function get path() returns json => {message: "Hello from backend!"};
}

listener http:Listener passthroughH2Listener = new (https_passthrough_port, secureSocket = {
    'key: {
        certFile: common:CERT_FILE,
        'keyFile: common:KEY_FILE
    }
});

listener http:Listener passthroughH2CListener = new (http_passthrough_port);

http:PoolConfiguration passthroughPoolConfig = {
    maxActiveConnections: 5,
    maxIdleConnections: 2,
    waitTime: 5,
    maxActiveStreamsPerConnection: 2,
    minEvictableIdleTime: 5,
    timeBetweenEvictionRuns: 2
};

final http:Client backendH2Client = check new (string `https://localhost:${backend_https_port}/api`, config = {
    poolConfig: passthroughPoolConfig,
    secureSocket: {
        cert: common:CERT_FILE
    }
});

final http:Client backendH2CClient = check new (string `http://localhost:${backend_http_port}/api`, config = {
    poolConfig: passthroughPoolConfig
});

service /passthrough on passthroughH2Listener, passthroughH2CListener {
    resource function get h2() returns json|error {
        return backendH2Client->/path;
    }

    resource function get h2c() returns json|error {
        return backendH2CClient->/path;
    }
}

final http:Client passthroughH2TestClient = check new (string `https://localhost:${https_passthrough_port}/passthrough`, config = {
    secureSocket: {
        cert: common:CERT_FILE
    }
});

final http:Client passthroughH2CTestClient = check new (string `http://localhost:${http_passthrough_port}/passthrough`, config = {});

@test:Config {
    groups: ["http2ClientConnectionEvictionInPassthrough"]
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
    groups: ["http2ClientConnectionEvictionInPassthrough"]
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
    groups: ["http2ClientConnectionEvictionInPassthrough"]
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
    groups: ["http2ClientConnectionEvictionInPassthrough"]
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
