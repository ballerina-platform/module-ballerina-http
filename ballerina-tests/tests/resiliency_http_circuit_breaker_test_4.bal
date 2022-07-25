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

listener http:Listener circuitBreakerEP03 = new(9309, httpVersion = "1.1");

http:ClientConfiguration conf03 = {
    httpVersion: "1.1",
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

final http:Client simpleClientEP = check new("http://localhost:8089", conf03);

service /cb on circuitBreakerEP03 {

    resource function 'default getstate(http:Caller caller, http:Request request) {
        http:Response|error backendRes = simpleClientEP->forward("/simple", request);
        http:CircuitState currentState = simpleClientEP.getCircuitBreakerCurrentState();
        if backendRes is http:Response {
            if (!(currentState == http:CB_CLOSED_STATE)) {
                backendRes.setPayload("Circuit Breaker is not in correct state state");
            }
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

service /simple on new http:Listener(8089, httpVersion = "1.1") {
    
    resource function 'default .(http:Caller caller, http:Request req) {
        error? responseToCaller = caller->respond("Hello World!!!");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

//Test for circuit breaker getState functionality
final http:Client testGetStateClient = check new("http://localhost:9309", httpVersion = "1.1");

@test:Config{ dataProvider:getStateResponseDataProvider }
function testGetState(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponse(testGetStateClient, "/cb/getstate", dataFeed);
}

function getStateResponseDataProvider() returns DataFeed[][] {
    return [
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}],
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}],
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}]
    ];
}
