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

# Represents OAuth2 introspection configurations for OAuth2 authentication.
public type OAuth2IntrospectionConfig record {|
    *oauth2:IntrospectionConfig;
    string scopeKey = "scopes";
|};

# Defines the OAuth2 handler for listener authentication.
public class ListenerOAuth2Handler {

    oauth2:ListenerOAuth2Provider provider;
    string scopeKey;

    # Initializes the `http:ListenerOAuth2Handler` object.
    #
    # + config - The `http:OAuth2IntrospectionConfig` instance
    public function __init(OAuth2IntrospectionConfig config) {
        oauth2:IntrospectionConfig|error result = config.cloneWithType(oauth2:IntrospectionConfig);
        if (result is oauth2:IntrospectionConfig) {
            self.scopeKey = config.scopeKey;
            self.provider = new(result);
        } else {
            panic result;
        }
    }

    # Authorizes with the relevant authentication & authorization requirements.
    #
    # + data - The `http:Request` instance or `string` Authorization header
    # + expectedScopes - The expected scopes as `string` or `string[]`
    # + customParams - Map of custom parameters that need to be sent to introspection endpoint
    # + return - The `oauth2:IntrospectionResponse` instance or else `Unauthorized` or `Forbidden` type in case of an error
    public function authorize(Request|string data, string|string[]? expectedScopes = (), map<string>? customParams = ())
                              returns oauth2:IntrospectionResponse|Unauthorized|Forbidden {
        string credential = extractCredential(data);
        oauth2:IntrospectionResponse|oauth2:Error details = self.provider.authorize(credential);
        if (details is oauth2:Error) {
            Unauthorized unauthorized = {};
            return unauthorized;
        }
        oauth2:IntrospectionResponse introspectionResponse = <oauth2:IntrospectionResponse>details;
        if (expectedScopes is ()) {
            return introspectionResponse;
        }

        string scopeKey = self.scopeKey;
        string? actualScope = introspectionResponse?.scopeKey;
        if (actualScope is ()) {
            Forbidden forbidden = {};
            return forbidden;
        }
        boolean matched = matchScopes(<string>actualScope, <string|string[]>expectedScopes);
        if (!matched) {
            Forbidden forbidden = {};
            return forbidden;
        }
    }
}
