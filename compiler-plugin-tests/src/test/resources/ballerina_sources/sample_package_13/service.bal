// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

service / on new http:Listener(9999) {
    resource function get invalid (http:Caller caller, string action) returns http:BadRequest? {
        if action == "complete" {
            error? result = caller->respond("This is successful");
        } else {
            http:BadRequest result = {
                body: "Provided `action` parameter is invalid"
            };
            return result;
        }
    }

    resource function get valid (string action) returns http:Accepted|http:BadRequest {
        if action == "complete" {
            http:Accepted result = {
                body: "Request was successfully processed"
            };
            return result;
        } else {
            http:BadRequest result = {
                body: "Provided `action` parameter is invalid"
            };
            return result;
        }
    }

    resource function get validWithCaller (http:Caller caller, string action) returns error? {
        check caller->respond("Hello, World..!");
    }

    resource function get validWithHttpErrors (http:Caller caller, http:Request request) returns http:ListenerError|http:ClientError? {
        string payload = check request.getTextPayload();
        if payload == "sample content" {
            check caller->respond("Received message");
        }
    }
}
