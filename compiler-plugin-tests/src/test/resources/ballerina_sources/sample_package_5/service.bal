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

type RateLimitHeaders record {|
    string x\-rate\-limit\-id;
    int? x\-rate\-limit\-remaining;
    string[]? x\-rate\-limit\-types;
|};

type TestRecord record {|
    string[]|string xRate;
|};

type NestedRecord record {|
    RateLimitHeaders xRate;
|};

enum HeaderValue {
    VALUE1 = "value1",
    VALUE2 = "value2",
    VALUE3 = "value3"
};

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

    resource function get headerRecord(@http:Header {name: "x-type"} RateLimitHeaders abc) returns string {
        return "done";
    }

    resource function get headerRecordReadonly(@http:Header readonly & RateLimitHeaders abc) returns string {
        return "done";
    }

    resource function get headerRecordWithInvalidFieldUnion(@http:Header TestRecord abc) returns string {
        return "done"; //error
    }

    resource function get headerRecordNil(@http:Header {name: "x-type"} RateLimitHeaders? abc) returns string {
        return "done";
    }

    resource function get headerRecordArr(@http:Header {name: "x-type"} RateLimitHeaders[] abc) returns string {
        return "done"; //error
    }

    resource function get headerRecordArrNil(@http:Header RateLimitHeaders[]? abc) returns string {
        return "done"; //error
    }

    resource function get headerRecordUnionStr(@http:Header RateLimitHeaders|string abc) returns string {
        return "done"; //error
    }

    resource function get headerInlineRecord(@http:Header record {|string hello;|} abc) returns string {
        return "done";
    }

    resource function get headerInlineRestAndStringRecord(@http:Header record {|string hello; string...;|} abc) returns
    string {
        return "done"; //error
    }

    resource function get headerInlineRestRecord(@http:Header record {|string...;|} abc) returns string {
        return "done"; //error
    }

    resource function get headerInt(@http:Header int foo, @http:Header int[] bar, @http:Header int? baz,
            @http:Header int[]? daz, @http:Header readonly & int dawz) returns string {
        return "done";
    }

    resource function get headerDecimal(@http:Header decimal foo, @http:Header decimal[] bar, @http:Header decimal? baz,
            @http:Header decimal[]? daz, @http:Header readonly & decimal? dawz) returns string {
        return "done";
    }

    resource function get headerFloat(@http:Header float foo, @http:Header float[] bar, @http:Header float? baz,
            @http:Header float[]? daz, @http:Header readonly & float dawz) returns string {
        return "done";
    }

    resource function get headerBool(@http:Header boolean foo, @http:Header boolean[] bar, @http:Header boolean? baz,
            @http:Header boolean[]? daz, @http:Header readonly & boolean dawz) returns string {
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

    resource function get headerRecordWithRecordField(@http:Header NestedRecord abc) returns string {
        return "done"; //error
    }

    resource function 'default [string... path](@http:Header HeaderValue? test) returns string {
        return test.toString();
    }
}
