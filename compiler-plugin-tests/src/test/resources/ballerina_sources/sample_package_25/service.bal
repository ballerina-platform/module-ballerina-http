// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;

service on new http:Listener(9090) {

    @http:ResourceConfig {
        name: "resource1",
        linkedTo: [
            {name: "resource1", method: "GET"},
            {name: "resource1", method: "post", relation: "add"},
            {name: "resource2", relation: "get"}
        ]
    }
    resource function get resource1/[int someInt]/path1() returns json {
        return {greeting: "hello"};
    }

    @http:ResourceConfig {
        name: "Resource1",
        linkedTo: [
            {name: "resource1", method: "POST"},
            {name: "resource3", method: "get", relation: "get"},
            {name: "resource3", method: "post", relation: "add"}
        ]
    }
    resource function post resource1/[string someString]/path1() returns json {
        return {greeting: "hello"};
    }

    @http:ResourceConfig {
        name: "resource2"
    }
    resource function 'default resource2/path1() returns json {
        return {greeting: "hello"};
    }

    @http:ResourceConfig {
        name: "resource3"
    }
    resource function 'default resource3/path1() returns @http:Payload{mediaType: "application/json"} json {
        return {greeting: "hello"};
    }

    @http:ResourceConfig {
        name: "RESOURCE3"
    }
    resource function get resource3/path1() returns json {
        return {greeting: "hello"};
    }
}

// Errors
service on new http:Listener(9091) {

    @http:ResourceConfig {
        name: "resource1",
        linkedTo: [
            {name: "resource1", method: "get"},
            {name: "resource2", method: "get"},
            {name: "resource3", method: "get", relation: "SELF"},
            {name: "resource5", method: "put", relation: "update"}
        ]
    }
    resource function get resource1/[int someInt]/path1() returns json {
        return {greeting: "hello"};
    }

    @http:ResourceConfig {
        name: "resource1",
        linkedTo: [
            {name: "resource1", method: "post", relation: "add"},
            {name: "resource3", relation: "get"},
            {name: "resource3", method: "post", relation: "add"}
        ]
    }
    resource function post resource1/[string someString]/path2() returns json {
        return {greeting: "hello"};
    }

    @http:ResourceConfig {
        name: "resource2"
    }
    resource function get resource2/path1() returns json {
        return {greeting: "hello"};
    }

    @http:ResourceConfig {
        name: "resource3"
    }
    resource function default resource3/path1() returns @http:Payload{mediaType: "application/json"} json {
        return {greeting: "hello"};
    }

    @http:ResourceConfig {
        name: "resource3"
    }
    resource function put resource3/path1() returns @http:Payload{mediaType: "application/json"} json {
        return {greeting: "hello"};
    }

    @http:ResourceConfig {
        name: "Resource3"
    }
    resource function get resource3/path2() returns json {
        return {greeting: "hello"};
    }
}
