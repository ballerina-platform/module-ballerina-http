// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com)
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
import ballerina/time;
import ballerina/uuid;

type User record {|
    string id;
    string name;
    string email;
    int age;
    string department?;
    string createdAt;
    string updatedAt;
|};

type UserInput record {|
    string name;
    string email;
    int age;
    string department?;
|};

type UserUpdate record {|
    string name?;
    string email?;
    int age?;
    string department?;
|};

type ErrorResponse record {|
    string message;
    string code;
    string timestamp;
|};

type SuccessResponse record {|
    string message;
    json data?;
|};

type Caller record {|
    int id;
|};

map<User> userStore = {};

service /api/v1 on new http:Listener(9090) {

    resource function get users(string? department, int? minAge, int? maxAge) returns User[]|ErrorResponse {
        User[] users = userStore.toArray();
        if department is string {
            users = users.filter(user => user.department == department);
        }
        if minAge is int {
            users = users.filter(user => user.age >= minAge);
        }
        if maxAge is int {
            users = users.filter(user => user.age <= maxAge);
        }
        return users;
    }

    resource function get users/[string id]() returns User|ErrorResponse {
        User? user = userStore[id];
        if user is User {
            return user;
        } else {
            return {
                message: "User not found",
                code: "USER_NOT_FOUND",
                timestamp: time:utcToString(time:utcNow())
            };
        }
    }

    resource function get health() returns SuccessResponse {
        return {
            message: "Service is healthy",
            data: {
                "status": "UP",
                "timestamp": time:utcToString(time:utcNow()),
                "totalUsers": userStore.length()
            }
        };
    }

    resource function get stats() returns SuccessResponse {
        map<int> departmentCount = {};
        int totalAge = 0;

        foreach User user in userStore {
            string dept = user.department ?: "Unknown";
            departmentCount[dept] = (departmentCount[dept] ?: 0) + 1;
            totalAge += user.age;
        }

        return {
            message: "Service statistics",
            data: {
                "totalUsers": userStore.length(),
                "averageAge": userStore.length() > 0 ? totalAge / userStore.length() : 0,
                "departmentDistribution": departmentCount
            }
        };
    }

    resource function post users(@http:Payload UserInput userInput) returns User|ErrorResponse {
        // Validate input
        if userInput.name.trim() == "" {
            return {
                message: "Name cannot be empty",
                code: "INVALID_INPUT",
                timestamp: time:utcToString(time:utcNow())
            };
        }

        if userInput.email.trim() == "" {
            return {
                message: "Email cannot be empty",
                code: "INVALID_INPUT",
                timestamp: time:utcToString(time:utcNow())
            };
        }

        if userInput.age < 0 || userInput.age > 150 {
            return {
                message: "Age must be between 0 and 150",
                code: "INVALID_INPUT",
                timestamp: time:utcToString(time:utcNow())
            };
        }

        foreach User user in userStore {
            if user.email == userInput.email {
                return {
                    message: "User with this email already exists",
                    code: "DUPLICATE_EMAIL",
                    timestamp: time:utcToString(time:utcNow())
                };
            }
        }

        string userId = uuid:createType1AsString();
        string currentTime = time:utcToString(time:utcNow());

        User newUser = {
            id: userId,
            name: userInput.name,
            email: userInput.email,
            age: userInput.age,
            department: userInput.department,
            createdAt: currentTime,
            updatedAt: currentTime
        };

        userStore[userId] = newUser;
        return newUser;
    }

    resource function post users/bulk(@http:Payload UserInput[] userInputs) returns User[]|ErrorResponse {
        if userInputs.length() == 0 {
            return {
                message: "At least one user must be provided",
                code: "INVALID_INPUT",
                timestamp: time:utcToString(time:utcNow())
            };
        }

        User[] createdUsers = [];
        foreach UserInput userInput in userInputs {
            string userId = uuid:createType1AsString();
            string currentTime = time:utcToString(time:utcNow());

            User newUser = {
                id: userId,
                name: userInput.name,
                email: userInput.email,
                age: userInput.age,
                department: userInput.department,
                createdAt: currentTime,
                updatedAt: currentTime
            };

            userStore[userId] = newUser;
            createdUsers.push(newUser);
        }
        return createdUsers;
    }

    resource function delete users/[string id]() returns SuccessResponse|ErrorResponse {
        if userStore.hasKey(id) {
            _ = userStore.remove(id);
            return {
                message: "User deleted successfully",
                data: {"deletedId": id}
            };
        } else {
            return {
                message: "User not found",
                code: "USER_NOT_FOUND",
                timestamp: time:utcToString(time:utcNow())
            };
        }
    }

    resource function delete users(string? confirm) returns SuccessResponse|ErrorResponse {
        if confirm != "yes" {
            return {
                message: "To delete all users, add query parameter: confirm=yes",
                code: "CONFIRMATION_REQUIRED",
                timestamp: time:utcToString(time:utcNow())
            };
        }

        int deletedCount = userStore.length();
        userStore.removeAll();

        return {
            message: "All users deleted successfully",
            data: {"deletedCount": deletedCount}
        };
    }

    resource function patch users/[string id](@http:Payload UserUpdate userUpdate) returns User|ErrorResponse {
        User? existingUser = userStore[id];
        if existingUser is () {
            return {
                message: "User not found",
                code: "USER_NOT_FOUND",
                timestamp: time:utcToString(time:utcNow())
            };
        }
        if userUpdate.email is string {
            foreach User user in userStore {
                if user.id != id && user.email == userUpdate.email {
                    return {
                        message: "User with this email already exists",
                        code: "DUPLICATE_EMAIL",
                        timestamp: time:utcToString(time:utcNow())
                    };
                }
            }
        }

        if userUpdate.age is int && (userUpdate.age < 0 || userUpdate.age > 150) {
            return {
                message: "Age must be between 0 and 150",
                code: "INVALID_INPUT",
                timestamp: time:utcToString(time:utcNow())
            };
        }

        User updatedUser = {
            id: existingUser.id,
            name: userUpdate.name ?: existingUser.name,
            email: userUpdate.email ?: existingUser.email,
            age: userUpdate.age ?: existingUser.age,
            department: userUpdate.department ?: existingUser.department,
            createdAt: existingUser.createdAt,
            updatedAt: time:utcToString(time:utcNow())
        };

        userStore[id] = updatedUser;
        return updatedUser;
    }

    resource function patch users/department/[string oldDept]/[string newDept]() returns SuccessResponse|ErrorResponse {
        int updatedCount = 0;
        string currentTime = time:utcToString(time:utcNow());

        foreach string userId in userStore.keys() {
            User user = userStore.get(userId);
            if user.department == oldDept {
                User updatedUser = {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    age: user.age,
                    department: newDept,
                    createdAt: user.createdAt,
                    updatedAt: currentTime
                };
                userStore[userId] = updatedUser;
                updatedCount += 1;
            }
        }
        return {
            message: "Department updated successfully",
            data: {
                "oldDepartment": oldDept,
                "newDepartment": newDept,
                "updatedCount": updatedCount
            }
        };
    }

    resource function default [string... path](http:Request req) returns string {
        return "done";
    }

    resource function get callerInf(@http:CallerInfo Caller abc) returns string {
        return "Caller ID: " + abc.id.toString();
    }

    resource function get callerErr1(@http:CallerInfo string abc) returns string {
        return "Invalid caller info type";
    }

    resource function post callerErr2(@http:CallerInfo @http:Payload Caller abc) returns string {
        return "Invalid annotation combination";
    }

    resource function get callerErr3(@http:CallerInfo Caller abc) returns string {
        return "Caller test: " + abc.id.toString();
    }
}
