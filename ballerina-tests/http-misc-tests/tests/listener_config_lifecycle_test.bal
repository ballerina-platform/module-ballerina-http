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
import ballerina/jballerina.java;
import ballerina/lang.runtime;
import ballerina/test;
import ballerina/time;

const int listenerCfgKeepAliveH2Port = 21101;
const int listenerCfgKeepAliveH10Port = 21102;
const int listenerCfgGracefulPort = 21103;
const int listenerCfgDuplicatePort = 21104;
const int listenerCfgPipelineLimitPort = 21105;
const int listenerCfgPipelineLimit2Port = 21106;
const int listenerCfgRepeatPort = 21107;

@test:Config {groups: ["listenerLifecycle"]}
function testRepeatedSecondListenerOnUsedPortKeepsFirstListenerServing() returns error? {
    // The failed bind completes on another thread, so the scenario is repeated to catch a race between the
    // roll-back of the failed start and the state the second start() hands back.
    http:Listener first = check new (listenerCfgRepeatPort, httpVersion = http:HTTP_1_1);
    check first.attach(new ListenerCfgService(), "/a");
    check first.'start();
    http:Client c = check new ("http://localhost:" + listenerCfgRepeatPort.toString(), httpVersion = http:HTTP_1_1);
    foreach int i in 0 ..< 50 {
        http:Listener second = check new (listenerCfgRepeatPort, httpVersion = http:HTTP_1_1);
        check second.attach(new ListenerCfgService(), "/b");
        error? startResult = trap second.'start();
        test:assertTrue(startResult is error, "iteration " + i.toString() + ": second start() must fail");
        http:Response r = check c->get("/a/hello");
        test:assertEquals(r.statusCode, 200, "iteration " + i.toString() + ": first listener must keep serving");
    }
    check first.gracefulStop();
}

@test:Config {groups: ["listenerConfig"]}
function testHttp2SettingsAreNotValidatedForHttp1Listeners() {
    test:assertTrue(new http:Listener(21120, httpVersion = http:HTTP_1_1, http2InitialWindowSize = -5,
        http2MaxActiveStreams = 0) is http:Listener);
}

isolated function sendRawAndReadAll(int port, boolean tls, string rawRequest, int expectedResponses)
        returns string|error = @java:Method {
    'class: "io.ballerina.stdlib.http.testutils.ExternListenerTestUtil"
} external;

service class ListenerCfgService {
    *http:Service;
    resource function get hello() returns string => "hello";
    resource function get slow(decimal s = 0) returns string {
        runtime:sleep(s);
        return "slept " + s.toString();
    }
}

// The default httpVersion (HTTP_2_0) serves HTTP/1.1 requests too; the HTTP/1.x settings apply to them.
listener http:Listener listenerCfgKeepAliveH2Listener = new (listenerCfgKeepAliveH2Port,
    http1Settings = {keepAlive: http:KEEPALIVE_NEVER});

listener http:Listener listenerCfgKeepAliveH10Listener = new (listenerCfgKeepAliveH10Port,
    httpVersion = http:HTTP_1_0, http1Settings = {keepAlive: http:KEEPALIVE_NEVER});

listener http:Listener listenerCfgPipelineLimitListener = new (listenerCfgPipelineLimitPort,
    http1Settings = {maxPipelinedRequests: 3});

listener http:Listener listenerCfgPipelineLimit2Listener = new (listenerCfgPipelineLimit2Port,
    httpVersion = http:HTTP_1_1, http1Settings = {maxPipelinedRequests: 2});

service /cfg on listenerCfgKeepAliveH2Listener, listenerCfgKeepAliveH10Listener,
        listenerCfgPipelineLimitListener, listenerCfgPipelineLimit2Listener {
    resource function get hello() returns string => "hello";
    resource function get slow(decimal s = 0) returns string {
        runtime:sleep(s);
        return "slept " + s.toString();
    }
}

@test:Config {groups: ["listenerConfig"]}
function testHttp1SettingsApplyWithDefaultHttpVersion() returns error? {
    string response = check sendRawAndReadAll(listenerCfgKeepAliveH2Port, false,
        "GET /cfg/hello HTTP/1.1\r\nHost: localhost\r\n\r\n", 1);
    test:assertTrue(response.toLowerAscii().includes("connection: close"),
        "keepAlive NEVER must close the connection on a default listener: " + response);
}

@test:Config {groups: ["listenerConfig"]}
function testHttp1SettingsApplyWithHttp10() returns error? {
    string response = check sendRawAndReadAll(listenerCfgKeepAliveH10Port, false,
        "GET /cfg/hello HTTP/1.1\r\nHost: localhost\r\n\r\n", 1);
    test:assertTrue(response.toLowerAscii().includes("connection: close"),
        "keepAlive NEVER must close the connection on an HTTP_1_0 listener: " + response);
}

@test:Config {groups: ["listenerConfig"]}
function testMaxPipelinedRequestsApplyWithDefaultHttpVersion() returns error? {
    string requests = "";
    foreach int i in 0 ..< 3 {
        requests += "GET /cfg/slow?s=" + (i == 0 ? "1" : "0") + " HTTP/1.1\r\nHost: localhost\r\n\r\n";
    }
    string response = check sendRawAndReadAll(listenerCfgPipelineLimitPort, false, requests, 3);
    int count = re `HTTP/1\.1 200`.split(response).length() - 1;
    // Three pipelined requests are within the configured limit of 3, so all three are answered.
    test:assertEquals(count, 3, "all three pipelined requests must be answered: " + response);
}

@test:Config {groups: ["listenerConfig"]}
function testConnectionClosedWhenPipelinedRequestsReachTheLimit() returns error? {
    string requests = "GET /cfg/slow?s=1 HTTP/1.1\r\nHost: localhost\r\n\r\n" +
        "GET /cfg/slow?s=1 HTTP/1.1\r\nHost: localhost\r\n\r\n" +
        "GET /cfg/slow?s=0 HTTP/1.1\r\nHost: localhost\r\n\r\n";
    string response = check sendRawAndReadAll(listenerCfgPipelineLimit2Port, false, requests, 3);
    int count = re `HTTP/1\.1 200`.split(response).length() - 1;
    // The third request arrives while two requests are not yet responded to, so the connection is closed.
    test:assertTrue(count < 3, "the connection must be closed when maxPipelinedRequests is reached: " + response);
}

@test:Config {groups: ["listenerConfig"]}
function testListenerPortRange() {
    foreach int port in [0, -1, -65535, 65536, 70000] {
        http:Listener|error l = new (port);
        test:assertTrue(l is error, "port " + port.toString() + " must be rejected");
        if l is error {
            test:assertTrue(l.message().length() > 0);
        }
    }
    foreach int port in [1, 65535] {
        http:Listener|error l = new (port);
        test:assertTrue(l is http:Listener, "port " + port.toString() + " must be accepted");
    }
}

@test:Config {groups: ["listenerConfig"]}
function testInvalidHttp2SettingsAreRejected() {
    test:assertTrue(new http:Listener(21110, http2InitialWindowSize = -5) is error);
    test:assertTrue(new http:Listener(21114, http2InitialWindowSize = 0) is error);
    test:assertTrue(new http:Listener(21111, http2MaxActiveStreams = 0) is error);
    test:assertTrue(new http:Listener(21112, http2MaxActiveStreams = -1) is error);
    test:assertTrue(new http:Listener(21113, http2InitialWindowSize = 1000000, http2MaxActiveStreams = 7)
        is http:Listener);
}

@test:Config {groups: ["listenerLifecycle"]}
function testGracefulStopTimeoutSurvivesImmediateStop() returns error? {
    http:Listener l = check new (listenerCfgGracefulPort, gracefulStopTimeout = 2);
    check l.attach(new ListenerCfgService(), "/");
    check l.'start();
    check l.immediateStop();
    check l.attach(new ListenerCfgService(), "/");
    check l.'start();
    time:Utc before = time:utcNow();
    check l.gracefulStop();
    decimal elapsed = time:utcDiffSeconds(time:utcNow(), before);
    test:assertTrue(elapsed >= 1.8d, "gracefulStop() must wait for the configured timeout, took " +
        elapsed.toString() + " s");
}

@test:Config {groups: ["listenerLifecycle"]}
function testSecondListenerOnUsedPortKeepsFirstListenerServing() returns error? {
    http:Listener first = check new (listenerCfgDuplicatePort, httpVersion = http:HTTP_1_1);
    check first.attach(new ListenerCfgService(), "/a");
    check first.'start();

    http:Listener second = check new (listenerCfgDuplicatePort, httpVersion = http:HTTP_1_1);
    check second.attach(new ListenerCfgService(), "/b");
    error? startResult = trap second.'start();
    test:assertTrue(startResult is error, "starting a second listener on a used port must fail");
    // Stopping the listener that failed to start must not stop the first listener.
    check second.gracefulStop();
    check second.immediateStop();

    http:Client c = check new ("http://localhost:" + listenerCfgDuplicatePort.toString(),
        httpVersion = http:HTTP_1_1);
    http:Response r = check c->get("/a/hello");
    test:assertEquals(r.statusCode, 200, "the first listener must keep serving its services");
    http:Response notServed = check c->get("/b/hello");
    test:assertEquals(notServed.statusCode, 404, "the failed second listener must not serve its services");
    check first.gracefulStop();
}
