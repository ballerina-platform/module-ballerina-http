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
public type ListenerAuthConfig FileUserStoreConfigWithScopes|
                               LdapUserStoreConfigWithScopes|
                               JwtValidatorConfigWithScopes|
                               OAuth2IntrospectionConfigWithScopes;

public type FileUserStoreConfigWithScopes record {|
   FileUserStoreConfig fileUserStoreConfig;
   string|string[] scopes?;
|};

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
    log:printError(message, 'error = err);
    if (err is error) {
        return error ClientAuthError(message, err);
    }
    return error ClientAuthError(message);
}

// Logs and prepares the `error` as an `http:ListenerAuthError`.
isolated function prepareListenerAuthError(string message, error? err = ()) returns ListenerAuthError {
    log:printError(message, 'error = err);
    if (err is error) {
        return error ListenerAuthError(message, err);
    }
    return error ListenerAuthError(message);
}

// Build complete error message by evaluating all the inner causes.
isolated function buildCompleteErrorMessage(error err) returns string {
    string message = err.message();
    error? cause = err.cause();
    while (cause is error) {
        message += " " + cause.message();
        cause = cause.cause();
    }
    return message;
}

// Extract the credential from `http:Request`, `http:Headers` or `string` header.
isolated function extractCredential(Request|Headers|string data) returns string|ListenerAuthError {
    if (data is string) {
        return regex:split(<string>data, " ")[1];
    } else {
        object {
            public isolated function getHeader(string headerName) returns string|HeaderNotFoundError;
        } headers = data;
        var header = headers.getHeader(AUTH_HEADER);
        if (header is string) {
            return regex:split(header, " ")[1];
        } else {
            return prepareListenerAuthError("Authorization header not available.", header);
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
