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
public type Name string;
public type FirstName Name;
public type FullName FirstName;

service http:Service on new http:Listener(9090) {

    resource function get callerInfo1(@http:Query string a, @http:Query int[] b, @http:Query float? c,
        @http:Query decimal[]? d) returns string {
        return "done";
    }

    resource function get callerInfo2(@http:Query string a, @http:Query int[] b) returns string {
        return "done";
    }

    resource function get callerInfo3(@http:Query string a, @http:Query int b, @http:Query float c,
        @http:Query decimal d, @http:Query boolean e) returns string {
        return "done";
    }

    resource function get callerInfo4(@http:Query string? a, @http:Query int? b, @http:Query float? c,
        @http:Query decimal? d, @http:Query boolean? e) returns string {
        return "done";
    }

    resource function get callerInfo5(@http:Query string[] a, @http:Query int[] b, @http:Query float[] c,
        @http:Query decimal[] d, @http:Query boolean[] e) returns string {
        return "done";
    }

    resource function get callerInfo6(@http:Query string[]? a, @http:Query int[]? b, @http:Query float[]? c,
        @http:Query decimal[]? d, @http:Query boolean[]? e) returns string {
        return "done";
    }

    resource function get callerInfo7(@http:Query map<json> aa, @http:Query string? ab,
        @http:Query boolean[] ac) returns string {
        return "done";
    }

    resource function get callerInfo8(@http:Query map<json>[] ba, @http:Query int bb,
        @http:Query decimal[]? bc) returns string {
        return "done";
    }

    resource function get callerInfo9(@http:Query float[] cb, @http:Query int[]? cc,
        @http:Query map<json>? ca) returns string {
        return "done";
    }

    resource function get callerInfo10(@http:Query string[] db, @http:Query boolean dc,
        @http:Query map<json>[]? da) returns string {
        return "done";
    }

    resource function get callerErr1(@http:Query mime:Entity abc) returns string {
        return "done";
    }

    resource function get callerErr2(@http:Query int|string a) returns string {
        return "done";
    }

    resource function get callerErr3(@http:Query int|string[]|float b) returns string {
        return "done";
    }

    resource function get callerErr4(@http:Query int[]|json c) returns string {
        return "done";
    }

    resource function get callerErr5(@http:Query xml? d, @http:Query string e) returns string {
        return "done";
    }

    resource function get callerErr6(@http:Query int[]? b, @http:Query json a, @http:Query json[] aa) returns string {
        return "done";
    }

    resource function get callerErr7(@http:Query string? b, @http:Query map<int> a) returns string {
        return "done";
    }

    resource function get callerErr8(@http:Query map<int>[] b, @http:Query int[] c) returns string {
        return "done";
    }

    resource function get callerErr9(@http:Query map<string>? c, @http:Query map<json> d) returns string {
        return "done";
    }

    resource function get callerErr10(@http:Query json[] d, @http:Query xml e) returns string {
            return "done";
    }

    resource function get pets(@http:Query Count count) returns http:Ok {
        http:Ok ok = {body: ()};
        return ok;
    }

    resource function get petsUnion(@http:Query Count? count) returns http:Ok {
        http:Ok ok = {body: ()};
        return ok;
    }

    resource function get petsArr(@http:Query Count[] count) returns http:Ok {
        http:Ok ok = {body: ()};
        return ok;
    }

    resource function get petsMap(@http:Query map<TypeJson> count) returns http:Ok {
        http:Ok ok = {body: ()};
        return ok;
    }

    resource function get nestedTypeRef(@http:Query FullName names) returns http:Ok {
        http:Ok ok = {body: ()};
        return ok;
    }
}
