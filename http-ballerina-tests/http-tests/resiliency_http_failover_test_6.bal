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
import ballerina/http;

listener http:Listener failoverEP05 = new(9305);

// Create an endpoint with port 8085 for the mock backend services.
listener http:Listener backendEP05 = new(8085);

// Define the failover client end point to call the backend services.
http:FailoverClient foBackendEP05 = new({
    timeoutInMillis: 5000,
    failoverCodes: [501, 502, 503],
    intervalInMillis: 5000,
    // Define set of HTTP Clients that needs to be Failover.
    targets: [
        { url: "http://localhost:3467/inavalidEP" },
        { url: "http://localhost:8085/delay" },
        { url: "http://localhost:8085/mock" }
    ]
});

@http:ServiceConfig {
    basePath: "/fo"
}
service failoverDemoService05 on failoverEP05 {
    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/index"
    }
    resource function failoverStartIndex(http:Caller caller, http:Request request) {
        string startIndex = foBackendEP05.succeededEndpointIndex.toString();
        var backendRes = foBackendEP05->forward("/", <@untainted> request);
        if (backendRes is http:Response) {
            string responseMessage = "Failover start index is : " + startIndex;
            var responseToCaller = caller->respond(<@untainted> responseMessage);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        } else if (backendRes is error) {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(<@untainted> backendRes.message());
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        }
    }
}

// Define the sample service to mock connection timeouts and service outages.
@http:ServiceConfig {
    basePath: "/delay"
}
service echo05 on backendEP05 {
    @http:ResourceConfig {
        methods: ["POST", "PUT", "GET"],
        path: "/"
    }
    resource function delayResource(http:Caller caller, http:Request req) {
        // Delay the response for 30000 milliseconds to mimic network level delays.
        runtime:sleep(30000);
        var responseToCaller = caller->respond("Delayed resource is invoked");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", responseToCaller);
        }
    }
}

// Define the sample service to mock a healthy service.
@http:ServiceConfig {
    basePath: "/mock"
}
service mock05 on backendEP05 {
    @http:ResourceConfig {
        methods: ["POST", "PUT", "GET"],
        path: "/"
    }
    resource function mockResource(http:Caller caller, http:Request req) {
        var responseToCaller = caller->respond("Mock Resource is Invoked.");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", responseToCaller);
        }
    }
}

//Test to verify whether failover will test from last successful endpoint
@test:Config {}
function testFailoverStartingPosition() {
    http:Client testClient = new("http://localhost:9305");
    var response = testClient->post("/fo/index", requestPayload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Failover start index is : 0");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    
    response = testClient->post("/fo/index", requestPayload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Failover start index is : 2");
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
