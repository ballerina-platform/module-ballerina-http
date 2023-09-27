// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/test;

public type Data record {|
    string name;
    int age;
    string[] address;
|};

final http:Client passthroughRetryClient = check new (string`http://localhost:${passthroughTestPort1}`,
    retryConfig = {
        count: 3,
        interval: 10
    }
);

final http:LoadBalanceClient passthroughLoadBalancerClient = check new ({
    targets: [
        {url: string`http://localhost:${passthroughTestPort1}`}
    ],
    timeout: 5
}
);

final http:FailoverClient passthroughFailoverClient = check new ({
    timeout: 5,
    failoverCodes: [501, 502, 503],
    interval: 5,
    targets: [
        {url: "http://nonexistentEP"},
        {url: string`http://localhost:${passthroughTestPort1}`}
    ]
});

final http:Client passthroughRedirectClient = check new (string`http://localhost:${passthroughTestPort1}`,
    followRedirects = {
        enabled: true,
        maxCount: 5
    }
);

service on new http:Listener(passthroughTestPort2) {

    resource function post passRetryWithReq(http:Request req) returns http:Response|error {
        return passthroughRetryClient->/echo.post(req);
    }

    resource function post passRetryWithPayload(@http:Payload Data[]|xml|string payload) returns Data[]|xml|string|error {
        return passthroughRetryClient->/echo.post(payload);
    }

    resource function post passLoadBalancerWithReq(http:Request req) returns http:Response|error {
        return passthroughLoadBalancerClient->/echo.post(req);
    }

    resource function post passLoadBalancerWithPayload(@http:Payload Data[]|xml|string payload) returns Data[]|xml|string|error {
        return passthroughLoadBalancerClient->/echo.post(payload);
    }

    resource function post passFailoverWithReq(http:Request req) returns http:Response|error {
        return passthroughFailoverClient->/echo.post(req);
    }

    resource function post passFailoverWithPayload(@http:Payload Data[]|xml|string payload) returns Data[]|xml|string|error {
        return passthroughFailoverClient->/echo.post(payload);
    }

    resource function post passRedirectWithReq(http:Request req) returns http:Response|error {
        return passthroughRedirectClient->/echo.post(req);
    }

    resource function post passRedirectWithPayload(@http:Payload Data[]|xml|string payload) returns Data[]|xml|string|error {
        return passthroughRedirectClient->/echo.post(payload);
    }
}

service on new http:Listener(passthroughTestPort1) {

    resource function post echo(@http:Payload Data[]|xml|string payload) returns Data[]|xml|string {
        return payload;
    }
}

@test:Config {}
function testPassthroughRetryClientWithReq() returns error? {
    http:Client clientEP = check new(string`http://localhost:${passthroughTestPort2}`);
    string stringResp = check clientEP->/passRetryWithReq.post("Hello World");
    test:assertEquals(stringResp, "Hello World");

    json jsonResp = check clientEP->/passRetryWithReq.post([{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);
    test:assertEquals(jsonResp, [{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);

    xml xmlResp = check clientEP->/passRetryWithReq.post(xml`<message>Hello World</message>`);
    test:assertEquals(xmlResp, xml`<message>Hello World</message>`);
}

@test:Config {}
function testPassthroughRetryClientWithPayload() returns error? {
    http:Client clientEP = check new(string`http://localhost:${passthroughTestPort2}`);
    string stringResp = check clientEP->/passRetryWithPayload.post("Hello World");
    test:assertEquals(stringResp, "Hello World");

    json jsonResp = check clientEP->/passRetryWithPayload.post([{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);
    test:assertEquals(jsonResp, [{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);

    xml xmlResp = check clientEP->/passRetryWithPayload.post(xml`<message>Hello World</message>`);
    test:assertEquals(xmlResp, xml`<message>Hello World</message>`);
}

@test:Config {}
function testPassthroughLoadBalancerClientWithReq() returns error? {
    http:Client clientEP = check new(string`http://localhost:${passthroughTestPort2}`);
    string stringResp = check clientEP->/passLoadBalancerWithReq.post("Hello World");
    test:assertEquals(stringResp, "Hello World");

    json jsonResp = check clientEP->/passLoadBalancerWithReq.post([{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);
    test:assertEquals(jsonResp, [{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);

    xml xmlResp = check clientEP->/passLoadBalancerWithReq.post(xml`<message>Hello World</message>`);
    test:assertEquals(xmlResp, xml`<message>Hello World</message>`);
}

@test:Config {}
function testPassthroughLoadBalancerClientWithPayload() returns error? {
    http:Client clientEP = check new(string`http://localhost:${passthroughTestPort2}`);
    string stringResp = check clientEP->/passLoadBalancerWithPayload.post("Hello World");
    test:assertEquals(stringResp, "Hello World");

    json jsonResp = check clientEP->/passLoadBalancerWithPayload.post([{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);
    test:assertEquals(jsonResp, [{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);

    xml xmlResp = check clientEP->/passLoadBalancerWithPayload.post(xml`<message>Hello World</message>`);
    test:assertEquals(xmlResp, xml`<message>Hello World</message>`);
}

@test:Config {}
function testPassthroughFailoverClientWithReq() returns error? {
    http:Client clientEP = check new(string`http://localhost:${passthroughTestPort2}`);
    string stringResp = check clientEP->/passFailoverWithReq.post("Hello World");
    test:assertEquals(stringResp, "Hello World");

    json jsonResp = check clientEP->/passFailoverWithReq.post([{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);
    test:assertEquals(jsonResp, [{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);

    xml xmlResp = check clientEP->/passFailoverWithReq.post(xml`<message>Hello World</message>`);
    test:assertEquals(xmlResp, xml`<message>Hello World</message>`);
}

@test:Config {}
function testPassthroughFailoverClientWithPayload() returns error? {
    http:Client clientEP = check new(string`http://localhost:${passthroughTestPort2}`);
    string stringResp = check clientEP->/passFailoverWithPayload.post("Hello World");
    test:assertEquals(stringResp, "Hello World");

    json jsonResp = check clientEP->/passFailoverWithPayload.post([{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);
    test:assertEquals(jsonResp, [{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);

    xml xmlResp = check clientEP->/passFailoverWithPayload.post(xml`<message>Hello World</message>`);
    test:assertEquals(xmlResp, xml`<message>Hello World</message>`);
}

@test:Config {}
function testPassthroughRedirectClientWithReq() returns error? {
    http:Client clientEP = check new(string`http://localhost:${passthroughTestPort2}`);
    string stringResp = check clientEP->/passRedirectWithReq.post("Hello World");
    test:assertEquals(stringResp, "Hello World");

    json jsonResp = check clientEP->/passRedirectWithReq.post([{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);
    test:assertEquals(jsonResp, [{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);

    xml xmlResp = check clientEP->/passRedirectWithReq.post(xml`<message>Hello World</message>`);
    test:assertEquals(xmlResp, xml`<message>Hello World</message>`);
}

@test:Config {}
function testPassthroughRedirectClientWithPayload() returns error? {
    http:Client clientEP = check new(string`http://localhost:${passthroughTestPort2}`);
    string stringResp = check clientEP->/passRedirectWithPayload.post("Hello World");
    test:assertEquals(stringResp, "Hello World");

    json jsonResp = check clientEP->/passRedirectWithPayload.post([{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);
    test:assertEquals(jsonResp, [{name:"John", age:30, address:["Colombo", "Sri Lanka"]}]);

    xml xmlResp = check clientEP->/passRedirectWithPayload.post(xml`<message>Hello World</message>`);
    test:assertEquals(xmlResp, xml`<message>Hello World</message>`);
}
