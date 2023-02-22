// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;
import ballerina/http;

final http:Client backendClientNegative = check new("http://localhost:8086", httpVersion = http:HTTP_1_1);

@test:Config {}
function testInvokingCBRelatedMethodOnNonCBClients() {
    error? err = trap backendClientNegative.circuitBreakerForceClose();
    if err is error {
        test:assertEquals(err.message(), "illegal method invocation. 'circuitBreakerForceClose()' is allowed for " +
            "clients which have configured with circuit breaker configurations", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }

    err = trap backendClientNegative.circuitBreakerForceOpen();
    if err is error {
        test:assertEquals(err.message(), "illegal method invocation. 'circuitBreakerForceOpen()' is allowed for " +
            "clients which have configured with circuit breaker configurations", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }

    http:CircuitState|error state = trap backendClientNegative.getCircuitBreakerCurrentState();
    if state is error {
        test:assertEquals(state.message(), "illegal method invocation. 'getCircuitBreakerCurrentState()' is allowed " +
            "for clients which have configured with circuit breaker configurations", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}
