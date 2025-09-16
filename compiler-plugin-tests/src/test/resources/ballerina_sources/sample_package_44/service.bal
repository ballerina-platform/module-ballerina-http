// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com)
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

type User record {
    string name;
    int age;
};

string globalVar = "test";

service /api/v1 on new http:Listener(9090) {
    resource function get users() returns User[] {
        return [];
    }
}

service /api/v2 on new http:Listener(9091) {
    resource function get products() returns string {
        return "products";
    }
}

service /api/v1 on new http:Listener(9092) {
    resource function get orders() returns string {
        return "orders";
    }
}

function utilityFunction() returns string {
    return "utility";
}

service / on new http:Listener(9093) {
    resource function get health() returns string {
        return "healthy";
    }
}

service / on new http:Listener(9094) {
    resource function get status() returns string {
        return "status";
    }
}
