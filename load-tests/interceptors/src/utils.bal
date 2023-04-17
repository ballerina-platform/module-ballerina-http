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
import ballerina/mime;
import ballerina/time;
import ballerina/constraint;

const string CLIENT_URL = "http://bal.perf.test:80";

type ResponsePayload record {|
    json message;
    string timestamp;
|};

type User record {|
    readonly int id;
    *UserDetails;
|};

type UserDetails record {|
    @constraint:String {minLength: 3}
    string name;
    @constraint:String {pattern: re `([a-zA-Z0-9._%\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,6})*`}
    string email;
|};

isolated function getCurrentTimeStamp() returns string {
    return time:utcToString(time:utcNow());
}

isolated function processJsonPayload(http:Response res) returns http:Response|error {
    string contentType = res.getContentType();
    if contentType == mime:APPLICATION_JSON {
        json payload = check res.getJsonPayload();
        if payload is map<json> {
            ResponsePayload responsePayload = {
                message: payload,
                timestamp: getCurrentTimeStamp()
            };
            res.setJsonPayload(responsePayload);
        }
    }
    return res;
}

isolated function testGetUsers() returns error? {
    http:Client testClient = check new (CLIENT_URL);
    http:Response res = check testClient->/users;
    if res.statusCode != http:STATUS_OK {
        return error("Test Get Users Failed");
    }
}

isolated function testGetUser() returns error? {
    http:Client testClient = check new (CLIENT_URL);
    http:Response res = check testClient->/users/'1;
    if res.statusCode != http:STATUS_OK {
        return error("Test Get User Failed");
    }
}

isolated function testPostUser() returns error? {
    http:Client testClient = check new (CLIENT_URL);
    http:Response res = check testClient->/users.post({name: "Robert", email: "robert@gmail.com"});
    if res.statusCode != http:STATUS_CREATED {
        return error("Test Post User Failed");
    }
}

isolated function testNotImplemented() returns error? {
    http:Client testClient = check new (CLIENT_URL);
    http:Response res = check testClient->/users({"API-Version": "v0.8.0"});
    if res.statusCode != http:STATUS_NOT_IMPLEMENTED {
        return error("Test Not Implemented Failed");
    }
}

isolated function testNotFound() returns error? {
    http:Client testClient = check new (CLIENT_URL);
    http:Response res = check testClient->/users/'100;
    if res.statusCode != http:STATUS_NOT_FOUND {
        return error("Test Not Found Failed");
    }
}

isolated function testUnsupportedMediaType() returns error? {
    http:Client testClient = check new (CLIENT_URL);
    http:Response res = check testClient->/users.post({name: "Robert", email: "robert@gmail.com"}, {"Content-Type": "text/plain"});
    if res.statusCode != http:STATUS_UNSUPPORTED_MEDIA_TYPE {
        return error("Test 5 failed");
    }
}

isolated function testBadRequest() returns error? {
    http:Client testClient = check new (CLIENT_URL);
    http:Response res = check testClient->/users.post({name: "R", email: "robert"});
    if res.statusCode != http:STATUS_BAD_REQUEST {
        return error("Test 6 failed");
    }
}
