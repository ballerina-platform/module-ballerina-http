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

listener http:Listener https11Listener = new (http11_https_port,
    httpVersion = http:HTTP_1_1,
    secureSocket = {
        'key: {
            certFile: common:CERT_FILE,
            'keyFile: common:KEY_FILE
        }
    }
);

listener http:Listener http11Listener = new (http11_http_port, httpVersion = http:HTTP_1_1);

service /api on https11Listener, http11Listener {
    resource function get path() returns json => {message: "Hello from backend!"};

    resource function get delay() returns json {
        runtime:sleep(2);
        return {message: "Delayed response"};
    }
}

http:PoolConfiguration poolConfig = {
    maxActiveConnections: 5,
    maxIdleConnections: 2,
    waitTime: 5,
    maxActiveStreamsPerConnection: 2,
    minEvictableIdleTime: 3,
    timeBetweenEvictionRuns: 2
};

final http:Client h1ClientHttps = check new (string`https://localhost:${http11_https_port}/api`, config = {
    httpVersion: http:HTTP_1_1,
    poolConfig: poolConfig,
    secureSocket: {
        cert: common:CERT_FILE
    }
});

final http:Client h1cClient = check new (string`http://localhost:${http11_http_port}/api`, config = {
    httpVersion: http:HTTP_1_1,
    poolConfig: poolConfig
});

@test:Config {
    groups: ["clientConnectionEviction"]
}
function testConnectionEvictionInHttpSecureClient() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check h1ClientHttps->/path;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json response = check h1ClientHttps->/path;
    test:assertEquals(response, {message: "Hello from backend!"});
}

@test:Config {
    groups: ["clientConnectionEviction"]
}
function testConnectionEvictionInHttpClient() returns error? {
    foreach int i in 0 ... 4 {
        json _ = check h1cClient->/path;
        // Wait until the connection becomes IDLE and evicted
        runtime:sleep(5);
    }

    json response = check h1cClient->/path;
    test:assertEquals(response, {message: "Hello from backend!"});
}
