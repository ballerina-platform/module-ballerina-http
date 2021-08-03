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
import ballerina/mime;

type Caller record {|
    int id;
|};

service http:Service on new http:Listener(9090) {

    resource function get callerInfo1(string a, int[] b, float? c, decimal[]? d) returns string {
        return "done";
    }

    resource function get callerInfo2(string a, int[] b) returns string {
        return "done";
    }

    resource function get callerInfo3(string a, int b, float c, decimal d, boolean e) returns string {
        return "done";
    }

    resource function get callerInfo4(string? a, int? b, float? c, decimal? d, boolean? e) returns string {
        return "done";
    }

    resource function get callerInfo5(string[] a, int[] b, float[] c, decimal[] d, boolean[] e) returns string {
        return "done";
    }

    resource function get callerInfo6(string[]? a, int[]? b, float[]? c, decimal[]? d, boolean[]? e) returns string {
        return "done";
    }

    resource function get callerErr1(json a) returns string {
        return "done";
    }

    resource function get callerErr2(mime:Entity abc) returns string {
        return "done";
    }

    resource function get callerErr3(int|string a) returns string {
        return "done";
    }

    resource function get callerErr4(int|string[]|float a) returns string {
        return "done";
    }

    resource function get callerErr5(int[]|json a) returns string {
        return "done";
    }

    resource function get callerErr6(json[] a) returns string {
        return "done";
    }

    resource function get callerErr7(json? a) returns string {
        return "done";
    }
}
