// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/log;
import ballerina/regex;

# Represents the Authorization header name.
public const string AUTH_HEADER = "Authorization";

# The prefix used to denote the Basic authentication scheme.
public const string AUTH_SCHEME_BASIC = "Basic";

# The prefix used to denote the Bearer authentication scheme.
public const string AUTH_SCHEME_BEARER = "Bearer";

# Defines the authentication configurations for the HTTP client.
public type ClientAuthConfig CredentialsConfig|BearerTokenConfig|JwtIssuerConfig|OAuth2GrantConfig;

// Defines the client authentication handlers.
type ClientAuthHandler ClientBasicAuthHandler|ClientBearerTokenAuthHandler|ClientSelfSignedJwtAuthHandler|ClientOAuth2Handler;

# Defines the authentication configurations for the HTTP listener.
public type ListenerAuthConfig LdapUserStoreConfigWithScopes|
                               JwtValidatorConfigWithScopes|
                               OAuth2IntrospectionConfigWithScopes;

// TODO: Enable these tests once the configurable features supports for map data types.
// https://github.com/ballerina-platform/ballerina-standard-library/issues/862
//public type FileUserStoreConfigWithScopes record {|
//   FileUserStoreConfig fileUserStoreConfig;
//   string|string[] scopes?;
//|};

public type LdapUserStoreConfigWithScopes record {|
   LdapUserStoreConfig ldapUserStoreConfig;
   string|string[] scopes?;
|};

public type JwtValidatorConfigWithScopes record {|
   JwtValidatorConfig jwtValidatorConfig;
   string|string[] scopes?;
|};

public type OAuth2IntrospectionConfigWithScopes record {|
   OAuth2IntrospectionConfig oauth2IntrospectionConfig;
   string|string[] scopes?;
|};

// Logs and prepares the `error` as an `http:ClientAuthError`.
isolated function prepareClientAuthError(string message, error? err = ()) returns ClientAuthError {
    log:printError(message, err = err);
    if (err is error) {
        return error ClientAuthError(message, err);
    }
    return error ClientAuthError(message);
}

// Extract the credential from `http:Request` or `string` header.
isolated function extractCredential(Request|string data) returns string? {
    if (data is string) {
        return regex:split(<string>data, " ")[1];
    } else {
        string|error header = data.getHeader(AUTH_HEADER);
        if (header is string) {
            return regex:split(header, " ")[1];
        }
    }
}

// Match the expectedScopes with actualScopes and return if there is a match.
isolated function matchScopes(string|string[] actualScopes, string|string[] expectedScopes) returns boolean {
    if (expectedScopes is string) {
        if (actualScopes is string) {
            return actualScopes == expectedScopes;
        } else {
            foreach string actualScope in actualScopes {
                if (actualScope == expectedScopes) {
                    return true;
                }
            }
        }
    } else {
        if (actualScopes is string) {
            foreach string expectedScope in expectedScopes {
                if (actualScopes == expectedScope) {
                    return true;
                }
            }
        } else {
            foreach string actualScope in actualScopes {
                foreach string expectedScope in expectedScopes {
                    if (actualScope == expectedScope) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

// Constructs an array of groups from the given space-separated string of groups.
isolated function convertToArray(string spaceSeperatedString) returns string[] {
    if (spaceSeperatedString.length() == 0) {
        return [];
    }
    return regex:split(spaceSeperatedString, " ");
}
