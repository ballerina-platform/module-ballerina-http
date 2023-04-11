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
import ballerina/io;
import ballerina/mime;
import ballerina/lang.runtime as runtime;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener failoverEP03 = new (9303, httpVersion = http:HTTP_1_1);

// Create an endpoint with port 8083 for the mock backend services.
listener http:Listener backendEP03 = new (8083, httpVersion = http:HTTP_1_1);

// Define the failover client end point to call the backend services.
final http:FailoverClient foBackendEP03 = check new (
    httpVersion = http:HTTP_1_1,
    timeout = 5,
    failoverCodes = [501, 502, 503],
    interval = 5,
    // Define set of HTTP Clients that needs to be Failover.
    targets = [
    {url: "http://localhost:3467/inavalidEP"},
    {url: "http://localhost:8083/echo03"},
    {url: "http://localhost:8083/mock03"},
    {url: "http://localhost:8083/mock03"}
]
);

final http:FailoverClient foBackendFailureEP03 = check new (
    httpVersion = http:HTTP_1_1,
    timeout = 5,
    failoverCodes = [501, 502, 503],
    interval = 5,
    // Define set of HTTP Clients that needs to be Failover.
    targets = [
    {url: "http://localhost:3467/inavalidEP"},
    {url: "http://localhost:8083/echo03"},
    {url: "http://localhost:8083/echo03"}
]
);

final http:FailoverClient foStatusCodesEP03 = check new (
    httpVersion = http:HTTP_1_1,
    timeout = 5,
    failoverCodes = [501, 502, 503],
    interval = 5,
    // Define set of HTTP Clients that needs to be Failover.
    targets = [
    {url: "http://localhost:8083/failureStatusCodeService03"},
    {url: "http://localhost:8083/failureStatusCodeService03"},
    {url: "http://localhost:8083/failureStatusCodeService03"}
]
);

service /failoverDemoService03 on failoverEP03 {
    resource function 'default invokeAllFailureEndpoint03(http:Caller caller, http:Request request) {
        http:Response|error backendRes = foBackendEP03->forward("/", request);
        if backendRes is http:Response {
            error? responseToCaller = caller->respond(backendRes);
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

    resource function 'default invokeAllFailureEndpoint(http:Caller caller, http:Request request) {
        http:Response|error backendRes = foBackendFailureEP03->forward("/", request);
        if backendRes is http:Response {
            error? responseToCaller = caller->respond(backendRes);
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

    resource function 'default invokeAllFailureStatusCodesEndpoint(http:Caller caller, http:Request request) {
        http:Response|error backendRes = foStatusCodesEP03->forward("/", request);
        if backendRes is http:Response {
            error? responseToCaller = caller->respond(backendRes);
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

    resource function 'default failoverStartIndex(http:Caller caller, http:Request request) {
        string startIndex = foBackendEP03.getSucceededEndpointIndex().toString();
        http:Response|error backendRes = foBackendEP03->forward("/", request);
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
service /echo03 on backendEP03 {
    resource function 'default .(http:Caller caller, http:Request req) {
        // Delay the response for 30000 milliseconds to mimic network level delays.
        runtime:sleep(30);
        error? responseToCaller = caller->respond("echo Resource is invoked");
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

int counter03 = 1;

// Define the sample service to mock a healthy service.
service /mock03 on backendEP03 {
    resource function 'default .(http:Caller caller, http:Request req) {
        int count = 0;
        lock {
            counter03 += 1;
            count = counter03;
        }
        if count % 5 == 0 {
            runtime:sleep(30);
        }
        http:Response response = new;
        if req.hasHeader(mime:CONTENT_TYPE)
            && req.getContentType().startsWith(http:MULTIPART_AS_PRIMARY_TYPE) {
            var mimeEntity = req.getBodyParts();
            if mimeEntity is error {
                // log:printError(mimeEntity.message());
                response.setPayload("Error in decoding multiparts!");
                response.statusCode = 500;
            } else {
                foreach var bodyPart in mimeEntity {
                    if bodyPart.hasHeader(mime:CONTENT_TYPE)
                        && bodyPart.getContentType().startsWith(http:MULTIPART_AS_PRIMARY_TYPE) {
                        var nestedMimeEntity = bodyPart.getBodyParts();
                        if nestedMimeEntity is error {
                            // log:printError(nestedMimeEntity.message());
                            response.setPayload("Error in decoding nested multiparts!");
                            response.statusCode = 500;
                        } else {
                            mime:Entity[] childParts = nestedMimeEntity;
                            foreach var childPart in childParts {
                                // When performing passthrough scenarios, message needs to be built before
                                // invoking the endpoint to create a message datasource.
                                byte[]|error childBlobContent = childPart.getByteArray();
                                if childBlobContent is error {
                                    // log:printError("Error reading payload", 'error = childBlobContent);
                                }
                            }
                            io:println(bodyPart.getContentType());
                            bodyPart.setBodyParts(childParts, bodyPart.getContentType());
                        }
                    } else {
                        byte[]|error bodyPartBlobContent = bodyPart.getByteArray();
                        if bodyPartBlobContent is error {
                            // log:printError("Error reading payload", 'error = bodyPartBlobContent);
                        }
                    }
                }
                response.setBodyParts(mimeEntity, req.getContentType());
            }
        } else {
            response.setPayload("Mock Resource is Invoked.");
        }

        error? responseToCaller = caller->respond(response);
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

// Define the sample service to mock connection timeouts and service outages.
service /failureStatusCodeService03 on backendEP03 {
    resource function 'default .(http:Caller caller, http:Request req) {
        http:Response outResponse = new;
        outResponse.statusCode = 503;
        outResponse.setPayload("Failure status code scenario");
        error? responseToCaller = caller->respond(outResponse);
        if responseToCaller is error {
            // log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

//Test the functionality for all endpoints failure scenario
@test:Config
function testAllEndpointFailure() returns error? {
    string expectedMessage = "All the failover endpoints failed. Last error was: " +
                "Idle timeout triggered before initiating inbound response";
    http:Client testClient = check new ("http://localhost:9303", httpVersion = http:HTTP_1_1);
    http:Response|error response = testClient->post("/failoverDemoService03/invokeAllFailureEndpoint", requestPayload);
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), expectedMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
