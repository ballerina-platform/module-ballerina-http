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

// Basic auth secured service - Unsecured resource

@http:ServiceConfig {
    auth: [
        {
            scopes: ["write", "update"],
            fileUserStoreConfig: {
                tableName: "b7a.users",
                scopeKey: "scopes"
            }
        }
    ]
}
service /basicAuth on authListener {
    resource function get foo() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testServiceAuthSuccess() {
    assertSuccess("/basicAuth/foo");
}

@test:Config {}
function testServiceAuthzFailure() {
    assertForbidden("/basicAuth/foo");
}

@test:Config {}
function testServiceAuthnFailure() {
    assertUnauthorized("/basicAuth/foo");
}

// Unsecured service - Basic auth secured resource

service /foo on authListener {

    @http:ResourceConfig {
        auth: [
            {
                scopes: ["write", "update"],
                fileUserStoreConfig: {
                    tableName: "b7a.users",
                    scopeKey: "scopes"
                }
            }
        ]
    }
    resource function get basicAuth() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testResourceAuthSuccess() {
    assertSuccess("/foo/basicAuth");
}

@test:Config {}
function testResourceAuthzFailure() {
    assertForbidden("/foo/basicAuth");
}

@test:Config {}
function testResourceAuthnFailure() {
    assertUnauthorized("/foo/basicAuth");
}

// OAuth2 secured service - Basic auth secured resource

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
                fileUserStoreConfig: {
                    tableName: "b7a.users",
                    scopeKey: "scopes"
                }
            }
        ]
    }
    resource function get basicAuth() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testServiceResourceAuthSuccess() {
    assertSuccess("/oauth2/basicAuth");
}

@test:Config {}
function testServiceResourceAuthzFailure() {
    assertForbidden("/oauth2/basicAuth");
}

@test:Config {}
function testServiceResourceAuthnFailure() {
    assertUnauthorized("/oauth2/basicAuth");
}

// OAuth2 & Basic auth secured service - Unsecured resource

//@http:ServiceConfig {
//    auth: [
//        {
//            scopes: ["write", "update"],
//            oauth2IntrospectionConfig: {
//                url: "https://localhost:" + oauth2AuthorizationServerPort.toString() + "/oauth2/token/introspect",
//                tokenTypeHint: "access_token",
//                scopeKey: "scp",
//                clientConfig: {
//                    secureSocket: {
//                       trustStore: {
//                           path: TRUSTSTORE_PATH,
//                           password: "ballerina"
//                       }
//                    }
//                }
//            }
//        },
//        {
//            scopes: ["write", "update"],
//            fileUserStoreConfig: {
//                tableName: "b7a.users",
//                scopeKey: "scopes"
//            }
//        }
//    ]
//}
//service /multipleAuth on authListener {
//    resource function get bar() returns string {
//        return "Hello World!";
//    }
//}
//
//@test:Config {}
//function testMultipleServiceAuthSuccess() {
//    assertSuccess("/multipleAuth/bar");
//}
//
//@test:Config {}
//function testMultipleServiceAuthzFailure() {
//    assertForbidden("/multipleAuth/bar");
//}
//
//@test:Config {}
//function testMultipleServiceAuthnFailure() {
//    assertUnauthorized("/multipleAuth/bar");
//}
//
//// Unsecured service - OAuth2 & Basic auth secured resource
//
//service /bar on authListener {
//    @http:ResourceConfig {
//        auth: [
//            {
//                scopes: ["write", "update"],
//                oauth2IntrospectionConfig: {
//                    url: "https://localhost:" + oauth2AuthorizationServerPort.toString() + "/oauth2/token/introspect",
//                    tokenTypeHint: "access_token",
//                    scopeKey: "scp",
//                    clientConfig: {
//                        secureSocket: {
//                           trustStore: {
//                               path: TRUSTSTORE_PATH,
//                               password: "ballerina"
//                           }
//                        }
//                    }
//                }
//            },
//            {
//                scopes: ["write", "update"],
//                fileUserStoreConfig: {
//                    tableName: "b7a.users",
//                    scopeKey: "scopes"
//                }
//            }
//        ]
//    }
//    resource function get multipleAuth() returns string {
//        return "Hello World!";
//    }
//}
//
//@test:Config {}
//function testMultipleResourceAuthSuccess() {
//    assertSuccess("/bar/multipleAuth");
//}
//
//@test:Config {}
//function testMultipleResourceAuthzFailure() {
//    assertForbidden("/bar/multipleAuth");
//}
//
//@test:Config {}
//function testMultipleResourceAuthnFailure() {
//    assertUnauthorized("/bar/multipleAuth");
//}

function assertSuccess(string path) {
    http:Client clientEP = checkpanic new("https://localhost:" + securedListenerPort.toString(), {
        auth: {
            username: "alice",
            password: "xxx"
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
    http:Client clientEP = checkpanic new("https://localhost:" + securedListenerPort.toString(), {
        auth: {
            username: "bob",
            password: "yyy"
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
    http:Client clientEP = checkpanic new("https://localhost:" + securedListenerPort.toString(), {
        auth: {
            username: "unknown",
            password: "unknown"
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
