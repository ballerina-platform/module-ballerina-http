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

listener http:Listener httpRoutingListenerEP = new(httpRoutingTestPort);
http:Client httpRoutingClient = check new("http://localhost:" + httpRoutingTestPort.toString());

http:Client nasdaqEP = check new("http://localhost:" + httpRoutingTestPort.toString() + "/nasdaqStocks");
http:Client nyseEP2 = check new("http://localhost:" + httpRoutingTestPort.toString() + "/nyseStocks");

service /contentBasedRouting on httpRoutingListenerEP {

    resource function post .(http:Caller conn, http:Request req) {
        string nyseString = "nyse";
        var jsonMsg = req.getJsonPayload();
        string nameString = "";
        if (jsonMsg is json) {
            var tempName = jsonMsg.name;
            nameString = tempName is error ? tempName.toString() : tempName.toString();
        } else {
            io:println("Error getting payload");
        }
        http:Request clientRequest = new;
        http:Response clientResponse = new;
        if (nameString == nyseString) {
            var result = nyseEP2 -> post("/stocks", clientRequest);
            if (result is http:Response) {
                checkpanic conn->respond(<@untainted> result);
            } else  {
                clientResponse.statusCode = 500;
                clientResponse.setPayload("Error sending request");
                checkpanic conn->respond(clientResponse);
            }
        } else {
            var result = nasdaqEP -> post("/stocks", clientRequest);
            if (result is http:Response) {
                checkpanic conn->respond(<@untainted> result);
            } else {
                clientResponse.statusCode = 500;
                clientResponse.setPayload("Error sending request");
                checkpanic conn->respond(clientResponse);
            }
        }
    }
}

service /headerBasedRouting on httpRoutingListenerEP {

    resource function get .(http:Caller caller, http:Request req) {
        string nyseString = "nyse";
        var nameString = checkpanic req.getHeader("name");

        http:Request clientRequest = new;
        http:Response clientResponse = new;
        if (nameString == nyseString) {
            var result = nyseEP2 -> post("/stocks", clientRequest);
            if (result is http:Response) {
                checkpanic caller->respond(<@untainted> result);
            } else {
                clientResponse.statusCode = 500;
                clientResponse.setPayload("Error sending request");
                checkpanic caller->respond(clientResponse);
            }
        } else {
            var result = nasdaqEP -> post("/stocks", clientRequest);
            if (result is http:Response) {
                checkpanic caller->respond(<@untainted> result);
            } else {
                clientResponse.statusCode = 500;
                clientResponse.setPayload("Error sending request");
                checkpanic caller->respond(clientResponse);
            }
        }
    }
}

service /nasdaqStocks on httpRoutingListenerEP {

    resource function post stocks(http:Caller caller, http:Request req) {
        json payload = {"exchange":"nasdaq", "name":"IBM", "value":"127.50"};
        http:Response res = new;
        res.setJsonPayload(payload);
        checkpanic caller->respond(res);
    }
}

service /nyseStocks on httpRoutingListenerEP {

    resource function post stocks(http:Caller caller, http:Request req) {
        json payload = {"exchange":"nyse", "name":"IBM", "value":"127.50"};
        http:Response res = new;
        res.setJsonPayload(payload);
        checkpanic caller->respond(res);
    }
}

json requestNyseMessage = {name:"nyse"};
json responseNyseMessage = {exchange:"nyse", name:"IBM", value:"127.50"};
json requestNasdaqMessage = {name:"nasdaq"};
json responseNasdaqMessage = {exchange:"nasdaq", name:"IBM", value:"127.50"};

//Test Content base routing sample
@test:Config {}
function testContentBaseRouting() {
    var response = httpRoutingClient->post("/contentBasedRouting", requestNyseMessage);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), responseNyseMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    response = httpRoutingClient->post("/contentBasedRouting", requestNasdaqMessage);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), responseNasdaqMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test Header base routing sample
@test:Config {}
function testHeaderBaseRouting() {
    http:Request req = new;
    req.setHeader("name", "nyse");
    var response = httpRoutingClient->get("/headerBasedRouting", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), responseNyseMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    req = new;
    req.setHeader("name", "nasdaq");
    response = httpRoutingClient->get("/headerBasedRouting", req);
    if (response is http:Response) {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        assertHeaderValue(checkpanic response.getHeader(CONTENT_TYPE), APPLICATION_JSON);
        assertJsonPayload(response.getJsonPayload(), responseNasdaqMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

