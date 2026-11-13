// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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
import ballerina/http_test_common as common;
import ballerina/jballerina.java;
import ballerina/lang.runtime;
import ballerina/test;

const int tlsCertValidationPort = 21001;
const int tlsShareSessionH1Port = 21002;
const int tlsShareSessionH2Port = 21003;
const int tlsNamedGroupsPort = 21004;
const int tlsPipeliningPort = 21005;

isolated function sysProp(handle key) returns handle? = @java:Method {
    'class: "java.lang.System",
    name: "getProperty"
} external;

isolated function sendRawAndReadAll(int port, boolean tls, string rawRequest, int expectedResponses)
        returns string|error = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternListenerTestUtil"
} external;

listener http:Listener tlsShareSessionH1Listener = new (tlsShareSessionH1Port, httpVersion = http:HTTP_1_1,
    secureSocket = {key: {path: common:KEYSTORE_PATH, password: "ballerina"}, shareSession: false});

listener http:Listener tlsShareSessionH2Listener = new (tlsShareSessionH2Port,
    secureSocket = {key: {path: common:KEYSTORE_PATH, password: "ballerina"}, shareSession: false});

service /shareSession on tlsShareSessionH1Listener, tlsShareSessionH2Listener {
    resource function get hello() returns string => "hello";
}

listener http:Listener tlsPipeliningListener = new (tlsPipeliningPort, httpVersion = http:HTTP_1_1,
    secureSocket = {key: {path: common:KEYSTORE_PATH, password: "ballerina"}});

service /tlsPipelining on tlsPipeliningListener {
    resource function get slow(decimal s = 0) returns string {
        runtime:sleep(s);
        return "slept " + s.toString();
    }
}

final http:ClientSecureSocket tlsSettingsClientSocket = {
    cert: {path: common:TRUSTSTORE_PATH, password: "ballerina"}
};

@test:Config {groups: ["tlsListenerSettings"]}
function testCertValidationOnListenerAndClient() returns error? {
    // OCSP_CRL validates the client certificate, so a listener needs mutualSsl and an HTTP/1.1 listener.
    http:Listener|error l = new (tlsCertValidationPort, httpVersion = http:HTTP_1_1, secureSocket = {
        key: {path: common:KEYSTORE_PATH, password: "ballerina"},
        mutualSsl: {verifyClient: http:REQUIRE, cert: {path: common:TRUSTSTORE_PATH, password: "ballerina"}},
        certValidation: {'type: http:OCSP_CRL, cacheSize: 0, cacheValidityPeriod: 0}
    });
    test:assertTrue(l is http:Listener, "listener with certValidation failed to initialize: " +
        (l is error ? l.message() : ""));
    http:Client|error c = new ("https://localhost:" + tlsCertValidationPort.toString(), secureSocket = {
        cert: {path: common:TRUSTSTORE_PATH, password: "ballerina"},
        certValidation: {'type: http:OCSP_CRL, cacheSize: 10, cacheValidityPeriod: 10}
    });
    test:assertTrue(c is http:Client, "client with certValidation failed to initialize: " +
        (c is error ? c.message() : ""));
}

@test:Config {groups: ["tlsListenerSettings"]}
function testUnsupportedListenerCertValidationIsRejected() {
    // OCSP_STAPLING is not supported on a listener.
    http:Listener|error stapling = new (tlsCertValidationPort + 10, httpVersion = http:HTTP_1_1, secureSocket = {
        key: {path: common:KEYSTORE_PATH, password: "ballerina"},
        certValidation: {'type: http:OCSP_STAPLING, cacheSize: 0, cacheValidityPeriod: 0}
    });
    test:assertTrue(stapling is error, "OCSP_STAPLING on a listener must be rejected");
    // OCSP_CRL without mutualSsl would fail every handshake.
    http:Listener|error noMutual = new (tlsCertValidationPort + 11, httpVersion = http:HTTP_1_1, secureSocket = {
        key: {path: common:KEYSTORE_PATH, password: "ballerina"},
        certValidation: {'type: http:OCSP_CRL, cacheSize: 0, cacheValidityPeriod: 0}
    });
    test:assertTrue(noMutual is error, "OCSP_CRL without mutualSsl must be rejected");
    // The HTTP/2 listener does not apply OCSP_CRL.
    http:Listener|error h2 = new (tlsCertValidationPort + 12, secureSocket = {
        key: {path: common:KEYSTORE_PATH, password: "ballerina"},
        mutualSsl: {verifyClient: http:REQUIRE, cert: {path: common:TRUSTSTORE_PATH, password: "ballerina"}},
        certValidation: {'type: http:OCSP_CRL, cacheSize: 0, cacheValidityPeriod: 0}
    });
    test:assertTrue(h2 is error, "OCSP_CRL on an HTTP/2 listener must be rejected");
}

@test:Config {groups: ["tlsListenerSettings"]}
function testShareSessionFalseHttp1() returns error? {
    http:Client c = check new ("https://localhost:" + tlsShareSessionH1Port.toString(),
        httpVersion = http:HTTP_1_1, secureSocket = tlsSettingsClientSocket);
    string r = check c->get("/shareSession/hello");
    test:assertEquals(r, "hello");
    // A second connection also completes the handshake.
    http:Client c2 = check new ("https://localhost:" + tlsShareSessionH1Port.toString(),
        httpVersion = http:HTTP_1_1, secureSocket = tlsSettingsClientSocket);
    string r2 = check c2->get("/shareSession/hello");
    test:assertEquals(r2, "hello");
}

@test:Config {groups: ["tlsListenerSettings"]}
function testShareSessionFalseHttp2() returns error? {
    http:Client c = check new ("https://localhost:" + tlsShareSessionH2Port.toString(),
        secureSocket = tlsSettingsClientSocket);
    string r = check c->get("/shareSession/hello");
    test:assertEquals(r, "hello");
}

@test:Config {groups: ["tlsListenerSettings"]}
function testProtocolConfigDoesNotSetNamedGroupsSystemProperty() returns error? {
    http:Listener _ = check new (tlsNamedGroupsPort, secureSocket = {
        key: {path: common:KEYSTORE_PATH, password: "ballerina"},
        protocol: {name: http:TLS, versions: ["TLSv1.2"]}
    });
    test:assertTrue(sysProp(java:fromString("jdk.tls.namedGroups")) is (),
        "jdk.tls.namedGroups must not be set by a listener configuration");
}

@test:Config {groups: ["tlsListenerSettings"]}
function testPipelinedResponseOrderOnTlsListener() returns error? {
    string request = "GET /tlsPipelining/slow?s=2 HTTP/1.1\r\nHost: localhost\r\n\r\n" +
        "GET /tlsPipelining/slow?s=0 HTTP/1.1\r\nHost: localhost\r\n\r\n";
    string response = check sendRawAndReadAll(tlsPipeliningPort, true, request, 2);
    int? first = response.indexOf("slept 2");
    int? second = response.indexOf("slept 0");
    test:assertTrue(first is int && second is int, "both responses are expected, got: " + response);
    test:assertTrue((<int>first) < (<int>second), "responses must be returned in the request order: " + response);
}
