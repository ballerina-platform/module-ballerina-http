// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/test;

http:ClientConfiguration conf1 = {
    circuitBreaker: {
        rollingWindow: {
            timeWindow: 10,
            bucketSize: 2,
            requestVolumeThreshold: 0
        },
        failureThreshold: 0.2,
        resetTime: 10
    },
    timeout: 2
};

http:Client cbrBackend = check new ("http://localhost:" + cBClientWithoutStatusCodesTestPort1.toString(), conf1);
http:Client cbrClient = check new ("http://localhost:" + cBClientWithoutStatusCodesTestPort2.toString());
http:Client nonExistingBackend = check new ("https://nuwandiasbanda.com", conf1);

service / on new http:Listener(cBClientWithoutStatusCodesTestPort2) {

    resource function get test1() returns string|error {
        return cbrBackend->get("/hello");
    }

    resource function get test2() returns string|error {
        return nonExistingBackend->get("/hello");
    }
}

service / on new http:Listener(cBClientWithoutStatusCodesTestPort1) {
    private int counter = 1;
    resource function get hello() returns string|http:InternalServerError {
         if (self.counter % 5 == 3) {
             self.counter += 1;
             return {body:"Internal error occurred while processing the request."};
         } else {
            self.counter += 1;
            return "Hello World!!!";
        }
    }
}

@test:Config {
    dataProvider: responseDataProvider1
}
function testCircuitBreakerWithoutStatusCodes1(DataFeed dataFeed) {
    invokeApiAndVerifyResponseWithHttpGet(cbrClient, "/test1", dataFeed);
}

function responseDataProvider1() returns DataFeed[][] {
    return [
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}],
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:INTERNAL_ERROR_MESSAGE}],
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}],
        [{responseCode:SC_OK, message:SUCCESS_HELLO_MESSAGE}]
    ];
}

// Issue https://github.com/ballerina-platform/ballerina-standard-library/issues/305
@test:Config {
    enable: false,
    dataProvider: responseDataProvider2
}
function testCircuitBreakerWithoutStatusCodes2(DataFeed dataFeed) {
    invokeApiAndVerifyResponseWithHttpGet(cbrClient, "/test2", dataFeed);
}

function responseDataProvider2() returns DataFeed[][] {
    return [
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:"Something wrong with the connection"}],
        [{responseCode:SC_INTERNAL_SERVER_ERROR, message:UPSTREAM_UNAVAILABLE_MESSAGE}]
    ];
}
