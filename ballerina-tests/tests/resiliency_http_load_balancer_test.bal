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

listener http:Listener LBbackendListener = new(8093, httpVersion = http:HTTP_1_1);

final http:LoadBalanceClient lbBackendEP = check new(
    httpVersion = http:HTTP_1_1,
    targets = [
        { url: "http://localhost:8093/LBMock1" },
        { url: "http://localhost:8093/LBMock2" },
        { url: "http://localhost:8093/LBMock3" }
    ],
    timeout = 5
);

final http:LoadBalanceClient lbFailoverBackendEP = check new(
    httpVersion = http:HTTP_1_1,
    targets = [
        { url: "http://localhost:8093/LBMock4" },
        { url: "http://localhost:8093/LBMock2" },
        { url: "http://localhost:8093/LBMock3" }
    ],
    failover = true,
    timeout = 2
);

final http:LoadBalanceClient delayedBackendEP = check new(
    httpVersion = http:HTTP_1_1,
    targets = [
        { url: "http://localhost:8093/LBMock4" },
        { url: "http://localhost:8093/LBMock5" }
    ],
    failover = true,
    timeout = 2
);

CustomLoadBalancerRule customLbRule = new CustomLoadBalancerRule(2);

final http:LoadBalanceClient customLbBackendEP = check new(
    httpVersion = http:HTTP_1_1,
    targets = [
        { url: "http://localhost:8093/LBMock1" },
        { url: "http://localhost:8093/LBMock2" },
        { url: "http://localhost:8093/LBMock3" }
    ],
    lbRule = customLbRule,
    timeout = 5
);

service /loadBalancerDemoService on new http:Listener(9313, httpVersion = http:HTTP_1_1) {
    resource function 'default roundRobin(http:Caller caller, http:Request req) {
        json requestPayload = { "name": "Ballerina" };
        http:Response|error response = lbBackendEP->post("/", requestPayload);
        if response is http:Response {
            error? responseToCaller = caller->respond(response);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response outResponse = new;
            outResponse.statusCode = 500;
            outResponse.setPayload(response.message());
            error? responseToCaller = caller->respond(outResponse);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function 'default lbFailover(http:Caller caller, http:Request req) {
        json requestPayload = { "name": "Ballerina" };
        http:Response|error response = lbFailoverBackendEP->post("/", requestPayload);
        if response is http:Response {
            error? responseToCaller = caller->respond(response);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response outResponse = new;
            outResponse.statusCode = 500;
            outResponse.setPayload(response.message());
            error? responseToCaller = caller->respond(outResponse);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function 'default delayResource(http:Caller caller, http:Request req) {
        json requestPayload = { "name": "Ballerina" };
        http:Response|error response = delayedBackendEP->post("/", requestPayload);
        if response is http:Response {
            error? responseToCaller = caller->respond(response);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response outResponse = new;
            outResponse.statusCode = 500;
            outResponse.setPayload(response.message());
            error? responseToCaller = caller->respond(outResponse);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function 'default customResource(http:Caller caller, http:Request req) {
        json requestPayload = { "name": "Ballerina" };
        http:Response|error response = customLbBackendEP->post("/", requestPayload);
        if response is http:Response {
            error? responseToCaller = caller->respond(response);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response outResponse = new;
            outResponse.statusCode = 500;
            outResponse.setPayload(response.message());
            error? responseToCaller = caller->respond(outResponse);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }
}

service /LBMock1 on LBbackendListener {
    resource function 'default .(http:Caller caller, http:Request req) {
        error? responseToCaller = caller->respond("Mock1 Resource is Invoked.");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

service /LBMock2 on LBbackendListener {
    resource function 'default .(http:Caller caller, http:Request req) {
        error? responseToCaller = caller->respond("Mock2 Resource is Invoked.");
        if (responseToCaller is error) {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

service /LBMock3 on LBbackendListener {
    resource function 'default .(http:Caller caller, http:Request req) {
        error? responseToCaller = caller->respond("Mock3 Resource is Invoked.");
        if (responseToCaller is error) {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

service /LBMock4 on LBbackendListener {
    resource function 'default .(http:Caller caller, http:Request req) {
        runtime:sleep(5);
        error? responseToCaller = caller->respond("Mock4 Resource is Invoked.");
        if (responseToCaller is error) {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

service /LBMock5 on LBbackendListener {
    resource function 'default .(http:Caller caller, http:Request req) {
        runtime:sleep(5);
        error? responseToCaller = caller->respond("Mock5 Resource is Invoked.");
        if (responseToCaller is error) {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

# Implementation of custom load balancing strategy.
#
# + index - Keep tracks the current point of the CallerActions[]
public isolated class CustomLoadBalancerRule {

    private int index;

    public function init(int index) {
        self.index = index;
    }

    # Provides an HTTP client which is choosen according to the custom algorithm.
    #
    # + loadBalanceClientsArray - Array of HTTP clients which needs to be load balanced
    # + return - Choosen `CallerActions` from the algorithm or an `error` for a failure in
    #            the algorithm implementation
    public isolated function getNextClient(http:Client?[] loadBalanceClientsArray) returns http:Client|http:ClientError {
        lock {
            http:Client httpClient = <http:Client>loadBalanceClientsArray[self.index];
            if (self.index >= loadBalanceClientsArray.length()) {
                return error http:AllLoadBalanceEndpointsFailedError("Provided index is doesn't match with the targets.");
            }
            lock {
                if (self.index == (loadBalanceClientsArray.length() - 1)) {
                    httpClient = <http:Client>loadBalanceClientsArray[self.index];
                    self.index = 0;
                } else {
                    httpClient = <http:Client>loadBalanceClientsArray[self.index];
                    self.index += 1;
                }
            }
            return httpClient;
        }
    }
}

//Test for round robin implementation algorithm of load balancer
final http:Client roundRobinLoadBalanceTestClient = check new("http://localhost:9313", httpVersion = http:HTTP_1_1);

@test:Config{ dataProvider:roundRobinResponseDataProvider }
function roundRobinLoadBalanceTest(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponse(roundRobinLoadBalanceTestClient, "/loadBalancerDemoService/roundRobin", dataFeed);
}

function roundRobinResponseDataProvider() returns DataFeed[][] {
    return [
        [{responseCode:SC_OK, message:MOCK_1_INVOKED}],
        [{responseCode:SC_OK, message:MOCK_2_INVOKED}],
        [{responseCode:SC_OK, message:MOCK_3_INVOKED}],
        [{responseCode:SC_OK, message:MOCK_1_INVOKED}]
    ];
}

//Test for verify failover behavior with load balancer
@test:Config{ dataProvider:roundRobinWithFailoverResponseDataProvider }
function roundRobinWithFailoverResponseTest(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponse(roundRobinLoadBalanceTestClient, "/loadBalancerDemoService/lbFailover", dataFeed);
}

function roundRobinWithFailoverResponseDataProvider() returns DataFeed[][] {
    return [
        [{responseCode:SC_OK, message:MOCK_2_INVOKED}],
        [{responseCode:SC_OK, message:MOCK_3_INVOKED}],
        [{responseCode:SC_OK, message:MOCK_2_INVOKED}]
    ];
}

//Test for verify the error message when all endpoints are failing
@test:Config{}
function testAllLbEndpointFailure() returns error? {
    string expectedMessage = "All the load balance endpoints failed. Last error was: Idle timeout triggered " +
                "before initiating inbound response";
    http:Response|error response = roundRobinLoadBalanceTestClient->post("/loadBalancerDemoService/delayResource", requestPayload);
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTrueTextPayload(response.getTextPayload(), expectedMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test for custom algorithm implementation of load balancer
@test:Config{ dataProvider:customLbResponseDataProvider }
function customLbResponseTest(DataFeed dataFeed) returns error? {
    check invokeApiAndVerifyResponse(roundRobinLoadBalanceTestClient, "/loadBalancerDemoService/customResource", dataFeed);
}

function customLbResponseDataProvider() returns DataFeed[][] {
    return [
        [{responseCode:SC_OK, message:MOCK_3_INVOKED}],
        [{responseCode:SC_OK, message:MOCK_1_INVOKED}],
        [{responseCode:SC_OK, message:MOCK_2_INVOKED}],
        [{responseCode:SC_OK, message:MOCK_3_INVOKED}]
    ];
}
