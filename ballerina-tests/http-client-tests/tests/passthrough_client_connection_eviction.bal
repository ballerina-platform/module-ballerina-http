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

listener http:Listener https11BackendListener = new (backend_http11_https_port,
    httpVersion = http:HTTP_1_1,
    secureSocket = {
        'key: {
            certFile: common:CERT_FILE,
            'keyFile: common:KEY_FILE
        }
    }
);

listener http:Listener http11BackendListener = new (backend_http11_http_port, httpVersion = http:HTTP_1_1);

service /api on https11BackendListener, http11BackendListener {
    resource function get path() returns json => {message: "Hello from backend!"};
}

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

http:PoolConfiguration passthroughPoolConfig = {
    maxActiveConnections: 5,
    maxIdleConnections: 2,
    waitTime: 5,
    maxActiveStreamsPerConnection: 2,
    minEvictableIdleTime: 5,
    timeBetweenEvictionRuns: 2
};

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

service /passthrough on passthroughH1Listener, passthroughH1CListener {
    resource function get h1() returns json|error {
        return backendH1Client->/path;
    }

    resource function get h1c() returns json|error {
        return backendH1CClient->/path;
    }
}

final http:Client passthroughH1TestClient = check new (string `https://localhost:${http11_https_passthrough_port}/passthrough`, config = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        cert: common:CERT_FILE
    }
});

final http:Client passthroughH1CTestClient = check new (string `http://localhost:${http11_http_passthrough_port}/passthrough`, config = {
    httpVersion: http:HTTP_1_1
});

@test:Config {
    groups: ["clientConnectionEvictionInPassthrough"]
}
function testConnectionEvictionInH1PassthroughToH1Backend() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check passthroughH1TestClient->/h1;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json response = check passthroughH1TestClient->/h1;
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

    json response = check passthroughH1TestClient->/h1c;
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

    json response = check passthroughH1CTestClient->/h1;
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

    json response = check passthroughH1CTestClient->/h1c;
    test:assertEquals(response, {message: "Hello from backend!"});
}
