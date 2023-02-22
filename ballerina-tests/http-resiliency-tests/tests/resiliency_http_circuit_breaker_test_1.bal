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

import ballerina/lang.runtime as runtime;
// import ballerina/log;
import ballerina/test;
import ballerina/http;

isolated int cbCounter = 1;

listener http:Listener circuitBreakerEP00 = new(9306, httpVersion = http:HTTP_1_1);

http:ClientConfiguration conf = {
    httpVersion: http:HTTP_1_1,
    circuitBreaker: {
        rollingWindow: {
            timeWindow: 60,
            bucketSize: 20,
            requestVolumeThreshold: 0
        },
        failureThreshold: 0.3,
        resetTime: 5,
        statusCodes: [501, 502, 503]
    },
    timeout: 2
};

final http:Client backendClientEP00 = check new("http://localhost:8086", conf);

service /cb on circuitBreakerEP00 {

    resource function 'default typical(http:Caller caller, http:Request request) {
        http:Response|error backendRes = backendClientEP00->forward("/hello/typical", request);
        int count = 0;
        lock {
            count = cbCounter;
        }
        if (count % 5 == 0) {
            runtime:sleep(5);
        } else {
            runtime:sleep(1);
        }
        lock {
            cbCounter += 1;
        }
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
}

// This sample service is used to mock connection timeouts and service outages.
// Mock a service outage by stopping/starting this service.
// This should run separately from the `circuitBreakerDemo` service.
service /hello on new http:Listener(8086, httpVersion = http:HTTP_1_1) {

    resource function 'default typical(http:Caller caller, http:Request req) {
        int count = 0;
        lock {
            count = cbCounter;
        }
        if (count % 5 == 3) {
            runtime:sleep(3);
        }
        error? responseToCaller = caller->respond("Hello World!!!");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

//Test basic circuit breaker functionality
final http:Client testTypicalBackendTimeoutClient = check new("http://localhost:9306", httpVersion = http:HTTP_1_1);

@test:Config {
    dataProvider:responseDataProvider
}
function testTypicalBackendTimeout(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponse(testTypicalBackendTimeoutClient, "/cb/typical", dataFeed);
}

function responseDataProvider() returns DataFeed[][] {
    return [
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}],
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:IDLE_TIMEOUT_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}],
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}]
    ];
}
