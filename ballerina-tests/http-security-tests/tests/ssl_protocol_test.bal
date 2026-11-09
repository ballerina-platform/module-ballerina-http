// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// under the License.

import ballerina/http;
import ballerina/lang.'string as strings;
import ballerina/test;
import ballerina/http_test_common as common;

http:ListenerConfiguration sslProtocol12ServiceConfig = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        },
        protocol: {
            name: http:TLS,
            versions: ["TLSv1.2"]
        }
    }
};

listener http:Listener sslProtocol12Listener = new (tls12Port, config = sslProtocol12ServiceConfig);

service /protocol on sslProtocol12Listener {

    resource function get protocolResource() returns string {
        return "Hello, World!";
    }
}

http:ListenerConfiguration sslProtocol13ServiceConfig = {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        },
        protocol: {
            name: http:TLS,
            versions: ["TLSv1.3"]
        }
    }
};

listener http:Listener sslProtocol13Listener = new (tls13Port, config = sslProtocol13ServiceConfig);

service /protocol on sslProtocol13Listener {

    resource function get protocolResource() returns string {
        return "Hello, World!";
    }
}

final readonly & http:ClientSecureSocket sslProtocolClientConfig = {
    cert: {
        path: common:TRUSTSTORE_PATH,
        password: "ballerina"
    }
};

@test:Config {}
function testTLS12() returns error? {
    http:ClientSecureSocket sslConfig = {...sslProtocolClientConfig};
    sslConfig.protocol = {
        name: http:TLS,
        versions: ["TLSv1.2"]
    };
    http:Client clientEP = check new (string `https://localhost:${tls12Port}`, secureSocket = sslConfig, httpVersion = http:HTTP_1_1);
    string resp = check clientEP->/protocol/protocolResource;
    test:assertEquals(resp, "Hello, World!");
}

@test:Config {}
function testTLS13() returns error? {
    http:ClientSecureSocket sslConfig = {...sslProtocolClientConfig};
    sslConfig.protocol = {
        name: http:TLS,
        versions: ["TLSv1.3"]
    };
    http:Client clientEP = check new (string `https://localhost:${tls13Port}`, secureSocket = sslConfig, httpVersion = http:HTTP_1_1);
    string resp = check clientEP->/protocol/protocolResource;
    test:assertEquals(resp, "Hello, World!");
}

@test:Config {}
function testSslProtocol() returns error? {
    http:ClientSecureSocket sslConfig = {...sslProtocolClientConfig};
    sslConfig.protocol = {
        name: http:TLS,
        versions: ["TLSv1.2", "TLSv1.3"]
    };
    http:Client clientEP = check new (string `https://localhost:${tls13Port}`, secureSocket = sslConfig, httpVersion = http:HTTP_1_1);
    string resp = check clientEP->/protocol/protocolResource;
    test:assertEquals(resp, "Hello, World!");

    sslConfig.protocol.versions = ["TLSv1.3", "TLSv1.2"];
    clientEP = check new (string `https://localhost:${tls12Port}`, secureSocket = sslConfig, httpVersion = http:HTTP_1_1);
    resp = check clientEP->/protocol/protocolResource;
    test:assertEquals(resp, "Hello, World!");
}

@test:Config {}
function testSslProtocolConflict() returns error? {
    http:ClientSecureSocket sslConfig = {...sslProtocolClientConfig};
    sslConfig.protocol = {
        name: http:TLS,
        versions: ["TLSv1.2"]
    };
    http:Client clientEP = check new (string `https://localhost:${tls13Port}`, secureSocket = sslConfig, httpVersion = http:HTTP_1_1);
    http:Response|error resp = clientEP->/protocol/protocolResource;
    if resp is http:Response {
        test:assertFail(msg = "Found unexpected output: Expected an error");
    } else {
        test:assertTrue(strings:includes(resp.message(), "SSL connection failed"));
    }

    sslConfig.protocol.versions = ["TLSv1.3"];
    clientEP = check new (string `https://localhost:${tls12Port}`, secureSocket = sslConfig, httpVersion = http:HTTP_1_1);
    resp = clientEP->/protocol/protocolResource;
    if resp is http:Response {
        test:assertFail(msg = "Found unexpected output: Expected an error");
    } else {
        test:assertTrue(strings:includes(resp.message(), "SSL connection failed"));
    }
}
