// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

service http:Service on new http:Listener(9090) {

    resource function get headerString(@http:Header {name: "x-type"} string abc) returns string {
        return "done";
    }

    resource function get headerStringArr(@http:Header {name: "x-type"} string[] abc) returns string {
        return "done";
    }

    resource function get headerStringNil(@http:Header {name: "x-type"} string? abc) returns string {
        return "done";
    }

    resource function get headerStringArrNil(@http:Header {name: "x-type"} string[]? abc) returns string {
        return "done";
    }

    resource function get headerErr1(@http:Header {name: "x-type"} json abc) returns string {
        return "done"; //error
    }

    resource function post headerErr2(@http:Header @http:Payload string abc) returns string {
        return "done"; //error
    }

    resource function get headerErr3(@http:Header {name: "x-type"} http:Request abc) returns string {
        return "done"; //error
    }

    resource function get headerErr4(@http:Header {name: "x-type"} string|json abc) returns string {
        return "done"; //error
    }

    resource function get headerErr5(@http:Header {name: "x-type"} json? abc) returns string {
        return "done"; //error
    }

    resource function get headerErr6(@http:Header {name: "x-type"} string|json|xml abc) returns string {
        return "done"; //error
    }

    resource function get headerErr7(@http:Header {name: "x-type"} int[] abc) returns string {
        return "done"; //error
    }
}
