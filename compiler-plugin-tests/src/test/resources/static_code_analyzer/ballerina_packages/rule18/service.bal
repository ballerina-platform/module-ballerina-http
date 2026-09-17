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

@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["admin"]
        }
    ]
}
service /secured on securedListener {

    // Noncompliant: a revoked caller may keep receiving this from a cache.
    resource function get profile() returns @http:Cache {isPrivate: true, mustRevalidate: false} json {
        return {name: "user"};
    }

    // Compliant: revalidation left at its default.
    resource function get settings() returns @http:Cache {isPrivate: true} json {
        return {theme: "dark"};
    }

    // Compliant: revalidation explicitly kept on.
    resource function get token() returns @http:Cache {isPrivate: true, mustRevalidate: true} json {
        return {token: "abc"};
    }
}

service /unsecured on new http:Listener(9091) {

    // Compliant: no authentication, so the response is not caller-specific.
    resource function get banner() returns @http:Cache {mustRevalidate: false} json {
        return {message: "hello"};
    }
}
