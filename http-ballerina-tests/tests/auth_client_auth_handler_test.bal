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
    http:Request|http:ClientAuthError result1 = handler.enrich(request);
    if (result1 is http:Request) {
        string header = checkpanic result1.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Basic YWRtaW46MTIz");
    } else {
        test:assertFail(msg = "Test Failed! " + result1.message());
    }

    map<string|string[]> headers = {};
    map<string|string[]>|http:ClientAuthError result2 = handler.enrichHeaders(headers);
    if (result2 is map<string|string[]>) {
        string header = <string>result2.get(http:AUTH_HEADER);
        test:assertEquals(header, "Basic YWRtaW46MTIz");
    } else {
        test:assertFail(msg = "Test Failed! " + result2.message());
    }

    map<string|string[]>|http:ClientAuthError result3 = handler.getSecurityHeaders();
    if (result3 is map<string|string[]>) {
        string header = <string>result3.get(http:AUTH_HEADER);
        test:assertEquals(header, "Basic YWRtaW46MTIz");
    } else {
        test:assertFail(msg = "Test Failed! " + result3.message());
    }
}

@test:Config {}
isolated function testClientBasicAuthHandlerWithEmptyCredentials() {
    http:CredentialsConfig config = {
        username: "admin",
        password: ""
    };
    http:ClientBasicAuthHandler handler = new(config);
    http:Request request = createDummyRequest();
    http:Request|http:ClientAuthError result1 = handler.enrich(request);
    if (result1 is http:ClientAuthError) {
        test:assertEquals(result1.message(), "Failed to enrich request with Basic Auth token. Username or password " +
            "cannot be empty.", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output");
    }

    map<string|string[]> headers = {};
    map<string|string[]>|http:ClientAuthError result2 = handler.enrichHeaders(headers);
    if (result2 is http:ClientAuthError) {
        test:assertEquals(result2.message(), "Failed to enrich headers with Basic Auth token. Username or password " +
            "cannot be empty.", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output");
    }

    map<string|string[]>|http:ClientAuthError result3 = handler.getSecurityHeaders();
    if (result3 is http:ClientAuthError) {
        test:assertEquals(result3.message(), "Failed to enrich headers with Basic Auth token. Username or password " +
            "cannot be empty.", msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output");
    }
}

@test:Config {}
isolated function testClientBearerTokenAuthHandler() {
    http:BearerTokenConfig config = {
        token: "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ"
    };
    http:ClientBearerTokenAuthHandler handler = new(config);
    http:Request request = createDummyRequest();
    http:Request|http:ClientAuthError result1 = handler.enrich(request);
    if (result1 is http:Request) {
        string header = checkpanic result1.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ");
    } else {
        test:assertFail(msg = "Test Failed! " + result1.message());
    }

    map<string|string[]> headers = {};
    map<string|string[]>|http:ClientAuthError result2 = handler.enrichHeaders(headers);
    if (result2 is map<string|string[]>) {
        string header = <string>result2.get(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ");
    } else {
        test:assertFail(msg = "Test Failed! " + result2.message());
    }

    map<string|string[]>|http:ClientAuthError result3 = handler.getSecurityHeaders();
    if (result3 is map<string|string[]>) {
        string header = <string>result3.get(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ");
    } else {
        test:assertFail(msg = "Test Failed! " + result3.message());
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
    http:Request|http:ClientAuthError result1 = handler.enrich(request);
    if (result1 is http:Request) {
        string header = checkpanic result1.getHeader(http:AUTH_HEADER);
        test:assertTrue(header.startsWith("Bearer eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ"));
    } else {
        test:assertFail(msg = "Test Failed! " + result1.message());
    }

    map<string|string[]> headers = {};
    map<string|string[]>|http:ClientAuthError result2 = handler.enrichHeaders(headers);
    if (result2 is map<string|string[]>) {
        string header = <string>result2.get(http:AUTH_HEADER);
        test:assertTrue(header.startsWith("Bearer eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ"));
    } else {
        test:assertFail(msg = "Test Failed! " + result2.message());
    }

    map<string|string[]>|http:ClientAuthError result3 = handler.getSecurityHeaders();
    if (result3 is map<string|string[]>) {
        string header = <string>result3.get(http:AUTH_HEADER);
        test:assertTrue(header.startsWith("Bearer eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ"));
    } else {
        test:assertFail(msg = "Test Failed! " + result3.message());
    }
}

@test:Config {}
isolated function testClientSelfSignedJwtAuthHandlerWithEmptyPassword() {
    http:JwtIssuerConfig config = {
        username: "admin",
        issuer: "wso2",
        audience: ["ballerina"],
        signatureConfig: {
            config: {
                keyStore: {
                    path: KEYSTORE_PATH,
                    password: ""
                },
                keyAlias: "ballerina",
                keyPassword: "ballerina"
            }
        }
    };
    http:ClientSelfSignedJwtAuthHandler handler = new(config);
    http:Request request = createDummyRequest();
    http:Request|http:ClientAuthError result1 = handler.enrich(request);
    if (result1 is http:ClientAuthError) {
        test:assertEquals(result1.message(), "Failed to enrich request with JWT. Failed to generate a self-signed JWT.",
            msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output");
    }

    map<string|string[]> headers = {};
    map<string|string[]>|http:ClientAuthError result2 = handler.enrichHeaders(headers);
    if (result2 is http:ClientAuthError) {
        test:assertEquals(result2.message(), "Failed to enrich headers with JWT. Failed to generate a self-signed JWT.",
            msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output");
    }

    map<string|string[]>|http:ClientAuthError result3 = handler.getSecurityHeaders();
    if (result3 is http:ClientAuthError) {
        test:assertEquals(result3.message(), "Failed to enrich headers with JWT. Failed to generate a self-signed JWT.",
            msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output");
    }
}

@test:Config {}
isolated function testClientOAuth2Handler() {
    http:OAuth2ClientCredentialsGrantConfig config1 = {
        tokenUrl: "https://localhost:" + stsPort.toString() + "/oauth2/token",
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
        tokenUrl: "https://localhost:" + stsPort.toString() + "/oauth2/token",
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

    http:OAuth2RefreshTokenGrantConfig config3 = {
        refreshUrl: "https://localhost:" + stsPort.toString() + "/oauth2/token",
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
    http:Request|http:ClientAuthError result1 = handler->enrich(request);
    if (result1 is http:Request) {
        string header = checkpanic result1.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result1.message());
    }

    map<string|string[]> headers = {};
    map<string|string[]>|http:ClientAuthError result2 = handler.enrichHeaders(headers);
    if (result2 is map<string|string[]>) {
        string header = <string>result2.get(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result2.message());
    }

    map<string|string[]>|http:ClientAuthError result3 = handler.getSecurityHeaders();
    if (result3 is map<string|string[]>) {
        string header = <string>result3.get(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result3.message());
    }

    handler = new(config2);
    result1 = handler->enrich(request);
    if (result1 is http:Request) {
        string header = checkpanic result1.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result1.message());
    }

    headers = {};
    result2 = handler.enrichHeaders(headers);
    if (result2 is map<string|string[]>) {
        string header = <string>result2.get(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result2.message());
    }

    result3 = handler.getSecurityHeaders();
    if (result3 is map<string|string[]>) {
        string header = <string>result3.get(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result3.message());
    }

    handler = new(config3);
    result1 = handler->enrich(request);
    if (result1 is http:Request) {
        string header = checkpanic result1.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result1.message());
    }

    headers = {};
    result2 = handler.enrichHeaders(headers);
    if (result2 is map<string|string[]>) {
        string header = <string>result2.get(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result2.message());
    }

    result3 = handler.getSecurityHeaders();
    if (result3 is map<string|string[]>) {
        string header = <string>result3.get(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result3.message());
    }
}
