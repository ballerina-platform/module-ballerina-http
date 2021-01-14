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

const string HEADER_VALUE = "MyValue";

class MyRequestFilter {

    *http:RequestFilter;

    public isolated function filterRequest(http:Caller caller, http:Request request, http:FilterContext context) returns boolean {
        request.setHeader("Foo", HEADER_VALUE);
        return true;
    }
}

class MyResponseFilter {

    *http:ResponseFilter;

    public isolated function filterResponse(http:Response response, http:FilterContext context) returns boolean {
        response.setHeader("Baz", <@untainted>response.getHeader("Bar"));
        return true;
    }
}

MyRequestFilter reqFilter = new;
MyResponseFilter resFilter = new;

listener http:Listener listenerEP = new http:Listener(filterTestPort, config = {filters: [reqFilter, resFilter]});

service /hello on listenerEP {
    resource function get sayHello(http:Caller caller, http:Request req) {
        http:Response res = new;
        res.setHeader("Bar", <@untainted>req.getHeader("Foo"));
        res.setPayload(<@untainted>req.getHeader("Foo"));
        checkpanic caller->respond(<@untainted>res);
    }
}

@test:Config {}
function testFilterInvocation() {
    http:Client clientEP = new("http://localhost:" + filterTestPort);
    var res = clientEP->get("/hello/sayHello");
    if (res is http:Response) {
        string header = res.getHeader("Baz");
        test:assertEquals(header, HEADER_VALUE);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}
