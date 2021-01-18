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
function testNormalServiceSuccess() {
    assertSuccess("/baz/foo");
}

@test:Config {}
function testNormalServiceWithRequestSuccess() {
    assertSuccess("/baz/bar");
}

@test:Config {}
function testNormalServiceWithRequestAndCallerSuccess() {
    assertSuccess("/baz/baz");
}

// JWT secured service - Unsecured resource

@http:ServiceConfig {
    auth: [
        {
            scopes: ["write", "update"],
            jwtValidatorConfig: {
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
            }
        }
    ]
}
service /jwtAuth on authListener {
    resource function get foo() returns string|http:Unauthorized|http:Forbidden {
        return "Hello World!";
    }
}

@test:Config {}
function testServiceAuthSuccess() {
    assertSuccess("/jwtAuth/foo");
}

@test:Config {}
function testServiceAuthzFailure() {
    assertForbidden("/jwtAuth/foo");
}

@test:Config {}
function testServiceAuthnFailure() {
    assertUnauthorized("/jwtAuth/foo");
}

// Unsecured service - JWT secured resource

service /foo on authListener {

    @http:ResourceConfig {
        auth: [
            {
                scopes: ["write", "update"],
                jwtValidatorConfig: {
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
                }
            }
        ]
    }
    resource function get jwtAuth() returns string|http:Unauthorized|http:Forbidden {
        return "Hello World!";
    }
}

@test:Config {}
function testResourceAuthSuccess() {
    assertSuccess("/foo/jwtAuth");
}

@test:Config {}
function testResourceAuthzFailure() {
    assertForbidden("/foo/jwtAuth");
}

@test:Config {}
function testResourceAuthnFailure() {
    assertUnauthorized("/foo/jwtAuth");
}

// OAuth2 secured service - JWT secured resource

@http:ServiceConfig {
    auth: [
        {
            scopes: ["write", "update"],
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
            }
        }
    ]
}
service /oauth2 on authListener {

    @http:ResourceConfig {
        auth: [
            {
                scopes: ["write", "update"],
                jwtValidatorConfig: {
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
                }
            }
        ]
    }
    resource function get jwtAuth() returns string|http:Unauthorized|http:Forbidden {
        return "Hello World!";
    }
}

@test:Config {}
function testServiceResourceAuthSuccess() {
    assertSuccess("/oauth2/jwtAuth");
}

@test:Config {}
function testServiceResourceAuthzFailure() {
    assertForbidden("/oauth2/jwtAuth");
}

@test:Config {}
function testServiceResourceAuthnFailure() {
    assertUnauthorized("/oauth2/jwtAuth");
}

// OAuth2 & JWT secured service - Unsecured resource

@http:ServiceConfig {
    auth: [
        {
            scopes: ["write", "update"],
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
            }
        },
        {
            scopes: ["write", "update"],
            jwtValidatorConfig: {
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
            }
        }
    ]
}
service /multipleAuth on authListener {
    resource function get bar() returns string|http:Unauthorized|http:Forbidden {
        return "Hello World!";
    }
}

@test:Config {}
function testMultipleServiceAuthSuccess() {
    assertSuccess("/multipleAuth/bar");
}

@test:Config {}
function testMultipleServiceAuthzFailure() {
    assertForbidden("/multipleAuth/bar");
}

@test:Config {}
function testMultipleServiceAuthnFailure() {
    assertUnauthorized("/multipleAuth/bar");
}

// Unsecured service - OAuth2 & JWT secured resource

service /bar on authListener {
    @http:ResourceConfig {
        auth: [
            {
                scopes: ["write", "update"],
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
                }
            },
            {
                scopes: ["write", "update"],
                jwtValidatorConfig: {
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
                }
            }
        ]
    }
    resource function get multipleAuth() returns string|http:Unauthorized|http:Forbidden {
        return "Hello World!";
    }
}

@test:Config {}
function testMultipleResourceAuthSuccess() {
    assertSuccess("/bar/multipleAuth");
}

@test:Config {}
function testMultipleResourceAuthzFailure() {
    assertForbidden("/bar/multipleAuth");
}

@test:Config {}
function testMultipleResourceAuthnFailure() {
    assertUnauthorized("/bar/multipleAuth");
}

function assertSuccess(string path) {
    string jwt = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV0k" +
                 "0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTk1NTcyNCwgIm" +
                 "p0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoid3JpdGUifQ.H99ufLvCLFA5i1gfCt" +
                 "klVdPrBvEl96aobNvtpEaCsO4v6_EgEZYz8Pg0B1Y7yJPbgpuAzXEg_CzowtfCTu3jUFf5FH_6M1fWGko5vpljtCb5Xknt_" +
                 "YPqvbk5fJbifKeXqbkCGfM9c0GS0uQO5ss8StquQcofxNgvImRV5eEGcDdybkKBNkbA-sJFHd1jEhb8rMdT0M0SZFLnhrPL" +
                 "8edbFZ-oa-ffLLls0vlEjUA7JiOSpnMbxRmT-ac6QjPxTQgNcndvIZVP2BHueQ1upyNorFKSMv8HZpATYHZjgnJQSpmt3Oa" +
                 "oFJ6pgzbFuniVNuqYghikCQIizqzQNfC7JUD8wA";
    http:Client clientEP = new("https://localhost:" + securedListenerPort.toString(), {
        auth: {
            token: jwt
        },
        secureSocket: {
            trustStore: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    var res = clientEP->get(path);
    if (res is http:Response) {
        test:assertEquals(res.statusCode, 200);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

function assertForbidden(string path) {
    string jwt = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV0k" +
                 "0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTk1NTg3NiwgIm" +
                 "p0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoicmVhZCJ9.MVx_bJJpRyQryrTZ1-WC" +
                 "1BkJdeBulX2CnxYN5Y4r1XbVd0-rgbCQ86jEbWvLZOybQ8Hx7MB9thKaBvidBnctgMM1JzG-ULahl-afoyTCv_qxMCS-5B7" +
                 "AUA1f-sOQHzq-n7T3b0FKsWtmOEXbGmRxQFv89_v8xwUzIItXtZ6IjkoiZn5GerGrozX0DEBDAeG-2BOj8gSlsFENdPB5Sn" +
                 "5oEM6-Chrn6KFLXo3GFTwLQELgYkIGjgnMQfbyLLaw5oyJUyOCCsdMZ4oeVLO2rdKZs1L8ZDnolUfcdm5mTxxP9A4mTOTd-" +
                 "xC404MKwxkRhkgI4EJkcEwMHce2iCInZer10Q";
    http:Client clientEP = new("https://localhost:" + securedListenerPort.toString(), {
        auth: {
            token: jwt
        },
        secureSocket: {
            trustStore: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    var res = clientEP->get(path);
    if (res is http:Response) {
        test:assertEquals(res.statusCode, 403);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

function assertUnauthorized(string path) {
    string jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0Ij" +
                 "oxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";
    http:Client clientEP = new("https://localhost:" + securedListenerPort.toString(), {
        auth: {
            token: jwt
        },
        secureSocket: {
            trustStore: {
                path: TRUSTSTORE_PATH,
                password: "ballerina"
            }
        }
    });
    var res = clientEP->get(path);
    if (res is http:Response) {
        test:assertEquals(res.statusCode, 401);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}
