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

@http:ServiceConfig {}
service /test1 on new http:Listener(9999) {

    resource function get test (http:Request req) returns string {
        return "test";
    }
}

@http:ServiceConfig {
    host : "b7a.default"
}
service /test2 on new http:Listener(9998) {

    resource function get test (http:Request req) returns string {
        return "test";
    }
}

@http:ServiceConfig {
    host : "b7a.default",
    mediaTypeSubtypePrefix : "prefix.subType"
}
service /test3 on new http:Listener(9997) {

    resource function get test (http:Request req) returns string {
        return "test";
    }
}

@http:ServiceConfig {
    host : "b7a.default",
    mediaTypeSubtypePrefix : "prefix.subType+suffix"
}
service /test4 on new http:Listener(9996) {

    resource function get test (http:Request req) returns string {
        return "test";
    }
}

@http:ServiceConfig {
    host : "b7a.default",
    mediaTypeSubtypePrefix : "vnd.prefix.subType+ suffix1+ suffix2"
}
service /test4 on new http:Listener(9996) {

    resource function get test (http:Request req) returns string {
        return "test";
    }
}

@http:ServiceConfig {
    host : "b7a.default",
    mediaTypeSubtypePrefix : "+suffix"
}
service /test5 on new http:Listener(9995) {

    resource function get test (http:Request req) returns string {
        return "test";
    }
}

@http:ServiceConfig {
    host : "b7a.default",
    mediaTypeSubtypePrefix : "vnd.prefix.subtype+ "
}
service /test6 on new http:Listener(9994) {

    resource function get test (http:Request req) returns string {
        return "test";
    }
}
