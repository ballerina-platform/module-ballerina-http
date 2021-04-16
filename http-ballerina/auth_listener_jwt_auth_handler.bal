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

import ballerina/jwt;

# Represents JWT validator configurations for JWT authentication.
#
# + scopeKey - The key used to fetch the scopes
public type JwtValidatorConfig record {|
    *jwt:ValidatorConfig;
    string scopeKey = "scope";
|};

# Defines the JWT auth handler for listener authentication.
public class ListenerJwtAuthHandler {

    jwt:ListenerJwtAuthProvider provider;
    string scopeKey;

    # Initializes the `http:ListenerJwtAuthHandler` object.
    #
    # + config - The `http:JwtValidatorConfig` instance
    public isolated function init(JwtValidatorConfig config) {
        self.scopeKey = config.scopeKey;
        self.provider = new(config);
    }

    # Authenticates with the relevant authentication requirements.
    #
    # + data - The `http:Request` instance or `http:Headers` instance or `string` Authorization header
    # + return - The `jwt:Payload` instance or else `Unauthorized` type in case of an error
    public isolated function authenticate(Request|Headers|string data) returns jwt:Payload|Unauthorized {
        string|ListenerAuthError credential = extractCredential(data);
        if (credential is string) {
            jwt:Payload|jwt:Error details = self.provider.authenticate(credential);
            if (details is jwt:Payload) {
                return details;
            } else {
                Unauthorized unauthorized = {
                    body: buildCompleteErrorMessage(details)
                };
                return unauthorized;
            }
        } else {
            Unauthorized unauthorized = {
                body: credential.message()
            };
            return unauthorized;
        }
    }

    # Authorizes with the relevant authorization requirements.
    #
    # + jwtPayload - The `jwt:Payload` instance which is received from authentication results
    # + expectedScopes - The expected scopes as `string` or `string[]`
    # + return - `()`, if it is successful or else `Forbidden` type in case of an error
    public isolated function authorize(jwt:Payload jwtPayload, string|string[] expectedScopes) returns Forbidden? {
        string scopeKey = self.scopeKey;
        var actualScope = jwtPayload[scopeKey];
        if (actualScope is string) {
            boolean matched = matchScopes(actualScope, expectedScopes);
            if (matched) {
                return;
            }
        }
        return {};
    }
}
