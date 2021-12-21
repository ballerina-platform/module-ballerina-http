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

// Logs and prepares the `error` as an `http:ClientAuthError`.
isolated function prepareClientAuthError(string message, error? err = ()) returns ClientAuthError {
    log:printError(message, 'error = err);
    if err is error {
        return error ClientAuthError(message + " " + err.message(), err);
    }
    return error ClientAuthError(message);
}

// Logs and prepares the `error` as an `http:ListenerAuthError`.
isolated function prepareListenerAuthError(string message, error? err = ()) returns ListenerAuthError {
    log:printError(message, 'error = err);
    if err is error {
        return error ListenerAuthError(message, err);
    }
    return error ListenerAuthError(message);
}

// Build complete error message by evaluating all the inner causes.
isolated function buildCompleteErrorMessage(error err) returns string {
    string message = err.message();
    error? cause = err.cause();
    while cause is error {
        message += " " + cause.message();
        cause = cause.cause();
    }
    return message;
}

// Extract the credential from `http:Request`, `http:Headers` or `string` header.
isolated function extractCredential(Request|Headers|string data) returns string|ListenerAuthError {
    if data is string {
        return regex:split(data, " ")[1];
    } else {
        object {
            public isolated function getHeader(string headerName) returns string|HeaderNotFoundError;
        } headers = data;
        var header = headers.getHeader(AUTH_HEADER);
        if header is string {
            return regex:split(header, " ")[1];
        } else {
            return prepareListenerAuthError("Authorization header not available.", header);
        }
    }
}

// Extract the scheme from `string` header.
isolated function extractScheme(string header) returns string {
    return regex:split(header, " ")[0];
}

// Match the expectedScopes with actualScopes and return if there is a match.
isolated function matchScopes(string|string[] actualScopes, string|string[] expectedScopes) returns boolean {
    if expectedScopes is string {
        if actualScopes is string {
            return actualScopes == expectedScopes;
        } else {
            foreach string actualScope in actualScopes {
                if actualScope == expectedScopes {
                    return true;
                }
            }
        }
    } else {
        if actualScopes is string {
            foreach string expectedScope in expectedScopes {
                if actualScopes == expectedScope {
                    return true;
                }
            }
        } else {
            foreach string actualScope in actualScopes {
                foreach string expectedScope in expectedScopes {
                    if actualScope == expectedScope {
                        return true;
                    }
                }
            }
        }
    }
    log:printDebug("Failed to match the scopes. Expected '" + expectedScopes.toString() + "', but found '" +
                   actualScopes.toString());
    return false;
}

// Constructs an array of groups from the given space-separated string of groups.
isolated function convertToArray(string spaceSeperatedString) returns string[] {
    if spaceSeperatedString.length() == 0 {
        return [];
    }
    return regex:split(spaceSeperatedString, " ");
}
