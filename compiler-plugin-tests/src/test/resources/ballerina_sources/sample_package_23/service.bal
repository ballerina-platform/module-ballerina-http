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
import ballerina/mime;

type Person record {|
    readonly int id;
    string name;
|};

type PersonTable table<Person> key(id);

service http:Service on new http:Listener(9090) {

    resource function get withCaller(readonly & http:Caller caller) returns string { //not allowed
        return "done";
    }

    resource function get withRequest(readonly & http:Request request) returns string { //not allowed
        return "done";
    }

    resource function get withHeadersObj(readonly & http:Headers headers) returns string { //not allowed
        return "done";
    }

    resource function get withMimeEntity(readonly & mime:Entity entity) returns string { //not allowed
        return "done";
    }

    resource function get withQuery(readonly & int a) returns string { //allowed
        return "done";
    }

    resource function get withHeader(@http:Header readonly & string host) returns string { //allowed
        return "done";
    }

    resource function get withHeaderArr(@http:Header readonly & string[] host) returns string { //allowed
        return "done";
    }

    resource function get withHeaderArrInvalid(@http:Header readonly & json[] host) returns string { //not allowed
        return "done";
    }

    resource function get withHeaderWithUnion(@http:Header readonly & string? host) returns string { //allowed
        return "done";
    }

    resource function get withCallerInfo(@http:CallerInfo readonly & http:Caller host) returns error? { //allowed
        return;
    }

    resource function get withCallerInfoWithUnion(@http:CallerInfo readonly & http:Caller? host) returns error? { //not allowed
        return;
    }

    resource function get returnReadonlyJson() returns readonly & json { // allowed
        return "done";
    }

    resource function get returnReadonlyOk() returns readonly & http:Ok { // allowed
        http:Ok ok = {};
        return ok.cloneReadOnly();
    }

    resource function get returnReadonlyUnion() returns readonly & map<json>[]|string[] { // allowed
        map<json> jj = {sam: {hello:"world"}, jon: {no:56}};
        return [jj,jj].cloneReadOnly();
    }

    resource function get returnReadonlyMap() returns readonly & map<json> { // allowed
        map<json> jj = {sam: {hello:"world"}, jon: {no:56}};
        return jj.cloneReadOnly();
    }

    resource function get returnReadonlyTableArr() returns readonly & PersonTable[] { // allowed
        PersonTable tbPerson = table [
            {id: 1, name: "John"},
            {id: 2, name: "Bella"}
        ];
        return [tbPerson, tbPerson].cloneReadOnly();
    }

    resource function get returnReadonlyRecordArr() returns readonly & Person[] { // allowed
        return [{id:123, name: "john"}, {id:124, name: "khan"}].cloneReadOnly();
    }

    // Currently following give error reported in https://github.com/ballerina-platform/ballerina-lang/issues/35332
    // Once it's fixed, uncomment the following case
    //resource function get returnReadonlyInlineRecord() returns readonly & record {|*http:Created; Person body;|} {
    //    Person person = {id:123, name: "john"};
    //    return {
    //        mediaType: "application/person+json",
    //        headers: {
    //            "X-Server": "myServer"
    //        },
    //        body: person
    //    }.cloneReadOnly();
    //}
}
