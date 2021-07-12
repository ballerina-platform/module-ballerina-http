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

listener http:Listener failoverEP00 = new(9300);

// Create an endpoint with port 8080 for the mock backend services.
listener http:Listener backendEP00 = new(8080);

// Define the failover client end point to call the backend services.
http:FailoverClient foBackendEP00 = check new(
    timeout = 5,
    failoverCodes = [501, 502, 503],
    interval = 5,
    // Define set of HTTP Clients that needs to be Failover.
    targets = [
        { url: "http://localhost:3467/inavalidEP" },
        { url: "http://localhost:8080/echo00" },
        { url: "http://localhost:8080/mockResource" },
        { url: "http://localhost:8080/mockResource" }
    ]
);

http:FailoverClient foBackendFailureEP00 = check new({
    timeout: 5,
    failoverCodes: [501, 502, 503],
    interval: 5,
    // Define set of HTTP Clients that needs to be Failover.
    targets: [
        { url: "http://localhost:3467/inavalidEP" },
        { url: "http://localhost:8080/echo00" },
        { url: "http://localhost:8080/echo00" }
    ]
});

http:FailoverClient foStatusCodesEP00 = check new({
    timeout: 5,
    failoverCodes: [501, 502, 503],
    interval: 5,
    // Define set of HTTP Clients that needs to be Failover.
    targets: [
        { url: "http://localhost:8080/failureStatusCodeService" },
        { url: "http://localhost:8080/failureStatusCodeService" },
        { url: "http://localhost:8080/failureStatusCodeService" }
    ]
});

service /failoverDemoService00 on failoverEP00 {
    resource function 'default typical(http:Caller caller, http:Request request) {
        http:Response|error backendRes = foBackendEP00->forward("/", request);
        if (backendRes is http:Response) {
            error? responseToCaller = caller->respond(backendRes);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(backendRes.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function 'default invokeAllFailureEndpoint(http:Caller caller, http:Request request) {
        http:Response|error backendRes = foBackendFailureEP00->forward("/", request);
        if (backendRes is http:Response) {
            error? responseToCaller = caller->respond(backendRes);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(backendRes.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function 'default invokeAllFailureStatusCodesEndpoint(http:Caller caller, http:Request request) {
        http:Response|error backendRes = foStatusCodesEP00->forward("/", request);
        if (backendRes is http:Response) {
            error? responseToCaller = caller->respond(backendRes);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(backendRes.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }

    resource function 'default failoverStartIndex(http:Caller caller, http:Request request) {
        string startIndex = foBackendEP00.getSucceededEndpointIndex().toString();
        http:Response|error backendRes = foBackendEP00->forward("/", request);
        if (backendRes is http:Response) {
            string responseMessage = "Failover start index is : " + startIndex;
            error? responseToCaller = caller->respond(responseMessage);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(backendRes.message());
            error? responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", 'error = responseToCaller);
            }
        }
    }
}

// Define the sample service to mock connection timeouts and service outages.
service /echo00 on backendEP00 {
    resource function 'default .(http:Caller caller, http:Request req) {
        http:Response outResponse = new;
        // Delay the response for 30000 milliseconds to mimic network level delays.
        runtime:sleep(30000);
        error? responseToCaller = caller->respond("echo Resource is invoked");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

int counter00 = 1;
// Define the sample service to mock a healthy service.
service /mockResource on backendEP00 {
    resource function 'default .(http:Caller caller, http:Request req) {
        counter00 += 1;
        if (counter00 % 5 == 0) {
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
                                byte[]|error childBlobContent = childPart.getByteArray();
                            }
                            io:println(bodyPart.getContentType());
                            bodyPart.setBodyParts(childParts, bodyPart.getContentType());
                        }
                    } else {
                        byte[]|error bodyPartBlobContent = bodyPart.getByteArray();
                    }
                }
                response.setBodyParts(mimeEntity, req.getContentType());
            }
        } else {
            response.setPayload("Mock Resource is Invoked.");
        }
        error? responseToCaller = caller->respond(response);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

// Define the sample service to mock connection timeouts and service outages.
service /failureStatusCodeService on backendEP00 {
    resource function 'default .(http:Caller caller, http:Request req) {
        http:Response outResponse = new;
        outResponse.statusCode = 503;
        outResponse.setPayload("Failure status code scenario");
        error? responseToCaller = caller->respond(outResponse);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", 'error = responseToCaller);
        }
    }
}

//Test basic failover functionality
@test:Config {}
function testSimpleFailover() {
    http:Client testClient = checkpanic new("http://localhost:9300");
    http:Response|error response = testClient->post("/failoverDemoService00/typical", requestPayload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Mock Resource is Invoked.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
