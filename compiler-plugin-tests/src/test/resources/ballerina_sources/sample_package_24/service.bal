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

type NewError error;

service http:Service on new http:Listener(9090) {

    resource function get callerInfo20(@http:CallerInfo {respondType: http:Error} http:Caller caller) returns error? {
        check caller->respond(<http:Error> error("hello world"));
    }

    // Will give an error at the moment, since we only support only http:Error error type
    resource function get callerInfo21(@http:CallerInfo {respondType: NewError} http:Caller caller) returns error? {
        check caller->respond(<NewError> error("New Error"));
    }

    // Will give an error at the moment, since typedesc has a limitation to have error as type
    resource function get greeting(@http:CallerInfo{respondType: error} http:Caller caller) returns error? {
        check caller->respond(error("New Error"));
    }
}
