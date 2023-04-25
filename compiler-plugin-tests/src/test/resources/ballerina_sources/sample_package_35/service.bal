// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

type Person record {|
    readonly int id;
|};

type Pp Person;

class WorkPlace {};

type Employee record {
    int id;
    string name;
    WorkPlace workplace;
};

service http:Service on new http:Listener(9090) {

    resource function post ambiguous1(Person a, Person b) returns string {
        return "done"; // ambiguous
    }

    resource function post ambiguous2(map<json> c, Person d) returns string {
        return "done"; // ambiguous
    }

    resource function post ambiguous3(byte[] e, Person f) returns string {
        return "done"; // ambiguous
    }

    resource function post ambiguous4(map<json>|string g, Person h) returns string {
        return "done"; // ambiguous
    }

    resource function post multiple1(@http:Payload @http:Query map<json> g) returns string {
        return "done"; // multiple annotation
    }

    resource function post unionError(http:Request|string p) returns string {
        return "done"; // p is payload param
    }

    resource function post testMultipleWithUnion(Person q, map<json>? p) returns string {
        return "done";
    }

    resource function post nonAnydataStructuredType1(Employee e) returns string {
        return "done";
    }

    resource function post nonAnydataStructuredType2(Employee e, Person p) returns string {
        return "done";
    }

    resource function post unionWithNonAnydataStructuredType(Employee|Person a) returns string {
        return "done";
    }
}

