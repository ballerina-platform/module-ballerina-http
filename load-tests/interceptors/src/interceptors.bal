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
import ballerina/constraint;
import ballerina/time;

type ResponsePayload record {|
    json message;
    string timestamp;
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

service class DefaultResponseInterceptor {
    *http:ResponseInterceptor;

    isolated remote function interceptResponse(http:Response res) returns http:Response|error {
        res.setHeader("API-Version", "v1.0.0");
        return processJsonPayload(res);
    }
}

service class DefaultRequestInterceptor {
    *http:RequestInterceptor;

    isolated resource function 'default [string... path](http:RequestContext ctx,
            @http:Header string? API\-Version) returns http:NextService|error? {
        if API\-Version is string && API\-Version != "v1.0.0" {
            return error http:NotImplementedError("API version is not supported",
                body = {
                "message": string `API version ${API\-Version} is not supported`,
                "timestamp": getCurrentTimeStamp()
            }
            );
        }
        return ctx.next();
    }
}

service class DefaultResponseErrorInterceptor {
    *http:ResponseErrorInterceptor;

    remote function interceptResponseError(error err) returns error {
        return error http:DefaultStatusCodeError("Default error", err, body = {
            message: err.message(),
            timestamp: "2021-01-01T00:00:00.000Z"
        });
    }
}

listener http:Listener serverEP = new (9090,
    interceptors = [
        new DefaultResponseErrorInterceptor(),
        new DefaultResponseInterceptor(),
        new DefaultRequestInterceptor()
    ]
);

service class ServiceRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx,
            http:Request req) returns http:NextService|error? {
        if req.hasHeader("Content-Type") && req.getContentType() != mime:APPLICATION_JSON {
            return error http:UnsupportedMediaTypeError("Content-Type is not supported",
                body = {
                "message": "Only application/json is supported",
                "timestamp": getCurrentTimeStamp()
            });
        }
        return ctx.next();
    }
}

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

isolated table<User> key(id) users = table [
    {id: 1, name: "John Doe", email: "john.doe@gmail.com"},
    {id: 2, name: "Jane Doe", email: "jane.doe@gmail.com"}
];

@http:ServiceConfig {
    interceptors: [new ServiceRequestInterceptor()]
}
service /users on serverEP {

    isolated resource function get .() returns User[] {
        lock {
            return users.cloneReadOnly().toArray();
        }
    }

    isolated resource function get [int id]() returns User|http:NotFoundError {
        lock {
            if users.hasKey(id) {
                return users.cloneReadOnly().get(id);
            }
        }
        return error http:NotFoundError("User not found", body = {
            "message": string `User with id ${id} not found`,
            "timestamp": getCurrentTimeStamp()
        });
    }

    isolated resource function post .(readonly & UserDetails user) returns http:Created {
        lock {
            // Limit the users for testing purposes
            if users.length() < 5 {
                users.add({id: users.length() + 1, ...user});
            }
            return http:CREATED;
        }
    }
}
