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

type UnionType EnumValue|Value;

service /header/positive on listenerEP {

    resource function get case1(@http:Header "value1"|"value2" header) {}

    resource function get case2(@http:Header (1.234d|12.34d|123.4d)? header) {}

    resource function get case3(@http:Header Value header) {}

    resource function get case4(@http:Header Value? header) {}

    resource function get case5(@http:Header ValueNilable header) {}

    resource function get case6(@http:Header EnumValue header) {}

    resource function get case7(@http:Header EnumValue? header) {}

    resource function get case8(@http:Header EnumCombined header) {}

    resource function get case9(@http:Header EnumValue|"VALUE4"|"VALUE5"? header) {}

    resource function get case10(@http:Header EnumValue|Value? header) {}

    resource function get case11(@http:Header (1|2|3)[] header) {}

    resource function get case12(@http:Header Value[]? header) {}

    resource function get case13(@http:Header EnumValue[] header) {}

    resource function get case14(@http:Header (EnumValue|"VALUE4")[]? header) {}

    resource function get case15(@http:Header UnionType[] header) {}

    resource function get case16(@http:Header (EnumValue|Value)[]? header) {}

    resource function get case17(@http:Header HeaderRecord? header) {}
}

type MixedValue "value2"|4.56|true;

type MixedValueNilable MixedValue?;

type HeaderInvalidRecord record {|
    "value1"|"value2"|4 header1;
    1.2|2.4|3? header2;
    MixedValue header3;
    MixedValue? header4;
    MixedValueNilable header5;
    EnumValue|4 header6;
    EnumValue|true? header7;
    EnumValue|Value? header8;
    (1|2|3|3.2)[] header9;
    MixedValue[]? header10;
    UnionType[] header11;
    (EnumValue|true)[]? header12;
    (EnumValue|Value)[]? header13;
|};

service /header/negative on listenerEP {
    resource function get case1(@http:Header "value1"|"value2"|4 header) {}

    resource function get case2(@http:Header 1.2|2.4|3? header) {}

    resource function get case3(@http:Header MixedValue header) {}

    resource function get case4(@http:Header MixedValue? header) {}

    resource function get case5(@http:Header MixedValueNilable header) {}

    resource function get case6(@http:Header EnumValue|4 header) {}

    resource function get case7(@http:Header EnumValue|true? header) {}

    resource function get case11(@http:Header (1|2|3|3.2)[] header) {}

    resource function get case12(@http:Header MixedValue[]? header) {}

    resource function get case15(@http:Header (EnumValue|true)[]? header) {}

    resource function get case17(@http:Header HeaderRecord|record {|string header;|} header) {}

    resource function get case18(@http:Header HeaderInvalidRecord header) {}
}
