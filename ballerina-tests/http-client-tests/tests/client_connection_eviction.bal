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
listener http:Listener httpsListener = new (https_port, secureSocket = {
    'key: {
        certFile: common:CERT_FILE,
        'keyFile: common:KEY_FILE
    }
});

// HTTP listener for H2C tests
listener http:Listener httpListener = new (http_port);

// HTTP/1.1 HTTPS listener for H1 tests
listener http:Listener https11Listener = new (http11_https_port,
    httpVersion = http:HTTP_1_1,
    secureSocket = {
        'key: {
            certFile: common:CERT_FILE,
            'keyFile: common:KEY_FILE
        }
    }
);

// HTTP/1.1 HTTP listener for H1C tests
listener http:Listener http11Listener = new (http11_http_port, httpVersion = http:HTTP_1_1);

service /api on httpsListener, httpListener, https11Listener, http11Listener {
    resource function get path() returns json => {message: "Hello from backend!"};
}

// Common pool configuration for all tests
http:PoolConfiguration poolConfig = {
    maxActiveConnections: 5,
    maxIdleConnections: 2,
    waitTime: 5,
    maxActiveStreamsPerConnection: 2,
    minEvictableIdleTime: 3,
    timeBetweenEvictionRuns: 2
};

// H2 client -> H2 server (HTTPS)
final http:Client h2ClientHttps = check new (string`https://localhost:${https_port}/api`, config = {
    poolConfig: poolConfig,
    secureSocket: {
        cert: common:CERT_FILE
    }
});

// H2C client -> H2C server (HTTP)
final http:Client h2cClient = check new (string`http://localhost:${http_port}/api`, config = {
    poolConfig: poolConfig
});

// H1 client -> H1 server (HTTPS)
final http:Client h1ClientHttps = check new (string`https://localhost:${http11_https_port}/api`, config = {
    httpVersion: http:HTTP_1_1,
    poolConfig: poolConfig,
    secureSocket: {
        cert: common:CERT_FILE
    }
});

// H1C client -> H1C server (HTTP)
final http:Client h1cClient = check new (string`http://localhost:${http11_http_port}/api`, config = {
    httpVersion: http:HTTP_1_1,
    poolConfig: poolConfig
});

@test:Config {
    groups: ["clientConnectionEviction"]
}
function testConnectionEvictionInClientH2H2Scenario() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check h2ClientHttps->/path;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = h2ClientHttps->/path;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }
    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEviction"]
}
function testConnectionEvictionInClientH2CH2CScenario() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check h2cClient->/path;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = h2cClient->/path;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }
    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEviction"]
}
function testConnectionEvictionInClientH1H1Scenario() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check h1ClientHttps->/path;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = h1ClientHttps->/path;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }
    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEviction"]
}
function testConnectionEvictionInClientH1CH1CScenario() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check h1cClient->/path;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json|error response = h1cClient->/path;
    if response is error {
        test:assertFail("Expected a successful response, but got an error: " + response.message());
    }
    test:assertEquals(response, {message: "Hello from backend!"});
}
