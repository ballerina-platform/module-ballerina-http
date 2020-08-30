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

import ballerina/test;
import http;

listener http:Listener vhEP  = new(virtualHostTest);
http:Client vhClient = new("http://localhost:" + virtualHostTest.toString());

@http:ServiceConfig {
    basePath:"/page",
    host:"abc.com"
}
service Host1 on vhEP {
    @http:ResourceConfig {
        path: "/index"
    }
    resource function productsInfo1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = { "echo": "abc.com" };
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {
    basePath:"/page",
    host:"xyz.org"
}
service Host2 on vhEP {
    @http:ResourceConfig {
        path: "/index"
    }
    resource function productsInfo1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = { "echo": "xyz.org" };
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

@http:ServiceConfig {
    basePath:"/page"
}
service Host3 on vhEP {
    @http:ResourceConfig {
        path: "/index"
    }
    resource function productsInfo1(http:Caller caller, http:Request req) {
        http:Response res = new;
        json responseJson = { "echo": "no host" };
        res.setJsonPayload(responseJson);
        checkpanic caller->respond(res);
    }
}

// Need to use separate client to change Host header, as ballerina client does not allow it.
// @test:Config {}
function testInvokingTwoServicesWithDifferentHostsAndSameBasePaths() {
    string hostName1 = "abc.com";
    http:Request req1 = new;
    req1.setHeader("Host", hostName1);
    var response = vhClient->get("/page/index", req1);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", hostName1);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }

    string hostName2 = "xyz.org";
    http:Request req2 = new;
    req2.setHeader("Host", hostName2);
    response = vhClient->get("/page/index", req2);
    if (response is http:Response) {
        assertJsonValue(response.getJsonPayload(), "echo", hostName2);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
