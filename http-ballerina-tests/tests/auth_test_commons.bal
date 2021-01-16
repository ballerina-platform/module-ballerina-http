// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

// NOTE: All the tokens/credentials used in this test are dummy tokens/credentials and used only for testing purposes.

import ballerina/http;

const string KEYSTORE_PATH = "tests/certsandkeys/ballerinaKeystore.p12";
const string TRUSTSTORE_PATH = "tests/certsandkeys/ballerinaTruststore.p12";

isolated function createDummyRequest() returns http:Request {
    http:Request request = new;
    request.rawPath = "/helloWorld/sayHello";
    request.method = "GET";
    request.httpVersion = "1.1";
    return request;
}

isolated function createSecureRequest(string headerValue) returns http:Request {
    http:Request request = createDummyRequest();
    request.addHeader(http:AUTH_HEADER, headerValue);
    return request;
}

// Mock OAuth2 authorization server implementation, which treats the APIs with successful responses.
listener http:Listener oauth2Listener = new(oauth2AuthorizationServerPort, {
    secureSocket: {
        keyStore: {
            path: KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

service /oauth2 on oauth2Listener {
    resource function post token(http:Caller caller, http:Request request) {
        http:Response res = new;
        json response = {
            "access_token": "2YotnFZFEjr1zCsicMWpAA",
            "token_type": "example",
            "expires_in": 3600,
            "example_parameter": "example_value"
        };
        res.setPayload(response);
        checkpanic caller->respond(res);
    }

    resource function post token/refresh(http:Caller caller, http:Request request) {
        http:Response res = new;
        json response = {
            "access_token": "2YotnFZFEjr1zCsicMWpAA",
            "token_type": "example",
            "expires_in": 3600,
            "example_parameter": "example_value"
        };
        res.setPayload(response);
        checkpanic caller->respond(res);
    }

    resource function post token/introspect/success(http:Caller caller, http:Request request) {
        http:Response res = new;
        json response = { "active": true, "exp": 3600, "scp": "read write" };
        res.setPayload(response);
        checkpanic caller->respond(res);
    }

    resource function post token/introspect/failure(http:Caller caller, http:Request request) {
        http:Response res = new;
        json response = { "active": false };
        res.setPayload(response);
        checkpanic caller->respond(res);
    }
}
