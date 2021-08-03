// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/test;

listener http:Listener outRequestTypeTestEP = new(outRequestTypeTest);

http:Client outRequestClient = check new("http://localhost:" + outRequestTypeTest.toString());

type CustomerTable table<map<json>>;
type CustomerIntTable table<map<int>>;

@test:Config {}
public function testSendingNil() returns error? {
    http:Response resp = check outRequestClient->post("/mytest/nil", ());
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    test:assertEquals(check resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
    assertTextPayload(resp.getTextPayload(), "0");
}

@test:Config {}
public function testSendingInt() returns error? {
    int val = 139;
    http:Response resp = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
    assertJsonPayload(resp.getJsonPayload(), 139);
}

@test:Config {}
public function testSendingIntArr() returns error? {
    int[] val = [139,5345];
    json payload = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(payload, [139, 5345], msg = "Found unexpected output");
}

@test:Config {}
public function testSendingIntMap() returns error? {
    map<int> val = {a: 139, b: 5345};
    json payload = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(payload, {a: 139,b: 5345}, msg = "Found unexpected output");
}

@test:Config {}
public function testSendingIntMapTable() returns error? {
    table<map<int>> customerTab = table [
        {id: 13 , fname: 1, lname: 2},
        {id: 23 , fname: 3 , lname: 4}
    ];
    json payload = check outRequestClient->post("/mytest/json", customerTab);
    test:assertEquals(payload, [{id: 13 , fname: 1, lname: 2}, {id: 23 , fname: 3 , lname: 4}],
        msg = "Found unexpected output");
}

@test:Config {}
public function testSendingFloat() returns error? {
    float val = 1.39;
    http:Response resp = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
    assertJsonPayloadtoJsonString(resp.getJsonPayload(), 1.39);
}

@test:Config {}
public function testSendingFloatArr() returns error? {
    float[] val = [13.9,53.45];
    json payload = check outRequestClient->post("/mytest/json", val);
    assertJsonPayloadtoJsonString(payload, [13.9,53.45]);
}

@test:Config {}
public function testSendingFloatMap() returns error? {
    map<float> val = {a: 13.9, b: 53.45};
    json payload = check outRequestClient->post("/mytest/json", val);
    assertJsonPayloadtoJsonString(payload, {a: 13.9,b: 53.45});
}

@test:Config {}
public function testSendingFloatMapTable() returns error? {
    table<map<float>> customerTab = table [
        {id: 13 , fname: 1.0, lname: 2.23},
        {id: 23 , fname: 34.234 , lname: 4.42314}
    ];
    json payload = check outRequestClient->post("/mytest/json", customerTab);
    assertJsonPayloadtoJsonString(payload, [{id: 13.0 , fname: 1.0, lname: 2.23},
        {id: 23.0 , fname: 34.234 , lname: 4.42314}]);
}

@test:Config {}
public function testSendingDecimal() returns error? {
    decimal val = 1.3;
    http:Response resp = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
    assertJsonPayloadtoJsonString(resp.getJsonPayload(), 1.3);
}

@test:Config {}
public function testSendingDecimalArr() returns error? {
    decimal[] val = [13.9,53.45];
    json payload = check outRequestClient->post("/mytest/json", val);
    assertJsonPayloadtoJsonString(payload, [13.9,53.45]);
}

@test:Config {}
public function testSendingDecimalMap() returns error? {
    map<decimal> val = {a: 13.9, b: 53.45};
    json payload = check outRequestClient->post("/mytest/json", val);
    assertJsonPayloadtoJsonString(payload, {a: 13.9,b: 53.45});
}

@test:Config {}
public function testSendingDecimalMapTable() returns error? {
    table<map<decimal>> customerTab = table [
        {id: 13 , fname: 1.0, lname: 2.23},
        {id: 23 , fname: 34.234 , lname: 4.42314}
    ];
    json payload = check outRequestClient->post("/mytest/json", customerTab);
    assertJsonPayloadtoJsonString(payload, [{id: 13 , fname: 1.0, lname: 2.23},
        {id: 23 , fname: 34.234 , lname: 4.42314}]);
}

@test:Config {}
public function testSendingBoolean() returns error? {
    boolean val = true;
    http:Response resp = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
    assertJsonPayload(resp.getJsonPayload(), true);
}

@test:Config {}
public function testSendingBooleanArr() returns error? {
    boolean[] val = [true, false];
    json payload = check outRequestClient->post("/mytest/json", val);
    assertJsonPayloadtoJsonString(payload, [true,false]);
}

@test:Config {}
public function testSendingBooleanMap() returns error? {
    map<boolean> val = {a: true, b: false};
    json payload = check outRequestClient->post("/mytest/json", val);
    assertJsonPayloadtoJsonString(payload, {a: true,b: false});
}

@test:Config {}
public function testSendingBooleanMapTable() returns error? {
    table<map<boolean>> customerTab = table [
        {id: true, fname: false, lname: true},
        {id: false, fname: true, lname: false}
    ];
    json payload = check outRequestClient->post("/mytest/json", customerTab);
    assertJsonPayloadtoJsonString(payload, [{id: true, fname: false, lname: true},
        {id: false, fname: true, lname: false}]);
}

@test:Config {}
public function testSendingString() returns error? {
    string val = "ballerina";
    http:Response resp = check outRequestClient->post("/mytest/string", val);
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    assertHeaderValue(check resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
    test:assertEquals(check resp.getTextPayload(), "ballerina");
}

@test:Config {}
public function testSendingStringArr() returns error? {
    string[] val = ["ballerina1","ballerina2"];
    json payload = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(payload, ["ballerina1", "ballerina2"], msg = "Found unexpected output");
}

@test:Config {}
public function testSendingStringMap() returns error? {
    map<string> val = {a: "ballerina1", b: "ballerina2"};
    json payload = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(payload, {a: "ballerina1",b: "ballerina2"}, msg = "Found unexpected output");
}

@test:Config {}
public function testSendingStringMapTable() returns error? {
    table<map<string>> customerTab = table [
        {id: "ballerina1" , fname: "ballerina2", lname: "ballerina3"},
        {id: "ballerina3" , fname: "ballerina2" , lname: "ballerina1"}
    ];
    json payload = check outRequestClient->post("/mytest/json", customerTab);
    test:assertEquals(payload, [{id: "ballerina1" , fname: "ballerina2", lname: "ballerina3"},
        {id: "ballerina3" , fname: "ballerina2" , lname: "ballerina1"}],
        msg = "Found unexpected output");
}

@test:Config {}
public function testSendingXml() returns error? {
    xml val = xml `<name>Ballerina</name>`;
    http:Response resp = check outRequestClient->post("/mytest/xml", val);
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_XML);
    test:assertEquals(check resp.getXmlPayload(), val);
}

@test:Config {}
public function testSendingXmlArr() returns error? {
    xml val = xml `<name>Ballerina</name>`;
    xml[] arr = [val, val];
    json payload = check outRequestClient->post("/mytest/json", arr);
    assertJsonPayloadtoJsonString(payload, ["<name>Ballerina</name>","<name>Ballerina</name>"]);
}

@test:Config {}
public function testSendingXmlMap() returns error? {
    xml val = xml `<name>Ballerina</name>`;
    map<xml> xmlMap = {a: val, b: val};
    json payload = check outRequestClient->post("/mytest/json", xmlMap);
    assertJsonPayloadtoJsonString(payload, {a: "<name>Ballerina</name>",b: "<name>Ballerina</name>"});
}

@test:Config {}
public function testSendingXmlMapTable() returns error? {
    xml val1 = xml `<name>Ballerina1</name>`;
    xml val2 = xml `<name>Ballerina2</name>`;
    xml val3 = xml `<name>Ballerina3</name>`;
    table<map<xml>> customerTab = table [
        {id: val1, fname: val2, lname: val3},
        {id: val3, fname: val1, lname: val2}
    ];
    json payload = check outRequestClient->post("/mytest/json", customerTab);
    assertJsonPayloadtoJsonString(payload,
        [{id: "<name>Ballerina1</name>", fname: "<name>Ballerina2</name>", lname: "<name>Ballerina3</name>"},
        {id: "<name>Ballerina3</name>", fname: "<name>Ballerina1</name>", lname: "<name>Ballerina2</name>"}]);
}

@test:Config {}
public function testSendingMap() returns error? {
    map<json> val = {sam: 50, john: {no:56}};
    http:Response|error resp = outRequestClient->post("/mytest/json", val);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {sam: 50, john: {no:56}});
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingMapArray() returns error? {
    map<json> jj = {sam: {hello:"world"}, john: {no:56}};
    map<json>[] val = [jj,jj];
    http:Response|error resp = outRequestClient->post("/mytest/json", val);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), val);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingTable() returns error? {
    CustomerTable customerTab = table [
        {id: 13 , fname: "Dan", lname: "Bing"},
        {id: 23 , fname: "Hay" , lname: "Kelsey"}
    ];
    http:Response|error resp = outRequestClient->post("/mytest/json", customerTab);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [{id: 13 , fname: "Dan", lname: "Bing"},
            {id: 23 , fname: "Hay" , lname: "Kelsey"}]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingTableArray() returns error? {
    CustomerTable customerTab = table [
        {id: 13 , fname: "Dan", lname: "Bing"}
    ];
    CustomerTable[] customerTabArr = [customerTab, customerTab];
    http:Response|error resp = outRequestClient->post("/mytest/json", customerTabArr);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [[{id: 13 , fname: "Dan", lname: "Bing"}],
            [{id: 13 , fname: "Dan", lname: "Bing"}]]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingTableMap() returns error? {
    CustomerTable customerTab = table [
        {id: 13 , fname: "Dan", lname: "Bing"}
    ];
    map<CustomerTable> customerTabMap = {a: customerTab, b: customerTab};
    json payload = check outRequestClient->post("/mytest/json", customerTabMap);
    assertJsonPayload(payload, {a : [{id: 13 , fname: "Dan", lname: "Bing"}],
        b: [{id: 13 , fname: "Dan", lname: "Bing"}]});
}

type OpenCustomer record {
    string name;
    xml aa;
    byte[] bb;
};

@test:Config {}
public function testSendingOpenRecord() returns error? {
    OpenCustomer customer = { name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    json payload = check outRequestClient->post("/mytest/json", customer);
    assertJsonPayload(payload, {"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]});
}

@test:Config {}
public function testSendingOpenRecordArray() returns error? {
    OpenCustomer customer = { name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    OpenCustomer[] custArr = [customer, customer];
    json payload = check outRequestClient->post("/mytest/json", custArr);
    assertJsonPayload(payload, [{"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]},
        {"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]}]);
}

@test:Config {}
public function testSendingOpenRecordMap() returns error? {
    OpenCustomer customer = { name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    map<OpenCustomer> custMap = {a:customer, b:customer};
    json payload = check outRequestClient->post("/mytest/json", custMap);
    assertJsonPayload(payload,
        {a:{"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]},
        b:{"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]}});
}

@test:Config {}
public function testSendingOpenRecordTable() returns error? {
    table<OpenCustomer> customerTab = table [
        { name: "ballerina1", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()},
        { name: "ballerina2", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()}
    ];
    json payload = check outRequestClient->post("/mytest/json", customerTab);
    assertJsonPayload(payload,
        [{ name: "ballerina1", aa: "<book>Hello World</book>", bb: [97,98,99]},
        { name: "ballerina2", aa: "<book>Hello World</book>", bb: [97,98,99]}]);
}

type ClosedCustomer record {|
    string name;
    xml aa;
    byte[] bb;
|};

@test:Config {}
public function testSendingClosedRecord() returns error? {
    ClosedCustomer customer = { name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    json payload = check outRequestClient->post("/mytest/json", customer);
    assertJsonPayload(payload, {name: "ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]});
}

@test:Config {}
public function testSendingClosedRecordArray() returns error? {
    ClosedCustomer customer = { name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    ClosedCustomer[] custArr = [customer, customer];
    json payload = check outRequestClient->post("/mytest/json", custArr);
    assertJsonPayload(payload, [{"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]},
        {"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]}]);
}

@test:Config {}
public function testSendingClosedRecordMap() returns error? {
    ClosedCustomer customer = { name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    map<ClosedCustomer> custMap = {a:customer, b:customer};
    json payload = check outRequestClient->post("/mytest/json", custMap);
    assertJsonPayload(payload,
        {a:{"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]},
        b:{"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]}});
}

@test:Config {}
public function testSendingClosedRecordTable() returns error? {
    table<ClosedCustomer> customerTab = table [
        { name: "ballerina1", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()},
        { name: "ballerina2", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()}
    ];
    json payload = check outRequestClient->post("/mytest/json", customerTab);
    assertJsonPayload(payload,
        [{ name: "ballerina1", aa: "<book>Hello World</book>", bb: [97,98,99]},
        { name: "ballerina2", aa: "<book>Hello World</book>", bb: [97,98,99]}]);
}

@test:Config {}
public function testRequestAnydataNegative() returns error? {
    anydata[] x = [];
    x.push(x);
    json|error payload = outRequestClient->post("/mytest/json", x);
    if payload is error {
        if payload is http:InitializingOutboundRequestError {
            //Change error after https://github.com/ballerina-platform/ballerina-lang/issues/32001 is fixed
            test:assertEquals(payload.message(), "json conversion error: java.lang.ClassCastException");
            return;
        }
    }
    test:assertFail(msg = "Found unexpected output");
}

service /mytest on outRequestTypeTestEP {

    resource function post 'json(@http:Payload json data) returns json {
        return data;
    }

    resource function post nil(http:Caller caller, http:Request req) returns string|error {
        return req.getHeader("Content-Length");
    }

    resource function get nil(http:Caller caller) returns error? {
        check caller->respond(());
    }

    resource function get 'int(http:Caller caller) returns error? {
        int val = 1395767;
        check caller->respond(val);
    }

    resource function get 'intArr(http:Caller caller) returns error? {
        int[] val = [139,5345];
        check caller->respond(val);
    }

    resource function get 'intMap(http:Caller caller) returns error? {
        map<int> val = {a: 139, b: 5345};
        check caller->respond(val);
    }

    resource function get 'intTable(http:Caller caller) returns error? {
        table<map<int>> customerTab = table [
                {id: 13 , fname: 1, lname: 2},
                {id: 23 , fname: 3 , lname: 4}
            ];
        check caller->respond(customerTab);
    }

    resource function get 'float(http:Caller caller) returns error? {
        float val = 13.95767;
        check caller->respond(val);
    }

    resource function get 'decimal(http:Caller caller) returns error? {
        decimal val = 6.7;
        check caller->respond(val);
    }

    resource function get bool(http:Caller caller) returns error? {
        boolean val = true;
        check caller->respond(val);
    }

    resource function post 'string(@http:Payload string data) returns string {
        return data;
    }

    resource function post 'xml(@http:Payload xml data) returns xml {
        return data;
    }

    resource function get 'map(http:Caller caller) returns error? {
        map<string> val = {line1: "a", line2: "b"};
        check caller->respond(val);
    }

    resource function get mapArr(http:Caller caller) returns error? {
        map<string>[] val = [{line1: "a", line2: "b"}, {line3: "c", line4: "d"}];
        check caller->respond(val);
    }

    resource function get 'table(http:Caller caller) returns error? {
        table<map<string>> val = table [
            {fname: "John", lname: "Wick"},
            {fname: "Robert", lname: "Downey"}
        ];
        check caller->respond(val);
    }

    resource function get tableArr(http:Caller caller) returns error? {
        table<map<string>> val1 = table [{fname: "John", lname: "Wick"}];
        table<map<json>> val2 = table [{name: 23, lname: {a:"go"}}];
        table<map<json>>[] val = [val1, val2];
        check caller->respond(val);
    }

    resource function get tableMap(http:Caller caller) returns error? {
        CustomerTable customerTab = table [
                {id: 13 , fname: "Dan", lname: "Bing"}
            ];
        map<CustomerTable> customerTabMap = {a: customerTab, b: customerTab};
        check caller->respond(customerTabMap);
    }

    resource function get openRecord(http:Caller caller) returns error? {
        OpenCustomer customer = { name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
        check caller->respond(customer);
    }

    resource function get openRecordArr(http:Caller caller) returns error? {
        OpenCustomer customer = { name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
        OpenCustomer[] custArr = [customer, customer];
        check caller->respond(custArr);
    }

    resource function get closedRecord(http:Caller caller) returns error? {
        ClosedCustomer customer = { name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
        check caller->respond(customer);
    }

    resource function get closedRecordArr(http:Caller caller) returns error? {
        ClosedCustomer customer = { name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
        ClosedCustomer[] custArr = [customer, customer];
        check caller->respond(custArr);
    }

    resource function get anydataNegative(http:Caller caller) returns error? {
        anydata[] x = [];
        x.push(x);
        check caller->respond(x);
    }
}

@test:Config {}
public function testGettingNil() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/nil");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    assertHeaderValue(check resp.getHeader(CONTENT_LENGTH), "0");
}

@test:Config {}
public function testGettingInt() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/int");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
    assertJsonPayload(resp.getJsonPayload(), 1395767);
}

@test:Config {}
public function testGettingIntArr() returns error? {
    json payload = check outRequestClient->get("/mytest/intArr");
    test:assertEquals(payload, [139, 5345], msg = "Found unexpected output");
}

@test:Config {}
public function testGettingIntMap() returns error? {
    json payload = check outRequestClient->get("/mytest/intMap");
    test:assertEquals(payload, {a: 139,b: 5345}, msg = "Found unexpected output");
}

@test:Config {}
public function testGettingIntTable() returns error? {
    json payload = check outRequestClient->get("/mytest/intTable");
    test:assertEquals(payload, [{id: 13 , fname: 1, lname: 2}, {id: 23 , fname: 3 , lname: 4}],
            msg = "Found unexpected output");
}

@test:Config {}
public function testGettingFloat() returns error? {
    http:Response|error resp = outRequestClient->get("/mytest/float");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(resp.getJsonPayload(), 13.95767);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingDecimal() returns error? {
    http:Response|error resp = outRequestClient->get("/mytest/decimal");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(resp.getJsonPayload(), 6.7);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingBoolean() returns error? {
    http:Response|error resp = outRequestClient->get("/mytest/bool");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), true);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingMap() returns error? {
    http:Response|error resp = outRequestClient->get("/mytest/map");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {line1: "a", line2: "b"});
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingMapArray() returns error? {
    http:Response|error resp = outRequestClient->get("/mytest/mapArr");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [{line1: "a", line2: "b"}, {line3: "c", line4: "d"}]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingTable() returns error? {
    http:Response|error resp = outRequestClient->get("/mytest/table");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [{fname: "John", lname: "Wick"},
            {fname: "Robert", lname: "Downey"}]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingTableArray() returns error? {
    http:Response|error resp = outRequestClient->get("/mytest/tableArr");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [[{fname: "John", lname: "Wick"}],
            [{name: 23, lname: {a:"go"}}]]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingTableMap() returns error? {
    json payload = check outRequestClient->get("/mytest/tableMap");
    assertJsonPayload(payload, {a : [{id: 13 , fname: "Dan", lname: "Bing"}],
            b: [{id: 13 , fname: "Dan", lname: "Bing"}]});
}

@test:Config {}
public function testGettingOpenRecord() returns error? {
    http:Response|error resp = outRequestClient->get("/mytest/openRecord");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]});
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingOpenRecordArray() returns error? {
    http:Response|error resp = outRequestClient->get("/mytest/openRecordArr");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [{"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]},
            {"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]}]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingClosedRecord() returns error? {
    http:Response|error resp = outRequestClient->get("/mytest/closedRecord");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]});
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingClosedRecordArray() returns error? {
    http:Response|error resp = outRequestClient->get("/mytest/closedRecordArr");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(check resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [{"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]},
            {"name":"ballerina","aa":"<book>Hello World</book>","bb":[97,98,99]}]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testResponseAnydataNegative() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/anydataNegative");
    test:assertEquals(resp.statusCode, 500, msg = "Found unexpected output");
    assertHeaderValue(check resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
    //Change error after https://github.com/ballerina-platform/ballerina-lang/issues/32001 is fixed
    test:assertEquals(check resp.getTextPayload(), "json conversion error: java.lang.ClassCastException");
}
