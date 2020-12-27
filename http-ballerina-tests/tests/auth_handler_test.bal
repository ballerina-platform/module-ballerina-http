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
import ballerina/test;
import ballerina/http;

@test:Config {}
isolated function testClientBasicAuthHandler() {
    http:CredentialsConfig config = {
        username: "admin",
        password: "123"
    }
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
    }
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
    }
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
    request.addHeader(http:AUTH_HEADER, AUTH_SCHEME_BASIC + " " + "YWxpY2U6eHh4");
    auth:UserDetails|http:Unauthorized authn = handler.authenticate(request);
    if (authn is auth:UserDetails) {
        test:assertEquals(authn.username, "alice");
        test:assertEquals(authn.scopes, ["read", "write"]);
    } else {
        test:assertFail(msg = "Test Failed! " + authn.message());
    }

    http:Forbidden? authz = handler.authorize(<auth:UserDetails>authn, "read");
    if (authn is http:Forbidden) {
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
        }
    }
    http:ListenerJwtAuthHandler handler = new(config);
    http:Request request = createRequest();
    string jwt = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV0k0Tk" +
                 "RObFpEVTFPR0ZrTmpGaU1RIn0.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTYwOTc0NjUzMSwgImp0aSI6" +
                 "IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoid3JpdGUifQ.dY3pLPNBkZWTxR4un1_f_8N5BLp" +
                 "q5H3EB9SdcVvao50pnxK7CjQiq8N_kFuUT6jEc66Hzl83KAp5OMBHysUpoFmXiBclh5Ee-pOUHWLsOrR1u0GyITErBpG4nqjNv" +
                 "lzzCQBcdqt0smooh7eeTccYJbNsgBOTPQFOia3fVvhijcAQtMnnqPChgjaUfUnvnVCwcd7jvB8w1uRp9oHlZT1OEfGbBauKOyw" +
                 "3A0rjN8_P1RjuvOD824MhDcJCmbDSu682fwWKkbYDOCNxaudP7eyv7fpl5UK8ZwP21Q5bMSycelKEEVBHx65-miAjp0i2hhnUo" +
                 "qRA-PGsbu_rpBjcAK9XrA";
    request.addHeader(http:AUTH_HEADER, AUTH_SCHEME_BEARER + " " + jwt);
    jwt:Payload|http:Unauthorized authn = handler.authenticate(request);
    if (authn is jwt:Payload) {
        test:assertEquals(authn?.iss, "wso2");
        test:assertEquals(authn?.aud, "ballerina");
    } else {
        test:assertFail(msg = "Test Failed! " + authn.message());
    }

    Forbidden? authz = handler.authorize(<jwt:Payload>authn, "write");
    if (authz is Forbidden) {
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
