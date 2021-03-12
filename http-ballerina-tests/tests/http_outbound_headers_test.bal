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

listener http:Listener outRequestOptionsTestEP = new(outRequestOptionsTest);

http:Client outReqHeadClient = check new("http://localhost:" + outRequestOptionsTest.toString());

// Define the failover client 
http:FailoverClient outRequestFOClient = check new({
    timeoutInMillis: 5000,
    failoverCodes: [501, 502, 503],
    intervalInMillis: 5000,
    targets: [
        { url: "http://localhost:3467/inavalidEP" },
        { url: "http://localhost:" + outRequestOptionsTest.toString() }
    ]
});

// Define the load balance client 
http:LoadBalanceClient outRequestLBClient = check new({
    targets: [
        { url: "http://localhost:" + outRequestOptionsTest.toString() }
    ],
    timeoutInMillis: 5000
});

@test:Config {}
public function testGetWithInlineHeadersMap() {
    var resp = outReqHeadClient->get("/mytest/headers", {"x-type": "hello", "y-type": ["yello", "elle"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "hello:yello");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGetWithDefinedHeadersMap() {
    map<string> headerMap = {"x-type": "Ross", "y-type": "Rachel"};
    var resp = outReqHeadClient->get("/mytest/headers", headerMap, string);
    if (resp is string) {
        assertTextPayload(resp, "Ross:Rachel");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGetWithDefinedHeadersMapOfArray() {
    map<string[]> headerMap = {"x-type": ["Geller", "Ross"], "y-type": ["Green", "Rachel"]};
    var resp = outReqHeadClient->get("/mytest/headers", headers = headerMap, targetType = string);
    if (resp is string) {
        assertTextPayload(resp, "Geller:Green");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testOptionsWithInlineHeadersMap() {
    var resp = outReqHeadClient->options("/mytest/headers", 
        headers = {"x-type": "options", "y-type": ["yello", "elle"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "options:yello");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testOptionsWithTargetType() {
    var resp = outReqHeadClient->options("/mytest/any", targetType = json);
    if (resp is json) {
        assertJsonPayload(resp, {result:"default"});
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testHeadWithInlineHeadersMap() {
    var resp = outReqHeadClient->head("/mytest/headers", headers = {"x-type": "head", "y-type": ["yello", "elle"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testPostWithInlineHeadersMap() {
    var resp = outReqHeadClient->post("/mytest/headers", "abc", headers = {"x-type": "joe", "y-type": ["yello", "go"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "joe:yello:text/plain");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testPostWithInlineHeadersMapNMediaType() {
    map<string[]> headerMap = {"x-type": ["monica"], "y-type": ["yello", "go"]};
    var resp = outReqHeadClient->post("/mytest/headers", "abc", "application/json", headerMap, string);
    if (resp is string) {
        assertTextPayload(resp, "monica:yello:application/json");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testPostWithOverrideMediaType() {
    map<string> headerMap = {"x-type": "hello", "y-type": "ross", "content-type":"application/xml"};
    var resp = outReqHeadClient->post("/mytest/headers", "abc", headers = headerMap, targetType = string);
    if (resp is string) {
        assertTextPayload(resp, "hello:ross:application/xml");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testPutWithInlineHeadersMap() {
    var resp = outReqHeadClient->put("/mytest/headers/put", "abc", 
        headers = {"x-type": "joe", "y-type": ["hello", "go"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "joe:hello:text/plain");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testPutWithInlineHeadersMapNMediaType() {
    map<string[]> headerMap = {"x-type": ["monica"], "y-type": ["chan", "go"]};
    var resp = outReqHeadClient->put("/mytest/headers/put", "abc", "application/json", headerMap, string);
    if (resp is string) {
        assertTextPayload(resp, "monica:chan:application/json");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testPutWithOverrideMediaType() {
    map<string> headerMap = {"x-type": "yello", "y-type": "ross", "content-type":"application/xml"};
    var resp = outReqHeadClient->put("/mytest/headers/put", "abc", headers = headerMap, targetType = string);
    if (resp is string) {
        assertTextPayload(resp, "yello:ross:application/xml");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testExecuteWithInlineHeadersMap() {
    var resp = outReqHeadClient->execute("POST", "/mytest/headers", "abc", 
        headers = {"x-type": "joe", "y-type": ["hello", "go"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "joe:hello:text/plain");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testExecuteWithInlineHeadersMapNMediaType() {
    map<string[]> headerMap = {"x-type": ["monica"], "y-type": ["chan", "go"]};
    var resp = outReqHeadClient->execute("PUT", "/mytest/headers/put", "abc", "application/json", headerMap, string);
    if (resp is string) {
        assertTextPayload(resp, "monica:chan:application/json");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testExecuteWithOverrideMediaType() {
    map<string> headerMap = {"x-type": "yello", "y-type": "ross", "content-type":"application/xml"};
    var resp = outReqHeadClient->execute("PATCH", "/mytest/headers/patch", "abc", headers = headerMap, 
        targetType = string);
    if (resp is string) {
        assertTextPayload(resp, "yello:ross:application/xml");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testExecuteToSendGet() {
    map<string> headerMap = {"x-type": "monica", "y-type": "ross", "content-type":"application/xml"};
    var resp = outReqHeadClient->execute("GET", "/mytest/headersWithExecute", "abc", headers = headerMap, 
        targetType = string);
    if (resp is string) {
        assertTextPayload(resp, "monica:ross:abc");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testPatchWithInlineHeadersMap() {
    var resp = outReqHeadClient->patch("/mytest/headers/patch", "abc", 
        headers = {"x-type": "joe", "y-type": ["hello", "go"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "joe:hello:text/plain");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testPatchWithInlineHeadersMapNMediaType() {
    map<string[]> headerMap = {"x-type": ["monica"], "y-type": ["chan", "go"]};
    var resp = outReqHeadClient->patch("/mytest/headers/patch", "abc", "application/json", headerMap, string);
    if (resp is string) {
        assertTextPayload(resp, "monica:chan:application/json");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testPatchWithOverrideMediaType() {
    map<string> headerMap = {"x-type": "yello", "y-type": "ross", "content-type":"application/xml"};
    var resp = outReqHeadClient->patch("/mytest/headers/patch", "abc", headers = headerMap, targetType = string);
    if (resp is string) {
        assertTextPayload(resp, "yello:ross:application/xml");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testDeleteWithInlineHeadersMap() {
    var resp = outReqHeadClient->delete("/mytest/headers/nobody", 
        headers = {"x-type": "joe", "y-type": ["hello", "go"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "joe:hello");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testDeleteWithInlineHeadersMapNMediaType() {
    map<string[]> headerMap = {"x-type": ["monica"], "y-type": ["chan", "go"]};
    var resp = outReqHeadClient->delete("/mytest/headers/delete", "abc", "application/json", headerMap, string);
    if (resp is string) {
        assertTextPayload(resp, "monica:chan:application/json");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testDeleteWithOverrideMediaType() {
    map<string> headerMap = {"x-type": "yello", "y-type": "ross", "content-type":"application/xml"};
    var resp = outReqHeadClient->delete("/mytest/headers/delete", message = "abc", headers = headerMap, 
        targetType = string);
    if (resp is string) {
        assertTextPayload(resp, "yello:ross:application/xml");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testInlineReq() {
    var resp = outReqHeadClient->post("/mytest/inline", 
        { 
            name: "foo", 
            age: 30, 
            address: "area 51"
        }, 
        mediaType = "application/json",
        headers = {
            "my-header": "my-value"
        }, 
        targetType = string);
    if (resp is string) {
        assertTextPayload(resp, "{\"name\":\"foo\", \"age\":30, \"address\":\"area 51\"}:my-value:application/json");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testGetWithNothing() {
    var resp = outReqHeadClient->get("/mytest/any");
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(resp.getJsonPayload(), {result:"default"});
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

//FO client tests
@test:Config {}
public function testFOGetWithInlineHeadersMap() {
    var resp = outRequestFOClient->get("/mytest/headers", headers = {"x-type": "hello", "y-type": ["yello", "elle"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "hello:yello");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testFOOptionsWithInlineHeadersMap() {
    var resp = outRequestFOClient->options("/mytest/headers", 
        headers = {"x-type": "options", "y-type": ["yello", "elle"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "options:yello");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testFOPostWithInlineHeadersMap() {
    var resp = outRequestFOClient->post("/mytest/headers", "abc", headers = {"x-type": "joe", "y-type": ["yello", "go"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "joe:yello:text/plain");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testFOHeadWithInlineHeadersMap() {
    var resp = outRequestFOClient->head("/mytest/headers", headers = {"x-type": "head", "y-type": ["yello", "elle"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testFOPutWithInlineHeadersMapNMediaType() {
    map<string[]> headerMap = {"x-type": ["monica"], "y-type": ["chan", "go"]};
    var resp = outRequestFOClient->put("/mytest/headers/put", "abc", "application/json", headerMap, string);
    if (resp is string) {
        assertTextPayload(resp, "monica:chan:application/json");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testFOExecuteWithInlineHeadersMapNMediaType() {
    map<string[]> headerMap = {"x-type": ["monica"], "y-type": ["chan", "go"]};
    var resp = outRequestFOClient->execute("PUT", "/mytest/headers/put", "abc", "application/json", headerMap, string);
    if (resp is string) {
        assertTextPayload(resp, "monica:chan:application/json");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testFOPatchWithOverrideMediaType() {
    map<string> headerMap = {"x-type": "yello", "y-type": "ross", "content-type":"application/xml"};
    var resp = outRequestFOClient->patch("/mytest/headers/patch", "abc", headers = headerMap, targetType = string);
    if (resp is string) {
        assertTextPayload(resp, "yello:ross:application/xml");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testFODeleteWithInlineHeadersMap() {
    var resp = outRequestFOClient->delete("/mytest/headers/nobody", 
        headers = {"x-type": "joe", "y-type": ["hello", "go"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "joe:hello");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

//LB client tests
@test:Config {}
public function testLBGetWithInlineHeadersMap() {
    var resp = outRequestLBClient->get("/mytest/headers", headers = {"x-type": "hello", "y-type": ["yello", "elle"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "hello:yello");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testLBOptionsWithInlineHeadersMap() {
    var resp = outRequestLBClient->options("/mytest/headers", 
        headers = {"x-type": "options", "y-type": ["yello", "elle"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "options:yello");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testLBPostWithInlineHeadersMap() {
    var resp = outRequestLBClient->post("/mytest/headers", "abc", headers = {"x-type": "joe", "y-type": ["yello", "go"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "joe:yello:text/plain");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testLBHeadWithInlineHeadersMap() {
    var resp = outRequestLBClient->head("/mytest/headers", headers = {"x-type": "head", "y-type": ["yello", "elle"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testLBPutWithInlineHeadersMapNMediaType() {
    map<string[]> headerMap = {"x-type": ["monica"], "y-type": ["chan", "go"]};
    var resp = outRequestLBClient->put("/mytest/headers/put", "abc", "application/json", headerMap, string);
    if (resp is string) {
        assertTextPayload(resp, "monica:chan:application/json");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testLBExecuteWithInlineHeadersMapNMediaType() {
    map<string[]> headerMap = {"x-type": ["monica"], "y-type": ["chan", "go"]};
    var resp = outRequestLBClient->execute("PUT", "/mytest/headers/put", "abc", "application/json", headerMap, string);
    if (resp is string) {
        assertTextPayload(resp, "monica:chan:application/json");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testLBPatchWithOverrideMediaType() {
    map<string> headerMap = {"x-type": "yello", "y-type": "ross", "content-type":"application/xml"};
    var resp = outRequestLBClient->patch("/mytest/headers/patch", "abc", headers = headerMap, targetType = string);
    if (resp is string) {
        assertTextPayload(resp, "yello:ross:application/xml");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

@test:Config {}
public function testLBDeleteWithInlineHeadersMap() {
    var resp = outRequestLBClient->delete("/mytest/headers/nobody", 
        headers = {"x-type": "joe", "y-type": ["hello", "go"]});
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg = "Found unexpected output");
        test:assertEquals(checkpanic resp.getHeader(CONTENT_TYPE), TEXT_PLAIN);
        assertTextPayload(resp.getTextPayload(), "joe:hello");
    } else {
        test:assertFail(msg = "Found unexpected output: " +  resp.message());
    }
}

service /mytest on outRequestOptionsTestEP {

    resource function get headers(@http:Header {name: "x-type"} string value1, http:Request req) returns string|error {
        string value2 = check req.getHeader("y-type");
        return value1 + ":" + value2;
    }

    resource function get headersWithExecute(@http:Header {name: "x-type"} string value1, http:Request req) 
            returns string|error {
        string value2 = check req.getHeader("y-type");
        string value3 = check req.getTextPayload();
        return value1 + ":" + value2 + ":" + value3;
    }

    resource function options headers(@http:Header {name: "x-type"} string value1, http:Request req) returns string {
        string value2 = checkpanic req.getHeader("y-type");
        return value1 + ":" + value2;
    }

    resource function head headers(@http:Header {name: "x-type"} string value1, http:Request req) returns string {
        string value2 = checkpanic req.getHeader("y-type");
        return value1 + ":" + value2;
    }

    resource function 'default 'any() returns json {
        return {result: "default"};
    }

    resource function post headers(@http:Header {name: "x-type"} string value1, http:Request req) returns string {
        string value2 = checkpanic req.getHeader("y-type");
        string value3 = checkpanic req.getHeader("content-type");
        return value1 + ":" + value2 + ":" + value3;
    }

    resource function put headers/put(@http:Header {name: "x-type"} string value1, http:Request req) returns string {
        string value2 = checkpanic req.getHeader("y-type");
        string value3 = checkpanic req.getHeader("content-type");
        return value1 + ":" + value2 + ":" + value3;
    }

    resource function patch headers/patch(@http:Header {name: "x-type"} string value1, http:Request req) 
            returns string {
        string value2 = checkpanic req.getHeader("y-type");
        string value3 = checkpanic req.getHeader("content-type");
        return value1 + ":" + value2 + ":" + value3;
    }

    resource function delete headers/delete(@http:Header {name: "x-type"} string value1, http:Request req) 
            returns string {
        string value2 = checkpanic req.getHeader("y-type");
        string value3 = checkpanic req.getHeader("content-type");
        return value1 + ":" + value2 + ":" + value3;
    }

    resource function delete headers/nobody(@http:Header {name: "x-type"} string value1, http:Request req) 
            returns string {
        string value2 = checkpanic req.getHeader("y-type");
        return value1 + ":" + value2;
    }

    resource function post inline(@http:Payload {} json value1, http:Request req) returns string {
        string value2 = checkpanic req.getHeader("my-header");
        string value3 = checkpanic req.getHeader("content-type");
        return value1.toJsonString() + ":" + value2 + ":" + value3;
    }
}
