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

import ballerina/auth;
import ballerina/http;
import ballerina/jwt;
import ballerina/oauth2;
import ballerina/test;

const string KEYSTORE_PATH = "tests/certsandkeys/ballerinaKeystore.p12";
const string TRUSTSTORE_PATH = "tests/certsandkeys/ballerinaTruststore.p12";

@test:Config {}
isolated function testClientBasicAuthHandler() {
    http:CredentialsConfig config = {
        username: "admin",
        password: "123"
    };
    http:ClientBasicAuthHandler handler = new(config);
    http:Request request = createRequest();
    http:Request|http:ClientAuthError result = handler.enrich(request);
    if (result is http:Request) {
        string header = result.getHeader(http:AUTH_HEADER);
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
    http:Request request = createRequest();
    http:Request|http:ClientAuthError result = handler.enrich(request);
    if (result is http:Request) {
        string header = result.getHeader(http:AUTH_HEADER);
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
        keyStoreConfig: {
            keyStore: {
                path: KEYSTORE_PATH,
                password: "ballerina"
            },
            keyAlias: "ballerina",
            keyPassword: "ballerina"
        }
    };
    http:ClientSelfSignedJwtAuthProvider handler = new(config);
    http:Request request = createRequest();
    http:Request|http:ClientAuthError result = handler.enrich(request);
    if (result is http:Request) {
        string header = result.getHeader(http:AUTH_HEADER);
        test:assertTrue(header.startsWith("Bearer eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ"));
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}

@test:Config {}
isolated function testClientOAuth2Handler() {
    http:OAuth2ClientCredentialsGrantConfig config1 = {
        tokenUrl: "https://localhost:20000/oauth2/token",
        clientId: "3MVG9YDQS5WtC11paU2WcQjBB3L5w4gz52uriT8ksZ3nUVjKvrfQMrU4uvZohTftxStwNEW4cfStBEGRxRL68",
        clientSecret: "9205371918321623741",
        scopes: ["token-scope1", "token-scope2"],
        clientConfig: {
            secureSocket: {
               trustStore: {
                   path: TRUSTSTORE_PATH,
                   password: "ballerina"
               }
            }
        }
    };

    http:OAuth2PasswordGrantConfig config2 = {
        tokenUrl: "https://localhost:20000/oauth2/token",
        username: "johndoe",
        password: "A3ddj3w",
        clientId: "3MVG9YDQS5WtC11paU2WcQjBB3L5w4gz52uriT8ksZ3nUVjKvrfQMrU4uvZohTftxStwNEW4cfStBEGRxRL68",
        clientSecret: "9205371918321623741",
        scopes: ["token-scope1", "token-scope2"],
        clientConfig: {
            secureSocket: {
               trustStore: {
                   path: TRUSTSTORE_PATH,
                   password: "ballerina"
               }
            }
        }
    };

    http:OAuth2DirectTokenConfig config3 = {
        accessToken: "2YotnFZFEjr1zCsicMWpAA",
        refreshConfig: {
            refreshUrl: "https://localhost:20000/oauth2/token/refresh",
            refreshToken: "XlfBs91yquexJqDaKEMzVg==",
            clientId: "3MVG9YDQS5WtC11paU2WcQjBB3L5w4gz52uriT8ksZ3nUVjKvrfQMrU4uvZohTftxStwNEW4cfStBEGRxRL68",
            clientSecret: "9205371918321623741",
            scopes: ["token-scope1", "token-scope2"],
            clientConfig: {
                secureSocket: {
                   trustStore: {
                       path: TRUSTSTORE_PATH,
                       password: "ballerina"
                   }
                }
            }
        }
    };
    http:Request request = createRequest();

    http:ClientOAuth2Handler handler = new(config1);
    http:Request|http:ClientAuthError result = handler.enrich(request);
    if (result is http:Request) {
        string header = result.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }

    handler = new(config2);
    result = handler.enrich(request);
    if (result is http:Request) {
        string header = result.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }

    handler = new(config3);
    result = handler.enrich(request);
    if (result is http:Request) {
        string header = result.getHeader(http:AUTH_HEADER);
        test:assertEquals(header, "Bearer 2YotnFZFEjr1zCsicMWpAA");
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}

@test:Config {}
isolated function testListenerFileUserStoreBasicAuthHandlerAuthSuccess() {
    http:ListenerFileUserStoreBasicAuthHandler handler = new;
    string basicAuthToken = "YWxpY2U6eHh4";
    string headerValue = http:AUTH_SCHEME_BASIC + " " + basicAuthToken;
    http:Request request = createSecureRequest(headerValue);
    auth:UserDetails|http:Unauthorized authn1 = handler.authenticate(request);
    if (authn1 is auth:UserDetails) {
        test:assertEquals(authn1.username, "alice");
        test:assertEquals(authn1.scopes, ["read", "write"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }

    auth:UserDetails|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if (authn2 is auth:UserDetails) {
        test:assertEquals(authn2.username, "alice");
        test:assertEquals(authn2.scopes, ["read", "write"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }

    http:Forbidden? authz1 = handler.authorize(<auth:UserDetails>authn1, "read");
    if (authz1 is http:Forbidden) {
        test:assertFail(msg = "Test Failed!");
    }

    http:Forbidden? authz2 = handler.authorize(<auth:UserDetails>authn2, "write");
    if (authz2 is http:Forbidden) {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testListenerFileUserStoreBasicAuthHandlerAuthSuccessAuthzFailure() {
    http:ListenerFileUserStoreBasicAuthHandler handler = new;
    string basicAuthToken = "YWxpY2U6eHh4";
    string headerValue = http:AUTH_SCHEME_BASIC + " " + basicAuthToken;
    http:Request request = createSecureRequest(headerValue);
    auth:UserDetails|http:Unauthorized authn1 = handler.authenticate(request);
    if (authn1 is auth:UserDetails) {
        test:assertEquals(authn1.username, "alice");
        test:assertEquals(authn1.scopes, ["read", "write"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }

    auth:UserDetails|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if (authn2 is auth:UserDetails) {
        test:assertEquals(authn2.username, "alice");
        test:assertEquals(authn2.scopes, ["read", "write"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }

    http:Forbidden? authz1 = handler.authorize(<auth:UserDetails>authn1, "update");
    if (authz1 is ()) {
        test:assertFail(msg = "Test Failed!");
    }

    http:Forbidden? authz2 = handler.authorize(<auth:UserDetails>authn2, "update");
    if (authz2 is ()) {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testListenerFileUserStoreBasicAuthHandlerAuthFailure() {
    http:ListenerFileUserStoreBasicAuthHandler handler = new;
    string basicAuthToken = "YWxpY2U6aW52YWxpZA==";
    string headerValue = http:AUTH_SCHEME_BASIC + " " + basicAuthToken;
    http:Request request = createSecureRequest(headerValue);
    auth:UserDetails|http:Unauthorized authn1 = handler.authenticate(request);
    if (authn1 is auth:UserDetails) {
        test:assertFail(msg = "Test Failed!");
    }

    auth:UserDetails|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if (authn2 is auth:UserDetails) {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testListenerLdapUserStoreBasicAuthHandler() {
    // TODO: add authenticate/authorize sample
}

@test:Config {}
isolated function testListenerJwtAuthHandlerAuthSuccess() {
    http:JwtValidatorConfig config = {
        issuer: "wso2",
        audience: "ballerina",
        trustStoreConfig: {
            trustStore: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            },
            certificateAlias: "ballerina"
        },
        scopeKey: "scp"
    };
    http:ListenerJwtAuthHandler handler = new(config);
    string jwt = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTI5MzU" +
                 "2MSwgImp0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoid3JpdGUifQ.Xcqmj0qxM_zKIE" +
                 "uNzZJ1kfI_Ba0mTqHfYmwnqrArRx7jA-HrKENAqTSYDlQbpCTF-3sUPCaV2uHoPPNnFaAxKlzuZtIIjfkPhKm5PfHfmnGoAN7n" +
                 "YthtkBV8lwCFy0vyCQwiN4SYDXQT0gbfJ2VH08hYzaI3gY5jtCMlqhiouds4glbbC-9_o9uURBnGiF5dfnPMEvRHpkgD8Ge-Rf" +
                 "LoppEcb69pPSMvXX65Ookal3_mEiJRZHzyqsJnli8m5_13SsnpppXt0xme_KrvJmdm7-er5cbKHjvF8Ve7OO6V7VSs6pwsRVfe" +
                 "TaFgNpEXC8RCDcaFykiBQW6uT5jYH3W3Eg";
    string headerValue = http:AUTH_SCHEME_BEARER + " " + jwt;
    http:Request request = createSecureRequest(headerValue);
    jwt:Payload|http:Unauthorized authn1 = handler.authenticate(request);
    if (authn1 is jwt:Payload) {
        test:assertEquals(authn1?.sub, "admin");
        test:assertEquals(authn1?.iss, "wso2");
        test:assertEquals(authn1?.aud, ["ballerina"]);
        test:assertEquals(authn1["scp"], "write");
        test:assertTrue(authn1?.exp is int);
        test:assertTrue(authn1?.jti is string);
    } else {
        test:assertFail(msg = "Test Failed!");
    }

    jwt:Payload|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if (authn2 is jwt:Payload) {
        test:assertEquals(authn2?.sub, "admin");
        test:assertEquals(authn2?.iss, "wso2");
        test:assertEquals(authn2?.aud, ["ballerina"]);
        test:assertEquals(authn2["scp"], "write");
        test:assertTrue(authn2?.exp is int);
        test:assertTrue(authn2?.jti is string);
    } else {
        test:assertFail(msg = "Test Failed!");
    }

    http:Forbidden? authz1 = handler.authorize(<jwt:Payload>authn1, "write");
    if (authz1 is http:Forbidden) {
        test:assertFail(msg = "Test Failed!");
    }

    http:Forbidden? authz2 = handler.authorize(<jwt:Payload>authn2, "write");
    if (authz2 is http:Forbidden) {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testListenerJwtAuthHandlerAuthzFailure() {
    http:JwtValidatorConfig config = {
        issuer: "wso2",
        audience: "ballerina",
        trustStoreConfig: {
            trustStore: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            },
            certificateAlias: "ballerina"
        }
    };
    http:ListenerJwtAuthHandler handler = new(config);
    string jwt = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTI5MzU" +
                 "2MSwgImp0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoid3JpdGUifQ.Xcqmj0qxM_zKIE" +
                 "uNzZJ1kfI_Ba0mTqHfYmwnqrArRx7jA-HrKENAqTSYDlQbpCTF-3sUPCaV2uHoPPNnFaAxKlzuZtIIjfkPhKm5PfHfmnGoAN7n" +
                 "YthtkBV8lwCFy0vyCQwiN4SYDXQT0gbfJ2VH08hYzaI3gY5jtCMlqhiouds4glbbC-9_o9uURBnGiF5dfnPMEvRHpkgD8Ge-Rf" +
                 "LoppEcb69pPSMvXX65Ookal3_mEiJRZHzyqsJnli8m5_13SsnpppXt0xme_KrvJmdm7-er5cbKHjvF8Ve7OO6V7VSs6pwsRVfe" +
                 "TaFgNpEXC8RCDcaFykiBQW6uT5jYH3W3Eg";
    string headerValue = http:AUTH_SCHEME_BEARER + " " + jwt;
    http:Request request = createSecureRequest(headerValue);
    jwt:Payload|http:Unauthorized authn1 = handler.authenticate(request);
    if (authn1 is jwt:Payload) {
        test:assertEquals(authn1?.sub, "admin");
        test:assertEquals(authn1?.iss, "wso2");
        test:assertEquals(authn1?.aud, ["ballerina"]);
        test:assertTrue(authn1?.exp is int);
        test:assertTrue(authn1?.jti is string);
    } else {
        test:assertFail(msg = "Test Failed!");
    }

    jwt:Payload|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if (authn2 is jwt:Payload) {
        test:assertEquals(authn2?.sub, "admin");
        test:assertEquals(authn2?.iss, "wso2");
        test:assertEquals(authn2?.aud, ["ballerina"]);
        test:assertTrue(authn2?.exp is int);
        test:assertTrue(authn2?.jti is string);
    } else {
        test:assertFail(msg = "Test Failed!");
    }

    http:Forbidden? authz1 = handler.authorize(<jwt:Payload>authn1, "write");
    if (authz1 is ()) {
        test:assertFail(msg = "Test Failed!");
    }

    http:Forbidden? authz2 = handler.authorize(<jwt:Payload>authn2, "write");
    if (authz2 is ()) {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testListenerJwtAuthHandlerAuthFailure() {
    http:JwtValidatorConfig config = {
        issuer: "ballerina",
        audience: "ballerina",
        trustStoreConfig: {
            trustStore: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            },
            certificateAlias: "ballerina"
        }
    };
    http:ListenerJwtAuthHandler handler = new(config);
    string jwt = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTI5MzU" +
                 "2MSwgImp0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoid3JpdGUifQ.Xcqmj0qxM_zKIE" +
                 "uNzZJ1kfI_Ba0mTqHfYmwnqrArRx7jA-HrKENAqTSYDlQbpCTF-3sUPCaV2uHoPPNnFaAxKlzuZtIIjfkPhKm5PfHfmnGoAN7n" +
                 "YthtkBV8lwCFy0vyCQwiN4SYDXQT0gbfJ2VH08hYzaI3gY5jtCMlqhiouds4glbbC-9_o9uURBnGiF5dfnPMEvRHpkgD8Ge-Rf" +
                 "LoppEcb69pPSMvXX65Ookal3_mEiJRZHzyqsJnli8m5_13SsnpppXt0xme_KrvJmdm7-er5cbKHjvF8Ve7OO6V7VSs6pwsRVfe" +
                 "TaFgNpEXC8RCDcaFykiBQW6uT5jYH3W3Eg";
    string headerValue = http:AUTH_SCHEME_BEARER + " " + jwt;
    http:Request request = createSecureRequest(headerValue);
    jwt:Payload|http:Unauthorized authn1 = handler.authenticate(request);
    if (authn1 is jwt:Payload) {
        test:assertFail(msg = "Test Failed!");
    }

    jwt:Payload|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if (authn1 is jwt:Payload) {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testListenerOAuth2HandlerAuthSuccess() {
    http:OAuth2IntrospectionConfig config = {
        url: "https://localhost:20000/oauth2/token/introspect/success",
        tokenTypeHint: "access_token",
        scopeKey: "scp",
        clientConfig: {
            secureSocket: {
               trustStore: {
                   path: TRUSTSTORE_PATH,
                   password: "ballerina"
               }
            }
        }
    };
    http:ListenerOAuth2Handler handler = new(config);
    string oauth2Token = "2YotnFZFEjr1zCsicMWpAA";
    string headerValue = http:AUTH_SCHEME_BEARER + " " + oauth2Token;
    http:Request request = createSecureRequest(headerValue);
    oauth2:IntrospectionResponse|http:Unauthorized|http:Forbidden auth = handler.authorize(request, "read");
    if (auth is oauth2:IntrospectionResponse) {
        test:assertEquals(auth.active, true);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testListenerOAuth2HandlerAuthzFailure() {
    http:OAuth2IntrospectionConfig config = {
        url: "https://localhost:20000/oauth2/token/introspect/success",
        tokenTypeHint: "access_token",
        scopeKey: "scp",
        clientConfig: {
            secureSocket: {
               trustStore: {
                   path: TRUSTSTORE_PATH,
                   password: "ballerina"
               }
            }
        }
    };
    http:ListenerOAuth2Handler handler = new(config);
    string oauth2Token = "2YotnFZFEjr1zCsicMWpAA";
    string headerValue = http:AUTH_SCHEME_BEARER + " " + oauth2Token;
    http:Request request = createSecureRequest(headerValue);
    oauth2:IntrospectionResponse|http:Unauthorized|http:Forbidden auth = handler.authorize(request, "update");
    if (auth is oauth2:IntrospectionResponse || auth is http:Unauthorized) {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testListenerOAuth2HandlerAuthFailure() {
    http:OAuth2IntrospectionConfig config = {
        url: "https://localhost:20000/oauth2/token/introspect/failure",
        tokenTypeHint: "access_token",
        scopeKey: "scp",
        clientConfig: {
            secureSocket: {
               trustStore: {
                   path: TRUSTSTORE_PATH,
                   password: "ballerina"
               }
            }
        }
    };
    http:ListenerOAuth2Handler handler = new(config);
    string oauth2Token = "invalid_token";
    string headerValue = http:AUTH_SCHEME_BEARER + " " + oauth2Token;
    http:Request request = createSecureRequest(headerValue);
    oauth2:IntrospectionResponse|http:Unauthorized|http:Forbidden auth = handler.authorize(request);
    if (auth is oauth2:IntrospectionResponse || auth is http:Forbidden) {
        test:assertFail(msg = "Test Failed!");
    }
}

isolated function createRequest() returns http:Request {
    http:Request request = new;
    request.rawPath = "/helloWorld/sayHello";
    request.method = "GET";
    request.httpVersion = "1.1";
    return request;
}

isolated function createSecureRequest(string headerValue) returns http:Request {
    http:Request request = createRequest();
    request.addHeader(http:AUTH_HEADER, headerValue);
    return request;
}

// Mock OAuth2 authorization server implementation, which treats the APIs with successful responses.
listener http:Listener oauth2Listener = new(20000, {
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
