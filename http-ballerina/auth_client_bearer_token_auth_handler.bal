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

# Represents token for Bearer token authentication.
#
# + token - Bearer token for authentication
public type BearerTokenConfig record {|
    string token;
|};

# Defines the Bearer token auth handler for client authentication.
public class ClientBearerTokenAuthHandler {

    *ClientAuthHandler;

    BearerTokenConfig config;

    # Initializes the `http:ClientBearerTokenAuthHandler` object.
    #
    # + config - The `http:BearerTokenConfig` instance
    public function init(BearerTokenConfig config) {
        self.config = config;
    }

    # Enrich the request with the relevant authentication requirements.
    #
    # + req - The `http:Request` instance
    # + return - The updated `http:Request` instance or else an `http:ClientAuthError` in case of an error
    public function enrich(Request req) returns Request|ClientAuthError {
        req.setHeader(AUTH_HEADER, AUTH_SCHEME_BEARER + " " + self.config.token);
        return req;
    }
}
