// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/io;
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener httpRoutingListenerEP = new (httpRoutingTestPort, httpVersion = http:HTTP_1_1);
final http:Client httpRoutingClient = check new ("http://localhost:" + httpRoutingTestPort.toString(), httpVersion = http:HTTP_1_1);

final http:Client nasdaqEP = check new ("http://localhost:" + httpRoutingTestPort.toString() + "/nasdaqStocks", httpVersion = http:HTTP_1_1);
final http:Client nyseEP2 = check new ("http://localhost:" + httpRoutingTestPort.toString() + "/nyseStocks", httpVersion = http:HTTP_1_1);

service /contentBasedRouting on httpRoutingListenerEP {

    resource function post .(http:Caller conn, http:Request req) returns error? {
        string nyseString = "nyse";
        var jsonMsg = req.getJsonPayload();
        string nameString = "";
        if jsonMsg is json {
            var tempName = jsonMsg.name;
            nameString = tempName is error ? tempName.toString() : tempName.toString();
        } else {
            io:println("Error getting payload");
        }
        http:Request clientRequest = new;
        http:Response clientResponse = new;
        if nameString == nyseString {
            http:Response|error result = nyseEP2->post("/stocks", clientRequest);
            if result is http:Response {
                check conn->respond(result);
            } else {
                clientResponse.statusCode = 500;
                clientResponse.setPayload("Error sending request");
                check conn->respond(clientResponse);
            }
        } else {
            http:Response|error result = nasdaqEP->post("/stocks", clientRequest);
            if result is http:Response {
                check conn->respond(result);
            } else {
                clientResponse.statusCode = 500;
                clientResponse.setPayload("Error sending request");
                check conn->respond(clientResponse);
            }
        }
    }
}

service /headerBasedRouting on httpRoutingListenerEP {

    resource function get .(http:Caller caller, http:Request req) returns error? {
        string nyseString = "nyse";
        var nameString = check req.getHeader("name");

        http:Request clientRequest = new;
        http:Response clientResponse = new;
        if nameString == nyseString {
            http:Response|error result = nyseEP2->post("/stocks", clientRequest);
            if result is http:Response {
                check caller->respond(result);
            } else {
                clientResponse.statusCode = 500;
                clientResponse.setPayload("Error sending request");
                check caller->respond(clientResponse);
            }
        } else {
            http:Response|error result = nasdaqEP->post("/stocks", clientRequest);
            if result is http:Response {
                check caller->respond(result);
            } else {
                clientResponse.statusCode = 500;
                clientResponse.setPayload("Error sending request");
                check caller->respond(clientResponse);
            }
        }
    }
}

service /nasdaqStocks on httpRoutingListenerEP {

    resource function post stocks(http:Caller caller, http:Request req) returns error? {
        json payload = {"exchange": "nasdaq", "name": "IBM", "value": "127.50"};
        http:Response res = new;
        res.setJsonPayload(payload);
        check caller->respond(res);
    }
}

service /nyseStocks on httpRoutingListenerEP {

    resource function post stocks(http:Caller caller, http:Request req) returns error? {
        json payload = {"exchange": "nyse", "name": "IBM", "value": "127.50"};
        http:Response res = new;
        res.setJsonPayload(payload);
        check caller->respond(res);
    }
}

json requestNyseMessage = {name: "nyse"};
json responseNyseMessage = {exchange: "nyse", name: "IBM", value: "127.50"};
json requestNasdaqMessage = {name: "nasdaq"};
json responseNasdaqMessage = {exchange: "nasdaq", name: "IBM", value: "127.50"};

//Test Content base routing sample
@test:Config {}
function testContentBaseRouting() returns error? {
    http:Response|error response = httpRoutingClient->post("/contentBasedRouting", requestNyseMessage);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), responseNyseMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpRoutingClient->post("/contentBasedRouting", requestNasdaqMessage);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), responseNasdaqMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Header base routing sample
@test:Config {}
function testHeaderBaseRouting() returns error? {
    http:Response|error response = httpRoutingClient->get("/headerBasedRouting", {"name": "nyse"});
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), responseNyseMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpRoutingClient->get("/headerBasedRouting", {"name": "nasdaq"});
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), responseNasdaqMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

