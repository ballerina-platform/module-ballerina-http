// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

type RecordA record {|
    string name;
|};

type RecordB readonly & record {|
    int age;
|};

type TestRecord1 RecordA|http:Request;

type TestRecord2 RecordA|http:Service;

type TestRecord3 RecordA|http:Client;

type TestRecord4 RecordB|http:Client;

service on new http:Listener(4000) {

    resource function hello1 [string... path]() returns TestRecord1[] {
        return [{name: "Hello, World"}];
    }

    resource function hello2 [string... path]() returns TestRecord2[] {
        return [{name: "Hello, World"}];
    }

    resource function hello3 [string... path]() returns TestRecord3[] {
        return [{name: "Hello, World"}];
    }

    resource function hello4 [string... path]() returns TestRecord4[] {
            return [{age: 12}];
        }
}
