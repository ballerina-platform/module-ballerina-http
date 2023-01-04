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

listener http:Listener authListener = new(securedListenerPort,
    secureSocket = {
        key: {
            path: KEYSTORE_PATH,
            password: "ballerina"
        }
    }
);

// Unsecured service - Unsecured resource with different combination of resource signature parameters

service /baz on authListener {
    resource function get foo() returns string {
        return "Hello World!";
    }

    resource function get bar(http:Request req) returns string|http:BadRequest {
        boolean hasHeader = req.hasHeader(http:AUTH_HEADER);
        if hasHeader {
            return "Hello World!";
        }
        http:BadRequest bad = {};
        return bad;
    }

    resource function get baz(http:Caller caller, http:Request req) returns http:ListenerError? {
        boolean hasHeader = req.hasHeader(http:AUTH_HEADER);
        if hasHeader {
            check caller->respond("Hello World!");
        }
        http:Response resp = new;
        resp.statusCode = 500;
        resp.setPayload("Oops!");
        check caller->respond(resp);
    }
}

@test:Config {}
isolated function testNoAuthServiceResourceSuccess() {
    assertSuccess(sendBearerTokenRequest("/baz/foo", JWT1));
    assertSuccess(sendBearerTokenRequest("/baz/foo", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/baz/foo", JWT1_2));
    assertSuccess(sendJwtRequest("/baz/foo"));
}

@test:Config {}
isolated function testNoAuthServiceResourceWithRequestSuccess() {
    assertSuccess(sendBearerTokenRequest("/baz/bar", JWT2));
    assertSuccess(sendBearerTokenRequest("/baz/bar", JWT2_1));
    assertSuccess(sendBearerTokenRequest("/baz/bar", JWT2_2));
}

@test:Config {}
isolated function testNoAuthServiceResourceWithRequestAndCallerSuccess() {
    assertSuccess(sendBearerTokenRequest("/baz/baz", JWT3));
}

// Basic auth (file user store) secured service - Unsecured resource

@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["write", "update"]
        }
    ]
}
service /basicAuthFile on authListener {
    resource function get .() returns string {
        return "Hello World!";
    }
}

@test:Config {}
isolated function testBasicAuthFileUserStoreServiceAuthSuccess() {
    assertSuccess(sendBasicTokenRequest("/basicAuthFile", "alice", "xxx"));
}

@test:Config {}
isolated function testBasicAuthFileUserStoreServiceAuthzFailure() {
    assertForbidden(sendBasicTokenRequest("/basicAuthFile", "bob", "yyy"));
}

@test:Config {}
isolated function testBasicAuthFileUserStoreServiceAuthnFailure() {
    assertUnauthorized(sendBasicTokenRequest("/basicAuthFile", "peter", "123"));
    assertUnauthorized(sendNoTokenRequest("/basicAuthFile"));
}

// Basic auth (LDAP user store) secured service - Unsecured resource

@http:ServiceConfig {
    auth: [
        {
            ldapUserStoreConfig: {
                domainName: "avix.lk",
                connectionUrl: "ldap://localhost:389",
                connectionName: "cn=admin,dc=avix,dc=lk",
                connectionPassword: "avix123",
                userSearchBase: "ou=Users,dc=avix,dc=lk",
                userEntryObjectClass: "inetOrgPerson",
                userNameAttribute: "uid",
                userNameSearchFilter: "(&(objectClass=inetOrgPerson)(uid=?))",
                userNameListFilter: "(objectClass=inetOrgPerson)",
                groupSearchBase: ["ou=Groups,dc=avix,dc=lk"],
                groupEntryObjectClass: "groupOfNames",
                groupNameAttribute: "cn",
                groupNameSearchFilter: "(&(objectClass=groupOfNames)(cn=?))",
                groupNameListFilter: "(objectClass=groupOfNames)",
                membershipAttribute: "member",
                userRolesCacheEnabled: true,
                connectionPoolingEnabled: false,
                connectionTimeout: 5,
                readTimeout: 60
            },
            scopes: ["admin"]
        }
    ]
}
service /basicAuthLdap on authListener {
    resource function get .() returns string {
        return "Hello World!";
    }
}

@test:Config {
    groups: ["ldap", "disabledOnWindows"]
}
isolated function testBasicAuthLdapUserStoreServiceAuthSuccess() {
    assertSuccess(sendBasicTokenRequest("/basicAuthLdap", "ldclakmal", "ldclakmal@123"));
}

@test:Config {
    groups: ["ldap", "disabledOnWindows"]
}
isolated function testBasicAuthLdapUserStoreServiceAuthzFailure() {
    assertForbidden(sendBasicTokenRequest("/basicAuthLdap", "alice", "alice@123"));
}

@test:Config {
    groups: ["ldap", "disabledOnWindows"]
}
isolated function testBasicAuthLdapUserStoreServiceAuthnFailure() {
    assertUnauthorized(sendBasicTokenRequest("/basicAuthLdap", "eve", "eve@123"));
    assertUnauthorized(sendNoTokenRequest("/basicAuthLdap"));
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
    resource function get .() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testJwtAuthServiceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/jwtAuth", JWT1));
    assertSuccess(sendBearerTokenRequest("/jwtAuth", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/jwtAuth", JWT1_2));
    assertSuccess(sendJwtRequest("/jwtAuth"));
}

@test:Config {}
function testJwtAuthServiceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/jwtAuth", JWT2));
    assertForbidden(sendBearerTokenRequest("/jwtAuth", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/jwtAuth", JWT2_2));
}

@test:Config {}
function testJwtAuthServiceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/jwtAuth", JWT3));
    assertUnauthorized(sendNoTokenRequest("/jwtAuth"));
}

// OAuth2 auth secured service - Unsecured resource

@http:ServiceConfig {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: "https://localhost:" + stsPort.toString() + "/oauth2/introspect",
                tokenTypeHint: "access_token",
                scopeKey: "scp",
                clientConfig: {
                    secureSocket: {
                       cert: {
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
    resource function get .() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testOAuth2ServiceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/oauth2", ACCESS_TOKEN_1));
    assertSuccess(sendOAuth2TokenRequest("/oauth2"));
}

@test:Config {}
function testOAuth2ServiceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/oauth2", ACCESS_TOKEN_2));
}

@test:Config {}
function testOAuth2ServiceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/oauth2", ACCESS_TOKEN_3));
    assertUnauthorized(sendNoTokenRequest("/oauth2"));
}

// Unsecured service - Basic auth secured resource, JWT auth secured resource & OAuth2 secured resource

service /foo on authListener {

    @http:ResourceConfig {
        auth: [
            {
                fileUserStoreConfig: {},
                scopes: ["write", "update"]
            }
        ]
    }
    resource function get basicAuth() returns string {
        return "Hello World!";
    }

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

    @http:ResourceConfig {
        auth: [
            {
                oauth2IntrospectionConfig: {
                    url: "https://localhost:" + stsPort.toString() + "/oauth2/introspect",
                    tokenTypeHint: "access_token",
                    scopeKey: "scp",
                    clientConfig: {
                        secureSocket: {
                           cert: {
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
    resource function get oauth2() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testBasicAuthResourceAuthSuccess() {
    assertSuccess(sendBasicTokenRequest("/foo/basicAuth", "alice", "xxx"));
}

@test:Config {}
function testBasicAuthResourceAuthzFailure() {
    assertForbidden(sendBasicTokenRequest("/foo/basicAuth", "bob", "yyy"));
}

@test:Config {}
function testBasicAuthResourceAuthnFailure() {
    assertUnauthorized(sendBasicTokenRequest("/foo/basicAuth", "peter", "123"));
    assertUnauthorized(sendNoTokenRequest("/foo/basicAuth"));
}

@test:Config {}
function testJwtAuthResourceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/foo/jwtAuth", JWT1));
    assertSuccess(sendBearerTokenRequest("/foo/jwtAuth", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/foo/jwtAuth", JWT1_2));
    assertSuccess(sendJwtRequest("/foo/jwtAuth"));
}

@test:Config {}
function testJwtAuthResourceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/foo/jwtAuth", JWT2));
    assertForbidden(sendBearerTokenRequest("/foo/jwtAuth", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/foo/jwtAuth", JWT2_2));
}

@test:Config {}
function testJwtAuthResourceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/foo/jwtAuth", JWT3));
    assertUnauthorized(sendNoTokenRequest("/foo/jwtAuth"));
}

@test:Config {}
function testOAuth2ResourceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/foo/oauth2", ACCESS_TOKEN_1));
    assertSuccess(sendOAuth2TokenRequest("/foo/oauth2"));
}

@test:Config {}
function testOAuth2ResourceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/foo/oauth2", ACCESS_TOKEN_2));
}

@test:Config {}
function testOAuth2ResourceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/foo/oauth2", ACCESS_TOKEN_3));
    assertUnauthorized(sendNoTokenRequest("/foo/oauth2"));
}

// Testing configurations overwritten support.
// OAuth2 secured service - JWT auth secured resource

@http:ServiceConfig {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: "https://localhost:" + stsPort.toString() + "/oauth2/introspect",
                tokenTypeHint: "access_token",
                scopeKey: "scp",
                clientConfig: {
                    secureSocket: {
                       cert: {
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
service /ignoreOAuth2 on authListener {

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
    assertSuccess(sendBearerTokenRequest("/ignoreOAuth2/jwtAuth", JWT1));
    assertSuccess(sendBearerTokenRequest("/ignoreOAuth2/jwtAuth", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/ignoreOAuth2/jwtAuth", JWT1_2));
    assertSuccess(sendJwtRequest("/ignoreOAuth2/jwtAuth"));
}

@test:Config {}
function testServiceResourceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/ignoreOAuth2/jwtAuth", JWT2));
    assertForbidden(sendBearerTokenRequest("/ignoreOAuth2/jwtAuth", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/ignoreOAuth2/jwtAuth", JWT2_2));
}

@test:Config {}
function testServiceResourceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/ignoreOAuth2/jwtAuth", JWT3));
    assertUnauthorized(sendNoTokenRequest("/ignoreOAuth2/jwtAuth"));
}

// Testing scopes configurations overwritten support.
// JWT auth secured service - scopes overwritten at resource

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
            scopes: ["read"]
        }
    ]
}
service /ignoreScopes on authListener {

    @http:ResourceConfig {
        auth: {
            scopes: ["write", "update"]
        }
    }
    resource function get jwtAuth() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testScopesOverwrittenResourceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/ignoreScopes/jwtAuth", JWT1));
    assertSuccess(sendBearerTokenRequest("/ignoreScopes/jwtAuth", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/ignoreScopes/jwtAuth", JWT1_2));
    assertSuccess(sendJwtRequest("/ignoreScopes/jwtAuth"));
}

@test:Config {}
function testScopesOverwrittenResourceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/ignoreScopes/jwtAuth", JWT2));
    assertForbidden(sendBearerTokenRequest("/ignoreScopes/jwtAuth", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/ignoreScopes/jwtAuth", JWT2_2));
}

@test:Config {}
function testScopesOverwrittenResourceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/ignoreScopes/jwtAuth", JWT3));
    assertUnauthorized(sendNoTokenRequest("/ignoreScopes/jwtAuth"));
}

// Testing scopes configurations appending support.
// JWT auth secured service - scopes appended at resource

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
            }
        }
    ]
}
service /appendScopes on authListener {

    @http:ResourceConfig {
        auth: {
            scopes: ["write", "update"]
        }
    }
    resource function get jwtAuth() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testScopesAppendingResourceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/appendScopes/jwtAuth", JWT1));
    assertSuccess(sendBearerTokenRequest("/appendScopes/jwtAuth", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/appendScopes/jwtAuth", JWT1_2));
    assertSuccess(sendJwtRequest("/appendScopes/jwtAuth"));
}

@test:Config {}
function testScopesAppendingResourceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/appendScopes/jwtAuth", JWT2));
    assertForbidden(sendBearerTokenRequest("/appendScopes/jwtAuth", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/appendScopes/jwtAuth", JWT2_2));
}

@test:Config {}
function testScopesAppendingResourceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/appendScopes/jwtAuth", JWT3));
    assertUnauthorized(sendNoTokenRequest("/appendScopes/jwtAuth"));
}

// Testing multiple auth configurations support.
// OAuth2, Basic auth & JWT auth secured service - Unsecured resource

@http:ServiceConfig {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: "https://localhost:" + stsPort.toString() + "/oauth2/introspect",
                tokenTypeHint: "access_token",
                scopeKey: "scp",
                clientConfig: {
                    secureSocket: {
                       cert: {
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
    resource function get .() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testMultipleAuthServiceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/multipleAuth", JWT1));
    assertSuccess(sendBearerTokenRequest("/multipleAuth", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/multipleAuth", JWT1_2));
    assertSuccess(sendJwtRequest("/multipleAuth"));
}

@test:Config {}
function testMultipleAuthServiceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/multipleAuth", JWT2));
    assertForbidden(sendBearerTokenRequest("/multipleAuth", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/multipleAuth", JWT2_2));
}

@test:Config {}
function testMultipleAuthServiceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/multipleAuth", JWT3));
    assertUnauthorized(sendNoTokenRequest("/multipleAuth"));
}

// Testing multiple auth configurations support.
// Unsecured service - OAuth2, Basic auth & JWT auth secured resource

service /bar on authListener {

    @http:ResourceConfig {
        auth: [
            {
                oauth2IntrospectionConfig: {
                    url: "https://localhost:" + stsPort.toString() + "/oauth2/introspect",
                    tokenTypeHint: "access_token",
                    scopeKey: "scp",
                    clientConfig: {
                        secureSocket: {
                           cert: {
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
function testMultipleAuthResourceAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/bar/multipleAuth", JWT1));
    assertSuccess(sendBearerTokenRequest("/bar/multipleAuth", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/bar/multipleAuth", JWT1_2));
    assertSuccess(sendJwtRequest("/bar/multipleAuth"));
}

@test:Config {}
function testMultipleAuthResourceAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/bar/multipleAuth", JWT2));
    assertForbidden(sendBearerTokenRequest("/bar/multipleAuth", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/bar/multipleAuth", JWT2_2));
}

@test:Config {}
function testMultipleAuthResourceAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/bar/multipleAuth", JWT3));
    assertUnauthorized(sendNoTokenRequest("/bar/multipleAuth"));
}

// JWT auth secured service (without scopes) - Unsecured resource

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
                }
            }
        }
    ]
}
service /noScopes on authListener {
    resource function get .() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testServiceAuthWithoutScopesAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/noScopes", JWT1));
    assertSuccess(sendBearerTokenRequest("/noScopes", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/noScopes", JWT1_2));
    assertSuccess(sendBearerTokenRequest("/noScopes", JWT2));
    assertSuccess(sendBearerTokenRequest("/noScopes", JWT2_1));
    assertSuccess(sendBearerTokenRequest("/noScopes", JWT2_2));
    assertSuccess(sendJwtRequest("/noScopes"));
}

@test:Config {}
function testServiceAuthWithoutScopesAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/noScopes", JWT3));
    assertUnauthorized(sendNoTokenRequest("/noScopes"));
}

// Unsecured service - JWT auth secured resource with special resource paths

service /resourcepath on authListener {

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
    resource function get .() returns string {
        return "Hello World!";
    }

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
    resource function get foo\$bar\@() returns string {
        return "Hello World!";
    }
}

@test:Config {}
function testResourceWithNoPathAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/resourcepath", JWT1));
    assertSuccess(sendBearerTokenRequest("/resourcepath", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/resourcepath", JWT1_2));
    assertSuccess(sendJwtRequest("/resourcepath"));
}

@test:Config {}
function testResourceWithNoPathAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/resourcepath", JWT2));
    assertForbidden(sendBearerTokenRequest("/resourcepath", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/resourcepath", JWT2_2));
}

@test:Config {}
function testResourceWithNoPathAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/resourcepath", JWT3));
    assertUnauthorized(sendNoTokenRequest("/resourcepath"));
}

@test:Config {}
function testResourceWithSpecialPathAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/resourcepath/foo%24bar%40", JWT1));
    assertSuccess(sendBearerTokenRequest("/resourcepath/foo%24bar%40", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/resourcepath/foo%24bar%40", JWT1_2));
    assertSuccess(sendJwtRequest("/resourcepath/foo%24bar%40"));
}

@test:Config {}
function testResourceWithSpecialPathAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/resourcepath/foo%24bar%40", JWT2));
    assertForbidden(sendBearerTokenRequest("/resourcepath/foo%24bar%40", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/resourcepath/foo%24bar%40", JWT2_2));
}

@test:Config {}
function testResourceWithSpecialPathAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/resourcepath/foo%24bar%40", JWT3));
    assertUnauthorized(sendNoTokenRequest("/resourcepath/foo%24bar%40"));
}
