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
import sample_28.records;

type RecordA record {|
    string name;
|};

type RecordB readonly & record {|
    int age;
|};

type TestRecord1 RecordA;

type TestRecord2 RecordA|RecordB;

type TestRecord3 RecordA|string;

type TestRecord4 RecordA|http:Response;

type TestRecord5 RecordA|map<string>;

type TestRecord6 RecordA|table<map<string>>;

type TestRecord7 int|table<map<string>>;

type TestRecord8 int|http:StatusCodeResponse;

type TestRecord9 RecordA|error;

type TestRecord10 records:RecordC|records:RecordD;

type TestRecord11 records:RecordC|xml;

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
        return [{name: "Hello, World"}];
    }

    resource function hello5 [string... path]() returns TestRecord5[] {
        return [{}];
    }

    resource function hello6 [string... path]() returns TestRecord6[] {
        return [{name: "Hello, World"}];
    }

    resource function hello7 [string... path]() returns TestRecord7[] {
        return [1];
    }

    resource function hello8 [string... path]() returns TestRecord8[] {
        return [1];
    }

    resource function hello9 [string... path]() returns TestRecord9[] {
        return [{name: "Hello, World"}];
    }

    resource function hello10 [string... path]() returns TestRecord10[] {
        records:RecordC response = {
            capacity: 10,
            elevationgain: 120,
            id: "2",
            name: "Test",
            night: false,
            status: records:HOLD
        };
        return [response];
    }

    resource function hello11 [string... path]() returns TestRecord11[] {
        return [xml`<A>Test</A>`];
    }
}
