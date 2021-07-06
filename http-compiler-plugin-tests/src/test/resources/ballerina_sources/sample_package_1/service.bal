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

    string abc = "as";

    resource function get greeting() {
    }

    isolated resource function post noGreeting() {
    }

    private function hello() returns string {
        return "yo";
    }

    isolated remote function greeting() returns string {
        return "Hello";
    }

    function hello2() returns string {
        return "yo";
    }

    remote function greeting2() returns string|http:Response {
        return "Hello";
    }
}

service http:Service on new http:Listener(9091) {
    remote function greeting2(http:Caller caller) {
    }
}
