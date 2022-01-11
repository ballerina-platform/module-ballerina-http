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

service /declarativeclient on authListener {
    resource function 'default foo(http:Request req) returns string|http:Unauthorized|http:Forbidden {
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
}

final http:Client declarativeClientEP = check new("https://localhost:" + securedListenerPort.toString(),
    auth = {
        username: "admin",
        issuer: "wso2",

        audience: ["ballerina"],
        jwtId: "100078234ba23",
        keyId: "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ",
        customClaims: { "scp": "write" },
        signatureConfig: {
            config: {
                keyStore: {
                    path: KEYSTORE_PATH,
                    password: "ballerina"
                },
                keyAlias: "ballerina",
                keyPassword: "ballerina"
            }
        }
    },
    secureSocket = {
        cert: {
            path: TRUSTSTORE_PATH,
            password: "ballerina"
        }
    }
);

@test:Config {}
function testDeclarativeClientForGet() returns error? {
    http:Response response = check declarativeClientEP->get("/declarativeclient/foo");
    assertSuccess(response);
}

@test:Config {}
function testDeclarativeClientForPost() returns error? {
    string payload = "sample_value";
    http:Response response = check declarativeClientEP->post("/declarativeclient/foo", payload);
    assertSuccess(response);
}

@test:Config {}
function testDeclarativeClientForHead() returns error? {
    http:Response response = check declarativeClientEP->head("/declarativeclient/foo");
    assertSuccess(response);
}

@test:Config {}
function testDeclarativeClientForPut() returns error? {
    string payload = "sample_value";
    http:Response response = check declarativeClientEP->put("/declarativeclient/foo", payload);
    assertSuccess(response);
}

@test:Config {}
function testDeclarativeClientForExecute() returns error? {
    string payload = "sample_value";
    http:Response response = check declarativeClientEP->execute("POST", "/declarativeclient/foo", payload);
    assertSuccess(response);
}

@test:Config {}
function testDeclarativeClientForPatch() returns error? {
    string payload = "sample_value";
    http:Response response = check declarativeClientEP->patch("/declarativeclient/foo", payload);
    assertSuccess(response);
}

@test:Config {}
function testDeclarativeClientForDelete() returns error? {
    string payload = "sample_value";
    http:Response response = check declarativeClientEP->delete("/declarativeclient/foo", payload);
    assertSuccess(response);
}

@test:Config {}
function testDeclarativeClientForOptions() returns error? {
    http:Response response = check declarativeClientEP->options("/declarativeclient/foo");
    assertSuccess(response);
}
