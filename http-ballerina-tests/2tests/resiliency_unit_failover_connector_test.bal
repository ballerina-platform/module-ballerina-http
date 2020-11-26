// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/io;
import ballerina/mime;
import ballerina/test;
import ballerina/http;

int counter = 0;

// /**
//  * Test case scenario:
//  * - First endpoint returns HttpConnectorError for the request.
//  * - Failover connector should retry the second endpoint.
//  * - Second endpoints returns success response.
//  */
//Test case for failover connector for at least one endpoint send success response.
@test:Config {}
function testSuccessScenario() {

    int counter = 0;
    http:FailoverClient backendClientEP = new({
        failoverCodes : [400, 500, 502, 503],
        targets: [
                 {url: "http://invalidEP"},
                 {url: "http://localhost:8080"}],
        timeoutInMillis:5000
    });

    http:Response clientResponse = new;
    http:Client?[] httpClients = [createMockClient("http://invalidEP"),
                                 createMockClient("http://localhost:8080")];
    backendClientEP.failoverInferredConfig.failoverClientsArray = httpClients;

    while (counter < 2) {
        http:Request request = new;
        var serviceResponse = backendClientEP->get("/hello", request);
        if (serviceResponse is http:Response) {
            clientResponse = serviceResponse;
        } else if (serviceResponse is error) {
            // Ignore the error to verify failover scenario
        }
        counter = counter + 1;
    }
    test:assertEquals(clientResponse.statusCode, 200, msg = "Found unexpected output");
}

//    /**
//     * Test case scenario:
//     * - All Endpoints return HttpConnectorError for the requests.
//     * - Once all endpoints were tried out failover connector responds with
//     * - status code of 500 and the error return from the last endpoint.
//     */
//Test case for failover connector when all endpoints return error response.
@test:Config {}
function testFailureScenario() {
    var result = failureScenario();
    if (result is error) {
        test:assertEquals(result.message(), 
            "All the failover endpoints failed. Last endpoint returned response is: 500 ", 
            msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type");
    }
}

function failureScenario() returns @tainted http:Response|error {
    int counter = 0;
    http:FailoverClient backendClientEP = new({
        failoverCodes : [400, 404, 500, 502, 503],
        targets: [
                 {url: "http://invalidEP"},
                 {url: "http://localhost:50000000"}],
        timeoutInMillis:5000
    });

    http:Response response = new;
    http:Client?[] httpClients = [createMockClient("http://invalidEP"),
                                 createMockClient("http://localhost:50000000")];
    backendClientEP.failoverInferredConfig.failoverClientsArray = httpClients;
    while (counter < 1) {
        http:Request request = new;
        var serviceResponse = backendClientEP->get("/hello", request);
        if (serviceResponse is http:Response) {
            counter = counter + 1;
            response = serviceResponse;
        } else if (serviceResponse is error) {
            counter = counter + 1;
            return serviceResponse;
        }
    }
    return response;
}

public client class FoMockClient {
    public string url = "";
    public http:ClientConfiguration config = {};
    public http:Client httpClient;
    public http:CookieStore? cookieStore = ();

    public function init(string url, http:ClientConfiguration? config = ()) {
        http:Client simpleClient = new(url);
        self.url = url;
        self.config = config ?: {};
        self.cookieStore = ();
        self.httpClient = simpleClient;
    }

    public remote function post(string path,
                           http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|() message,
                           http:TargetType targetType = http:Response) returns http:Response|http:Payload|http:ClientError {
        return getUnsupportedFOError();
    }

    public remote function head(string path, http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|()
            message = ()) returns http:Response|http:ClientError {
        return getUnsupportedFOError();
    }

    public remote function put(string path, http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|()
            message, http:TargetType targetType = http:Response) returns http:Response|http:Payload|http:ClientError
             {
        return getUnsupportedFOError();
    }

    public remote function execute(string httpVerb, string path,
                                   http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|()
                                        message, http:TargetType targetType = http:Response) returns http:Response|http:Payload|http:ClientError {
        return getUnsupportedFOError();
    }

    public remote function patch(string path,
                           http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|() message, http:TargetType targetType = http:Response)
                                                                                returns http:Response|http:Payload|http:ClientError {
        return getUnsupportedFOError();
    }

    public remote function delete(string path,
                           http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|() message, http:TargetType targetType = http:Response)
                                                                                returns http:Response|http:Payload|http:ClientError {
        return getUnsupportedFOError();
    }

    public remote function get(string path,
                            http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|() message, http:TargetType targetType = http:Response)
                                                                                returns http:Response|http:Payload|http:ClientError {
        http:Response response = new;
        var result = handleFailoverScenario(counter);
        if (result is http:Response) {
            response = result;
        } else {
            string errMessage = result.message();
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setTextPayload(errMessage);
        }
        return response;
    }

    public remote function options(string path,
           http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|() message = (), http:TargetType targetType = http:Response)
                                                                                returns http:Response|http:Payload|http:ClientError {
        return getUnsupportedFOError();
    }

    public remote function forward(string path, http:Request req, http:TargetType targetType = http:Response) returns http:Response|http:Payload|http:ClientError {
        return getUnsupportedFOError();
    }

    public remote function submit(string httpVerb, string path,
                           http:Request|string|xml|json|byte[]|io:ReadableByteChannel|mime:Entity[]|() message)
                                                                            returns http:HttpFuture|http:ClientError {
        return getUnsupportedFOError();
    }

    public remote function getResponse(http:HttpFuture httpFuture)  returns http:Response|http:ClientError {
        return getUnsupportedFOError();
    }

    public remote function hasPromise(http:HttpFuture httpFuture) returns boolean {
        return false;
    }

    public remote function getNextPromise(http:HttpFuture httpFuture) returns http:PushPromise|http:ClientError {
        return getUnsupportedFOError();
    }

    public remote function getPromisedResponse(http:PushPromise promise) returns http:Response|http:ClientError {
        return getUnsupportedFOError();
    }

    public remote function rejectPromise(http:PushPromise promise) {
    }

    public function getCookieStore() returns http:CookieStore? {
        return self.cookieStore;
    }
}

function handleFailoverScenario (int count) returns (http:Response | http:ClientError) {
    if (count == 0) {
        return http:GenericClientError("Connection refused");
    } else {
        http:Response inResponse = new;
        inResponse.statusCode = http:STATUS_OK;
        return inResponse;
    }
}

function getUnsupportedFOError() returns http:ClientError {
    return http:GenericClientError("Unsupported function for MockClient");
}

function createMockClient(string url) returns FoMockClient {
    FoMockClient mockClient = new(url);
    return mockClient;
}
