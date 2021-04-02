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

# Represents file user store configurations for Basic Auth authentication.
public type FileUserStoreConfig record {|
    *auth:FileUserStoreConfig;
|};

# Defines the file store Basic Auth handler for listener authentication.
public class ListenerFileUserStoreBasicAuthHandler {

    auth:ListenerFileUserStoreBasicAuthProvider provider;

    # Initializes the `http:ListenerFileUserStoreBasicAuthHandler` object.
    #
    # + config - The `http:FileUserStoreConfig` instance
    public isolated function init(FileUserStoreConfig config = {}) {
        self.provider = new(config);
    }

    # Authenticates with the relevant authentication requirements.
    #
    # + data - The `http:Request` instance or `http:Headers` instance or `string` Authorization header
    # + return - The `auth:UserDetails` instance or else `Unauthorized` type in case of an error
    public isolated function authenticate(Request|Headers|string data) returns auth:UserDetails|Unauthorized {
        string|ListenerAuthError credential = extractCredential(data);
        if (credential is string) {
            auth:UserDetails|auth:Error details = self.provider.authenticate(credential);
            if (details is auth:UserDetails) {
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
    # + userDetails - The `auth:UserDetails` instance which is received from authentication results
    # + expectedScopes - The expected scopes as `string` or `string[]`
    # + return - `()`, if it is successful or else `Forbidden` type in case of an error
    public isolated function authorize(auth:UserDetails userDetails, string|string[] expectedScopes) returns Forbidden? {
        string[]? actualScopes = userDetails?.scopes;
        if (actualScopes is string[]) {
            boolean matched = matchScopes(actualScopes, expectedScopes);
            if (matched) {
                return;
            }
        }
        return {};
    }
}
