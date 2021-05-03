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

import ballerina/log;
import ballerina/test;
import ballerina/http;

listener http:Listener http2RetryTestserviceEndpoint1 = new(http2RetryFunctionTestPort1, { httpVersion: "2.0" });
listener http:Listener http2RetryTestserviceEndpoint2 = new(http2RetryFunctionTestPort2, { httpVersion: "2.0" });

http:Client http2RetryFunctionTestClient = check new("http://localhost:" + http2RetryFunctionTestPort1.toString(), { httpVersion: "2.0" });

// Define the end point to the call the `mockHelloService`.
http:Client http2RetryBackendClientEP = check new("http://localhost:" + http2RetryFunctionTestPort1.toString(), {
    // Retry configuration options.
    retryConfig: {
        interval: 3,
        count: 3,
        backOffFactor: 0.5
    },
    timeout: 2,
    httpVersion: "2.0"
});

http:Client http2InternalErrorEP = check new("http://localhost:" + http2RetryFunctionTestPort2.toString(), {
    retryConfig: {
        interval: 3,
        count: 3,
        backOffFactor: 2.0,
        maxWaitInterval: 20,
        statusCodes: [501, 502, 503]
    },
    timeout: 2,
    httpVersion: "2.0"
});

service /retryDemoService on http2RetryTestserviceEndpoint1 {
    // Create a REST resource within the API.
    // Parameters include a reference to the caller endpoint and an object of
    // the request data.
    resource function 'default .(http:Caller caller, http:Request request) {
        var backendFuture = http2RetryBackendClientEP->submit("GET", "/mockHelloService", request);
        if (backendFuture is http:HttpFuture) {
            var backendResponse = http2RetryBackendClientEP->getResponse(backendFuture);
            if (backendResponse is http:Response) {
                error? responseToCaller = caller->respond(<@untainted> backendResponse);
                if (responseToCaller is error) {
                    log:printError("Error sending response", 'error = responseToCaller);
                }
            } else {
                http:Response response = new;
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                response.setPayload(<@untainted> backendResponse.message());
                error? responseToCaller = caller->respond(response);
                if (responseToCaller is error) {
                    log:printError("Error sending response", 'error = responseToCaller);
                }
            }
        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setPayload(<@untainted> (<error>backendFuture).message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }
}

int http2RetryCount = 0;

// This sample service is used to mock connection timeouts and service outages.
// The service outage is mocked by stopping/starting this service.
// This should run separately from the `retryDemoService` service.
service /mockHelloService on http2RetryTestserviceEndpoint1 {
    resource function get .(http:Caller caller, http:Request request) {
        http2RetryCount = http2RetryCount + 1;
        waitForRetry(http2RetryCount);
        http:Response res = new;
        error? responseToCaller = caller->respond("Hello World!!!");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

//Test basic retry functionality with HTTP2
@test:Config {
    groups: ["http2RetryClientTest"]
}
function testHttp2SimpleRetry() {
    json payload = {Name:"Ballerina"};
    var response = http2RetryFunctionTestClient->post("/retryDemoService", payload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
