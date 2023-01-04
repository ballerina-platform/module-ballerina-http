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
import ballerina/jwt;
import ballerina/test;

final http:ListenerJwtAuthHandler handler = new({
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
});

service /imperative on authListener {
    resource function get foo(http:Request req) returns string|http:Unauthorized|http:Forbidden {
        jwt:Payload|http:Unauthorized authn = handler.authenticate(req);
        if authn is http:Unauthorized {
            return authn;
        }
        http:Forbidden? authz = handler.authorize(<jwt:Payload> authn, ["write", "update"]);
        if authz is http:Forbidden {
            return authz;
        }
        return "Hello World!";
    }

    resource function get bar(http:Headers headers) returns string|http:Unauthorized|http:Forbidden {
        jwt:Payload|http:Unauthorized authn = handler.authenticate(headers);
        if authn is http:Unauthorized {
            return authn;
        }
        http:Forbidden? authz = handler.authorize(<jwt:Payload> authn, ["write", "update"]);
        if authz is http:Forbidden {
            return authz;
        }
        return "Hello World!";
    }

    resource function get baz(@http:Header { name: "Authorization" } string header) returns string|http:Unauthorized|http:Forbidden {
        jwt:Payload|http:Unauthorized authn = handler.authenticate(header);
        if authn is http:Unauthorized {
            return authn;
        }
        http:Forbidden? authz = handler.authorize(<jwt:Payload> authn, ["write", "update"]);
        if authz is http:Forbidden {
            return authz;
        }
        return "Hello World!";
    }
}

@test:Config {}
function testImperativeAuthSuccess() {
    assertSuccess(sendBearerTokenRequest("/imperative/foo", JWT1));
    assertSuccess(sendBearerTokenRequest("/imperative/bar", JWT1));
    assertSuccess(sendBearerTokenRequest("/imperative/baz", JWT1));
    assertSuccess(sendBearerTokenRequest("/imperative/foo", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/imperative/bar", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/imperative/baz", JWT1_1));
    assertSuccess(sendBearerTokenRequest("/imperative/foo", JWT1_2));
    assertSuccess(sendBearerTokenRequest("/imperative/bar", JWT1_2));
    assertSuccess(sendBearerTokenRequest("/imperative/baz", JWT1_2));
}

@test:Config {}
function testImperativeAuthzFailure() {
    assertForbidden(sendBearerTokenRequest("/imperative/foo", JWT2));
    assertForbidden(sendBearerTokenRequest("/imperative/bar", JWT2));
    assertForbidden(sendBearerTokenRequest("/imperative/baz", JWT2));
    assertForbidden(sendBearerTokenRequest("/imperative/foo", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/imperative/bar", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/imperative/baz", JWT2_1));
    assertForbidden(sendBearerTokenRequest("/imperative/foo", JWT2_2));
    assertForbidden(sendBearerTokenRequest("/imperative/bar", JWT2_2));
    assertForbidden(sendBearerTokenRequest("/imperative/baz", JWT2_2));
}

@test:Config {}
function testImperativeAuthnFailure() {
    assertUnauthorized(sendBearerTokenRequest("/imperative/foo", JWT3));
    assertUnauthorized(sendBearerTokenRequest("/imperative/bar", JWT3));
    assertUnauthorized(sendBearerTokenRequest("/imperative/baz", JWT3));
}
