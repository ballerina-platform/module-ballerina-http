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
import ballerina/runtime;
import ballerina/test;
import http;

listener http:Listener failoverEP00 = new(9300);

// Create an endpoint with port 8080 for the mock backend services.
listener http:Listener backendEP00 = new(8080);

// Define the failover client end point to call the backend services.
http:FailoverClient foBackendEP00 = new({
    timeoutInMillis: 5000,
    failoverCodes: [501, 502, 503],
    intervalInMillis: 5000,
    // Define set of HTTP Clients that needs to be Failover.
    targets: [
        { url: "http://localhost:3467/inavalidEP" },
        { url: "http://localhost:8080/echo" },
        { url: "http://localhost:8080/mock" },
        { url: "http://localhost:8080/mock" }
    ]
});

http:FailoverClient foBackendFailureEP00 = new({
    timeoutInMillis: 5000,
    failoverCodes: [501, 502, 503],
    intervalInMillis: 5000,
    // Define set of HTTP Clients that needs to be Failover.
    targets: [
        { url: "http://localhost:3467/inavalidEP" },
        { url: "http://localhost:8080/echo" },
        { url: "http://localhost:8080/echo" }
    ]
});

http:FailoverClient foStatusCodesEP00 = new({
    timeoutInMillis: 5000,
    failoverCodes: [501, 502, 503],
    intervalInMillis: 5000,
    // Define set of HTTP Clients that needs to be Failover.
    targets: [
        { url: "http://localhost:8080/statuscodes" },
        { url: "http://localhost:8080/statuscodes" },
        { url: "http://localhost:8080/statuscodes" }
    ]
});

@http:ServiceConfig {
    basePath: "/fo"
}
service failoverDemoService00 on failoverEP00 {
    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/typical"
    }
    resource function invokeEndpoint(http:Caller caller, http:Request request) {
        var backendRes = foBackendEP00->forward("/", <@untainted> request);
        if (backendRes is http:Response) {
            var responseToCaller = caller->respond(backendRes);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(<@untainted> backendRes.message());
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        }
    }

    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/failures"
    }
    resource function invokeAllFailureEndpoint(http:Caller caller, http:Request request) {
        var backendRes = foBackendFailureEP00->forward("/", <@untainted> request);
        if (backendRes is http:Response) {
            var responseToCaller = caller->respond(backendRes);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(<@untainted> backendRes.message());
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        }
    }

    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/failurecodes"
    }
    resource function invokeAllFailureStatusCodesEndpoint(http:Caller caller, http:Request request) {
        var backendRes = foStatusCodesEP00->forward("/", <@untainted> request);
        if (backendRes is http:Response) {
            var responseToCaller = caller->respond(backendRes);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        } else {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload(<@untainted> backendRes.message());
            var responseToCaller = caller->respond(response);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        }
    }

    @http:ResourceConfig {
        methods: ["GET", "POST"],
        path: "/index"
    }
    resource function failoverStartIndex(http:Caller caller, http:Request request) {
        string startIndex = foBackendEP00.succeededEndpointIndex.toString();
        var backendRes = foBackendEP00->forward("/", <@untainted> request);
        if (backendRes is http:Response) {
            string responseMessage = "Failover start index is : " + startIndex;
            var responseToCaller = caller->respond(responseMessage);
            if (responseToCaller is error) {
                log:printError("Error sending response", responseToCaller);
            }
        } else {
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
    basePath: "/echo"
}
service echo00 on backendEP00 {
    @http:ResourceConfig {
        methods: ["POST", "PUT", "GET"],
        path: "/"
    }
    resource function echoResource(http:Caller caller, http:Request req) {
        http:Response outResponse = new;
        // Delay the response for 30000 milliseconds to mimic network level delays.
        runtime:sleep(30000);
        var responseToCaller = caller->respond("echo Resource is invoked");
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", responseToCaller);
        }
    }
}

int counter00 = 1;
// Define the sample service to mock a healthy service.
@http:ServiceConfig {
    basePath: "/mock"
}
service mock00 on backendEP00 {
    @http:ResourceConfig {
        methods: ["POST", "PUT", "GET"],
        path: "/"
    }
    resource function mockResource(http:Caller caller, http:Request req) {
        counter00 += 1;
        if (counter00 % 5 == 0) {
            runtime:sleep(30000);
        }
        http:Response response = new;
        if (req.hasHeader(mime:CONTENT_TYPE)
            && req.getHeader(mime:CONTENT_TYPE).startsWith(http:MULTIPART_AS_PRIMARY_TYPE)) {
            var mimeEntity = req.getBodyParts();
            if (mimeEntity is error) {
                log:printError(mimeEntity.message());
                response.setPayload("Error in decoding multiparts!");
                response.statusCode = 500;
            } else {
                foreach var bodyPart in mimeEntity {
                    if (bodyPart.hasHeader(mime:CONTENT_TYPE)
                        && bodyPart.getHeader(mime:CONTENT_TYPE).startsWith(http:MULTIPART_AS_PRIMARY_TYPE)) {
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
            log:printError("Error sending response from mock service", responseToCaller);
        }
    }
}

// Define the sample service to mock connection timeouts and service outages.
@http:ServiceConfig {
    basePath: "/statuscodes"
}
service failureStatusCodeService00 on backendEP00 {
    @http:ResourceConfig {
        methods: ["POST", "PUT", "GET"],
        path: "/"
    }
    resource function errorStatusResource(http:Caller caller, http:Request req) {
        http:Response outResponse = new;
        outResponse.statusCode = 503;
        outResponse.setPayload("Failure status code scenario");
        var responseToCaller = caller->respond(outResponse);
        if (responseToCaller is error) {
            log:printError("Error sending response from mock service", responseToCaller);
        }
    }
}

//Test basic failover functionality
@test:Config {}
function testSimpleFailover() {
    http:Client testClient = new("http://localhost:9300");
    var response = testClient->post("/fo/typical", requestPayload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(response.getTextPayload(), "Mock Resource is Invoked.");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
