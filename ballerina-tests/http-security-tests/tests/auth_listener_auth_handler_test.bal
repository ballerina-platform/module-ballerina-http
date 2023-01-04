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

import ballerina/auth;
import ballerina/http;
import ballerina/jwt;
import ballerina/oauth2;
import ballerina/test;

@test:Config {}
isolated function testListenerFileUserStoreBasicAuthHandlerAuthSuccess() {
    http:ListenerFileUserStoreBasicAuthHandler handler = new;
    string basicAuthToken = "YWxpY2U6eHh4";
    string headerValue = http:AUTH_SCHEME_BASIC + " " + basicAuthToken;
    http:Request request = createSecureRequest(headerValue);
    auth:UserDetails|http:Unauthorized authn1 = handler.authenticate(request);
    if authn1 is auth:UserDetails {
        test:assertEquals(authn1.username, "alice");
        test:assertEquals(authn1?.scopes, ["write", "update"]);
    } else {
        test:assertFail("Test Failed!");
    }

    auth:UserDetails|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if authn2 is auth:UserDetails {
        test:assertEquals(authn2.username, "alice");
        test:assertEquals(authn2?.scopes, ["write", "update"]);
    } else {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz1 = handler.authorize(<auth:UserDetails>authn1, "write");
    if authz1 is http:Forbidden {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz2 = handler.authorize(<auth:UserDetails>authn2, "update");
    if authz2 is http:Forbidden {
        test:assertFail("Test Failed!");
    }
}

@test:Config {}
isolated function testListenerFileUserStoreBasicAuthHandlerAuthzFailure() {
    http:ListenerFileUserStoreBasicAuthHandler handler = new;
    string basicAuthToken = "Ym9iOnl5eQ==";
    string headerValue = http:AUTH_SCHEME_BASIC + " " + basicAuthToken;
    http:Request request = createSecureRequest(headerValue);
    auth:UserDetails|http:Unauthorized authn1 = handler.authenticate(request);
    if authn1 is auth:UserDetails {
        test:assertEquals(authn1.username, "bob");
        test:assertEquals(authn1?.scopes, ["read"]);
    } else {
        test:assertFail("Test Failed!");
    }

    auth:UserDetails|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if authn2 is auth:UserDetails {
        test:assertEquals(authn2.username, "bob");
        test:assertEquals(authn2?.scopes, ["read"]);
    } else {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz1 = handler.authorize(<auth:UserDetails>authn1, "write");
    if authz1 is () {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz2 = handler.authorize(<auth:UserDetails>authn2, "update");
    if authz2 is () {
        test:assertFail("Test Failed!");
    }
}

@test:Config {}
isolated function testListenerFileUserStoreBasicAuthHandlerAuthnFailure() {
    http:ListenerFileUserStoreBasicAuthHandler handler = new;
    string basicAuthToken = "YWxpY2U6aW52YWxpZA==";
    string headerValue = http:AUTH_SCHEME_BASIC + " " + basicAuthToken;
    http:Request request = createSecureRequest(headerValue);
    auth:UserDetails|http:Unauthorized authn1 = handler.authenticate(request);
    if authn1 is http:Unauthorized {
        test:assertEquals(authn1?.body, "Failed to authenticate username 'alice' from file user store.");
    }

    auth:UserDetails|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if authn2 is http:Unauthorized {
        test:assertEquals(authn2?.body, "Failed to authenticate username 'alice' from file user store.");
    }

    request = createDummyRequest();
    auth:UserDetails|http:Unauthorized authn3 = handler.authenticate(request);
    if authn3 is http:Unauthorized {
        test:assertEquals(authn3?.body, "Authorization header not available.");
    }
}

@test:Config {
    groups: ["ldap", "disabledOnWindows"]
}
isolated function testListenerLdapUserStoreBasicAuthHandlerAuthSuccess() {
    http:LdapUserStoreConfig config = {
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
    };
    http:ListenerLdapUserStoreBasicAuthHandler handler = new(config);
    string basicAuthToken = "bGRjbGFrbWFsOmxkY2xha21hbEAxMjM=";
    string headerValue = http:AUTH_SCHEME_BASIC + " " + basicAuthToken;
    http:Request request = createSecureRequest(headerValue);
    auth:UserDetails|http:Unauthorized authn1 = handler->authenticate(request);
    if authn1 is auth:UserDetails {
        test:assertEquals(authn1.username, "ldclakmal");
        test:assertEquals(authn1?.scopes, ["admin", "developer"]);
    } else {
        test:assertFail("Test Failed!");
    }

    auth:UserDetails|http:Unauthorized authn2 = handler->authenticate(headerValue);
    if authn2 is auth:UserDetails {
        test:assertEquals(authn2.username, "ldclakmal");
        test:assertEquals(authn2?.scopes, ["admin", "developer"]);
    } else {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz1 = handler->authorize(<auth:UserDetails>authn1, "admin");
    if authz1 is http:Forbidden {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz2 = handler->authorize(<auth:UserDetails>authn2, "developer");
    if authz2 is http:Forbidden {
        test:assertFail("Test Failed!");
    }
}

@test:Config {
    groups: ["ldap", "disabledOnWindows"]
}
isolated function testListenerLdapUserStoreBasicAuthHandlerAuthzFailure() {
    http:LdapUserStoreConfig config = {
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
    };
    http:ListenerLdapUserStoreBasicAuthHandler handler = new(config);
    string basicAuthToken = "YWxpY2U6YWxpY2VAMTIz";
    string headerValue = http:AUTH_SCHEME_BASIC + " " + basicAuthToken;
    http:Request request = createSecureRequest(headerValue);
    auth:UserDetails|http:Unauthorized authn1 = handler->authenticate(request);
    if authn1 is auth:UserDetails {
        test:assertEquals(authn1.username, "alice");
        test:assertEquals(authn1?.scopes, ["developer"]);
    } else {
        test:assertFail("Test Failed!");
    }

    auth:UserDetails|http:Unauthorized authn2 = handler->authenticate(headerValue);
    if authn2 is auth:UserDetails {
        test:assertEquals(authn2.username, "alice");
        test:assertEquals(authn2?.scopes, ["developer"]);
    } else {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz1 = handler->authorize(<auth:UserDetails>authn1, "admin");
    if authz1 is () {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz2 = handler->authorize(<auth:UserDetails>authn2, "admin");
    if authz2 is () {
        test:assertFail("Test Failed!");
    }
}

@test:Config {
    groups: ["ldap", "disabledOnWindows"]
}
isolated function testListenerLdapUserStoreBasicAuthHandlerAuthnFailure() {
    http:LdapUserStoreConfig config = {
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
    };
    http:ListenerLdapUserStoreBasicAuthHandler handler = new(config);
    string basicAuthToken = "ZXZlOmV2ZUAxMjM=";
    string headerValue = http:AUTH_SCHEME_BASIC + " " + basicAuthToken;
    http:Request request = createSecureRequest(headerValue);
    auth:UserDetails|http:Unauthorized authn1 = handler->authenticate(request);
    if authn1 is http:Unauthorized {
        test:assertEquals(authn1?.body, "Failed to authenticate username 'eve' with LDAP user store. Username cannot be found in the directory.");
    }

    auth:UserDetails|http:Unauthorized authn2 = handler->authenticate(headerValue);
    if authn2 is http:Unauthorized {
        test:assertEquals(authn2?.body, "Failed to authenticate username 'eve' with LDAP user store. Username cannot be found in the directory.");
    }

    request = createDummyRequest();
    auth:UserDetails|http:Unauthorized authn3 = handler->authenticate(request);
    if authn3 is http:Unauthorized {
        test:assertEquals(authn3?.body, "Authorization header not available.");
    }
}

@test:Config {}
isolated function testListenerJwtAuthHandlerAuthSuccess1() {
    http:JwtValidatorConfig config = {
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
    };
    http:ListenerJwtAuthHandler handler = new(config);
    string headerValue = http:AUTH_SCHEME_BEARER + " " + JWT1;
    http:Request request = createSecureRequest(headerValue);
    jwt:Payload|http:Unauthorized authn1 = handler.authenticate(request);
    if authn1 is jwt:Payload {
        test:assertEquals(authn1?.sub, "admin");
        test:assertEquals(authn1?.iss, "wso2");
        test:assertEquals(authn1?.aud, ["ballerina"]);
        test:assertEquals(authn1["scp"], "write");
        test:assertTrue(authn1?.exp is int);
        test:assertTrue(authn1?.jti is string);
    } else {
        test:assertFail("Test Failed!");
    }

    jwt:Payload|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if authn2 is jwt:Payload {
        test:assertEquals(authn2?.sub, "admin");
        test:assertEquals(authn2?.iss, "wso2");
        test:assertEquals(authn2?.aud, ["ballerina"]);
        test:assertEquals(authn2["scp"], "write");
        test:assertTrue(authn2?.exp is int);
        test:assertTrue(authn2?.jti is string);
    } else {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz1 = handler.authorize(<jwt:Payload>authn1, "write");
    if authz1 is http:Forbidden {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz2 = handler.authorize(<jwt:Payload>authn2, "write");
    if authz2 is http:Forbidden {
        test:assertFail("Test Failed!");
    }
}

@test:Config {}
isolated function testListenerJwtAuthHandlerAuthSuccess2() {
    http:JwtValidatorConfig config = {
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
    };
    http:ListenerJwtAuthHandler handler = new(config);
    string headerValue = http:AUTH_SCHEME_BEARER + " " + JWT1_1;
    http:Request request = createSecureRequest(headerValue);
    jwt:Payload|http:Unauthorized authn1 = handler.authenticate(request);
    if authn1 is jwt:Payload {
        test:assertEquals(authn1?.sub, "admin");
        test:assertEquals(authn1?.iss, "wso2");
        test:assertEquals(authn1?.aud, ["ballerina"]);
        test:assertEquals(authn1["scp"], "read write update");
        test:assertTrue(authn1?.exp is int);
        test:assertTrue(authn1?.jti is string);
    } else {
        test:assertFail("Test Failed!");
    }

    jwt:Payload|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if authn2 is jwt:Payload {
        test:assertEquals(authn2?.sub, "admin");
        test:assertEquals(authn2?.iss, "wso2");
        test:assertEquals(authn2?.aud, ["ballerina"]);
        test:assertEquals(authn2["scp"], "read write update");
        test:assertTrue(authn2?.exp is int);
        test:assertTrue(authn2?.jti is string);
    } else {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz1 = handler.authorize(<jwt:Payload>authn1, "write");
    if authz1 is http:Forbidden {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz2 = handler.authorize(<jwt:Payload>authn2, "write");
    if authz2 is http:Forbidden {
        test:assertFail("Test Failed!");
    }
}

@test:Config {}
isolated function testListenerJwtAuthHandlerAuthSuccess3() {
    http:JwtValidatorConfig config = {
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
    };
    http:ListenerJwtAuthHandler handler = new(config);
    string headerValue = http:AUTH_SCHEME_BEARER + " " + JWT1_2;
    http:Request request = createSecureRequest(headerValue);
    jwt:Payload|http:Unauthorized authn1 = handler.authenticate(request);
    if authn1 is jwt:Payload {
        test:assertEquals(authn1?.sub, "admin");
        test:assertEquals(authn1?.iss, "wso2");
        test:assertEquals(authn1?.aud, ["ballerina"]);
        test:assertEquals(authn1["scp"], ["read", "write", "update"]);
        test:assertTrue(authn1?.exp is int);
        test:assertTrue(authn1?.jti is string);
    } else {
        test:assertFail("Test Failed!");
    }

    jwt:Payload|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if authn2 is jwt:Payload {
        test:assertEquals(authn2?.sub, "admin");
        test:assertEquals(authn2?.iss, "wso2");
        test:assertEquals(authn2?.aud, ["ballerina"]);
        test:assertEquals(authn2["scp"], ["read", "write", "update"]);
        test:assertTrue(authn2?.exp is int);
        test:assertTrue(authn2?.jti is string);
    } else {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz1 = handler.authorize(<jwt:Payload>authn1, "write");
    if authz1 is http:Forbidden {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz2 = handler.authorize(<jwt:Payload>authn2, "write");
    if authz2 is http:Forbidden {
        test:assertFail("Test Failed!");
    }
}

@test:Config {}
isolated function testListenerJwtAuthHandlerAuthzFailure() {
    http:JwtValidatorConfig config = {
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
    };
    http:ListenerJwtAuthHandler handler = new(config);
    string headerValue = http:AUTH_SCHEME_BEARER + " " + JWT2;
    http:Request request = createSecureRequest(headerValue);
    jwt:Payload|http:Unauthorized authn1 = handler.authenticate(request);
    if authn1 is jwt:Payload {
        test:assertEquals(authn1?.sub, "admin");
        test:assertEquals(authn1?.iss, "wso2");
        test:assertEquals(authn1?.aud, ["ballerina"]);
        test:assertTrue(authn1?.exp is int);
        test:assertTrue(authn1?.jti is string);
    } else {
        test:assertFail("Test Failed!");
    }

    jwt:Payload|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if authn2 is jwt:Payload {
        test:assertEquals(authn2?.sub, "admin");
        test:assertEquals(authn2?.iss, "wso2");
        test:assertEquals(authn2?.aud, ["ballerina"]);
        test:assertTrue(authn2?.exp is int);
        test:assertTrue(authn2?.jti is string);
    } else {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz1 = handler.authorize(<jwt:Payload>authn1, "write");
    if authz1 is () {
        test:assertFail("Test Failed!");
    }

    http:Forbidden? authz2 = handler.authorize(<jwt:Payload>authn2, "write");
    if authz2 is () {
        test:assertFail("Test Failed!");
    }
}

@test:Config {}
isolated function testListenerJwtAuthHandlerAuthnFailure() {
    http:JwtValidatorConfig config = {
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
    };
    http:ListenerJwtAuthHandler handler = new(config);
    string headerValue = http:AUTH_SCHEME_BEARER + " " + JWT3;
    http:Request request = createSecureRequest(headerValue);
    jwt:Payload|http:Unauthorized authn1 = handler.authenticate(request);
    if authn1 is http:Unauthorized {
        test:assertEquals(authn1?.body, "JWT validation failed. JWT must contain a valid issuer name.");
    }

    jwt:Payload|http:Unauthorized authn2 = handler.authenticate(headerValue);
    if authn2 is http:Unauthorized {
        test:assertEquals(authn2?.body, "JWT validation failed. JWT must contain a valid issuer name.");
    }

    request = createDummyRequest();
    jwt:Payload|http:Unauthorized authn3 = handler.authenticate(request);
    if authn3 is http:Unauthorized {
        test:assertEquals(authn3?.body, "Authorization header not available.");
    }
}

@test:Config {}
function testListenerOAuth2HandlerAuthSuccess() {
    http:OAuth2IntrospectionConfig config = {
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
    };
    http:ListenerOAuth2Handler handler = new(config);
    string oauth2Token = "2YotnFZFEjr1zCsicMWpAA";
    string headerValue = http:AUTH_SCHEME_BEARER + " " + oauth2Token;
    http:Request request = createSecureRequest(headerValue);
    oauth2:IntrospectionResponse|http:Unauthorized|http:Forbidden auth1 = handler->authorize(request, ["write", "update"]);
    if auth1 is oauth2:IntrospectionResponse {
        test:assertEquals(auth1.active, true);
    } else {
        test:assertFail("Test Failed!");
    }

    oauth2:IntrospectionResponse|http:Unauthorized|http:Forbidden auth2 = handler->authorize(request);
    if auth2 is oauth2:IntrospectionResponse {
        test:assertEquals(auth2.active, true);
    } else {
        test:assertFail("Test Failed!");
    }
}

@test:Config {}
function testListenerOAuth2HandlerAuthzFailure() {
    http:OAuth2IntrospectionConfig config = {
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
    };
    http:ListenerOAuth2Handler handler = new(config);
    string oauth2Token = "2YotnFZFEjr1zCsicMWpAA";
    string headerValue = http:AUTH_SCHEME_BEARER + " " + oauth2Token;
    http:Request request = createSecureRequest(headerValue);
    oauth2:IntrospectionResponse|http:Unauthorized|http:Forbidden auth = handler->authorize(request, "read");
    if auth is oauth2:IntrospectionResponse || auth is http:Unauthorized {
        test:assertFail("Test Failed!");
    }
}

@test:Config {}
function testListenerOAuth2HandlerAuthnFailure() {
    http:OAuth2IntrospectionConfig config = {
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
    };
    http:ListenerOAuth2Handler handler = new(config);
    string oauth2Token = "invalid_token";
    string headerValue = http:AUTH_SCHEME_BEARER + " " + oauth2Token;
    http:Request request = createSecureRequest(headerValue);
    oauth2:IntrospectionResponse|http:Unauthorized|http:Forbidden auth1 = handler->authorize(request);
    if auth1 is http:Unauthorized {
        test:assertEquals(auth1?.body, "The provided access-token is not active.");
    }

    request = createDummyRequest();
    oauth2:IntrospectionResponse|http:Unauthorized|http:Forbidden auth2 = handler->authorize(request);
    if auth2 is http:Unauthorized {
        test:assertEquals(auth2?.body, "Authorization header not available.");
    }
}
