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

type DataFeed record {
    int responseCode = 0;
    string message = "";
};

json requestPayload = {Name:"Ballerina"};

const string SUCCESS_HELLO_MESSAGE = "Hello World!!!";
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
    var response = testClient->post(path, requestPayload);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, dataFeed.responseCode, msg = "Found unexpected output");
        assertHeaderValue(response.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTrueTextPayload(response.getTextPayload(), dataFeed.message);
    } else if (response is error) {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
