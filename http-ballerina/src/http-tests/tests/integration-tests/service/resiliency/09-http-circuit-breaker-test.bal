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

int forceCloseStateCount = 0;

listener http:Listener circuitBreakerEP02 = new(9308);

http:ClientConfiguration conf02 = {
    circuitBreaker: {
        rollingWindow: {
            timeWindowInMillis: 60000,
            bucketSizeInMillis: 20000,
            requestVolumeThreshold: 2
        },
        failureThreshold: 0.6,
        resetTimeInMillis: 1000,
        statusCodes: [501, 502, 503]
    },
    timeoutInMillis: 2000
};

http:Client unhealthyClientEP = new("http://localhost:8088", conf02);

@http:ServiceConfig {
    basePath: "/cb"
}
service circuitbreaker02 on circuitBreakerEP02 {

    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/forceclose"
    }
    resource function invokeForceClose(http:Caller caller, http:Request request) {
        http:CircuitBreakerClient cbClient = <http:CircuitBreakerClient>unhealthyClientEP.httpClient;
        forceCloseStateCount += 1;
        runtime:sleep(1000);
        if (forceCloseStateCount == 3) {
            runtime:sleep(5000);
            cbClient.forceClose();
        }
        var backendRes = unhealthyClientEP->forward("/unhealthy", request);
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

@http:ServiceConfig { basePath: "/unhealthy" }
service unhealthyService on new http:Listener(8088) {
    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/"
    }
    resource function sayHello(http:Caller caller, http:Request req) {
        http:Response res = new;
        if (forceCloseStateCount <= 3) {
            runtime:sleep(5000);
        } else {
            res.setPayload("Hello World!!!");
        }
        var responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", responseToCaller);
        }
    }
}

//Test for circuit breaker forceClose functionality
http:Client testForceCloseClient = new("http://localhost:9308");

@test:Config{
    dataProvider:"forceCloseResponseDataProvider"
}
function testForceClose(DataFeed dataFeed) {
    invokeApiAndVerifyResponse(testForceCloseClient, "/cb/forceclose", dataFeed);
}

function forceCloseResponseDataProvider() returns DataFeed[][] {
    return [
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:IDLE_TIMEOUT_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:IDLE_TIMEOUT_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}],
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}]
    ];
}
