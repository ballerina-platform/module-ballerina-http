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

import ballerina/test;
import ballerina/http;
import ballerina/io;

type DataFeed record {
    int responseCode = 0;
    string message = "";
};

json requestPayload = {Name:"Ballerina"};

const string CB_HEADER = "X-CB-Request";
const string ALLOW_HEADER = "Allow";

const string SUCCESS_HELLO_MESSAGE = "Hello World!!!";
const string CB_SUCCESS_HEADER_VALUE = "Successfull";
const string CB_FAILURE_HEADER_VALUE = "Unsuccessfull";
const string CB_SUCCESS_ALLOW_HEADER_VALUE = "OPTIONS, GET, HEAD, POST";
const string CB_FAILUE_ALLOW_HEADER_VALUE = "NONE";
const string INTERNAL_ERROR_MESSAGE = "Internal error occurred while processing the request.";
const string UPSTREAM_UNAVAILABLE_MESSAGE = "Upstream service unavailable.";
const string SERVICE_UNAVAILABLE_MESSAGE = "Service unavailable.";
const string IDLE_TIMEOUT_MESSAGE = "Idle timeout triggered before initiating inbound response";
const string MOCK_1_INVOKED = "Mock1 Resource is Invoked.";
const string MOCK_2_INVOKED = "Mock2 Resource is Invoked.";
const string MOCK_3_INVOKED = "Mock3 Resource is Invoked.";

const int SC_OK = 200;
const int SC_INTERNAL_SERVER_ERROR = 500;
const int SC_SERVICE_UNAVAILABLE = 503;

function invokeApiAndVerifyResponse(http:Client testClient, string path, DataFeed dataFeed) {
    http:Response|error response = testClient->post(path, requestPayload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTrueTextPayload(response.getTextPayload(), dataFeed.message);
    } else {
        assertError(response, dataFeed);
        //if (response is http:ApplicationResponseError) {
        //    test:assertEquals(response.detail().statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        //    assertErrorHeaderValue(response.detail().headers[CONTENT_TYPE], TEXT_PLAIN);
        //    assertTrueTextPayload(<string> response.detail().body, dataFeed.message);
        //} else {
        //    test:assertFail(msg = "Found unexpected output type: " + response.message());
        //}
    }
}

function invokeApiAndVerifyResponseWithHttpGet(http:Client testClient, string path, DataFeed dataFeed) {
    http:Response|error response = testClient->get(path);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTrueTextPayload(response.getTextPayload(), dataFeed.message);
    } else {
        assertError(response, dataFeed);
        //if (response is http:ApplicationResponseError) {
        //    test:assertEquals(response.detail().statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        //    assertErrorHeaderValue(response.detail().headers[CONTENT_TYPE], TEXT_PLAIN);
        //    assertTrueTextPayload(<string> response.detail().body, dataFeed.message);
        //} else {
        //    test:assertFail(msg = "Found unexpected output type: " + response.message());
        //}
    }
}

function invokeApiAndVerifyResponseWithHttpHead(http:Client testClient, string path, DataFeed dataFeed) {
    http:Response|error response = testClient->head(path);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CB_HEADER), dataFeed.message);
    } else {
        assertError(response, dataFeed);
        //if (response is http:ApplicationResponseError) {
        //    test:assertEquals(response.detail().statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        //    assertErrorHeaderValue(response.detail().headers[CONTENT_TYPE], TEXT_PLAIN);
        //    assertTrueTextPayload(<string> response.detail().body, dataFeed.message);
        //} else {
        //    test:assertFail(msg = "Found unexpected output type: " + response.message());
        //}
    }
}

function invokeApiAndVerifyResponseWithHttpOptions(http:Client testClient, string path, DataFeed dataFeed) {
    http:Response|error response = testClient->options(path);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(ALLOW_HEADER), dataFeed.message);
    } else {
        assertError(response, dataFeed);
        //test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function invokeApiAndVerifyResponseWithHttpPut(http:Client testClient, string path, DataFeed dataFeed) {
    http:Response|error response = testClient->put(path, requestPayload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTrueTextPayload(response.getTextPayload(), dataFeed.message);
    } else {
        assertError(response, dataFeed);
        //test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function invokeApiAndVerifyResponseWithHttpPatch(http:Client testClient, string path, DataFeed dataFeed) {
    http:Response|error response = testClient->patch(path, requestPayload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTrueTextPayload(response.getTextPayload(), dataFeed.message);
    } else {
        assertError(response, dataFeed);
        //test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function invokeApiAndVerifyResponseWithHttpDelete(http:Client testClient, string path, DataFeed dataFeed) {
    http:Response|error response = testClient->delete(path, requestPayload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTrueTextPayload(response.getTextPayload(), dataFeed.message);
    } else {
        assertError(response, dataFeed);
        //test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

function assertError(error err, DataFeed dataFeed) {
    if (err is http:ApplicationResponseError) {
        test:assertEquals(err.detail().statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        assertErrorHeaderValue(err.detail().headers[CONTENT_TYPE], TEXT_PLAIN);
        io:println("dataFeed.message");
        io:println(dataFeed.message);
        io:println("body");
        io:println(<string> err.detail().body);
        assertTrueTextPayload(<string> err.detail().body, dataFeed.message);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + err.message());
    }
}
