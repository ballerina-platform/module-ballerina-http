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

import ballerina/lang.runtime as runtime;
import ballerina/log;
import ballerina/test;
import ballerina/http;

listener http:Listener circuitBreakerEP07 = new(9315, { httpVersion: "2.0" });

http:ClientConfiguration conf07 = {
    circuitBreaker: {
        rollingWindow: {
            timeWindow: 60,
            bucketSize: 20,
            requestVolumeThreshold: 0
        },
        failureThreshold: 0.3,
        resetTime: 2,
        statusCodes: [500, 501, 502, 503]
    },
    timeout: 2,
    httpVersion: "2.0"
};

http:Client backendClientEP07 = check new("http://localhost:8095", conf07);

int cbTrialRequestCount = 0;

service /cb on circuitBreakerEP07 {

    resource function 'default trialrun(http:Caller caller, http:Request request) {
        cbTrialRequestCount += 1;
        // To ensure the reset timeout period expires
        if (cbTrialRequestCount == 3) {
            runtime:sleep(3);
        }
        var backendFuture = backendClientEP07->submit("GET", "/hello07", request);
        if (backendFuture is http:HttpFuture) {
            http:Response|error backendRes = backendClientEP07->getResponse(backendFuture);
            if (backendRes is http:Response) {
                error? responseToCaller = caller->respond(backendRes);
                if (responseToCaller is error) {
                    log:printError("Error sending response", 'error = responseToCaller);
                }
            } else {
                sendCBErrorResponse(caller, <error>backendRes);
            }
        } else {
            sendCBErrorResponse(caller, <error>backendFuture);
        }
    }
}

int cbTrialActualCount = 0;

service /hello07 on new http:Listener(8095) {
    
    resource function 'default .(http:Caller caller, http:Request req) {
        cbTrialActualCount += 1;
        http:Response res = new;
        if (cbTrialActualCount == 1 || cbTrialActualCount == 2) {
            res.statusCode = http:STATUS_SERVICE_UNAVAILABLE;
            res.setPayload("Service unavailable.");
        } else {
            res.setPayload("Hello World!!!");
        }
        error? responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

function sendCBErrorResponse(http:Caller caller, error e) {
    http:Response response = new;
    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
    response.setPayload(e.message());
    error? responseToCaller = caller->respond(response);
    if (responseToCaller is error) {
        log:printError("Error sending response", 'error = responseToCaller);
    }
}

//Test circuit breaker functionality for HTTP/2 methods
http:Client h2CBTestClient = check new("http://localhost:9315");

@test:Config{
    enable:false,
    dataProvider:http2CircuitBreakerDataProvider
}
function testBasicHttp2CircuitBreaker(DataFeed dataFeed) {
    invokeApiAndVerifyResponse(h2CBTestClient, "/cb/trialrun", dataFeed);
}

function http2CircuitBreakerDataProvider() returns DataFeed[][] {
    return [
        [{responseCode:SC_SERVICE_UNAVAILABLE, message:SERVICE_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_SERVICE_UNAVAILABLE, message:SERVICE_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}]
    ];
}
