// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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

// This is added to test some auto generated code segments.
// Please ignore the indentation.

import ballerina/http;

import ballerina/http;
import ballerina/log;

# The service type that handles the social media API
@http:ServiceConfig {
    mediaTypeSubtypePrefix: "vnd.socialMedia",
    basePath: "/socialMedia"
}
public type Service service object {
    *http:ServiceContract;
    *http:InterceptableService;

    public function createInterceptors() returns ErrorInterceptor;

    # Get all users
    #
    # + return - List of users(`User[]`) or an error
    @http:ResourceConfig {
        name: "users"
    }
    resource function get users() returns @http:Cache {maxAge: 10} User[]|error;

    # Get a user by ID
    #
    # + id - User ID
    # + return - `User` or NotFound response(`UserNotFound`) when the user is not found or an error
    @http:ResourceConfig {
        name: "user",
        linkedTo: [
            {name: "user", method: http:DELETE, relation: "delete-user"},
            {name: "posts", method: http:POST, relation: "create-posts"},
            {name: "posts", method: http:GET, relation: "get-posts"}
        ]
    }
    resource function get users/[int id]() returns User|UserNotFound|error;

    # Create a new user
    #
    # + newUser - New user details(`NewUser`) as payload
    # + return - Created(`http:Created`) response or an error
    @http:ResourceConfig {
        name: "users",
        linkedTo: [
            {name: "user", method: http:GET, relation: "get-user"},
            {name: "user", method: http:DELETE, relation: "delete-user"},
            {name: "posts", method: http:POST, relation: "create-posts"},
            {name: "posts", method: http:GET, relation: "get-posts"}
        ],
        consumes: ["application/vnd.socialMedia+json"]
    }
    resource function post users(NewUser newUser) returns http:Created|error;

    # Delete a user by ID
    #
    # + id - User ID
    # + return - NoContent response(`http:NoContent`) or an error
    @http:ResourceConfig {
        name: "user"
    }
    resource function delete users/[int id]() returns http:NoContent|error;

    # Get all posts of a user
    #
    # + id - User ID
    # + return - List of posts with metadata(`PostWithMeta[]`) or NotFound response(`UserNotFound`) when the user is not found or an error
    @http:ResourceConfig {
        name: "posts"
    }
    resource function get users/[int id]/posts() returns @http:Cache {maxAge: 25} PostWithMeta[]|UserNotFound|error;

    # Create a new post for a user
    #
    # + id - User ID
    # + newPost - New post details(`NewPost`) as payload
    # + return - Created(`http:Created`) response or an error
    @http:ResourceConfig {
        name: "posts",
        linkedTo: [
            {name: "posts", method: http:POST, relation: "create-posts"}
        ],
        consumes: ["application/vnd.socialMedia+json"]
    }
    resource function post users/[int id]/posts(@http:Payload NewPost newPost) returns http:Created|UserNotFound|PostForbidden|error;
};

public isolated service class ErrorInterceptor {
    *http:ResponseErrorInterceptor;

    isolated remote function interceptResponseError(error err, http:Response res, http:RequestContext ctx) returns DefaultResponse {
        log:printError("error occurred", err);
        return {
            body: err.message(),
            status: new (res.statusCode)
        };
    }
}

# Represents a user in the system
#
# + id - user ID
# + name - user name
# + email - user email
public type User record {
    int id;
    string name;
    string email;
};

# Represents a new user
#
# + name - user name
# + email - user email
public type NewUser record {
    string name;
    string email;
};

# Represents a user not found error
#
# + body - error message
public type UserNotFound record {|
    *http:NotFound;
    ErrorMessage body;
|};

# Represents a new post
#
# + content - post content
public type NewPost record {
    string content;
};

# Represents a post with metadata
#
# + id - post ID
# + content - post content
# + createdAt - post creation time
public type PostWithMeta record {
    int id;
    string content;
    string createdAt;
};

# Represents a post forbidden error
#
# + body - error message
public type PostForbidden record {|
    *http:Forbidden;
    ErrorMessage body;
|};

# Represents a default response
#
# + body - response body
public type DefaultResponse record {|
    *http:DefaultStatusCodeResponse;
    ErrorMessage body;
|};

# Represents a error message
public type ErrorMessage string;

service Service on new http:Listener(9090) {

}
