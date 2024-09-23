// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

type Value "value1"|"value2";

type ValueNilable ("value1"|"value2"|"value3")?;

enum EnumValue {
    VALUE1,
    VALUE2,
    VALUE3
}

type EnumCombined EnumValue|"VALUE4"|"VALUE5";

type HeaderRecord record {|
    "value1"|"value2" header1;
    EnumValue header2;
    (1|2|3)[] header3;
    (EnumValue|Value)[] header4;
|};

type HeaderRecordWithName record {|
    @http:Header {name: "x-header1"}
    string header1;
    @http:Header {name: "x-header2"}
    string header2;
    @http:Header {name: "x-header3"}
    string[] header3;
|};

type HeaderRecordWithType record {|
    @http:Header {name: "x-header1"}
    "value1"|"value2" header1;
    @http:Header {name: "x-header2"}
    EnumValue header2;
    @http:Header {name: "x-header3"}
    (EnumValue|Value)[] header3;
|};

type UnionFiniteType EnumValue|Value;

type QueryRecord record {|
    EnumValue enumValue;
    "value1"|"value2" value;
|};

type QueryRecordOpen record {
    EnumValue enumValue;
    "value1"|"value2" value;
    xml 'xml?;
    never 'type?;
};

type QueryRecordCombined QueryRecord|map<json>;

type QueryRecordCombinedAnydata QueryRecordOpen|map<anydata>;

type StringCharacter string:Char;

type SmallInt int:Signed8;

listener http:Listener resourceParamBindingListener = new(resourceParamBindingTestPort);

service /path on resourceParamBindingListener {
    
    resource function get case1/["value1"|"value2" path]() returns string {
        return path;
    }

    resource function get case2/[Value path]() returns string {
        return path;
    }

    resource function get case3/[EnumValue path]() returns string {
        return path;
    }

    resource function get case4/[1|2... paths]() returns int[] {
        return paths;
    }

    resource function get case5/[Value... paths]() returns string[] {
        return paths;
    }

    resource function get case6/[EnumValue... paths]() returns string[] {
        return paths;
    }

    resource function get case7/[EnumValue|string path]() returns string {
        if path is EnumValue {
            return "EnumValue: " + path;
        }
        return path;
    }

    resource function get case8/[EnumValue|"value3" path]() returns string {
        if path is EnumValue {
            return "EnumValue: " + path;
        }
        return path;
    }

    resource function get case9/[UnionFiniteType path]() returns string {
        if path is EnumValue {
            return "EnumValue: " + path;
        }
        return "Value: " + path;
    }

    resource function get case10/[(Value|EnumValue)... paths]() returns string[] {
        string[] result = [];
        foreach Value|EnumValue path in paths {
            if path is EnumValue {
                result.push("EnumValue: " + path);
            } else {
                result.push("Value: " + path);
            }
        }
        return result;
    }

    resource function get case11/[int:Signed32 path]() returns int:Signed32 {
        return path;
    }

    resource function get case12/[int:Unsigned32 path]() returns int:Unsigned32 {
        return path;
    }

    resource function get case13/[int:Signed8... path]() returns int:Signed8[] {
        return path;
    }

    resource function get case14/[string:Char path]() returns string:Char {
        return path;
    }

    resource function get case15/[StringCharacter path1]/[SmallInt path2]() returns [StringCharacter, SmallInt] {
        return [path1, path2];
    }
}

service /query on resourceParamBindingListener {

    resource function get case1("value1"|"value2" query) returns string {
        return query;
    }

    resource function get case2((1.2|2.4|3.6)? query) returns float {
        return query ?: 0.0;
    }

    resource function get case3(ValueNilable query = "value2") returns string {
        return query ?: "default";
    }

    resource function get case4(EnumValue query) returns string {
        return query;
    }

    resource function get case5(EnumCombined query) returns string {
        if query is EnumValue {
            return "EnumValue: " + query;
        } else {
            return query;
        }
    }

    resource function get case6(Value[]? query) returns string[] {
        return query ?: ["default"];
    }

    resource function get case7(EnumValue[] query) returns string[] {
        return query;
    }

    resource function get case8(UnionFiniteType[] query) returns string[] {
        string[] result = [];
        foreach var value in query {
            if value is EnumValue {
                result.push("EnumValue: " + value);
            } else {
                result.push("Value: " + value);
            }
        }
        return result;
    }

    resource function get case9(QueryRecordCombined? query) returns map<json>|error {
        if query is () {
            return {"type": "default"};
        }
        map<json> result = check query.cloneWithType();
        if query is QueryRecord {
            result["type"] = "QueryRecord";
        } else {
            result["type"] = "map<json>";
        }
        return result;
    }

    resource function get case10((QueryRecord|map<json>)[] query) returns map<json>[]|error {
        map<json>[] result = check query.cloneWithType();
        foreach int i in 0...(query.length() - 1) {
            if query[i] is QueryRecord {
                result[i]["type"] = "QueryRecord";
            } else {
                result[i]["type"] = "map<json>";
            }
        }
        return result;
    }

    resource function get case11(int:Signed32 query) returns int:Signed32 {
        return query;
    }

    resource function get case12(int:Unsigned32 query) returns int:Unsigned32 {
        return query;
    }

    resource function get case13(int:Signed8[] query) returns int:Signed8[] {
        return query;
    }

    resource function get case14(string:Char query) returns string:Char {
        return query;
    }

    resource function get case15(StringCharacter query1, SmallInt query2) returns [StringCharacter, SmallInt] {
        return [query1, query2];
    }

    resource function get case16(map<json> query1, string[] query2) returns [map<json>, string[]] {
        return [query1, query2];
    }

    resource function get case17(QueryRecordOpen? query) returns map<anydata>|error {
        if query is () {
            return {"type": "default"};
        }
        map<anydata> result = check query.cloneWithType();
        do {
            _ = check query.cloneWithType(QueryRecord);
            result["type"] = "QueryRecord";
        } on fail {
            result["type"] = "QueryRecordOpen";
            if (result.hasKey("xml") && result["xml"] is xml) {
                result["type"] = "QueryRecordOpenWithXML";
            }
        }
        return result;
    }

    resource function get case18(QueryRecordCombinedAnydata[] query) returns map<anydata>[]|error {
        map<anydata>[] result = check query.cloneWithType();
        foreach int i in 0 ... (query.length() - 1) {
            do {
                _ = check query[i].cloneWithType(QueryRecord);
                result[i]["type"] = "QueryRecord";
            } on fail {
                do {
                    QueryRecordOpen q = check query[i].cloneWithType();
                    result[i]["type"] = "QueryRecordOpen";
                    if (q.hasKey("xml") && q["xml"] is xml) {
                        result[i]["type"] = "QueryRecordOpenWithXML";
                    }
                } on fail {
                    result[i]["type"] = "map<anydata>";
                }
            }
        }
        return result;
    }

    resource function get case19(http:Request req) returns map<string[]> {
        return req.getQueryParams();
    }
}

service /header on resourceParamBindingListener {

    resource function get case1(@http:Header "value1"|"value2" header) returns string {
        return header;
    }

    resource function get case2(@http:Header (1.234d|12.34d|123.4d)? header) returns decimal {
        return header ?: 0.0d;
    }

    resource function get case3(@http:Header ValueNilable header) returns string {
        return header ?: "default";
    }

    resource function get case4(@http:Header EnumValue header) returns string {
        return header;
    }

    resource function get case5(@http:Header EnumCombined header) returns string {
        if header is EnumValue {
            return "EnumValue: " + header;
        }
        return header;
    }

    resource function get case6(@http:Header (1|2|3)[] header) returns int[] {
        return header;
    }

    resource function get case7(@http:Header Value[]? header) returns string[] {
        return header ?: ["default"];
    }

    resource function get case8(@http:Header UnionFiniteType[] header) returns string[] {
        string[] result = [];
        foreach var item in header {
            if item is EnumValue {
                result.push("EnumValue: " + item);
            } else {
                result.push("Value: " + item);
            }
        }
        return result;
    }

    resource function get case9(@http:Header HeaderRecord? header) returns map<json>|string {
        return header ?: "default";
    }

    resource function get case10(@http:Header int:Signed32 header) returns int:Signed32 {
        return header;
    }

    resource function get case11(@http:Header int:Unsigned32 header) returns int:Unsigned32 {
        return header;
    }

    resource function get case12(@http:Header int:Signed8[] header) returns int:Signed8[] {
        return header;
    }

    resource function get case13(@http:Header string:Char header) returns string:Char {
        return header;
    }

    resource function get case14(@http:Header StringCharacter header1, @http:Header SmallInt header2) returns [StringCharacter, SmallInt] {
        return [header1, header2];
    }

    resource function get case15(@http:Header HeaderRecordWithType header) returns map<json>|string {
        return header;
    }
}
