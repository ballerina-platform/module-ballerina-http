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
import ballerina/test;
import ballerina/http;

listener http:Listener circuitBreakerEP04 = new(9310);

http:ClientConfiguration conf04 = {
    circuitBreaker: {
        rollingWindow: {
            timeWindowInMillis: 60000,
            bucketSizeInMillis: 20000,
            requestVolumeThreshold: 6
        },
        failureThreshold: 0.3,
        resetTimeInMillis: 10000,
        statusCodes: [500, 502, 503]
    },
    timeoutInMillis: 2000
};

http:Client errornousClientEP = new("http://localhost:8090", conf04);

service /cb on circuitBreakerEP04 {

    resource function 'default requestvolume(http:Caller caller, http:Request request) {
        var backendRes = errornousClientEP->forward("/errornous", request);
        if (backendRes is http:Response) {
            var responseToCaller = caller->respond(<@untainted> backendRes);
            if (responseToCaller is error) {
                log:printError("Error sending response", err = responseToCaller);
            }
        } else if (backendRes is error) {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(<@untainted> backendRes.message());
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", err = responseToCaller);
            }
        }
    }
}

service /errornous on new http:Listener(8090) {
    
    resource function 'default .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
        res.setPayload("Internal error occurred while processing the request.");
        var responseToCaller = caller->respond(res);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
}

//Test for circuit breaker requestVolumeThreshold functionality
http:Client testRequestVolumeClient = new("http://localhost:9310");

@test:Config{ dataProvider:requestVolumeResponseDataProvider }
function requestVolumeTest(DataFeed dataFeed) {
    invokeApiAndVerifyResponse(testRequestVolumeClient, "/cb/requestvolume", dataFeed);
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
