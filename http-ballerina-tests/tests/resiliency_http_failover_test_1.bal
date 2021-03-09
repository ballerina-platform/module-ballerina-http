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
import ballerina/io;
import ballerina/mime;
import ballerina/lang.runtime as runtime;
import ballerina/test;
import ballerina/http;

listener http:Listener failoverEP01 = new(9301);

// Create an endpoint with port 8081 for the mock backend services.
listener http:Listener backendEP01 = new(8081);

// Define the failover client end point to call the backend services.
http:FailoverClient foBackendEP01 = check new({
    timeoutInMillis: 5000,
    failoverCodes: [501, 502, 503],
    intervalInMillis: 5000,
    // Define set of HTTP Clients that needs to be Failover.
    targets: [
        { url: "http://localhost:3467/inavalidEP" },
        { url: "http://localhost:8081/echo01" },
        { url: "http://localhost:8081/mock01" },
        { url: "http://localhost:8081/mock01" }
    ]
});

http:FailoverClient foBackendFailureEP01 = check new({
    timeoutInMillis: 5000,
    failoverCodes: [501, 502, 503],
    intervalInMillis: 5000,
    // Define set of HTTP Clients that needs to be Failover.
    targets: [
        { url: "http://localhost:3467/inavalidEP" },
        { url: "http://localhost:8081/echo01" },
        { url: "http://localhost:8081/echo01" }
    ]
});

http:FailoverClient foStatusCodesEP01 = check new({
    timeoutInMillis: 5000,
    failoverCodes: [501, 502, 503],
    intervalInMillis: 5000,
    // Define set of HTTP Clients that needs to be Failover.
    targets: [
        { url: "http://localhost:8081/failureStatusCodeService01" },
        { url: "http://localhost:8081/failureStatusCodeService01" },
        { url: "http://localhost:8081/failureStatusCodeService01" }
    ]
});

service /failoverDemoService01 on failoverEP01 {
    resource function 'default invokeAllFailureEndpoint01(http:Caller caller, http:Request request) {
        var backendRes = foBackendEP01->forward("/", <@untainted> request);
        if (backendRes is http:Response) {
            var responseToCaller = caller->respond(<@untainted> backendRes);
            if (responseToCaller is error) {
                log:printError("Error sending response", err = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(<@untainted> backendRes.message());
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", err = responseToCaller);
            }
        }
    }

    resource function 'default invokeAllFailureEndpoint(http:Caller caller, http:Request request) {
        var backendRes = foBackendFailureEP01->forward("/", <@untainted> request);
        if (backendRes is http:Response) {
            var responseToCaller = caller->respond(<@untainted> backendRes);
            if (responseToCaller is error) {
                log:printError("Error sending response", err = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(<@untainted> backendRes.message());
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", err = responseToCaller);
            }
        }
    }

    resource function 'default invokeAllFailureStatusCodesEndpoint(http:Caller caller, http:Request request) {
        var backendRes = foStatusCodesEP01->forward("/", <@untainted> request);
        if (backendRes is http:Response) {
            var responseToCaller = caller->respond(<@untainted> backendRes);
            if (responseToCaller is error) {
                log:printError("Error sending response", err = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(<@untainted> backendRes.message());
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", err = responseToCaller);
            }
        }
    }

    resource function 'default failoverStartIndex(http:Caller caller, http:Request request) {
        string startIndex = foBackendEP01.succeededEndpointIndex.toString();
        var backendRes = foBackendEP01->forward("/", <@untainted> request);
        if (backendRes is http:Response) {
            string responseMessage = "Failover start index is : " + startIndex;
            var responseToCaller = caller->respond(<@untainted> responseMessage);
            if (responseToCaller is error) {
                log:printError("Error sending response", err = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(<@untainted> backendRes.message());
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", err = responseToCaller);
            }
        }
    }
}

// Define the sample service to mock connection timeouts and service outages.
service /echo01 on backendEP01 {
    resource function 'default .(http:Caller caller, http:Request req) {
        http:Response outResponse = new;
        // Delay the response for 30000 milliseconds to mimic network level delays.
        runtime:sleep(30);
        var responseToCaller = caller->respond("echo Resource is invoked");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
}

int counter01 = 1;
// Define the sample service to mock a healthy service.
service /mock01 on backendEP01 {
    resource function 'default .(http:Caller caller, http:Request req) {
        counter01 += 1;
        if (counter01 % 5 == 0) {
            runtime:sleep(30000);
        }
        http:Response response = new;
        if (req.hasHeader(mime:CONTENT_TYPE)
            && req.getContentType().startsWith(http:MULTIPART_AS_PRIMARY_TYPE)) {
            var mimeEntity = req.getBodyParts();
            if (mimeEntity is error) {
                log:printError(mimeEntity.message());
                response.setPayload("Error in decoding multiparts!");
                response.statusCode = 500;
            } else {
                foreach var bodyPart in mimeEntity {
                    if (bodyPart.hasHeader(mime:CONTENT_TYPE)
                        && bodyPart.getContentType().startsWith(http:MULTIPART_AS_PRIMARY_TYPE)) {
                        var nestedMimeEntity = bodyPart.getBodyParts();
                        if (nestedMimeEntity is error) {
                            log:printError(nestedMimeEntity.message());
                            response.setPayload("Error in decoding nested multiparts!");
                            response.statusCode = 500;
                        } else {
                            mime:Entity[] childParts = nestedMimeEntity;
                            foreach var childPart in childParts {
                                // When performing passthrough scenarios, message needs to be built before
                                // invoking the endpoint to create a message datasource.
                                var childBlobContent = childPart.getByteArray();
                            }
                            io:println(bodyPart.getContentType());
                            bodyPart.setBodyParts(<@untainted> childParts, <@untainted> bodyPart.getContentType());
                        }
                    } else {
                        var bodyPartBlobContent = bodyPart.getByteArray();
                    }
                }
                response.setBodyParts(<@untainted> mimeEntity, <@untainted> req.getContentType());
            }
        } else {
            response.setPayload("Mock Resource is Invoked.");
        }

        var responseToCaller = caller->respond(response);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
}

// Define the sample service to mock connection timeouts and service outages.
service /failureStatusCodeService01 on backendEP01 {
    resource function 'default .(http:Caller caller, http:Request req) {
        http:Response outResponse = new;
        outResponse.statusCode = 503;
        outResponse.setPayload("Failure status code scenario");
        var responseToCaller = caller->respond(outResponse);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", err = responseToCaller);
        }
    }
}

//Test failover functionality with multipart requests
@test:Config {}
function testFailoverWithMultiPart() {
    test:assertTrue(externTestMultiPart(9301, "failoverDemoService01/invokeAllFailureEndpoint01"));
}
