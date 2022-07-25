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

listener http:Listener circuitBreakerEP04 = new(9310, httpVersion = "1.1");

http:ClientConfiguration conf04 = {
    httpVersion: "1.1",
    circuitBreaker: {
        rollingWindow: {
            timeWindow: 60,
            bucketSize: 20,
            requestVolumeThreshold: 6
        },
        failureThreshold: 0.3,
        resetTime: 10,
        statusCodes: [500, 502, 503]
    },
    timeout: 2
};

final http:Client errornousClientEP = check new("http://localhost:8090", conf04);

service /cb on circuitBreakerEP04 {

    resource function 'default requestvolume(http:Caller caller, http:Request request) {
        http:Response|error backendRes = errornousClientEP->post("/errornous", request);
        handleBackendResponse(caller, backendRes);
    }
}

service /errornous on new http:Listener(8090, httpVersion = "1.1") {
    
    resource function 'default .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
        res.setPayload("Internal error occurred while processing the request.");
        error? responseToCaller = caller->respond(res);
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

//Test for circuit breaker requestVolumeThreshold functionality
final http:Client testRequestVolumeClient = check new("http://localhost:9310", httpVersion = "1.1");

@test:Config{ 
    groups: ["circuitBreakerRequestVolume"],
    dataProvider:requestVolumeResponseDataProvider 
}
function requestVolumeTest(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponse(testRequestVolumeClient, "/cb/requestvolume", dataFeed);
}

function requestVolumeResponseDataProvider() returns DataFeed[][] {
    return [
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:INTERNAL_ERROR_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:INTERNAL_ERROR_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:INTERNAL_ERROR_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:INTERNAL_ERROR_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:INTERNAL_ERROR_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:INTERNAL_ERROR_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}]
    ];
}
