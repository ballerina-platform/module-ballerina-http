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

import ballerina/test;
import ballerina/http;

final http:Client serviceSpecificClientEP = check new("http://localhost:" + serviceMediaTypeSubtypePrefixPort.toString(), httpVersion = http:HTTP_1_1);
listener http:Listener serviceSpecificListener = new(serviceMediaTypeSubtypePrefixPort, httpVersion = http:HTTP_1_1);

@http:ServiceConfig {
    mediaTypeSubtypePrefix : "testServicePrefix1"
}
service /service1 on serviceSpecificListener {

    resource function default test1(http:Request req) returns string {
        return "test1";
    }

    resource function default test2(http:Request req) returns @http:Payload{mediaType : "type2/subtype2"} string {
            return "test2";
    }

    resource function default test3(http:Request req) returns http:Response|error {
        http:Response res = new;
        res.setPayload("test3");
        check res.setContentType("type3/subtype3");
        return res;
    }

    resource function default test4(http:Request req) returns http:Response {
        http:Response res = new;
        res.setPayload("test4", "type4/subtype4");
        return res;
    }

    resource function default test5(http:Request req, http:Caller caller) returns error? {
        http:Response res = new;
        res.setPayload("test5");
        res.setHeader("content-type", "type5/subtype5");
        check caller->respond(res);
        return;
    }

    resource function default test6(http:Request req, http:Caller caller) returns error? {
        http:Response res = new;
        res.setPayload("test6");
        check caller->respond(res);
        return;
    }
}

@http:ServiceConfig {
    mediaTypeSubtypePrefix : "testServicePrefix2"
}
service /service2 on serviceSpecificListener {

    resource function default test(http:Request req) returns json {
        return {message : "test"};
    }
}

@test:Config {}
function testServiceWithSpecificmediaTypeSubtypePrefix() returns error? {
    http:Response response = check serviceSpecificClientEP->get("/service1/test1");
    assertTextPayload(response.getTextPayload(), "test1");
    assertHeaderValue(check response.getHeader(CONTENT_TYPE), "text/testServicePrefix1+plain");

    response = check serviceSpecificClientEP->get("/service1/test2");
    assertTextPayload(response.getTextPayload(), "test2");
    assertHeaderValue(check response.getHeader(CONTENT_TYPE), "type2/testServicePrefix1+subtype2");

    response = check serviceSpecificClientEP->get("/service1/test3");
    assertTextPayload(response.getTextPayload(), "test3");
    assertHeaderValue(check response.getHeader(CONTENT_TYPE), "type3/testServicePrefix1+subtype3");

    response = check serviceSpecificClientEP->get("/service1/test4");
    assertTextPayload(response.getTextPayload(), "test4");
    assertHeaderValue(check response.getHeader(CONTENT_TYPE), "type4/testServicePrefix1+subtype4");

    response = check serviceSpecificClientEP->get("/service1/test5");
    assertTextPayload(response.getTextPayload(), "test5");
    assertHeaderValue(check response.getHeader(CONTENT_TYPE), "type5/testServicePrefix1+subtype5");

    response = check serviceSpecificClientEP->get("/service1/test6");
    assertTextPayload(response.getTextPayload(), "test6");
    assertHeaderValue(check response.getHeader(CONTENT_TYPE), "text/testServicePrefix1+plain");

    response = check serviceSpecificClientEP->get("/service2/test");
    assertJsonPayload(response.getJsonPayload(), {message : "test"});
    assertHeaderValue(check response.getHeader(CONTENT_TYPE), "application/testServicePrefix2+json");
    return;
}
