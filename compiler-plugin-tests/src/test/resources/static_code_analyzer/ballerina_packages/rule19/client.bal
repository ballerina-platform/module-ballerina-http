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

// Noncompliant: a shared cache holding responses fetched with credentials.
final http:Client securedClient = check new ("https://api.example.com",
    auth = {username: "admin", password: "secret"},
    cache = {isShared: true}
);

// Compliant: the cache is private to this client's identity.
final http:Client privateCacheClient = check new ("https://api.example.com",
    auth = {username: "admin", password: "secret"},
    cache = {isShared: false}
);

// Compliant: a shared cache with no credentials configured.
final http:Client anonymousClient = check new ("https://api.example.com",
    cache = {isShared: true}
);

// Compliant: credentials with the default cache configuration.
final http:Client defaultCacheClient = check new ("https://api.example.com",
    auth = {username: "admin", password: "secret"}
);
