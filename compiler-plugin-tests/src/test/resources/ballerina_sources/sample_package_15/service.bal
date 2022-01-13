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

// DO NOT CHANGE THE EXISTING CODE SINCE IT WILL CAUSE TEST FAILURES
// TESTS ARE SENSITIVE TO SINGLE LINE/CHARACTER CHANGES

import ballerina/http;
import ballerina/test;

type Person record {|
    readonly int id;
|};

public annotation Person Pp on parameter;

service / on new http:Listener(9999) {

    resource function get test102() returns map<http:Client> {
        http:Client httpClient = checkpanic new("path");
        return {name:httpClient};
    }

    @test:Config {}
    resource function get test103() returns int|error|string {
        return error http:Error("hello") ;
    }

    resource function post test104(int num, @http:Payload json abc, @Pp {id:0} string a) returns string {
        return "done";
    }

    resource function get test106(table<Person> key(id)  abc) returns string {
        return "done";
    }

    resource function post test107(@http:Payload json[] abc) returns string {
        return "done"; // error
    }

    resource function post test108(@http:Payload @http:Header xml abc) returns string {
        return "done";
    }

    resource function get test109(@http:Header {name: "x-type"} http:Request abc) returns string {
        return "done"; //error
    }

    resource function get test110(@http:Header {name: "x-type"} string|json abc) returns string {
        return "done"; //error
    }

    resource function get test111(@http:CallerInfo http:Caller abc) returns string {
        return "done"; //error
    }

    resource function get test112(map<string>? c, map<json> d) returns string {
        return "done";
    }
    resource function get test113(int[]|json c) returns string {
        return "done";
    }

    @http:ResourceConfig {
        consumes: ["fwhbw"]
    }
    resource function get test115(@http:CallerInfo {respondType:string} http:Caller abc, http:Request req,
            http:Headers head, http:Caller xyz, http:Headers noo, http:Request aaa) {
        checkpanic xyz->respond("done");
    }

    resource function get test118(http:Caller caller, string action) returns http:BadRequest? {
        if action == "complete" {
            error? result = caller->respond("This is successful");
        } else {
            http:BadRequest result = {
                body: "Provided `action` parameter is invalid"
            };
            return result;
        }
    }

}
