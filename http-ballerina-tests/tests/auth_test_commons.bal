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
import ballerina/regex;
import ballerina/test;

const string KEYSTORE_PATH = "tests/certsandkeys/ballerinaKeystore.p12";
const string TRUSTSTORE_PATH = "tests/certsandkeys/ballerinaTruststore.p12";
const string ACCESS_TOKEN = "2YotnFZFEjr1zCsicMWpAA";

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

function sendRequest(string path, string token) returns http:Response|http:ClientError {
    http:Client clientEP = checkpanic new("https://localhost:" + securedListenerPort.toString(), {
        auth: {
            token: token
        },
        secureSocket: {
            trustStore: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    return <@untainted> clientEP->get(path);
}

isolated function assertSuccess(http:Response|http:ClientError response) {
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

isolated function assertForbidden(http:Response|http:ClientError response) {
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 403);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

isolated function assertUnauthorized(http:Response|http:ClientError response) {
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 401);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
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
    resource function post token() returns json {
        json response = {
            "access_token": ACCESS_TOKEN,
            "token_type": "example",
            "expires_in": 3600,
            "example_parameter": "example_value"
        };
        return response;
    }

    resource function post token/refresh() returns json {
        json response = {
            "access_token": ACCESS_TOKEN,
            "token_type": "example",
            "expires_in": 3600,
            "example_parameter": "example_value"
        };
        return response;
    }

    resource function post token/introspect(http:Request request) returns json {
        string|http:ClientError payload = request.getTextPayload();
        json response = ();
        if (payload is string) {
            string[] parts = regex:split(payload, "&");
            foreach string part in parts {
                if (part.indexOf("token=") is int) {
                    string token = regex:split(part, "=")[1];
                    if (token == ACCESS_TOKEN) {
                        response = { "active": true, "exp": 3600, "scp": "read write" };
                    } else {
                        response = { "active": false };
                    }
                    break;
                }
            }
        }
        return response;
    }
}
