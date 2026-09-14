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
import ballerina/http_test_common as common;

// The test certificate is issued for CN=localhost with no subject alternative names, so reaching the
// same listener over 127.0.0.1 is a host name mismatch. That is what makes verifyHostName observable.

listener http:Listener hostNameVerificationListener = new (hostNameVerificationPort, {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

listener http:Listener http2HostNameVerificationListener = new (http2HostNameVerificationPort, {
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

listener http:Listener certFileHostNameVerificationListener = new (certFileHostNameVerificationPort, {
    httpVersion: http:HTTP_1_1,
    secureSocket: {
        key: {
            certFile: common:CERT_FILE,
            keyFile: common:KEY_FILE
        }
    }
});

service /hostNameVerificationService on hostNameVerificationListener {
    resource function get .() returns string {
        return "Hello from HTTP/1.1!";
    }
}

service /hostNameVerificationService on http2HostNameVerificationListener {
    resource function get .() returns string {
        return "Hello from HTTP/2!";
    }
}

service /hostNameVerificationService on certFileHostNameVerificationListener {
    resource function get .() returns string {
        return "Hello from the cert file listener!";
    }
}

@test:Config {}
public function testHostNameVerificationDisabledWithTrustStore() returns error? {
    http:Client clientEP = check new (string `https://127.0.0.1:${hostNameVerificationPort}`, {
        httpVersion: http:HTTP_1_1,
        secureSocket: {
            cert: {
                path: common:TRUSTSTORE_PATH,
                password: "ballerina"
            },
            verifyHostName: false
        }
    });
    string response = check clientEP->/hostNameVerificationService;
    test:assertEquals(response, "Hello from HTTP/1.1!");
}

@test:Config {}
public function testHostNameVerificationEnabledWithTrustStore() returns error? {
    http:Client clientEP = check new (string `https://127.0.0.1:${hostNameVerificationPort}`, {
        httpVersion: http:HTTP_1_1,
        secureSocket: {
            cert: {
                path: common:TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    string|error response = clientEP->/hostNameVerificationService;
    assertHostNameMismatch(response);
}

@test:Config {}
public function testHostNameVerificationDisabledWithCertFile() returns error? {
    http:Client clientEP = check new (string `https://127.0.0.1:${certFileHostNameVerificationPort}`, {
        httpVersion: http:HTTP_1_1,
        secureSocket: {
            cert: common:CERT_FILE,
            verifyHostName: false
        }
    });
    string response = check clientEP->/hostNameVerificationService;
    test:assertEquals(response, "Hello from the cert file listener!");
}

@test:Config {}
public function testHostNameVerificationEnabledWithCertFile() returns error? {
    http:Client clientEP = check new (string `https://127.0.0.1:${certFileHostNameVerificationPort}`, {
        httpVersion: http:HTTP_1_1,
        secureSocket: {
            cert: common:CERT_FILE
        }
    });
    string|error response = clientEP->/hostNameVerificationService;
    assertHostNameMismatch(response);
}

@test:Config {}
public function testHttp2HostNameVerificationDisabled() returns error? {
    http:Client clientEP = check new (string `https://127.0.0.1:${http2HostNameVerificationPort}`, {
        secureSocket: {
            cert: {
                path: common:TRUSTSTORE_PATH,
                password: "ballerina"
            },
            verifyHostName: false
        }
    });
    string response = check clientEP->/hostNameVerificationService;
    test:assertEquals(response, "Hello from HTTP/2!");
}

@test:Config {}
public function testHttp2HostNameVerificationEnabled() returns error? {
    http:Client clientEP = check new (string `https://127.0.0.1:${http2HostNameVerificationPort}`, {
        secureSocket: {
            cert: {
                path: common:TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    string|error response = clientEP->/hostNameVerificationService;
    assertHostNameMismatchOnOpenSsl(response);

    // Positive control: the only difference is the host name, so the failure above cannot be a trust
    // path, protocol or connectivity problem.
    http:Client matchingHostClientEP = check new (string `https://localhost:${http2HostNameVerificationPort}`, {
        secureSocket: {
            cert: {
                path: common:TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    string matchingHostResponse = check matchingHostClientEP->/hostNameVerificationService;
    test:assertEquals(matchingHostResponse, "Hello from HTTP/2!");
}

// Only a host name verification diagnostic counts as a pass here: a trust-path, protocol or connection
// failure would also satisfy `is error` but would mean the test never exercised verifyHostName.
final readonly & string[] HOST_NAME_MISMATCH_HINTS = [
    "no subject alternative names",
    "no subject alternative dns name",
    "no name matching",
    "hostname verification",
    "host name verification",
    "doesn't match",
    "does not match"
];

final readonly & string[] UNRELATED_FAILURE_HINTS = [
    "unable to find valid certification path",
    "pkix path",
    "certificate expired",
    "certificate chain validation failed",
    "connection refused",
    "connection timeout",
    "could not resolve host",
    "closed the connection"
];

// The HTTP/2 client is pinned to the OpenSSL provider, which reports every handshake rejection as the
// same opaque line, so this only rules out unrelated causes. The paired positive control against the
// matching host name is what proves endpoint identification did the rejecting.
isolated function assertHostNameMismatchOnOpenSsl(string|error response) {
    test:assertTrue(response is error, msg = "Expected the handshake to fail on a host name mismatch");
    if response is error {
        string message = response.message().toLowerAscii();
        foreach string hint in UNRELATED_FAILURE_HINTS {
            if message.includes(hint) {
                test:assertFail(string `Expected a host name verification failure, but got an unrelated failure: ${response.message()}`);
            }
        }
    }
}

isolated function assertHostNameMismatch(string|error response) {
    test:assertTrue(response is error, msg = "Expected the handshake to fail on a host name mismatch");
    if response is error {
        string message = response.message().toLowerAscii();
        foreach string hint in HOST_NAME_MISMATCH_HINTS {
            if message.includes(hint) {
                return;
            }
        }
        foreach string hint in UNRELATED_FAILURE_HINTS {
            if message.includes(hint) {
                test:assertFail(string `Expected a host name verification failure, but got an unrelated failure: ${response.message()}`);
            }
        }
        test:assertFail(string `Expected a host name verification failure, but got: ${response.message()}`);
    }
}
