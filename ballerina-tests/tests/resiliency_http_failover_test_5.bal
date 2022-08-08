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

listener http:Listener failoverEP05 = new(9305, httpVersion = http:HTTP_1_1);

// Create an endpoint with port 8085 for the mock backend services.
listener http:Listener backendEP05 = new(8085, httpVersion = http:HTTP_1_1);

// Define the failover client end point to call the backend services.
final http:FailoverClient foBackendEP05 = check new(
    httpVersion = http:HTTP_1_1,
    timeout = 5,
    failoverCodes = [501, 502, 503],
    interval = 5,
    // Define set of HTTP Clients that needs to be Failover.
    targets = [
        { url: "http://localhost:3467/inavalidEP" },
        { url: "http://localhost:8085/delay" },
        { url: "http://localhost:8085/mock05" }
    ]
);

service /failoverDemoService05 on failoverEP05 {
    resource function 'default failoverStartIndex(http:Caller caller, http:Request request) {
        string startIndex = foBackendEP05.getSucceededEndpointIndex().toString();
        http:Response|error backendRes = foBackendEP05->forward("/", request);
        if backendRes is http:Response {
            string responseMessage = "Failover start index is : " + startIndex;
            error? responseToCaller = caller->respond(responseMessage);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(backendRes.message());
            error? responseToCaller = caller->respond(response);
            if responseToCaller is error {
                // log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }
}

// Define the sample service to mock connection timeouts and service outages.
service /delay on backendEP05 {
    resource function 'default .(http:Caller caller, http:Request req) {
        // Delay the response for 30000 milliseconds to mimic network level delays.
        runtime:sleep(30);
        error? responseToCaller = caller->respond("Delayed resource is invoked");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

// Define the sample service to mock a healthy service.
service /mock05 on backendEP05 {
    resource function 'default .(http:Caller caller, http:Request req) {
        error? responseToCaller = caller->respond("Mock Resource is Invoked.");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

//Test to verify whether failover will test from last successful endpoint
@test:Config {}
function testFailoverStartingPosition() returns error? {
    http:Client testClient = check new("http://localhost:9305", httpVersion = http:HTTP_1_1);
    http:Response|error response = testClient->post("/failoverDemoService05/failoverStartIndex", requestPayload);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Failover start index is : 0");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    
    response = testClient->post("/failoverDemoService05/failoverStartIndex", requestPayload);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Failover start index is : 2");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
