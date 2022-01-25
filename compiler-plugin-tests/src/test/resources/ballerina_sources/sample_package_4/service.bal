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

type Person record {|
    readonly int id;
|};

public annotation Person Pp on parameter;

service http:Service on new http:Listener(9090) {

    resource function post dbJson(@http:Payload json abc) returns string {
        return "done";
    }

    resource function post dbXml(@http:Payload @http:Header xml abc) returns string {
        return "done"; // error
    }

    resource function get dbString(@http:Payload string abc) returns string {
        return "done"; // error
    }

    resource function head dbString(@http:Payload string abc) returns string {
        return "done"; // error
    }

    resource function options dbString(@http:Payload string abc) returns string {
        return "done"; // error
    }

    resource function post dbMapOfString(@http:Payload map<string> abc) returns string {
        return "done";
    }

    resource function post dbByteArr(@http:Payload byte[] abc) returns string {
        return "done";
    }

    resource function post dbRecord(@http:Payload Person abc) returns string {
        return "done";
    }

    resource function post dbRecArr(@http:Payload Person[] abc) returns string {
        return "done";
    }

    resource function post dbJsonArr(@http:Payload json[] abc) returns string {
        return "done"; // error
    }

    resource function post greeting1(int num, @http:Payload json abc, @Pp {id:0} string a) returns string {
        return "done"; // error
    }

    resource function post dbTable(table<Person> key(id)  abc) returns string {
        return "done"; // error
    }

    resource function post dbMapOfIntNegative(@http:Payload map<int> abc) returns string {
        return "done"; // error
    }

    resource function post dbStringArrNegative(@http:Payload string[] abc) returns string {
        return "done"; // error
    }

    resource function post dbXmlArrNegative(@http:Payload xml[] abc) returns string {
        return "done"; // error
    }

    resource function post dbMapStringArrNegative(@http:Payload map<string>[] abc) returns string {
        return "done"; // error
    }
}
