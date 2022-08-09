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

// This is user-defined type
public type Count int;
public type TypeJson json;

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

    resource function get callerInfo7(map<json> aa, string? ab, boolean[] ac) returns string {
        return "done";
    }

    resource function get callerInfo8(map<json>[] ba, int bb, decimal[]? bc) returns string {
        return "done";
    }

    resource function get callerInfo9(float[] cb, int[]? cc, map<json>? ca) returns string {
        return "done";
    }

    resource function get callerInfo10(string[] db, boolean dc, map<json>[]? da) returns string {
        return "done";
    }

    resource function get callerErr1(mime:Entity abc) returns string {
        return "done";
    }

    resource function get callerErr2(int|string a) returns string {
        return "done";
    }

    resource function get callerErr3(int|string[]|float b) returns string {
        return "done";
    }

    resource function get callerErr4(int[]|json c) returns string {
        return "done";
    }

    resource function get callerErr5(xml? d, string e) returns string {
        return "done";
    }

    resource function get callerErr6(int[]? b, json a, json[] aa) returns string {
        return "done";
    }

    resource function get callerErr7(string? b, map<int> a) returns string {
        return "done";
    }

    resource function get callerErr8(map<int>[] b, int[] c) returns string {
        return "done";
    }

    resource function get callerErr9(map<string>? c, map<json> d) returns string {
        return "done";
    }

    resource function get callerErr10(json[] d, xml e) returns string {
            return "done";
    }

    resource function get pets(Count count) returns http:Ok {
        http:Ok ok = {body: ()};
        return ok;
    }

    resource function get petsUnion(Count? count) returns http:Ok {
        http:Ok ok = {body: ()};
        return ok;
    }

    resource function get petsArr(Count[] count) returns http:Ok {
        http:Ok ok = {body: ()};
        return ok;
    }

    resource function get petsMap(map<TypeJson> count) returns http:Ok {
        http:Ok ok = {body: ()};
        return ok;
    }
}
