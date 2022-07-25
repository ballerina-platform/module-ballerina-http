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

isolated int forceCloseStateCount = 0;

listener http:Listener circuitBreakerEP02 = new(9308, httpVersion = "1.1");

http:ClientConfiguration conf02 = {
    httpVersion: "1.1",
    circuitBreaker: {
        rollingWindow: {
            timeWindow: 60,
            bucketSize: 20,
            requestVolumeThreshold: 2
        },
        failureThreshold: 0.6,
        resetTime: 1,
        statusCodes: [501, 502, 503]
    },
    timeout: 2
};

final http:Client unhealthyClientEP = check new("http://localhost:8088", conf02);

service /cb on circuitBreakerEP02 {

    isolated resource function 'default forceclose(http:Caller caller, http:Request request) {
        lock {
            forceCloseStateCount = forceCloseStateCount + 1;
        }
        runtime:sleep(1);
        int count = 0;
        lock {
            count = forceCloseStateCount;
        }
        if (count == 4) {
            runtime:sleep(5);
            unhealthyClientEP.circuitBreakerForceClose();
        }
        http:Response|error backendRes = unhealthyClientEP->forward("/unhealthy", request);
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

service /unhealthy on new http:Listener(8088, httpVersion = "1.1") {

    resource function 'default .(http:Caller caller, http:Request req) {
        int count = 0;
        lock {
            count = forceCloseStateCount;
        }
        http:Response res = new;
        if (count <= 3) {
            runtime:sleep(5);
        } else {
            res.setPayload("Hello World!!!");
        }
        error? responseToCaller = caller->respond(res);
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

//Test for circuit breaker forceClose functionality
final http:Client testForceCloseClient = check new("http://localhost:9308", httpVersion = "1.1");

@test:Config{
    dataProvider:forceCloseResponseDataProvider
}
function testForceClose(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponse(testForceCloseClient, "/cb/forceclose", dataFeed);
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
