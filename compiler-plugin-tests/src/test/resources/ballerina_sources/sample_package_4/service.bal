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

    resource function post dbXmlNegative(@http:Payload @http:Header xml abc) returns string {
        return "done"; // error
    }

    resource function get dbStringNegative(@http:Payload string abc) returns string {
        return "done"; // error
    }

    resource function head dbStringNegative(@http:Payload string abc) returns string {
        return "done"; // error
    }

    resource function options dbStringNegative(@http:Payload string abc) returns string {
        return "done"; // error
    }

    // int
    resource function post dbInt(@http:Payload int abc) returns string {
        return "done";
    }

    resource function post dbIntArr(@http:Payload int[] abc) returns string {
        return "done";
    }

    resource function post dbIntMap(@http:Payload map<int> abc) returns string {
        return "done";
    }

    resource function post dbIntTable(@http:Payload table<map<int>> abc) returns string {
        return "done";
    }

    // boolean
    resource function post dbBool(@http:Payload boolean abc) returns string {
        return "done";
    }

    resource function post dbBoolArr(@http:Payload boolean[] abc) returns string {
        return "done";
    }

    resource function post dbBoolMap(@http:Payload map<boolean> abc) returns string {
        return "done";
    }

    resource function post dbBoolTable(@http:Payload table<map<boolean>> abc) returns string {
        return "done";
    }

    // float
    resource function post dbFloat(@http:Payload float abc) returns string {
        return "done";
    }

    resource function post dbFloatArr(@http:Payload float[] abc) returns string {
        return "done";
    }

    resource function post dbFloatMap(@http:Payload map<float> abc) returns string {
        return "done";
    }

    resource function post dbFloatTable(@http:Payload table<map<float>> abc) returns string {
        return "done";
    }

    // decimal
    resource function post dbDecimal(@http:Payload decimal abc) returns string {
        return "done";
    }

    resource function post dbDecimalArr(@http:Payload decimal[] abc) returns string {
        return "done";
    }

    resource function post dbDecimalMap(@http:Payload map<decimal> abc) returns string {
        return "done";
    }

    resource function post dbDecimalTable(@http:Payload table<map<decimal>> abc) returns string {
        return "done";
    }

    // byte[]
    resource function post dbByteArr(@http:Payload byte[] abc) returns string {
        return "done";
    }

    resource function post dbByteArrArr(@http:Payload byte[][] abc) returns string {
        return "done";
    }

    resource function post dbByteArrMap(@http:Payload map<byte[]> abc) returns string {
        return "done";
    }

    resource function post dbByteArrTable(@http:Payload table<map<byte[]>> abc) returns string {
        return "done";
    }

    // string
    resource function post dbString(@http:Payload string abc) returns string {
        return "done";
    }

    resource function post dbStringArr(@http:Payload string[] abc) returns string {
        return "done";
    }

    resource function post dbStringMap(@http:Payload map<string> abc) returns string {
        return "done";
    }

    resource function post dbStringTable(@http:Payload table<map<string>> abc) returns string {
        return "done";
    }

    // xml
    resource function post dbXml(@http:Payload xml abc) returns string {
        return "done";
    }

    resource function post dbXmlArr(@http:Payload xml[] abc) returns string {
        return "done";
    }

    resource function post dbXmlMap(@http:Payload map<xml> abc) returns string {
        return "done";
    }

    resource function post dbXmlTable(@http:Payload table<map<xml>> abc) returns string {
        return "done";
    }

    // json
    resource function post dbJson(@http:Payload json abc) returns string {
        return "done";
    }

    resource function post dbJsonArr(@http:Payload json[] abc) returns string {
        return "done";
    }

    resource function post dbJsonMap(@http:Payload map<json> abc) returns string {
        return "done";
    }

    resource function post dbJsonTable(@http:Payload table<map<json>> abc) returns string {
        return "done";
    }

    // record
    resource function post dbRecord(@http:Payload Person abc) returns string {
        return "done";
    }

    resource function post dbRecordArr(@http:Payload Person[] abc) returns string {
        return "done";
    }

    resource function post dbRecordMap(@http:Payload map<Person> abc) returns string {
        return "done";
    }

    resource function post dbRecordTable(@http:Payload table<Person> key(id) abc) returns string {
        return "done";
    }

    // map
    resource function post dbMapArr(@http:Payload map<Person>[] abc) returns string {
        return "done";
    }

    resource function post dbMapMap(@http:Payload map<map<Person>> abc) returns string {
        return "done";
    }

    // array
    resource function post dbArrArr(@http:Payload Person[][] abc) returns string {
        return "done";
    }

    resource function post dbArrayMap(@http:Payload map<Person[]> abc) returns string {
        return "done";
    }

    resource function post dbRecorArrayMapMap(@http:Payload map<map<Person[]>> abc) returns string {
        return "done";
    }

    // table
    resource function post dbTableArr(@http:Payload table<Person> key(id)[] abc) returns string {
        return "done";
    }

    resource function post dbTableMap(@http:Payload map<table<Person> key(id)> abc) returns string {
        return "done";
    }

    // anydata
    resource function post dbAnydata(@http:Payload anydata abc) returns string {
        return "done";
    }

    //readonly
    resource function post dbIntTableRO(@http:Payload table<readonly & map<readonly & byte[]>> abc) returns string {
        return "done";
    }

    resource function post dbArrayMapRO(@http:Payload readonly & map<readonly & Person[]> abc) returns string {
        return "done";
    }

    resource function post greeting1(int num, @http:Payload json abc, @Pp {id:0} string a) returns string {
        return "done"; // error
    }
}
