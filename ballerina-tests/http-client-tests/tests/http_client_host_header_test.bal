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

service /api on new http:Listener(passthroughHostTestPort1) {

    resource function 'default [string test]/host(@http:Header string host) returns string {
        return host;
    }
}

final http:Client httpHostPassthroughClientEP = check new (string `localhost:${passthroughHostTestPort1}`, httpVersion = http:HTTP_1_1);
final http:Client http2HostPassthroughClientEP = check new (string `localhost:${passthroughHostTestPort1}`);
final http:Client http2HostPassthroughClientEPWithPriorKnowledge = check new (string `localhost:${passthroughHostTestPort1}`, http2Settings = {http2PriorKnowledge: true});

final http:Client httpHostPassthroughTestClient = check new (string `localhost:${passthroughHostTestPort2}`);

service /api on new http:Listener(passthroughHostTestPort2) {

    resource function get http/host(http:Request req) returns http:Response|error {
        return httpHostPassthroughClientEP->execute(req.method, req.rawPath, req);
    }

    resource function get http2/host(http:Request req) returns http:Response|error {
        return http2HostPassthroughClientEP->execute(req.method, req.rawPath, req);
    }

    resource function get http2prior/host(http:Request req) returns http:Response|error {
        return http2HostPassthroughClientEPWithPriorKnowledge->execute(req.method, req.rawPath, req);
    }

    resource function get update1/host(string host, http:Request req) returns http:Response|error {
        req.setHeader("Host", host);
        return httpHostPassthroughClientEP->execute(req.method, req.rawPath, req);
    }

    resource function get update2/host(string host, http:Request req) returns http:Response|error {
        req.setHeader("host", host);
        return http2HostPassthroughClientEP->execute(req.method, req.rawPath, req);
    }

    resource function get update3/host(string host, http:Request req) returns http:Response|error {
        req.setHeader("HOST", host);
        return http2HostPassthroughClientEPWithPriorKnowledge->execute(req.method, req.rawPath, req);
    }

    resource function get update4/host(string host, http:Request req) returns http:Response|error {
        return httpHostPassthroughClientEP->execute(req.method, req.rawPath, req, {host: host});
    }

    resource function get update5/host(string host, http:Request req) returns http:Response|error {
        return http2HostPassthroughClientEP->execute(req.method, req.rawPath, req, {host: host});
    }

    resource function get update6/host(string host, http:Request req) returns http:Response|error {
        return http2HostPassthroughClientEPWithPriorKnowledge->execute(req.method, req.rawPath, req, {host: host});
    }

    resource function get update7/host(string host, http:Request req) returns http:Response|error {
        return httpHostPassthroughClientEP->post(req.rawPath, req, {host: host});
    }

    resource function get update8/host(string host, http:Request req) returns http:Response|error {
        return http2HostPassthroughClientEP->post(req.rawPath, req, {host: host});
    }

    resource function get update9/host(string host, http:Request req) returns http:Response|error {
        return http2HostPassthroughClientEPWithPriorKnowledge->post(req.rawPath, req, {host: host});
    }

    resource function get update10/host(string host, http:Request req) returns http:Response|error {
        return httpHostPassthroughClientEP->/api/test/host.post(req, {host: host});
    }

    resource function get update11/host(string host, http:Request req) returns http:Response|error {
        return http2HostPassthroughClientEP->/api/test/host.post(req, {host: host});
    }

    resource function get update12/host(string host, http:Request req) returns http:Response|error {
        return http2HostPassthroughClientEPWithPriorKnowledge->/api/test/host.post(req, {host: host});
    }

    resource function get negative1/host(string host, http:Request req) returns http:Response|error {
        return httpHostPassthroughClientEP->execute(req.method, req.rawPath, req, {host123: host});
    }

    resource function get negative2/host(string host, http:Request req) returns http:Response|error {
        req.setHeader("X-Host", host);
        return httpHostPassthroughClientEP->execute(req.method, req.rawPath, req);
    }

    resource function get negative3/host(string host, http:Request req) returns http:Response|error {
        req.setHeader("Host", host);
        req.removeHeader("Host");
        return httpHostPassthroughClientEP->execute(req.method, req.rawPath, req);
    }

    resource function get negative4/host(string host, http:Request req) returns http:Response|error {
        req.setHeader("Host", host);
        req.removeHeader("Host");
        return httpHostPassthroughClientEP->execute(req.method, req.rawPath, req, {host: "random.com"});
    }

    resource function get negative5/host(string host, http:Request req) returns http:Response|error {
        req.setHeader("Host", host);
        req.removeHeader("Host");
        req.setHeader("Host", "random.com");
        return httpHostPassthroughClientEP->execute(req.method, req.rawPath, req);
    }
}

@test:Config {}
function testHostHeaderInPassthrough() returns error? {
    string host = check httpHostPassthroughTestClient->/api/http/host.get();
    test:assertEquals(host, "localhost:9607", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/http2/host.get();
    test:assertEquals(host, "localhost:9607", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/http2prior/host.get();
    test:assertEquals(host, "localhost:9607", "Invalid host header in passthrough");
}

@test:Config {}
function testUpdateHostHeaderInPassthrough() returns error? {
    string host = check httpHostPassthroughTestClient->/api/update1/host.get(host = "random-update-1.com");
    test:assertEquals(host, "random-update-1.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/update2/host.get(host = "random-update-2.com");
    test:assertEquals(host, "random-update-2.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/update3/host.get(host = "random-update-3.com");
    test:assertEquals(host, "random-update-3.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/update4/host.get(host = "random-update-4.com");
    test:assertEquals(host, "random-update-4.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/update5/host.get(host = "random-update-5.com");
    test:assertEquals(host, "random-update-5.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/update6/host.get(host = "random-update-6.com");
    test:assertEquals(host, "random-update-6.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/update7/host.get(host = "random-update-7.com");
    test:assertEquals(host, "random-update-7.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/update8/host.get(host = "random-update-8.com");
    test:assertEquals(host, "random-update-8.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/update9/host.get(host = "random-update-9.com");
    test:assertEquals(host, "random-update-9.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/update10/host.get(host = "random-update-10.com");
    test:assertEquals(host, "random-update-10.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/update11/host.get(host = "random-update-11.com");
    test:assertEquals(host, "random-update-11.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/update12/host.get(host = "random-update-12.com");
    test:assertEquals(host, "random-update-12.com", "Invalid host header in passthrough");
}

@test:Config {}
function testNegativeCasesInPassthrough() returns error? {
    string host = check httpHostPassthroughTestClient->/api/negative1/host.get(host = "random-update-1.com");
    test:assertEquals(host, "localhost:9607", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/negative2/host.get(host = "random-update-2.com");
    test:assertEquals(host, "localhost:9607", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/negative3/host.get(host = "random-update-3.com");
    test:assertEquals(host, "localhost:9607", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/negative4/host.get(host = "random-update-4.com");
    test:assertEquals(host, "random.com", "Invalid host header in passthrough");

    host = check httpHostPassthroughTestClient->/api/negative5/host.get(host = "random-update-5.com");
    test:assertEquals(host, "random.com", "Invalid host header in passthrough");
}
