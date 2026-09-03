// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com)
//
// WSO2 LLC. licenses this file to you under the Apache License,
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


import ballerina/http;

listener http:Listener securedListener = new (9090, secureSocket = {
    key: {
        certFile: "/path/to/public.crt",
        keyFile: "/path/to/private.key"
    }
});

// Authenticated, but every authenticated caller is allowed through
@http:ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {
                signatureConfig: {
                    certFile: "/path/to/public.crt"
                },
                issuer: "wso2",
                audience: "ballerina"
            }
        }
    ]
}
service /noScopes on securedListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// The same on an OAuth2 introspection provider
@http:ServiceConfig {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: "https://idp.example.com/introspect",
                tokenTypeHint: "access_token"
            }
        }
    ]
}
service /introspectionNoScopes on securedListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// Negative case - the service authorizes on a scope
@http:ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {
                signatureConfig: {
                    certFile: "/path/to/public.crt"
                },
                issuer: "wso2",
                audience: "ballerina"
            },
            scopes: ["admin"]
        }
    ]
}
service /scoped on securedListener {
    resource function get greet() returns string {
        return "Hello";
    }
}
