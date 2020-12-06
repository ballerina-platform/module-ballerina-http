// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/io;
import ballerina/mime;
import ballerina/runtime;
import ballerina/test;

const string TEST_SCENARIO_HEADER = "test-scenario";

const string SCENARIO_TYPICAL = "typical-scenario";
const string SCENARIO_TRIAL_RUN_FAILURE = "trial-run-failure";
const string SCENARIO_HTTP_SC_FAILURE = "http-status-code-failure";
const string SCENARIO_CB_FORCE_OPEN = "cb-force-open-scenario";
const string SCENARIO_CB_FORCE_CLOSE = "cb-force-close-scenario";
const string SCENARIO_REQUEST_VOLUME_THRESHOLD_SUCCESS = "request-volume-threshold-success-scenario";
const string SCENARIO_REQUEST_VOLUME_THRESHOLD_FAILURE = "request-volume-threshold-failure-scenario";

const int CB_CLIENT_FIRST_ERROR_INDEX = 3;
const int CB_CLIENT_SECOND_ERROR_INDEX = 4;
const int CB_CLIENT_TOP_MOST_SUCCESS_INDEX = 2;
const int CB_CLIENT_FAILURE_CASE_ERROR_INDEX = 5;
const int CB_CLIENT_FORCE_OPEN_INDEX = 4;

function testTypicalScenario() returns @tainted [http:Response[], error?[]] {
    actualRequestNumber = 0;
    MockClient mockClient = new("http://localhost:8080");
    http:Client backendClientEP = new("http://localhost:8080", {
        circuitBreaker: {
            rollingWindow: {
                timeWindowInMillis:10000,
                bucketSizeInMillis:2000,
                requestVolumeThreshold: 0
            },
            failureThreshold:0.3,
            resetTimeInMillis:1000,
            statusCodes:[400, 404, 500, 502, 503]
        },
        timeoutInMillis:2000
    });

    http:Response[] responses = [];
    error?[] errs = [];
    int counter = 0;
        while (counter < 8) {
            http:Request request = new;
            request.setHeader(TEST_SCENARIO_HEADER, SCENARIO_TYPICAL);
            http:CircuitBreakerClient tempClient = <http:CircuitBreakerClient>backendClientEP.httpClient;
            tempClient.httpClient = mockClient;
            var serviceResponse = backendClientEP->get("/hello", request);
            if (serviceResponse is http:Response) {
                responses[counter] = serviceResponse;
            } else if (serviceResponse is error) {
                errs[counter] = serviceResponse;
            }
            counter = counter + 1;
            // To ensure the reset timeout period expires
            if (counter == 5) {
                runtime:sleep(5000);
            }
        }
    return [responses, errs];
}

function testTrialRunFailure() returns @tainted [http:Response[], error?[]] {
    actualRequestNumber = 0;
    MockClient mockClient = new("http://localhost:8080");
    http:Client backendClientEP = new("http://localhost:8080", {
        circuitBreaker: {
            rollingWindow: {
                timeWindowInMillis:10000,
                bucketSizeInMillis:2000,
                requestVolumeThreshold: 0
            },
            failureThreshold:0.3,
            resetTimeInMillis:1000,
            statusCodes:[400, 404, 500, 502, 503]
        },
        timeoutInMillis:2000
    });

    http:Response[] responses = [];
    error?[] errs = [];
    int counter = 0;

        while (counter < 8) {
            http:Request request = new;
            request.setHeader(TEST_SCENARIO_HEADER, SCENARIO_TRIAL_RUN_FAILURE);
            http:CircuitBreakerClient tempClient = <http:CircuitBreakerClient>backendClientEP.httpClient;
            tempClient.httpClient = mockClient;
            var serviceResponse = backendClientEP->get("/hello", request);
            if (serviceResponse is http:Response) {
                responses[counter] = serviceResponse;
            } else if (serviceResponse is error) {
                errs[counter] = serviceResponse;
            }
            counter = counter + 1;
            // To ensure the reset timeout period expires
            if (counter == 5) {
                runtime:sleep(5000);
            }
        }
    return [responses, errs];
}

function testHttpStatusCodeFailure() returns @tainted [http:Response[], error?[]] {
    actualRequestNumber = 0;
    MockClient mockClient = new("http://localhost:8080");
    http:Client backendClientEP = new("http://localhost:8080", {
        circuitBreaker: {
            rollingWindow: {
                timeWindowInMillis:10000,
                bucketSizeInMillis:2000,
                requestVolumeThreshold: 0
            },
            failureThreshold:0.3,
            resetTimeInMillis:1000,
            statusCodes:[400, 404, 500, 502, 503]
        },
        timeoutInMillis:2000
    });

    http:Response[] responses = [];
    error?[] errs = [];
    int counter = 0;
        while (counter < 8) {
            http:Request request = new;
            request.setHeader(TEST_SCENARIO_HEADER, SCENARIO_HTTP_SC_FAILURE);
            http:CircuitBreakerClient tempClient = <http:CircuitBreakerClient>backendClientEP.httpClient;
            tempClient.httpClient = mockClient;
            var serviceResponse = backendClientEP->get("/hello", request);
            if (serviceResponse is http:Response) {
                responses[counter] = serviceResponse;
            } else if (serviceResponse is error) {
                errs[counter] = serviceResponse;
            }
            counter = counter + 1;
        }
    return [responses, errs];
}

function testForceOpenScenario() returns @tainted [http:Response[], error?[]] {
    actualRequestNumber = 0;
    MockClient mockClient = new("http://localhost:8080");
    http:Client backendClientEP = new("http://localhost:8080", {
        circuitBreaker: {
            rollingWindow: {
                timeWindowInMillis:10000,
                bucketSizeInMillis:2000,
                requestVolumeThreshold: 0
            },
            failureThreshold:0.3,
            resetTimeInMillis:1000,
            statusCodes:[500, 502, 503]
        },
        timeoutInMillis:2000
    });

    http:Response[] responses = [];
    error?[] errs = [];
    int counter = 0;
    while (counter < 8) {
        http:Request request = new;
        request.setHeader(TEST_SCENARIO_HEADER, SCENARIO_CB_FORCE_OPEN);
        if (counter > 3) {
            backendClientEP.httpClient = getForcedOpenCircuitBreakerClient(backendClientEP.httpClient);
        }
        http:CircuitBreakerClient tempClient = <http:CircuitBreakerClient>backendClientEP.httpClient;
        tempClient.httpClient = mockClient;
        var serviceResponse = backendClientEP->get("/hello", request);
        if (serviceResponse is http:Response) {
            responses[counter] = serviceResponse;
        } else if (serviceResponse is error) {
            errs[counter] = serviceResponse;
        }
        counter = counter + 1;
    }
    return [responses, errs];
}

function testForceCloseScenario() returns @tainted [http:Response[], error?[]] {
    actualRequestNumber = 0;
    MockClient mockClient = new("http://localhost:8080");
    http:Client backendClientEP = new("http://localhost:8080", {
        circuitBreaker: {
            rollingWindow: {
                timeWindowInMillis:10000,
                bucketSizeInMillis:2000,
                requestVolumeThreshold: 0
            },
            failureThreshold:0.3,
            resetTimeInMillis:1000,
            statusCodes:[500, 502, 503]
        },
        timeoutInMillis:2000
    });

    http:Response[] responses = [];
    error?[] errs = [];
    int counter = 0;

    while (counter < 8) {
        http:Request request = new;
        request.setHeader(TEST_SCENARIO_HEADER, SCENARIO_CB_FORCE_CLOSE);
        if (counter > 2) {
            backendClientEP.httpClient = getForcedCloseCircuitBreakerClient(backendClientEP.httpClient);
        }
        http:CircuitBreakerClient tempClient = <http:CircuitBreakerClient>backendClientEP.httpClient;
        tempClient.httpClient = mockClient;
        var serviceResponse = backendClientEP->get("/hello", request);
        if (serviceResponse is http:Response) {
            responses[counter] = serviceResponse;
        } else if (serviceResponse is error) {
            errs[counter] = serviceResponse;
        }
        counter = counter + 1;
    }
    return [responses, errs];
}

function testRequestVolumeThresholdSuccessResponseScenario() returns @tainted [http:Response[], error?[]] {
    actualRequestNumber = 0;
    MockClient mockClient = new("http://localhost:8080");
    http:Client backendClientEP = new("http://localhost:8080", {
        circuitBreaker: {
            rollingWindow: {
                timeWindowInMillis:10000,
                bucketSizeInMillis:2000,
                requestVolumeThreshold: 6
            },
            failureThreshold:0.3,
            resetTimeInMillis:1000,
            statusCodes:[500, 502, 503]
        },
        timeoutInMillis:2000
    });

    http:Response[] responses = [];
    error?[] errs = [];
    int counter = 0;

    while (counter < 6) {
        http:Request request = new;
        request.setHeader(TEST_SCENARIO_HEADER, SCENARIO_REQUEST_VOLUME_THRESHOLD_SUCCESS);
        http:CircuitBreakerClient tempClient = <http:CircuitBreakerClient>backendClientEP.httpClient;
        tempClient.httpClient = mockClient;
        var serviceResponse = backendClientEP->get("/hello", request);
        if (serviceResponse is http:Response) {
            responses[counter] = serviceResponse;
        } else if (serviceResponse is error) {
            errs[counter] = serviceResponse;
        }
        counter = counter + 1;
    }
    return [responses, errs];
}

function testRequestVolumeThresholdFailureResponseScenario() returns @tainted [http:Response[], error?[]] {
    actualRequestNumber = 0;
    MockClient mockClient = new("http://localhost:8080");
    http:Client backendClientEP = new("http://localhost:8080", {
        circuitBreaker: {
            rollingWindow: {
                timeWindowInMillis:10000,
                bucketSizeInMillis:2000,
                requestVolumeThreshold: 6
            },
            failureThreshold:0.3,
            resetTimeInMillis:1000,
            statusCodes:[500, 502, 503]
        },
        timeoutInMillis:2000
    });

    http:Response[] responses = [];
    error?[] errs = [];
    int counter = 0;

    while (counter < 6) {
        http:Request request = new;
        request.setHeader(TEST_SCENARIO_HEADER, SCENARIO_REQUEST_VOLUME_THRESHOLD_FAILURE);
        http:CircuitBreakerClient tempClient = <http:CircuitBreakerClient>backendClientEP.httpClient;
        tempClient.httpClient = mockClient;
        var serviceResponse = backendClientEP->get("/hello", request);
        if (serviceResponse is http:Response) {
            responses[counter] = serviceResponse;
        } else if (serviceResponse is error) {
            errs[counter] = serviceResponse;
        }
        counter = counter + 1;
    }
    return [responses, errs];
}

function testInvalidRollingWindowConfiguration() returns error? {
    var backendClientEP = trap new http:Client("http://localhost:8080", {
        circuitBreaker: {
            rollingWindow: {
                timeWindowInMillis: 2000,
                bucketSizeInMillis: 3000,
                requestVolumeThreshold: 0
            },
            failureThreshold:0.3,
            resetTimeInMillis:1000,
            statusCodes:[400, 404, 500, 502, 503]
        },
        timeoutInMillis:2000
    });
    if (backendClientEP is error) {
        return backendClientEP;
    }
}

int actualRequestNumber = 0;

public client class MockClient {
    public string url = "";
    public http:ClientConfiguration config = {};
    public http:HttpClient httpClient;

    public function init(string url, http:ClientConfiguration? config = ()) {
        http:HttpClient simpleClient = new(url);
        self.url = url;
        self.config = config ?: {};
        self.httpClient = simpleClient;
    }

    public remote function post(@untainted string path, http:RequestMessage message,
            http:TargetType targetType = http:Response) returns http:Response|http:Payload|http:ClientError {
        return getUnsupportedError();
    }

    public remote function head(string path,
                           http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|() message = ())
                                                                                returns http:Response|http:ClientError {
        return getUnsupportedError();
    }

    public remote function put(@untainted string path, http:RequestMessage message,
            http:TargetType targetType = http:Response) returns http:Response|http:Payload|http:ClientError {
        return getUnsupportedError();
    }

    public remote function execute(@untainted string httpVerb, @untainted string path, http:RequestMessage message,
           http:TargetType targetType = http:Response) returns @tainted http:Response|http:Payload|http:ClientError {
        return getUnsupportedError();
    }

    public remote function patch(@untainted string path, http:RequestMessage message, http:TargetType targetType = http:Response)
                                             returns @tainted http:Response|http:Payload|http:ClientError {
        return getUnsupportedError();
    }

    public remote function delete(@untainted string path, http:RequestMessage message = (),
          http:TargetType targetType = http:Response) returns @tainted http:Response|http:Payload|http:ClientError {
        return getUnsupportedError();
    }

    public remote function get(@untainted string path, http:RequestMessage message = (),
           http:TargetType targetType = http:Response) returns @tainted http:Response|http:Payload|http:ClientError {
        http:Request req = buildRequest(message);
        http:Response response = new;
        actualRequestNumber = actualRequestNumber + 1;
        string scenario = req.getHeader(TEST_SCENARIO_HEADER);

        if (scenario == SCENARIO_TYPICAL) {
            var result = handleBackendFailureScenario(actualRequestNumber);
            if (result is http:Response) {
                response = result;
            } else {
                string errMessage = result.message();
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                response.setTextPayload(errMessage);
            }
        } else if (scenario == SCENARIO_TRIAL_RUN_FAILURE) {
            var result = handleTrialRunFailureScenario(actualRequestNumber);
            if (result is http:Response) {
                response = result;
            } else {
                string errMessage = result.message();
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                response.setTextPayload(errMessage);
            }
        } else if (scenario == SCENARIO_HTTP_SC_FAILURE) {
            var result = handleHTTPStatusCodeErrorScenario(actualRequestNumber);
            if (result is http:Response) {
                response = result;
            } else {
                string errMessage = result.message();
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                response.setTextPayload(errMessage);
            }
        } else if (scenario == SCENARIO_CB_FORCE_OPEN) {
            response = handleCBForceOpenScenario();
        } else if (scenario == SCENARIO_CB_FORCE_CLOSE) {
            var result = handleCBForceCloseScenario(actualRequestNumber);
            if (result is http:Response) {
                response = result;
            } else {
                string errMessage = result.message();
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                response.setTextPayload(errMessage);
            }
        } else if (scenario == SCENARIO_REQUEST_VOLUME_THRESHOLD_SUCCESS) {
            response = handleRequestVolumeThresholdSuccessResponseScenario();
        } else if (scenario == SCENARIO_REQUEST_VOLUME_THRESHOLD_FAILURE) {
            response = handleRequestVolumeThresholdFailureResponseScenario();
        }
        return response;
    }

    public remote function options(@untainted string path, http:RequestMessage message = (),
           http:TargetType targetType = http:Response) returns @tainted http:Response|http:Payload|http:ClientError {
        return getUnsupportedError();
    }

    public remote function forward(@untainted string path, http:Request request, http:TargetType targetType =
    http:Response)
                                               returns @tainted http:Response|http:Payload|http:ClientError {
        return getUnsupportedError();
    }

    public remote function submit(string httpVerb, string path,
                           http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|() message)
                                                                            returns http:HttpFuture|http:ClientError {
        return getUnsupportedError();
    }

    public remote function getResponse(http:HttpFuture httpFuture)  returns http:Response|http:ClientError {
        return getUnsupportedError();
    }

    public remote function hasPromise(http:HttpFuture httpFuture) returns boolean {
        return false;
    }

    public remote function getNextPromise(http:HttpFuture httpFuture) returns http:PushPromise|http:ClientError {
        return getUnsupportedError();
    }

    public remote function getPromisedResponse(http:PushPromise promise) returns http:Response|http:ClientError {
        return getUnsupportedError();
    }

    public remote function rejectPromise(http:PushPromise promise) {
    }
}

function handleBackendFailureScenario(int requestNo) returns http:Response|http:ClientError {
    // Deliberately fail a request
    if (requestNo == 3) {
        return getErrorStruct();
    }
    http:Response response = getResponse();
    return response;
}

function handleTrialRunFailureScenario(int counter) returns http:Response|http:ClientError {
    // Fail a request. Then, fail the trial request sent while in the HALF_OPEN state as well.
    if (counter == 2 || counter == 3) {
        return getErrorStruct();
    }

    http:Response response = getResponse();
    return response;
}

function handleHTTPStatusCodeErrorScenario(int counter) returns http:Response|http:ClientError {
    // Fail a request. Then, fail the trial request sent while in the HALF_OPEN state as well.
    if (counter == 2 || counter == 3) {
        return getMockErrorStruct();
    }

    http:Response response = getResponse();
    return response;
}

function handleCBForceOpenScenario() returns http:Response {
    return getResponse();
}

function handleCBForceCloseScenario(int requestNo) returns http:Response|http:ClientError {
    // DeliberattestCircuitBreakerely fail a request
    if (requestNo == 3) {
        return getErrorStruct();
    }
    http:Response response = getResponse();
    return response;
}

function handleRequestVolumeThresholdSuccessResponseScenario() returns http:Response {
    return getResponse();
}

function handleRequestVolumeThresholdFailureResponseScenario() returns http:Response {
    http:Response response = new;
    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
    return response;
}

function getErrorStruct() returns http:ClientError {
    return http:GenericClientError("Connection refused");
}

function getResponse() returns http:Response {
    // TODO: The way the status code is set may need to be changed once struct fields can be made read-only
    http:Response response = new;
    response.statusCode = http:STATUS_OK;
    return response;
}

function getMockErrorStruct() returns http:ClientError {
    return http:GenericClientError("Internal Server Error");
}

function getUnsupportedError() returns http:ClientError {
    return http:GenericClientError("Unsupported function for MockClient");
}

function buildRequest(http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|() message) returns
http:Request {
    http:Request request = new;
    if (message is ()) {
        return request;
    } else if (message is http:Request) {
        request = message;
    } else if (message is string) {
        request.setTextPayload(message);
    } else if (message is xml) {
        request.setXmlPayload(message);
    } else if (message is byte[]) {
        request.setBinaryPayload(message);
    } else if (message is json) {
        request.setJsonPayload(message);
    } else if (message is io:ReadableByteChannel) {
        request.setByteChannel(message);
    } else {
        request.setBodyParts(message);
    }
    return request;
}

listener http:Listener mockEP3 = new(9095);

http:Client clientEP = new("http://localhost:8080", {
    circuitBreaker: {
        rollingWindow: {
            timeWindowInMillis: 10000,
            bucketSizeInMillis: 2000
        },
        failureThreshold: 0.3,
        resetTimeInMillis: 1000,
        statusCodes: [500, 502, 503]
    },
    timeoutInMillis: 2000
});

@http:ServiceConfig { basePath: "/cb" }
service circuitBreakerService on mockEP3 {

    @http:ResourceConfig {
        path: "/getState"
    }
    resource function getState(http:Caller caller, http:Request req) {
        http:CircuitBreakerClient cbClient = <http:CircuitBreakerClient>clientEP.httpClient;
        http:CircuitState currentState = cbClient.getCurrentState();
        http:Response res = new;
        if (currentState == http:CB_CLOSED_STATE) {
            res.setPayload(<@untainted string> "Circuit Breaker is in CLOSED state");
            checkpanic caller->respond(res);
        }
    }
}

function getForcedOpenCircuitBreakerClient(http:HttpClient httpClient) returns http:CircuitBreakerClient {
    http:CircuitBreakerClient cbClient = <http:CircuitBreakerClient>httpClient;
    cbClient.forceOpen();
    return cbClient;
}

function getForcedCloseCircuitBreakerClient(http:HttpClient httpClient) returns http:CircuitBreakerClient {
    http:CircuitBreakerClient cbClient = <http:CircuitBreakerClient>httpClient;
    cbClient.forceClose();
    return cbClient;
}

function validateCBResponses(http:Response[] responses, error?[] errors, int[] expectedStatusCodes) {
    int i = 0;
    foreach var resp in responses {
        int statusCode;
        if (i < CB_CLIENT_FORCE_OPEN_INDEX) {
            statusCode = resp.statusCode;
            test:assertEquals(expectedStatusCodes[i], statusCode);
        } else {
            var e = errors[i];
            if (e is error) {
                string message = e.message();
                test:assertTrue(message.startsWith("Upstream service unavailable."));
            }
        }
        i = i + 1;
    }
}

// Test case for a typical scenario where an upstream service may become unavailable temporarily.
@test:Config {}
function testCircuitBreaker() {
    int[] expectedStatusCodes = [200, 200, 500, 503, 503, 200, 200, 200];
    [http:Response[], error?[]] result = testTypicalScenario();
    http:Response[] responses = result[0];
    error?[] err = result[1];
    int i = 0;
    foreach var resp in responses {
        int statusCode;
        if (i != CB_CLIENT_FIRST_ERROR_INDEX && i != CB_CLIENT_SECOND_ERROR_INDEX) {
            statusCode = resp.statusCode;
            test:assertEquals(expectedStatusCodes[i], statusCode);
        } else {
            var e = err[i];
            if (e is error) {
                string message = e.message();
                test:assertTrue(message.startsWith("Upstream service unavailable."));
            }
        }
        i = i + 1;
    }
}

// Test case scenario: - Initially the circuit is healthy and functioning normally. - Backend service becomes
// unavailable and eventually, the failure threshold is exceeded. - Requests afterwards are immediately failed, with
// a 503 response. - After the reset timeout expires, the circuit goes to HALF_OPEN state and a trial request is
// sent. - The backend service is not available and therefore, the request fails again and the circuit goes back to OPEN.
@test:Config {}
function trialRunFailureTest() {
    int[] expectedStatusCodes = [200, 500, 503, 500, 503, 500];
    [http:Response[], error?[]] result = testTrialRunFailure();
    http:Response[] responses = result[0];
    error?[] err = result[1];
    int i = 0;
    foreach var resp in responses {
        int statusCode;
        if (i < CB_CLIENT_TOP_MOST_SUCCESS_INDEX || i == CB_CLIENT_FAILURE_CASE_ERROR_INDEX) {
            statusCode = resp.statusCode;
            test:assertEquals(expectedStatusCodes[i], statusCode);
        } else {
            var e = err[i];
            if (e is error) {
                string message = e.message();
                test:assertTrue(message.startsWith("Upstream service unavailable."));
            }
        }
        i = i + 1;
    }
}

// Test case scenario: - Initially the circuit is healthy and functioning normally. - Backend service respond with
// HTTP status code configured to consider as failures responses. eventually the failure threshold is exceeded. -
// Requests afterwards are immediately failed, with a 503 response. - After the reset timeout expires, the circuit
// goes to HALF_OPEN state and a trial request is sent. - The backend service is not available and therefore, the
// request fails again and the circuit goes back to OPEN.
@test:Config {}
function httpStatusCodeFailureTest() {
    int[] expectedStatusCodes = [200, 500, 503, 500, 503, 503];
    [http:Response[], error?[]] result = testHttpStatusCodeFailure();
    http:Response[] responses = result[0];
    error?[] err = result[1];
    validateCBResponses(responses, err, expectedStatusCodes);
}

// Test case scenario: - Initially the circuit is healthy and functioning normally. - during the middle of execution
// circuit will be force fully opened. - Afterward requests should immediately fail.
@test:Config {}
function cBForceOpenScenarioTest() {
    int[] expectedStatusCodes = [200, 200, 200, 200, 503, 503, 503, 503];
    [http:Response[], error?[]] result = testForceOpenScenario();
    http:Response[] responses = result[0];
    error?[] err = result[1];
    validateCBResponses(responses, err, expectedStatusCodes);
}

// Test case scenario: - Initially the circuit is healthy and functioning normally. - Backend service becomes
// unavailable and eventually, the failure threshold is exceeded. - After that circuit will be force fully closed. -
// Afterward success responses should received.
@test:Config {}
function cBForceCloseScenarioTest() {
    int[] expectedStatusCodes = [200, 200, 500, 200, 200, 200, 200, 200];
    [http:Response[], error?[]] result = testForceCloseScenario();
    http:Response[] responses = result[0];
    error?[] err = result[1];
    int i = 0;
    foreach var resp in responses {
        int statusCode = resp.statusCode;
        test:assertEquals(expectedStatusCodes[i], statusCode);
        i = i + 1;
    }
}

// Test case scenario: - Circuit Breaker configured with requestVolumeThreshold. - Circuit Breaker shouldn't
// interact with circuit state until the configured threshold exceeded.
@test:Config {}
function cBRequestVolumeThresholdSuccessResponseScenarioTest() {
    int[] expectedStatusCodes = [200, 200, 200, 200, 200, 200];
    [http:Response[], error?[]] result = testRequestVolumeThresholdSuccessResponseScenario();
    http:Response[] responses = result[0];
    error?[] err = result[1];
    int i = 0;
    foreach var resp in responses {
        int statusCode = resp.statusCode;
        test:assertEquals(expectedStatusCodes[i], statusCode);
        i = i + 1;
    }
}

// Test case scenario: - Circuit Breaker configured with requestVolumeThreshold. - Circuit Breaker shouldn't
// interact with circuit state until the configured threshold exceeded.
@test:Config {}
function cBRequestVolumeThresholdFailureResponseScenarioTest() {
    int[] expectedStatusCodes = [500, 500, 500, 500, 500, 500];
    [http:Response[], error?[]] result = testRequestVolumeThresholdFailureResponseScenario();
    http:Response[] responses = result[0];
    error?[] err = result[1];
    int i = 0;
    foreach var resp in responses {
        int statusCode = resp.statusCode;
        test:assertEquals(expectedStatusCodes[i], statusCode);
        i = i + 1;
    }
}

@test:Config {}
function cBGetCurrentStatausScenarioTest() {
    string expected = "Circuit Breaker is in CLOSED state";
    http:Client reqClient = new("http://localhost:9095");
    var response = reqClient->get("/cb/getState");
    if (response is http:Response) {
        var body = response.getTextPayload();
        if (body is string) {
            test:assertEquals(body, expected);
        } else {
            test:assertFail(msg = body.message());
        }
    } else if (response is error) {
        test:assertFail(msg = "Didn't receive an http response" + response.message());
    }
}

@test:Config {}
function invalidRollingWindowConfigTest() {
    string expected = "Circuit breaker 'timeWindowInMillis' value should be greater than the 'bucketSizeInMillis' value.";
    error? err = testInvalidRollingWindowConfiguration();
    if (err is error) {
       test:assertEquals(err.message(), expected);  
    } else {
       test:assertFail(msg = "expected an error. But found a response");
    }
}
