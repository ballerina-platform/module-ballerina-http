// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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

final http:Client http2ClientHost1 = check new("localhost:" + http2ClientHostHeaderTestPort.toString());
final http:Client http2ClientHost2 = check new("localhost:" + httpClientHostHeaderTestPort.toString());
final http:Client httpClientHost1 = check new("localhost:" + httpClientHostHeaderTestPort.toString(), httpVersion = http:HTTP_1_1);
final http:Client httpClientHost2 = check new("localhost:" + http2ClientHostHeaderTestPort.toString(), httpVersion = http:HTTP_1_1);

service / on new http:Listener(http2ClientHostHeaderTestPort) {

    resource function 'default host(http:Request req) returns string|error {
        return req.getHeader("Host");
    }
}

service / on new http:Listener(httpClientHostHeaderTestPort, httpVersion = http:HTTP_1_1) {

    resource function 'default host(http:Request req) returns string|error {
        return req.getHeader("Host");
    }
}

@test:Config {}
function testHttpClientHostHeader1() returns error? {
    string host = check httpClientHost1->/host;
    test:assertEquals(host, "localhost:" + httpClientHostHeaderTestPort.toString());

    host = check httpClientHost1->get("/host");
    test:assertEquals(host, "localhost:" + httpClientHostHeaderTestPort.toString());

    host = check httpClientHost2->/host;
    test:assertEquals(host, "localhost:" + http2ClientHostHeaderTestPort.toString());

    host = check httpClientHost2->get("/host");
    test:assertEquals(host, "localhost:" + http2ClientHostHeaderTestPort.toString());
}

@test:Config {}
function testHttpClientHostHeader2() returns error? {
    string host = check httpClientHost1->/host.get({"Host": "mock.com"});
    test:assertEquals(host, "mock.com");

    host = check httpClientHost1->get("/host", {"Host": "mock.com"});
    test:assertEquals(host, "mock.com");

    host = check httpClientHost2->/host.get({"Host": "mock.com"});
    test:assertEquals(host, "mock.com");

    host = check httpClientHost2->get("/host", {"Host": "mock.com"});
    test:assertEquals(host, "mock.com");
}

@test:Config {}
function testHttpClientHostHeader3() returns error? {
    http:Request req = new;
    req.setHeader("Host", "mock.com");
    string host = check httpClientHost1->/host.post(req);
    test:assertEquals(host, "mock.com");

    host = check httpClientHost1->post("/host", req, {"Host": "mock2.com"});
    test:assertEquals(host, "mock2.com");

    host = check httpClientHost2->/host.post(req);
    test:assertEquals(host, "mock2.com");

    host = check httpClientHost2->post("/host", req, {"Host": "mock3.com"});
    test:assertEquals(host, "mock3.com");
}

@test:Config {}
function testHttp2ClientHostHeader1() returns error? {
    string host = check http2ClientHost1->/host;
    test:assertEquals(host, "localhost:" + http2ClientHostHeaderTestPort.toString());

    host = check http2ClientHost1->get("/host");
    test:assertEquals(host, "localhost:" + http2ClientHostHeaderTestPort.toString());

    host = check http2ClientHost2->/host;
    test:assertEquals(host, "localhost:" + httpClientHostHeaderTestPort.toString());

    host = check http2ClientHost2->get("/host");
    test:assertEquals(host, "localhost:" + httpClientHostHeaderTestPort.toString());
}

@test:Config {}
function testHttp2ClientHostHeader2() returns error? {
    string host = check http2ClientHost1->/host.get({"Host": "mock.com"});
    test:assertEquals(host, "mock.com");

    host = check http2ClientHost1->get("/host", {"Host": "mock.com"});
    test:assertEquals(host, "mock.com");

    host = check http2ClientHost2->/host.get({"Host": "mock.com"});
    test:assertEquals(host, "mock.com");

    host = check http2ClientHost2->get("/host", {"Host": "mock.com"});
    test:assertEquals(host, "mock.com");
}

@test:Config {}
function testHttp2ClientHostHeader3() returns error? {
    http:Request req = new;
    req.setHeader("Host", "mock.com");
    string host = check http2ClientHost1->/host.post(req);
    test:assertEquals(host, "mock.com");

    host = check http2ClientHost1->post("/host", req, {"Host": "mock2.com"});
    test:assertEquals(host, "mock2.com");

    host = check http2ClientHost2->/host.post(req);
    test:assertEquals(host, "mock2.com");

    host = check http2ClientHost2->post("/host", req, {"Host": "mock3.com"});
    test:assertEquals(host, "mock3.com");
}
