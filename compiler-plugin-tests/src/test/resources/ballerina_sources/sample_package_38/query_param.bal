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

type QueryRecord record {|
    EnumValue enumValue;
    "value1"|"value2" value;
|};

type QueryRecordCombined QueryRecord|map<json>;

listener http:Listener listenerEP = new (9090);

service /query/positive on listenerEP {

    resource function get case1("value1"|"value2" query) {}

    resource function get case2((1.2|2.4|3.6)? query) {}

    resource function get case3(Value query) {}

    resource function get case4(Value? query = "value2") {}

    resource function get case5(ValueNilable query) {}

    resource function get case6(EnumValue query) {}

    resource function get case7(EnumValue? query = VALUE2) {}

    resource function get case8(EnumCombined query) {}

    resource function get case9((EnumValue|"VALUE4"|"VALUE5")? query) {}

    resource function get case10(EnumValue|Value? query) {}

    resource function get case11((1|2|3)[] query) {}

    resource function get case12(Value[]? query) {}

    resource function get case13(EnumValue[] query) {}

    resource function get case14(UnionType[] query) {}

    resource function get case15((EnumValue|"VALUE4")[]? query) {}

    resource function get case16((EnumValue|Value)[]? query) {}

    resource function get case17(QueryRecord[]? query) {}

    resource function get case18(QueryRecord|map<json> query) {}

    resource function get case19(QueryRecordCombined? query) {}

    resource function get case20((QueryRecord|map<json>)[] query) {}

}

type QueryRecordCombinedInvalid QueryRecord|map<object {}>;

service /query/negative on listenerEP {

    resource function get case1("value1"|"value2"|4 query) {}

    resource function get case2(1.2|2.4|3? query) {}

    resource function get case3(MixedValue query) {}

    resource function get case4(MixedValue? query = "value2") {}

    resource function get case5(MixedValueNilable query) {}

    resource function get case6(EnumValue|4 query) {}

    resource function get case7(EnumValue|true? query = VALUE2) {}

    resource function get case11((1|2|3|3.2)[] query) {}

    resource function get case12(MixedValue[]? query) {}

    resource function get case14((EnumValue|true)[]? query) {}

    resource function get case15(QueryRecordCombinedInvalid? query) {}

    resource function get case16((QueryRecord|map<any>)[]? query) {}
}
