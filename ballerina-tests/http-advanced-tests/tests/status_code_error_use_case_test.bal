// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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
import ballerina/http.http_status;
import ballerina/time;
import ballerina/test;

// Custom Error Types
type Error distinct error;

type ErrorInfo record {|
    string timeStamp;
    string message;
|};

type ErrorDetails record {|
    *http_status:ErrorDetail;
    ErrorInfo body;
|};

type UserNotFoundError Error & http_status:NotFoundError & error<ErrorDetails>;

type UserNameAlreadyExistError Error & http_status:ConflictError & error<ErrorDetails>;

type BadUserError Error & http_status:BadRequestError & error<ErrorDetails>;

type User record {|
    readonly int id;
    *UserWithoutId;
|};

type UserWithoutId record {|
    string name;
    int age;
|};

isolated table<User> key(id) users = table [
    {id: 1, name: "John", age: 30},
    {id: 2, name: "Richard", age: 25},
    {id: 3, name: "Jane", age: 20}
];

isolated function getCurrentTimeStamp() returns string {
    return time:utcToString(time:utcNow());
}

isolated function getUser(int id) returns User|UserNotFoundError {
    lock {
        if users.hasKey(id) {
            return users.get(id).clone();
        } else {
            return error UserNotFoundError("User not found", body = {
                timeStamp: getCurrentTimeStamp(),
                message: string `User not found for id: ${id}`
            });
        }
    }
}

isolated function addUser(readonly & UserWithoutId newUser) returns User|UserNameAlreadyExistError|BadUserError {
    lock {
        check validateUserPayload(newUser);
        if users.filter(user => user.name == newUser.name).length() > 0 {
            return error UserNameAlreadyExistError("User name already exists", body = {
                timeStamp: getCurrentTimeStamp(),
                message: string `User name: ${newUser.name} already exists`
            });
        } else {
            int id = users.length() + 1;
            User user = {id: id, ...newUser};
            users.add(user);
            return user.clone();
        }
    }
}

isolated function validateUserPayload(readonly & UserWithoutId user) returns BadUserError? {
    string[] messages = [];
    if user.name.length() < 2 {
        messages.push("User name should be at least 2 characters");
    }
    if user.age < 18 {
        messages.push("User should be at least 18 years");
    }
    if messages.length() > 0 {
        return error BadUserError("User info is not acceptable", body = {
            timeStamp: getCurrentTimeStamp(),
            message: string:'join(" and ", ...messages)
        });
    }
}

service on new http:Listener(statusCodeErrorUseCasePort) {

    resource function get users/[int id]() returns User|UserNotFoundError {

        return getUser(id);
    }

    resource function post users(@http:Payload readonly & UserWithoutId user)
            returns User|UserNameAlreadyExistError|BadUserError {

        return addUser(user);
    }

    resource function 'default [string... path]() returns http_status:NotFoundError {

        return error http_status:NotFoundError("Resource not found", body = {
            timeStamp: getCurrentTimeStamp(),
            message: string `Resource not found for path: /${string:'join("/", ...path)}`
        });
    }
}

final http:Client statusCodeErrorUseCaseClient = check new ("http://localhost:" + statusCodeErrorUseCasePort.toString());

@test:Config {}
function testStatusCodeErrorUseCase1() returns error? {
    User user = check statusCodeErrorUseCaseClient->/users/["1"];
    test:assertEquals(user, {id: 1, name: "John", age: 30});

    http:Response response = check statusCodeErrorUseCaseClient->/users/["8"];
    test:assertEquals(response.statusCode, 404);
    json errorInfo = check response.getJsonPayload();
    test:assertEquals(errorInfo.message, "User not found for id: 8");
}

@test:Config {}
function testStatusCodeErrorUseCase2() returns error? {
    User _ = check statusCodeErrorUseCaseClient->/users.post({name: "Ravi", age: 30});

    http:Response response = check statusCodeErrorUseCaseClient->/users.post({name: "Ravi", age: 43});
    test:assertEquals(response.statusCode, 409);
    json errorInfo = check response.getJsonPayload();
    test:assertEquals(errorInfo.message, "User name: Ravi already exists");
}

@test:Config {}
function testStatusCodeErrorUseCase3() returns error? {
    http:Response response = check statusCodeErrorUseCaseClient->/users.post({name: "R", age: 43});
    test:assertEquals(response.statusCode, 400);
    json errorInfo = check response.getJsonPayload();
    test:assertEquals(errorInfo.message, "User name should be at least 2 characters");

    response = check statusCodeErrorUseCaseClient->/users.post({name: "Ravi", age: 3});
    test:assertEquals(response.statusCode, 400);
    errorInfo = check response.getJsonPayload();
    test:assertEquals(errorInfo.message, "User should be at least 18 years");

    response = check statusCodeErrorUseCaseClient->/users.post({name: "R", age: 4});
    test:assertEquals(response.statusCode, 400);
    errorInfo = check response.getJsonPayload();
    test:assertEquals(errorInfo.message, "User name should be at least 2 characters " +
        "and User should be at least 18 years");
}

@test:Config {}
function testStatusCodeErrorUseCase4() returns error? {
    http:Response response = check statusCodeErrorUseCaseClient->/users/["1"]/greeting;
    test:assertEquals(response.statusCode, 404);
    json errorInfo = check response.getJsonPayload();
    test:assertEquals(errorInfo.message, "Resource not found for path: /users/1/greeting");
}
