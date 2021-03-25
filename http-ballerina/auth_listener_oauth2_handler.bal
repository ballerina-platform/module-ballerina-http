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

import ballerina/oauth2;

# Represents OAuth2 introspection server configurations for OAuth2 authentication.
#
# + scopeKey - The key used to fetch the scopes
public type OAuth2IntrospectionConfig record {|
    *oauth2:IntrospectionConfig;
    string scopeKey = "scope";
|};

# Defines the OAuth2 handler for listener authentication.
public client class ListenerOAuth2Handler {

    oauth2:ListenerOAuth2Provider provider;
    string scopeKey;

    # Initializes the `http:ListenerOAuth2Handler` object.
    #
    # + config - The `http:OAuth2IntrospectionConfig` instance
    public isolated function init(OAuth2IntrospectionConfig config) {
        self.scopeKey = config.scopeKey;
        self.provider = new(config);
    }

    # Authorizes with the relevant authentication & authorization requirements.
    #
    # + data - The `http:Request` instance or `http:Headers` instance or `string` Authorization header
    # + expectedScopes - The expected scopes as `string` or `string[]`
    # + optionalParams - Map of optional parameters that need to be sent to introspection endpoint
    # + return - The `oauth2:IntrospectionResponse` instance or else `Unauthorized` or `Forbidden` type in case of an error
    remote isolated function authorize(Request|Headers|string data, string|string[]? expectedScopes = (),
                                       map<string>? optionalParams = ())
                                       returns oauth2:IntrospectionResponse|Unauthorized|Forbidden {
        string|ListenerAuthError credential = extractCredential(data);
        if (credential is string) {
            oauth2:IntrospectionResponse|oauth2:Error details = self.provider.authorize(credential, optionalParams);
            if (details is oauth2:IntrospectionResponse) {
                if (!details.active) {
                    Unauthorized unauthorized = {
                        body: "The provided access-token is not active."
                    };
                    return unauthorized;
                }

                if (expectedScopes is ()) {
                    return details;
                }

                string scopeKey = self.scopeKey;
                var actualScope = details[scopeKey];
                if (actualScope is string) {
                    boolean matched = matchScopes(convertToArray(actualScope), <string|string[]>expectedScopes);
                    if (matched) {
                        return details;
                    }
                }
                Forbidden forbidden = {};
                return forbidden;
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
}
