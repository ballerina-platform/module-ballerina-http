// Copyright (c) 2018 WSO2 Inc. (//www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// //www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

// import ballerina/log;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

isolated int forceOpen = 0;

isolated function retrieveAndIncrementCounter() returns int {
    lock {
        int currentCounter = forceOpen;
        forceOpen += 1;
        return currentCounter;
    }
}

listener http:Listener circuitBreakerEP01 = new(9307, httpVersion = http:HTTP_1_1);

http:ClientConfiguration conf01 = {
    httpVersion: http:HTTP_1_1,
    circuitBreaker: {
        rollingWindow: {
            timeWindow: 60,
            bucketSize: 20,
            requestVolumeThreshold: 0
        },
        failureThreshold: 0.2,
        resetTime: 1,
        statusCodes: [501, 502, 503]
    },
    timeout: 2
};

final http:Client healthyClientEP = checkpanic new("http://localhost:8087", conf01);

service /cb on circuitBreakerEP01 {

    resource function 'default forceopen(http:Caller caller, http:Request request) {
        int counter = retrieveAndIncrementCounter();
        if (counter % 3 == 0) {
            healthyClientEP.circuitBreakerForceClose();
        } else if (counter % 3 == 1) {
            healthyClientEP.circuitBreakerForceOpen();
        }

        http:Response|error backendRes = healthyClientEP->forward("/healthy", request);
        handleBackendResponse(caller, backendRes);
    }

    resource function get forceopen(http:Caller caller, http:Request request) {
        int counter = retrieveAndIncrementCounter();
        if (counter % 3 == 0) {
            healthyClientEP.circuitBreakerForceClose();
        } else if (counter % 3 == 1) {
            healthyClientEP.circuitBreakerForceOpen();
        }

        http:Response|error backendRes = healthyClientEP->get("/healthy");
        handleBackendResponse(caller, backendRes);
    }

    resource function head forceopen(http:Caller caller, http:Request request) {
        int counter = retrieveAndIncrementCounter();
        if (counter % 3 == 0) {
            healthyClientEP.circuitBreakerForceClose();
        } else if (counter % 3 == 1) {
            healthyClientEP.circuitBreakerForceOpen();
        }
        http:Response|error backendRes = healthyClientEP->head("/healthy");
        if backendRes is http:Response {
            error? responseToCaller = caller->respond(backendRes);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setHeader(CB_HEADER, CB_FAILURE_HEADER_VALUE);
            error? responseToCaller = caller->respond(response);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function options forceopen(http:Caller caller, http:Request request) {
        int counter = retrieveAndIncrementCounter();
        if (counter % 3 == 0) {
            healthyClientEP.circuitBreakerForceClose();
        } else if (counter % 3 == 1) {
            healthyClientEP.circuitBreakerForceOpen();
        }
        http:Response|error backendRes = healthyClientEP->options("/healthy");
        if backendRes is http:Response {
            error? responseToCaller = caller->respond(backendRes);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setHeader(ALLOW_HEADER, CB_FAILUE_ALLOW_HEADER_VALUE);
            error? responseToCaller = caller->respond(response);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function put forceopen(http:Caller caller, http:Request request) {
        int counter = retrieveAndIncrementCounter();
        if (counter % 3 == 0) {
            healthyClientEP.circuitBreakerForceClose();
        } else if (counter % 3 == 1) {
            healthyClientEP.circuitBreakerForceOpen();
        }

        http:Response|error backendRes = healthyClientEP->put("/healthy", request);
        handleBackendResponse(caller, backendRes);
    }

    resource function patch forceopen(http:Caller caller, http:Request request) {
        int counter = retrieveAndIncrementCounter();
        if (counter % 3 == 0) {
            healthyClientEP.circuitBreakerForceClose();
        } else if (counter % 3 == 1) {
            healthyClientEP.circuitBreakerForceOpen();
        }

        http:Response|error backendRes = healthyClientEP->patch("/healthy", request);
        handleBackendResponse(caller, backendRes);
    }

    resource function delete forceopen(http:Caller caller, http:Request request) {
        int counter = retrieveAndIncrementCounter();
        if (counter % 3 == 0) {
            healthyClientEP.circuitBreakerForceClose();
        } else if (counter % 3 == 1) {
            healthyClientEP.circuitBreakerForceOpen();
        }

        http:Response|error backendRes = healthyClientEP->delete("/healthy", request);
        handleBackendResponse(caller, backendRes);
    }
}

isolated function handleBackendResponse(http:Caller caller, http:Response|error backendRes) {
    if backendRes is http:Response {
        error? responseToCaller = caller->respond(backendRes);
        if responseToCaller is error {
            // log:printError("Error sending response", 'error = responseToCaller);
        }
    } else {
        http:Response response = new;
        response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
        response.setPayload(backendRes.message());
        error? responseToCaller = caller->respond(response);
        if responseToCaller is error {
            // log:printError("Error sending response", 'error = responseToCaller);
        }
    }
}

service /healthy on new http:Listener(8087, httpVersion = http:HTTP_1_1) {

    resource function 'default .(http:Caller caller, http:Request req) {
        error? responseToCaller = caller->respond("Hello World!!!");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function head .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setHeader(CB_HEADER, CB_SUCCESS_HEADER_VALUE);
        error? responseToCaller = caller->respond(res);
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }

    resource function options .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setHeader(ALLOW_HEADER, CB_SUCCESS_ALLOW_HEADER_VALUE);
        error? responseToCaller = caller->respond(res);
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}


//Test for circuit breaker forceOpen functionality
final http:Client testForceOpenClient = checkpanic new("http://localhost:9307", httpVersion = http:HTTP_1_1);

@test:Config{ 
    groups: ["circuitBreakerForceOpen"],
    dataProvider:forceOpenResponseDataProvider 
}
function testForceOpen(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponse(testForceOpenClient, "/cb/forceopen", dataFeed);
}

@test:Config{ 
    groups: ["circuitBreakerForceOpen"],
    dataProvider:forceOpenResponseDataProvider 
}
function testForceOpenWithHttpGet(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponseWithHttpGet(testForceOpenClient, "/cb/forceopen", dataFeed, common:TEXT_PLAIN);
}

@test:Config{ 
    groups: ["circuitBreakerForceOpen"],
    dataProvider:forceOpenResponseDataProviderForHeadRequest 
}
function testForceOpenWithHttpHead(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponseWithHttpHead(testForceOpenClient, "/cb/forceopen", dataFeed);
}

@test:Config{ 
    groups: ["circuitBreakerForceOpen"],
    dataProvider:forceOpenResponseDataProviderForOptionsRequest 
}
function testForceOpenWithHttpOptions(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponseWithHttpOptions(testForceOpenClient, "/cb/forceopen", dataFeed);
}

@test:Config{ 
    groups: ["circuitBreakerForceOpen"],
    dataProvider:forceOpenResponseDataProvider 
}
function testForceOpenWithHttpPut(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponseWithHttpPut(testForceOpenClient, "/cb/forceopen", dataFeed);
}

@test:Config{ 
    groups: ["circuitBreakerForceOpen"],
    dataProvider:forceOpenResponseDataProvider 
}
function testForceOpenWithHttpPatch(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponseWithHttpPatch(testForceOpenClient, "/cb/forceopen", dataFeed);
}

@test:Config{ 
    groups: ["circuitBreakerForceOpen"],
    dataProvider:forceOpenResponseDataProvider 
}
function testForceOpenWithHttpDelete(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponseWithHttpDelete(testForceOpenClient, "/cb/forceopen", dataFeed);
}

function forceOpenResponseDataProvider() returns DataFeed[][] {
    return [
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}]
    ];
}

function forceOpenResponseDataProviderForHeadRequest() returns DataFeed[][] {
    return [
        [{responseCode:SC_OK, message:CB_SUCCESS_HEADER_VALUE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:CB_FAILURE_HEADER_VALUE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:CB_FAILURE_HEADER_VALUE}]
    ];
}

function forceOpenResponseDataProviderForOptionsRequest() returns DataFeed[][] {
    return [
        [{responseCode:SC_OK, message:CB_SUCCESS_ALLOW_HEADER_VALUE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:CB_FAILUE_ALLOW_HEADER_VALUE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:CB_FAILUE_ALLOW_HEADER_VALUE}]
    ];
}
