// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

const string JWT1 = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV0k" +
                    "0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTk1NTcyNCwgIm" +
                    "p0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoid3JpdGUifQ.H99ufLvCLFA5i1gfCt" +
                    "klVdPrBvEl96aobNvtpEaCsO4v6_EgEZYz8Pg0B1Y7yJPbgpuAzXEg_CzowtfCTu3jUFf5FH_6M1fWGko5vpljtCb5Xknt_" +
                    "YPqvbk5fJbifKeXqbkCGfM9c0GS0uQO5ss8StquQcofxNgvImRV5eEGcDdybkKBNkbA-sJFHd1jEhb8rMdT0M0SZFLnhrPL" +
                    "8edbFZ-oa-ffLLls0vlEjUA7JiOSpnMbxRmT-ac6QjPxTQgNcndvIZVP2BHueQ1upyNorFKSMv8HZpATYHZjgnJQSpmt3Oa" +
                    "oFJ6pgzbFuniVNuqYghikCQIizqzQNfC7JUD8wA";

const string JWT2 = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV0k" +
                    "0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTk1NTg3NiwgIm" +
                    "p0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoicmVhZCJ9.MVx_bJJpRyQryrTZ1-WC" +
                    "1BkJdeBulX2CnxYN5Y4r1XbVd0-rgbCQ86jEbWvLZOybQ8Hx7MB9thKaBvidBnctgMM1JzG-ULahl-afoyTCv_qxMCS-5B7" +
                    "AUA1f-sOQHzq-n7T3b0FKsWtmOEXbGmRxQFv89_v8xwUzIItXtZ6IjkoiZn5GerGrozX0DEBDAeG-2BOj8gSlsFENdPB5Sn" +
                    "5oEM6-Chrn6KFLXo3GFTwLQELgYkIGjgnMQfbyLLaw5oyJUyOCCsdMZ4oeVLO2rdKZs1L8ZDnolUfcdm5mTxxP9A4mTOTd-" +
                    "xC404MKwxkRhkgI4EJkcEwMHce2iCInZer10Q";

const string JWT3 = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0Ij" +
                    "oxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";

listener http:Listener authListener = new(securedListenerPort, {
    secureSocket: {
        keyStore: {
            path: KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

// Unsecured service - Unsecured resource with different combination of resource signature parameters

service /baz on authListener {
    resource function get foo() returns string {
        return "Hello World!";
    }

    resource function get bar(http:Request req) returns string|http:BadRequest {
        boolean b = req.hasHeader(http:AUTH_HEADER);
        if (b) {
            return "Hello World!";
        }
        http:BadRequest bad = {};
        return bad;
    }

    resource function get baz(http:Caller caller, http:Request req) {
        boolean b = req.hasHeader(http:AUTH_HEADER);
        if (b) {
            checkpanic caller->respond("Hello World!");
        }
        http:Response resp = new;
        resp.statusCode = 500;
        resp.setPayload("Oops!");
        checkpanic caller->respond(resp);
    }
}

@test:Config {}
function testNoAuthServiceResourceSuccess() {
    assertSuccess(sendRequest("/baz/foo", JWT1));
}

@test:Config {}
function testNNoAuthServiceResourceWithRequestSuccess() {
    assertSuccess(sendRequest("/baz/bar", JWT2));
}

@test:Config {}
function testNoAuthServiceResourceWithRequestAndCallerSuccess() {
    assertSuccess(sendRequest("/baz/baz", JWT3));
}

// JWT auth secured service - Unsecured resource

@http:ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {
                issuer: "wso2",
                audience: "ballerina",
                signatureConfig: {
                    trustStoreConfig: {
                        trustStore: {
                            path: TRUSTSTORE_PATH,
                            password: "ballerina"
                        },
                        certAlias: "ballerina"
                    }
                },
                scopeKey: "scp"
            },
            scopes: ["write", "update"]
        }
    ]
}
service /jwtAuth on authListener {
    resource function get foo() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testServiceAuthSuccess() {
    assertSuccess(sendRequest("/jwtAuth/foo", JWT1));
}

@test:Config {}
function testServiceAuthzFailure() {
    assertForbidden(sendRequest("/jwtAuth/foo", JWT2));
}

@test:Config {}
function testServiceAuthnFailure() {
    assertUnauthorized(sendRequest("/jwtAuth/foo", JWT3));
}

// Unsecured service - JWT auth secured resource

service /foo on authListener {

    @http:ResourceConfig {
        auth: [
            {
                jwtValidatorConfig: {
                    issuer: "wso2",
                    audience: "ballerina",
                    signatureConfig: {
                        trustStoreConfig: {
                            trustStore: {
                                path: TRUSTSTORE_PATH,
                                password: "ballerina"
                            },
                            certAlias: "ballerina"
                        }
                    },
                    scopeKey: "scp"
                },
                scopes: ["write", "update"]
            }
        ]
    }
    resource function get jwtAuth() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testResourceAuthSuccess() {
    assertSuccess(sendRequest("/foo/jwtAuth", JWT1));
}

@test:Config {}
function testResourceAuthzFailure() {
    assertForbidden(sendRequest("/foo/jwtAuth", JWT2));
}

@test:Config {}
function testResourceAuthnFailure() {
    assertUnauthorized(sendRequest("/foo/jwtAuth", JWT3));
}

// OAuth2 secured service - JWT auth secured resource

@http:ServiceConfig {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: "https://localhost:" + oauth2AuthorizationServerPort.toString() + "/oauth2/token/introspect",
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
            },
            scopes: ["write", "update"]
        }
    ]
}
service /oauth2 on authListener {

    @http:ResourceConfig {
        auth: [
            {
                jwtValidatorConfig: {
                    issuer: "wso2",
                    audience: "ballerina",
                    signatureConfig: {
                        trustStoreConfig: {
                            trustStore: {
                                path: TRUSTSTORE_PATH,
                                password: "ballerina"
                            },
                            certAlias: "ballerina"
                        }
                    },
                    scopeKey: "scp"
                },
                scopes: ["write", "update"]
            }
        ]
    }
    resource function get jwtAuth() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testServiceResourceAuthSuccess() {
    assertSuccess(sendRequest("/oauth2/jwtAuth", JWT1));
}

@test:Config {}
function testServiceResourceAuthzFailure() {
    assertForbidden(sendRequest("/oauth2/jwtAuth", JWT2));
}

@test:Config {}
function testServiceResourceAuthnFailure() {
    assertUnauthorized(sendRequest("/oauth2/jwtAuth", JWT3));
}

// OAuth2, Basic auth & JWT auth secured service - Unsecured resource

@http:ServiceConfig {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: "https://localhost:" + oauth2AuthorizationServerPort.toString() + "/oauth2/token/introspect",
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
            },
            scopes: ["write", "update"]
        },
        {
            fileUserStoreConfig: {},
            scopes: ["write", "update"]
        },
        {
            jwtValidatorConfig: {
                issuer: "wso2",
                audience: "ballerina",
                signatureConfig: {
                    trustStoreConfig: {
                        trustStore: {
                            path: TRUSTSTORE_PATH,
                            password: "ballerina"
                        },
                        certAlias: "ballerina"
                    }
                },
                scopeKey: "scp"
            },
            scopes: ["write", "update"]
        }
    ]
}
service /multipleAuth on authListener {
    resource function get bar() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testMultipleServiceAuthSuccess() {
    assertSuccess(sendRequest("/multipleAuth/bar", JWT1));
}

@test:Config {}
function testMultipleServiceAuthzFailure() {
    assertForbidden(sendRequest("/multipleAuth/bar", JWT2));
}

@test:Config {}
function testMultipleServiceAuthnFailure() {
    assertUnauthorized(sendRequest("/multipleAuth/bar", JWT3));
}

// Unsecured service - OAuth2, Basic auth & JWT auth secured resource

service /bar on authListener {
    @http:ResourceConfig {
        auth: [
            {
                oauth2IntrospectionConfig: {
                    url: "https://localhost:" + oauth2AuthorizationServerPort.toString() + "/oauth2/token/introspect",
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
                },
                scopes: ["write", "update"]
            },
            {
                fileUserStoreConfig: {},
                scopes: ["write", "update"]
            },
            {
                jwtValidatorConfig: {
                    issuer: "wso2",
                    audience: "ballerina",
                    signatureConfig: {
                        trustStoreConfig: {
                            trustStore: {
                                path: TRUSTSTORE_PATH,
                                password: "ballerina"
                            },
                            certAlias: "ballerina"
                        }
                    },
                    scopeKey: "scp"
                },
                scopes: ["write", "update"]
            }
        ]
    }
    resource function get multipleAuth() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testMultipleResourceAuthSuccess() {
    assertSuccess(sendRequest("/bar/multipleAuth", JWT1));
}

@test:Config {}
function testMultipleResourceAuthzFailure() {
    assertForbidden(sendRequest("/bar/multipleAuth", JWT2));
}

@test:Config {}
function testMultipleResourceAuthnFailure() {
    assertUnauthorized(sendRequest("/bar/multipleAuth", JWT3));
}
