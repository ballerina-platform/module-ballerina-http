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

@test:Config {}
public function testSendingNil() {
    var resp = outRequestClient->post("/mytest/nil", ());
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "0");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingInt() {
    int val = 139; 
    var resp = outRequestClient->post("/mytest/json", val);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), 139);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingFloat() {
    float val = 1.39;
    var resp = outRequestClient->post("/mytest/json", val);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(resp.getJsonPayload(), 1.39);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingDecimal() {
    decimal val = 1.3;
    var resp = outRequestClient->post("/mytest/json", val);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(resp.getJsonPayload(), 1.3);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingBoolean() {
    boolean val = true;
    var resp = outRequestClient->post("/mytest/json", val);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), true);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingMap() {
    map<int> val = {sam: 50, jhon: 60};
    var resp = outRequestClient->post("/mytest/json", val);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {sam: 50, jhon: 60});
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingMapArray() {
    map<json> jj = {sam: {hello:"world"}, jhon: {no:56}};
    map<json>[] val = [jj,jj];
    var resp = outRequestClient->post("/mytest/json", val);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), val);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingTable() {
    CustomerTable customerTab = table [
        {id: 13 , fname: "Dan", lname: "Bing"},
        {id: 23 , fname: "Hay" , lname: "Kelsey"}
    ];
    var resp = outRequestClient->post("/mytest/json", customerTab);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [{id: 13 , fname: "Dan", lname: "Bing"}, 
            {id: 23 , fname: "Hay" , lname: "Kelsey"}]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testSendingTableArray() {
    CustomerTable customerTab = table [
        {id: 13 , fname: "Dan", lname: "Bing"}
    ];
    CustomerTable[] customerTabArr = [customerTab, customerTab];
    var resp = outRequestClient->post("/mytest/json", customerTabArr);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [[{id: 13 , fname: "Dan", lname: "Bing"}], 
            [{id: 13 , fname: "Dan", lname: "Bing"}]]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

service /mytest on outRequestTypeTestEP {

    resource function post 'json(@http:Payload {} json data) returns json {
        return data;
    }

    resource function post nil(http:Caller caller, http:Request req) returns string|error {
        return req.getHeader("Content-Length");
    }

    resource function get nil(http:Caller caller) {
        checkpanic caller->respond(());
    }

    resource function get 'int(http:Caller caller) {
        int val = 1395767; 
        checkpanic caller->respond(val);
    }

    resource function get 'float(http:Caller caller) {
        float val = 13.95767; 
        checkpanic caller->respond(val);
    }

    resource function get 'decimal(http:Caller caller) {
        decimal val = 6.7; 
        checkpanic caller->respond(val);
    }

    resource function get bool(http:Caller caller) {
        boolean val = true;
        checkpanic caller->respond(val);
    }

    resource function get 'map(http:Caller caller) {
        map<string> val = {line1: "a", line2: "b"};
        checkpanic caller->respond(val);    
    }

    resource function get mapArr(http:Caller caller) {
        map<string>[] val = [{line1: "a", line2: "b"}, {line3: "c", line4: "d"}];
        checkpanic caller->respond(val);    
    }

    resource function get 'table(http:Caller caller) {
        table<map<string>> val = table [
            {fname: "John", lname: "Wick"},
            {fname: "Robert", lname: "Downey"}
        ];
        checkpanic caller->respond(val);    
    }

    resource function get tableArr(http:Caller caller) {
        table<map<string>> val1 = table [{fname: "John", lname: "Wick"}];
        table<map<json>> val2 = table [{name: 23, lname: {a:"go"}}];
        table<map<json>>[] val = [val1, val2];
        checkpanic caller->respond(val);    
    }
}

@test:Config {}
public function testGettingNil() {
    var resp = outRequestClient->get("/mytest/nil");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_LENGTH), "0");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingInt() {
    var resp = outRequestClient->get("/mytest/int");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), 1395767);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingFloat() {
    var resp = outRequestClient->get("/mytest/float");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(resp.getJsonPayload(), 13.95767);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingDecimal() {
    var resp = outRequestClient->get("/mytest/decimal");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayloadtoJsonString(resp.getJsonPayload(), 6.7);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingBoolean() {
    var resp = outRequestClient->get("/mytest/bool");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), true);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingMap() {
    var resp = outRequestClient->get("/mytest/map");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {line1: "a", line2: "b"});
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingMapArray() {
    var resp = outRequestClient->get("/mytest/mapArr");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [{line1: "a", line2: "b"}, {line3: "c", line4: "d"}]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingTable() {
    var resp = outRequestClient->get("/mytest/table");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [{fname: "John", lname: "Wick"},
            {fname: "Robert", lname: "Downey"}]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGettingTableArray() {
    var resp = outRequestClient->get("/mytest/tableArr");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), [[{fname: "John", lname: "Wick"}], 
            [{name: 23, lname: {a:"go"}}]]);
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}
