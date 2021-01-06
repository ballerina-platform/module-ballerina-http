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
import ballerina/test;

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
                path: "tests/certsandkeys/ballerinaKeystore.p12",
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
    // TODO: add authenticate/authorize sample
}

@test:Config {}
isolated function testListenerFileUserStoreBasicAuthHandler() {
    http:ListenerFileUserStoreBasicAuthHandler handler = new;
    http:Request request = createRequest();
    request.addHeader(http:AUTH_HEADER, http:AUTH_SCHEME_BASIC + " " + "YWxpY2U6eHh4");
    auth:UserDetails|http:Unauthorized authn = handler.authenticate(request);
    if (authn is auth:UserDetails) {
        test:assertEquals(authn.username, "alice");
        test:assertEquals(authn.scopes, ["read", "write"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }

    http:Forbidden? authz = handler.authorize(<auth:UserDetails>authn, "read");
    if (authz is http:Forbidden) {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testListenerLdapUserStoreBasicAuthHandler() {
    // TODO: add authenticate/authorize sample
}

@test:Config {}
isolated function testListenerJwtAuthHandler() {
    http:JwtValidatorConfig config = {
        issuer: "wso2",
        audience: "ballerina",
        trustStoreConfig: {
            trustStore: {
                path: "tests/certsandkeys/ballerinaTruststore.p12",
                password: "ballerina"
            },
            certificateAlias: "ballerina"
        },
        scopeKey: "scp"
    };
    http:ListenerJwtAuthHandler handler = new(config);
    http:Request request = createRequest();
    string jwt = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QifQ.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTI5MzU" +
                 "2MSwgImp0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoid3JpdGUifQ.Xcqmj0qxM_zKIE" +
                 "uNzZJ1kfI_Ba0mTqHfYmwnqrArRx7jA-HrKENAqTSYDlQbpCTF-3sUPCaV2uHoPPNnFaAxKlzuZtIIjfkPhKm5PfHfmnGoAN7n" +
                 "YthtkBV8lwCFy0vyCQwiN4SYDXQT0gbfJ2VH08hYzaI3gY5jtCMlqhiouds4glbbC-9_o9uURBnGiF5dfnPMEvRHpkgD8Ge-Rf" +
                 "LoppEcb69pPSMvXX65Ookal3_mEiJRZHzyqsJnli8m5_13SsnpppXt0xme_KrvJmdm7-er5cbKHjvF8Ve7OO6V7VSs6pwsRVfe" +
                 "TaFgNpEXC8RCDcaFykiBQW6uT5jYH3W3Eg";
    request.addHeader(http:AUTH_HEADER, http:AUTH_SCHEME_BEARER + " " + jwt);
    jwt:Payload|http:Unauthorized authn = handler.authenticate(request);
    if (authn is jwt:Payload) {
        test:assertEquals(authn?.iss, "wso2");
        test:assertEquals(authn?.aud, ["ballerina"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }

    http:Forbidden? authz = handler.authorize(<jwt:Payload>authn, "write");
    if (authz is http:Forbidden) {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testListenerOAuth2Handler() {
    // TODO: add authenticate/authorize sample
}

isolated function createRequest() returns http:Request {
    http:Request request = new;
    request.rawPath = "/helloWorld/sayHello";
    request.method = "GET";
    request.httpVersion = "1.1";
    return request;
}
