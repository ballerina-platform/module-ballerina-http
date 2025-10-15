// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.org)
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
import ballerina/io;

final http:Client clientEp = check new ("http://example.com");

service on new http:Listener(8080) {
    resource function get .(string path) returns string|error {
        http:Client userClient = check new ("http://example.com");
        json response = check userClient->/api/[path];
        return response.toJsonString();
    }

    resource function post .(record {|string path;|} payload) returns string|error {
        http:Client userClient = check new ("http://example.com");
        json response = check userClient->/api/[payload.path];
        return response.toJsonString();
    }

    resource function post blocks/[string path](string location, boolean condition) returns http:Response|json|error {
        do {
            if condition {
                boolean b = true;
                while b {
                    http:Response _ = check clientEp->/api/[location];
                    b = false;
                }
                foreach int a in 1...4 {
                    http:Response res = new;
                    res = check clientEp->/api/[path];
                    io:println(res);
                }
                lock {
                    json response = check clientEp->/api/[location];
                    return response;
                }
            } else {
                http:Response res = check clientEp->/api/[location];
                if condition {
                    res = check clientEp->/api/[location];
                    return res;
                }
            }
            _ = check clientEp->/api/[condition]/[location](targetType = http:Response);
            return;
        } on fail {
            return clientEp->/api/[path];
        }
    }
}
