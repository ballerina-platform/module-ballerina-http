// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.com).
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
import ballerina/jballerina.java;
import ballerina/lang.'string as strings;
import ballerina/test;
import ballerina/http_test_common as common;

http:ListenerConfiguration sslProtocol12ServiceConfig = {
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
    http:Client clientEP = check new (string `https://localhost:${tls12Port}`, secureSocket = sslConfig);
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
    http:Client clientEP = check new (string `https://localhost:${tls13Port}`, secureSocket = sslConfig);
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
    http:Client clientEP = check new (string `https://localhost:${tls13Port}`, secureSocket = sslConfig);
    string resp = check clientEP->/protocol/protocolResource;
    test:assertEquals(resp, "Hello, World!");

    sslConfig.protocol.versions = ["TLSv1.3", "TLSv1.2"];
    clientEP = check new (string `https://localhost:${tls12Port}`, secureSocket = sslConfig);
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
    http:Client clientEP = check new (string `https://localhost:${tls13Port}`, secureSocket = sslConfig);
    http:Response|error resp = clientEP->/protocol/protocolResource;
    if resp is http:Response {
        test:assertFail(msg = "Found unexpected output: Expected an error");
    } else {
        assertProtocolMismatchError(resp.message());
    }

    sslConfig.protocol.versions = ["TLSv1.3"];
    clientEP = check new (string `https://localhost:${tls12Port}`, secureSocket = sslConfig);
    resp = clientEP->/protocol/protocolResource;
    if resp is http:Response {
        test:assertFail(msg = "Found unexpected output: Expected an error");
    } else {
        assertProtocolMismatchError(resp.message());
    }
}

isolated function assertProtocolMismatchError(string message) {
    // On Windows the server's reset can reach the client before the TLS alert, which surfaces as a generic error.
    boolean genericErrorOnWindows = isWindows() && strings:includes(message, "Something wrong with the connection");
    test:assertTrue(strings:includes(message, "SSL connection failed") || genericErrorOnWindows, msg = message);
}

isolated function isWindows() returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.Platform"
} external;

