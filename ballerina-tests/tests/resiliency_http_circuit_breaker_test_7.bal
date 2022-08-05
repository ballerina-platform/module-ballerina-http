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

int requestCount = 0;
int actualCount = 0;

listener http:Listener circuitBreakerEP06 = new(9312, httpVersion = http:HTTP_1_1);

http:ClientConfiguration conf06 = {
    httpVersion: http:HTTP_1_1,
    circuitBreaker: {
        rollingWindow: {
            timeWindow: 60,
            bucketSize: 20,
            requestVolumeThreshold: 0
        },
        failureThreshold: 0.3,
        resetTime: 2,
        statusCodes: [501, 502, 503]
    },
    timeout: 2
};

final http:Client backendClientEP06 = check new("http://localhost:8092", conf06);

service /cb on circuitBreakerEP06 {

    resource function 'default trialrun(http:Caller caller, http:Request request) {
        int count = 0;
        lock {
            requestCount += 1;
            count = requestCount;
        }
            // To ensure the reset timeout period expires
        if (count == 3) {
            runtime:sleep(3);
        }
        http:Response|error backendRes = backendClientEP06->forward("/hello06", request);
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

service /hello06 on new http:Listener(8092, httpVersion = http:HTTP_1_1) {

    resource function 'default .(http:Caller caller, http:Request req) {
        int count = 0;
        lock {
            actualCount += 1;
            count = actualCount;
        }
        http:Response res = new;
        if (count == 1 || count == 2) {
            res.statusCode = http:STATUS_SERVICE_UNAVAILABLE;
            res.setPayload("Service unavailable.");
        } else {
            res.setPayload("Hello World!!!");
        }
        error? responseToCaller = caller->respond(res);
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

//Test for circuit breaker trail failure functionality
final http:Client testTrialRunFailureClient = check new("http://localhost:9312", httpVersion = http:HTTP_1_1);

@test:Config{ dataProvider:trialRunFailureResponseDataProvider }
function testCBTrialRunFailure(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponse(testTrialRunFailureClient, "/cb/trialrun", dataFeed);
}

function trialRunFailureResponseDataProvider() returns DataFeed[][] {
    return [
        [{responseCode:SC_SERVICE_UNAVAILABLE, message:SERVICE_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_SERVICE_UNAVAILABLE, message:SERVICE_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}]
    ];
}

