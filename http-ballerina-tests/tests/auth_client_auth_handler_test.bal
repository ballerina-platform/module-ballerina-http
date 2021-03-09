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
import ballerina/test;

@test:Config {}
isolated function testClientBasicAuthHandler() {
    http:CredentialsConfig config = {
        username: "admin",
        password: "123"
    };
    http:ClientBasicAuthHandler handler = new(config);
    http:Request request = createDummyRequest();
    http:Request|http:ClientAuthError result = handler.enrich(request);
    if (result is http:Request) {
        string header = checkpanic result.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Basic YWRtaW46MTIz");
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}

@test:Config {}
isolated function testClientBearerTokenAuthHandler() {
    http:BearerTokenConfig config = {
        token: "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ"
    };
    http:ClientBearerTokenAuthHandler handler = new(config);
    http:Request request = createDummyRequest();
    http:Request|http:ClientAuthError result = handler.enrich(request);
    if (result is http:Request) {
        string header = checkpanic result.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ");
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}

@test:Config {}
isolated function testClientSelfSignedJwtAuthHandler() {
    http:JwtIssuerConfig config = {
        username: "admin",
        issuer: "wso2",
        audience: ["ballerina"],
        signatureConfig: {
            config: {
                keyStore: {
                    path: KEYSTORE_PATH,
                    password: "ballerina"
                },
                keyAlias: "ballerina",
                keyPassword: "ballerina"
            }
        }
    };
    http:ClientSelfSignedJwtAuthHandler handler = new(config);
    http:Request request = createDummyRequest();
    http:Request|http:ClientAuthError result = handler.enrich(request);
    if (result is http:Request) {
        string header = checkpanic result.getHeader(http:AUTH_HEADER);
        test:assertTrue(header.startsWith("Bearer eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ"));
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}

@test:Config {}
isolated function testClientOAuth2Handler() {
    http:OAuth2ClientCredentialsGrantConfig config1 = {
        tokenUrl: "https://localhost:" + oauth2AuthorizationServerPort.toString() + "/oauth2/token",
        clientId: "3MVG9YDQS5WtC11paU2WcQjBB3L5w4gz52uriT8ksZ3nUVjKvrfQMrU4uvZohTftxStwNEW4cfStBEGRxRL68",
        clientSecret: "9205371918321623741",
        scopes: ["token-scope1", "token-scope2"],
        clientConfig: {
            secureSocket: {
               cert: {
                   path: TRUSTSTORE_PATH,
                   password: "ballerina"
               }
            }
        }
    };

    http:OAuth2PasswordGrantConfig config2 = {
        tokenUrl: "https://localhost:" + oauth2AuthorizationServerPort.toString() + "/oauth2/token",
        username: "johndoe",
        password: "A3ddj3w",
        clientId: "3MVG9YDQS5WtC11paU2WcQjBB3L5w4gz52uriT8ksZ3nUVjKvrfQMrU4uvZohTftxStwNEW4cfStBEGRxRL68",
        clientSecret: "9205371918321623741",
        scopes: ["token-scope1", "token-scope2"],
        clientConfig: {
            secureSocket: {
               cert: {
                   path: TRUSTSTORE_PATH,
                   password: "ballerina"
               }
            }
        }
    };

    http:OAuth2DirectTokenConfig config3 = {
        refreshUrl: "https://localhost:" + oauth2AuthorizationServerPort.toString() + "/oauth2/token/refresh",
        refreshToken: "XlfBs91yquexJqDaKEMzVg==",
        clientId: "3MVG9YDQS5WtC11paU2WcQjBB3L5w4gz52uriT8ksZ3nUVjKvrfQMrU4uvZohTftxStwNEW4cfStBEGRxRL68",
        clientSecret: "9205371918321623741",
        scopes: ["token-scope1", "token-scope2"],
        clientConfig: {
            secureSocket: {
               cert: {
                   path: TRUSTSTORE_PATH,
                   password: "ballerina"
               }
            }
        }
    };

    http:Request request = createDummyRequest();
    http:ClientOAuth2Handler handler = new(config1);
    http:Request|http:ClientAuthError result = handler->enrich(request);
    if (result is http:Request) {
        string header = checkpanic result.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }

    handler = new(config2);
    result = handler->enrich(request);
    if (result is http:Request) {
        string header = checkpanic result.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }

    handler = new(config3);
    result = handler->enrich(request);
    if (result is http:Request) {
        string header = checkpanic result.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}
