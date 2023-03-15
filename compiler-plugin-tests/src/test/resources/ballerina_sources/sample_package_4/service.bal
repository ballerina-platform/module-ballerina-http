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

type Person record {|
    readonly int id;
|};

type RequestBody record {|
    string xyz;
    mime:Entity file1;
    http:Request req;
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

    // unions
    resource function post dbUnion(@http:Payload json|xml abc) returns string {
        return "done";
    }

    resource function post dbReadonlyJsonUnion(@http:Payload readonly & byte[]|xml abc) returns string {
        return "done";
    }

    resource function post dbReadonlyUnion(@http:Payload readonly & (json|xml) abc) returns string {
        return "done";
    }

    resource function post dbStringNil(@http:Payload string? abc) returns string {
        return "done";
    }

    resource function post dbUnionNegative(@http:Payload string|http:Caller abc) returns string {
        return "done";
    }

    // builtin subtypes
    resource function post dbXmlElement(@http:Payload xml:Element abc) returns string {
        return "done";
    }

    resource function post dbXmlText(@http:Payload xml:Text abc) returns string {
        return "done";
    }

    resource function post dbXmlComment(@http:Payload xml:Comment abc) returns string {
        return "done";
    }

    resource function post dbXmlProcessingInstruction(@http:Payload xml:ProcessingInstruction abc) returns string {
        return "done";
    }

    resource function post dbStrChar(@http:Payload string:Char abc) returns string {
        return "done";
    }

    resource function post dbIntSigned32(@http:Payload int:Signed32 abc) returns string {
        return "done";
    }

    resource function post dbIntSigned16(@http:Payload int:Signed16 abc) returns string {
        return "done";
    }

    resource function post dbIntSigned8(@http:Payload int:Signed8 abc) returns string {
        return "done";
    }

    resource function post dbIntUnsigned32(@http:Payload int:Unsigned32 abc) returns string {
        return "done";
    }

    resource function post dbIntUnsigned16(@http:Payload int:Unsigned16 abc) returns string {
        return "done";
    }

    resource function post dbIntUnsigned8(@http:Payload int:Unsigned8 abc) returns string {
        return "done";
    }

    resource function post dbRecordWithObjectNegative(@http:Payload RequestBody abc) returns string {
        return "done"; //error
    }
}

enum MenuType {
    BREAK_FAST,
    LUNCH,
    DINNER
}

type Item record {|
    int _id;
    string name;
    string description;
    decimal price;
|};

type Menu record {|
    int _id;
    MenuType 'type;
    Item[] items;
|};

type Restaurant record {|
    string name;
    string city;
    string description;
    Menu[] menus;
|};

public type User readonly & record {|
    int id;
    int age;
|};

type RestaurantNew record {|
    *Restaurant;
    [int, string, decimal, float, User] address;
|};

class Object {}

service on new http:Listener(9091) {

    resource function post menuType(@http:Payload MenuType menuType)
            returns http:Accepted {
        return http:ACCEPTED;
    }

    resource function post menu(@http:Payload Menu menu)
            returns http:Created {
        return http:CREATED;
    }

    resource function post restaurants(@http:Payload Restaurant restaurant)
            returns http:Created {
        return http:CREATED;
    }

    resource function post restaurantsNew(@http:Payload RestaurantNew restaurant) returns RestaurantNew {
        return restaurant;
    }

    resource function post address(@http:Payload [int, string, User] address) returns http:Created {
        return http:CREATED;
    }

    // error
    resource function post obj(@http:Payload [int, string, Object] address) returns http:Created {
        return http:CREATED;
    }
}

