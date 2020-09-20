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

import ballerina/log;
import ballerina/runtime;
import ballerina/test;
import http;

int cbCounter = 1;

listener http:Listener circuitBreakerEP00 = new(9306);

http:ClientConfiguration conf = {
    circuitBreaker: {
        rollingWindow: {
            timeWindowInMillis: 60000,
            bucketSizeInMillis: 20000,
            requestVolumeThreshold: 0
        },
        failureThreshold: 0.3,
        resetTimeInMillis: 3000,
        statusCodes: [501, 502, 503]
    },
    timeoutInMillis: 2000
};

http:Client backendClientEP00 = new("http://localhost:8086", conf);

@http:ServiceConfig {
    basePath: "/cb"
}
service circuitbreaker00 on circuitBreakerEP00 {
    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/typical"
    }
    resource function invokeEndpoint(http:Caller caller, http:Request request) {
        var backendRes = backendClientEP00->forward("/hello/typical", request);
        if (cbCounter % 5 == 0) {
            runtime:sleep(3000);
        } else {
            runtime:sleep(1000);
        }
        if (backendRes is http:Response) {
            var responseToCaller = caller->respond(backendRes);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(<@untainted> backendRes.message());
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        }
    }
}

// This sample service is used to mock connection timeouts and service outages.
// Mock a service outage by stopping/starting this service.
// This should run separately from the `circuitBreakerDemo` service.
@http:ServiceConfig { basePath: "/hello" }
service cbHelloWorld on new http:Listener(8086) {
    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/typical"
    }
    resource function sayHello(http:Caller caller, http:Request req) {
        if (cbCounter % 5 == 3) {
            cbCounter += 1;
            runtime:sleep(3000);
        } else {
            cbCounter += 1;
        }
        var responseToCaller = caller->respond("Hello World!!!");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", responseToCaller);
        }
    }
}

//Test basic circuit breaker functionality
http:Client testTypicalBackendTimeoutClient = new("http://localhost:9306");

@test:Config{
    dataProvider:"responseDataProvider"
}
function testTypicalBackendTimeout(DataFeed dataFeed) {
    invokeApiAndVerifyResponse(testTypicalBackendTimeoutClient, "/cb/typical", dataFeed);
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
