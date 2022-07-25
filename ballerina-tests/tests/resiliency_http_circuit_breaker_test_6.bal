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

listener http:Listener circuitBreakerEP05 = new(9311, httpVersion = "1.1");

http:ClientConfiguration conf05 = {
    httpVersion: "1.1",
    circuitBreaker: {
        rollingWindow: {
            timeWindow: 60,
            bucketSize: 20,
            requestVolumeThreshold: 3
        },
        failureThreshold: 0.3,
        resetTime: 1,
        statusCodes: [501, 502, 503]
    },
    timeout: 2
};

final http:Client backendClientEP05 = check new("http://localhost:8091", conf05);

service /cb on circuitBreakerEP05 {

    resource function 'default statuscode(http:Caller caller, http:Request request) {
        http:Response|error backendRes = backendClientEP05->execute("POST", "/statuscode", request);
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

service /statuscode on new http:Listener(8091, httpVersion = "1.1") {

    resource function 'default .(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.statusCode = http:STATUS_SERVICE_UNAVAILABLE;
        res.setPayload("Service unavailable.");
        error? responseToCaller = caller->respond(res);
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

//Test for circuit breaker failure status codes functionality 
final http:Client testCBStatusCodesClient = check new("http://localhost:9311", httpVersion = "1.1");

@test:Config{ 
    groups: ["circuitBreakerStatusCodeResponse"],
    dataProvider:statusCodeResponseDataProvider 
}
function httpStatusCodesTest(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponse(testCBStatusCodesClient, "/cb/statuscode", dataFeed);
}

function statusCodeResponseDataProvider() returns DataFeed[][] {
    return [
        [{responseCode:SC_SERVICE_UNAVAILABLE, message:SERVICE_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_SERVICE_UNAVAILABLE, message:SERVICE_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_SERVICE_UNAVAILABLE, message:SERVICE_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}]
    ];
}
