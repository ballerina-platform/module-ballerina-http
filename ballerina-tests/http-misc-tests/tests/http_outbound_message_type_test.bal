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
import ballerina/http_test_common as common;

listener http:Listener outRequestTypeTestEP = new (outRequestTypeTestPort, httpVersion = http:HTTP_1_1);

final http:Client outRequestClient = check new ("http://localhost:" + outRequestTypeTestPort.toString(), httpVersion = http:HTTP_1_1);

type CustomerTable table<map<json>>;

@test:Config {}
public function testSendingNil() returns error? {
    http:Response resp = check outRequestClient->post("/mytest/nil", ());
    test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
    test:assertEquals(check resp.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
    common:assertTextPayload(resp.getTextPayload(), "0");
}

@test:Config {}
public function testSendingInt() returns error? {
    int val = 139;
    http:Response resp = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), 139);
}

@test:Config {}
public function testSendingFloat() returns error? {
    float val = 1.39;
    http:Response resp = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayloadtoJsonString(resp.getJsonPayload(), 1.39);
}

@test:Config {}
public function testSendingDecimal() returns error? {
    decimal val = 1.3;
    http:Response resp = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayloadtoJsonString(resp.getJsonPayload(), 1.3);
}

@test:Config {}
public function testSendingBoolean() returns error? {
    boolean val = true;
    http:Response resp = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), true);
}

@test:Config {}
public function testSendingMap() returns error? {
    map<int> val = {sam: 50, jhon: 60};
    http:Response resp = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), {sam: 50, jhon: 60});
}

@test:Config {}
public function testSendingMapArray() returns error? {
    map<json> jj = {sam: {hello: "world"}, jhon: {no: 56}};
    map<json>[] val = [jj, jj];
    http:Response resp = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), val);
}

@test:Config {}
public function testSendingTable() returns error? {
    CustomerTable customerTab = table [
            {id: 13, fname: "Dan", lname: "Bing"},
            {id: 23, fname: "Hay", lname: "Kelsey"}
        ];
    http:Response resp = check outRequestClient->post("/mytest/json", customerTab);
    test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), [
        {id: 13, fname: "Dan", lname: "Bing"},
        {id: 23, fname: "Hay", lname: "Kelsey"}
    ]);
}

@test:Config {}
public function testSendingTableArray() returns error? {
    CustomerTable customerTab = table [
        {id: 13, fname: "Dan", lname: "Bing"}
    ];
    CustomerTable[] customerTabArr = [customerTab, customerTab];
    http:Response resp = check outRequestClient->post("/mytest/json", customerTabArr);
    test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), [
        [{id: 13, fname: "Dan", lname: "Bing"}],
        [{id: 13, fname: "Dan", lname: "Bing"}]
    ]);
}

@test:Config {}
public function testSendingJsonCompatibleOpenRecord() returns error? {
    // To make json compatible;
    // 1. Make exclusive record
    // 2. Have json rest param in open records
    // 3. Call .toJson() and pass as a json
    record {|string name;|} customer1 = {name: "ballerina1"};
    json payload = check outRequestClient->post("/mytest/json", customer1);
    common:assertJsonPayload(payload, {"name": "ballerina1"});

    record {|string name; json...;|} customer2 = {name: "ballerina2"};
    payload = check outRequestClient->post("/mytest/json", customer2);
    common:assertJsonPayload(payload, {"name": "ballerina2"});

    record {string name;} customer3 = {name: "ballerina3"};
    payload = check outRequestClient->post("/mytest/json", customer3.toJson());
    common:assertJsonPayload(payload, {"name": "ballerina3"});
}

type OpenCustomer record {
    string name;
    xml aa;
    byte[] bb;
};

@test:Config {}
public function testSendingOpenRecord() returns error? {
    OpenCustomer customer = {name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    json payload = check outRequestClient->post("/mytest/json", customer.toJson());
    common:assertJsonPayload(payload, {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]});
}

@test:Config {}
public function testSendingOpenRecordArray() returns error? {
    OpenCustomer customer = {name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    OpenCustomer[] custArr = [customer, customer];
    json payload = check outRequestClient->post("/mytest/json", custArr.toJson());
    common:assertJsonPayload(payload, [
        {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]},
        {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]}
    ]);
}

@test:Config {}
public function testSendingOpenRecordMap() returns error? {
    OpenCustomer customer = {name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    map<OpenCustomer> custMap = {a: customer, b: customer};
    json payload = check outRequestClient->post("/mytest/json", custMap.toJson());
    common:assertJsonPayload(payload,
        {
        a: {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]},
        b: {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]}
    });
}

@test:Config {}
public function testSendingOpenRecordTable() returns error? {
    table<OpenCustomer> customerTab = table [
            {name: "ballerina1", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()},
            {name: "ballerina2", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()}
        ];
    json payload = check outRequestClient->post("/mytest/json", customerTab.toJson());
    common:assertJsonPayload(payload,
        [
        {name: "ballerina1", aa: "<book>Hello World</book>", bb: [97, 98, 99]},
        {name: "ballerina2", aa: "<book>Hello World</book>", bb: [97, 98, 99]}
    ]);
}

type ClosedCustomer record {|
    string name;
    xml aa;
    byte[] bb;
|};

@test:Config {}
public function testSendingClosedRecord() returns error? {
    ClosedCustomer customer = {name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    json payload = check outRequestClient->post("/mytest/json", customer.toJson());
    common:assertJsonPayload(payload, {name: "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]});
}

@test:Config {}
public function testSendingClosedRecordArray() returns error? {
    ClosedCustomer customer = {name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    ClosedCustomer[] custArr = [customer, customer];
    json payload = check outRequestClient->post("/mytest/json", custArr.toJson());
    common:assertJsonPayload(payload, [
        {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]},
        {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]}
    ]);
}

@test:Config {}
public function testSendingClosedRecordMap() returns error? {
    ClosedCustomer customer = {name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
    map<ClosedCustomer> custMap = {a: customer, b: customer};
    json payload = check outRequestClient->post("/mytest/json", custMap.toJson());
    common:assertJsonPayload(payload,
        {
        a: {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]},
        b: {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]}
    });
}

@test:Config {}
public function testSendingClosedRecordTable() returns error? {
    table<ClosedCustomer> customerTab = table [
            {name: "ballerina1", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()},
            {name: "ballerina2", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()}
        ];
    json payload = check outRequestClient->post("/mytest/json", customerTab.toJson());
    common:assertJsonPayload(payload,
        [
        {name: "ballerina1", aa: "<book>Hello World</book>", bb: [97, 98, 99]},
        {name: "ballerina2", aa: "<book>Hello World</book>", bb: [97, 98, 99]}
    ]);
}

@test:Config {}
public function testRequestAnydataNegative() returns error? {
    json[] x = [];
    x.push(x);
    json|error payload = outRequestClient->post("/mytest/json", x);
    if payload is error {
        if payload is http:InitializingOutboundRequestError {
            test:assertEquals(payload.message(), "json conversion error: {ballerina/lang.value}CyclicValueReferenceError");
            return;
        }
    }
    test:assertFail(msg = "Found unexpected output");
}

@test:Config {}
public function testSendingAnydata() returns error? {
    anydata val = 139;
    http:Response resp = check outRequestClient->post("/mytest/json", val);
    test:assertEquals(resp.statusCode, 201, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), 139);
}

service /mytest on outRequestTypeTestEP {

    resource function post 'json(@http:Payload {} json data) returns json {
        return data;
    }

    resource function post nil(http:Request req) returns string|error {
        return req.getHeader("Content-Length");
    }

    resource function get nil(http:Caller caller) returns error? {
        check caller->respond(());
    }

    resource function get 'int(http:Caller caller) returns error? {
        int val = 1395767;
        check caller->respond(val);
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
        table<map<json>> val2 = table [{name: 23, lname: {a: "go"}}];
        table<map<json>>[] val = [val1, val2];
        check caller->respond(val);
    }

    resource function get openRecord(http:Caller caller) returns error? {
        OpenCustomer customer = {name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
        check caller->respond(customer.toJson());
        return;
    }

    resource function get openRecordArr(http:Caller caller) returns error? {
        OpenCustomer customer = {name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
        OpenCustomer[] custArr = [customer, customer];
        check caller->respond(custArr.toJson());
        return;
    }

    resource function get closedRecord(http:Caller caller) returns error? {
        ClosedCustomer customer = {name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
        check caller->respond(customer.toJson());
        return;
    }

    resource function get closedRecordArr(http:Caller caller) returns error? {
        ClosedCustomer customer = {name: "ballerina", aa: xml `<book>Hello World</book>`, bb: "abc".toBytes()};
        ClosedCustomer[] custArr = [customer, customer];
        check caller->respond(custArr.toJson());
        return;
    }

    resource function get anydataNegative(http:Caller caller) returns error? {
        json[] x = [];
        x.push(x);
        check caller->respond(x);
        return;
    }

    resource function get anydataPositive(http:Caller caller) returns error? {
        anydata val = 1395767;
        check caller->respond(val);
    }
}

@test:Config {}
public function testGettingNil() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/nil");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_LENGTH), "0");
}

@test:Config {}
public function testGettingInt() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/int");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), 1395767);
}

@test:Config {}
public function testGettingFloat() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/float");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayloadtoJsonString(resp.getJsonPayload(), 13.95767);
}

@test:Config {}
public function testGettingDecimal() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/decimal");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayloadtoJsonString(resp.getJsonPayload(), 6.7);
}

@test:Config {}
public function testGettingBoolean() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/bool");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), true);
}

@test:Config {}
public function testGettingMap() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/map");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), {line1: "a", line2: "b"});
}

@test:Config {}
public function testGettingMapArray() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/mapArr");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), [{line1: "a", line2: "b"}, {line3: "c", line4: "d"}]);
}

@test:Config {}
public function testGettingTable() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/table");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), [
        {fname: "John", lname: "Wick"},
        {fname: "Robert", lname: "Downey"}
    ]);
}

@test:Config {}
public function testGettingTableArray() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/tableArr");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), [
        [{fname: "John", lname: "Wick"}],
        [{name: 23, lname: {a: "go"}}]
    ]);
}

@test:Config {}
public function testGettingOpenRecord() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/openRecord");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]});
}

@test:Config {}
public function testGettingOpenRecordArray() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/openRecordArr");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), [
        {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]},
        {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]}
    ]);
}

@test:Config {}
public function testGettingClosedRecord() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/closedRecord");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]});
}

@test:Config {}
public function testGettingClosedRecordArray() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/closedRecordArr");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), [
        {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]},
        {"name": "ballerina", "aa": "<book>Hello World</book>", "bb": [97, 98, 99]}
    ]);
}

@test:Config {}
public function testResponseAnydataNegative() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/anydataNegative");
    test:assertEquals(resp.statusCode, 500, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    check common:assertJsonErrorPayload(check resp.getJsonPayload(), "json conversion error: {ballerina/lang.value}CyclicValueReferenceError",
        "Internal Server Error", 500, "/mytest/anydataNegative", "GET");
}

@test:Config {}
public function testResponseAnydataPositive() returns error? {
    http:Response resp = check outRequestClient->get("/mytest/int");
    test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
    common:assertHeaderValue(check resp.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
    common:assertJsonPayload(resp.getJsonPayload(), 1395767);
}
