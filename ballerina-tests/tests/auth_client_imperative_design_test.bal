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

service /imperativeclient on authListener {
    resource function 'default foo(http:Request req) returns string|http:Unauthorized|http:Forbidden {
        jwt:Payload|http:Unauthorized authn = handler.authenticate(req);
        if (authn is http:Unauthorized) {
            return authn;
        }
        http:Forbidden? authz = handler.authorize(<jwt:Payload> authn, ["write", "update"]);
        if (authz is http:Forbidden) {
            return authz;
        }
        return "Hello World!";
    }
}

final http:Client imperativeClientEP = checkpanic new("https://localhost:" + securedListenerPort.toString(), {
    secureSocket: {
        cert: {
            path: TRUSTSTORE_PATH,
            password: "ballerina"
        }
    }
});

@test:Config {}
function testImperativeEnrichRequest() {
    http:BearerTokenConfig config = {
        token: JWT1
    };
    http:ClientBearerTokenAuthHandler handler = new(config);
    http:Request request = createDummyRequest();
    http:Request|http:ClientAuthError result = handler.enrich(request);
    if (result is http:Request) {
        http:Response|http:ClientError response = imperativeClientEP->post("/imperativeclient/foo", result);
        assertSuccess(response);
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}

@test:Config {}
function testImperativeEnrichHeaders() {
    http:BearerTokenConfig config = {
        token: JWT1
    };
    http:ClientBearerTokenAuthHandler handler = new(config);
    map<string|string[]> headers = {};
    map<string|string[]>|http:ClientAuthError result = handler.enrichHeaders(headers);
    if (result is map<string|string[]>) {
        http:Response|http:ClientError response1 = imperativeClientEP->get("/imperativeclient/foo", result);
        assertSuccess(response1);
        http:Response|http:ClientError response2 = imperativeClientEP->post("/imperativeclient/foo", result);
        assertUnauthorized(response2);
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}

@test:Config {}
function testImperativeGetSecurityHeaders() {
    http:BearerTokenConfig config = {
        token: JWT1
    };
    http:ClientBearerTokenAuthHandler handler = new(config);
    map<string|string[]>|http:ClientAuthError result = handler.getSecurityHeaders();
    if (result is map<string|string[]>) {
        http:Response|http:ClientError response1 = imperativeClientEP->get("/imperativeclient/foo", result);
        assertSuccess(response1);
        http:Response|http:ClientError response2 = imperativeClientEP->post("/imperativeclient/foo", result);
        assertUnauthorized(response2);
    } else {
        test:assertFail(msg = "Test Failed! " + result.message());
    }
}
