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

# Represents JWT issuer configurations for JWT authentication.
public type JwtIssuerConfig record {|
    *jwt:IssuerConfig;
|};

# Defines the self signed JWT handler for client authentication.
public class ClientSelfSignedJwtAuthHandler {

    jwt:ClientSelfSignedJwtAuthProvider provider;

    # Initializes the `http:ClientSelfSignedJwtAuthProvider` object.
    #
    # + config - The `http:JwtIssuerConfig` instance
    public isolated function init(JwtIssuerConfig config) {
        self.provider = new(config);
    }

    # Enrich the request with the relevant authentication requirements.
    #
    # + req - The `http:Request` instance
    # + return - The updated `http:Request` instance or else an `http:ClientAuthError` in case of an error
    public isolated function enrich(Request req) returns Request|ClientAuthError {
        string|jwt:Error result = self.provider.generateToken();
        if (result is string) {
            req.setHeader(AUTH_HEADER, AUTH_SCHEME_BEARER + " " + result);
            return req;
        } else {
            return prepareClientAuthError("Failed to enrich request with JWT.", result);
        }
    }

    # Enrich the headers map with the relevant authentication requirements.
    #
    # + headers - The headers map
    # + return - The updated headers map or else an `http:ClientAuthError` in case of an error
    public isolated function enrichHeaders(map<string|string[]> headers) returns map<string|string[]>|ClientAuthError {
        string|jwt:Error result = self.provider.generateToken();
        if (result is string) {
            headers[AUTH_HEADER] = AUTH_SCHEME_BEARER + " " + result;
            return headers;
        } else {
            return prepareClientAuthError("Failed to enrich headers with JWT.", result);
        }
    }

    # Returns the headers map with the relevant authentication requirements.
    #
    # + return - The updated headers map or else an `http:ClientAuthError` in case of an error
    public isolated function getSecurityHeaders() returns map<string|string[]>|ClientAuthError {
        string|jwt:Error result = self.provider.generateToken();
        if (result is string) {
            map<string|string[]> headers = {};
            headers[AUTH_HEADER] = AUTH_SCHEME_BEARER + " " + result;
            return headers;
        } else {
            return prepareClientAuthError("Failed to enrich headers with JWT.", result);
        }
    }
}
