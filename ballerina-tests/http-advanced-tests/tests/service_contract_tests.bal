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

import ballerina/crypto;
import ballerina/http;
import ballerina/http_test_common as common;
import ballerina/test;

final http:Client serviceContractClient = check new (string `localhost:${serviceContractTestPort}/socialMedia`);

service common:Service on new http:Listener(serviceContractTestPort) {

    resource function get users() returns common:User[]|error {
        return [{id: 1, name: "Alice", email: "alice@gmail.com"}, {id: 2, name: "Bob", email: "bob@gmail.com"}];
    }

    resource function get users/[int id]() returns common:User|common:UserNotFound|error {
        return {id: 1, name: "Alice", email: "alice@gmail.com"};
    }

    resource function post users(common:NewUser newUser) returns http:Created|error {
        return {
            body: {
                message: "User created successfully"
            }
        };
    }

    resource function delete users/[int id]() returns http:NoContent|error {
        return http:NO_CONTENT;
    }

    resource function get users/[int id]/posts() returns common:PostWithMeta[]|common:UserNotFound|error {
        return [{id: 1, content: "Content 1", createdAt: "2020-01-01T10:00:00Z"}, {id: 2, content: "Content 2", createdAt: "2020-01-01T10:00:00Z"}];
    }

    resource function post users/[int id]/posts(common:NewPost newPost) returns http:Created|common:UserNotFound|common:PostForbidden|error {
        return error("invalid post");
    }

    public function createInterceptors() returns common:ErrorInterceptor {
        return new ();
    }
}

@test:Config {}
function testCachingWithServiceContract() returns error? {
    http:Response response = check serviceContractClient->/users;
    json payload = [{id: 1, name: "Alice", email: "alice@gmail.com"}, {id: 2, name: "Bob", email: "bob@gmail.com"}];
    test:assertTrue(response.hasHeader(common:LAST_MODIFIED));
    common:assertHeaderValue(check response.getHeader(common:CACHE_CONTROL), "must-revalidate,public,max-age=10");
    common:assertHeaderValue(check response.getHeader(common:ETAG), crypto:crc32b(payload.toString().toBytes()));
    common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), "application/vnd.socialMedia+json");
    common:assertJsonPayload(response.getJsonPayload(), payload);
}

@test:Config {}
function testLinksInServiceContract() returns error? {
    record{*http:Links; *common:User;} response = check serviceContractClient->/users/'2;
    map<http:Link> expectedLinks = {
        "delete-user": {
            href: "/socialMedia/users/{id}",
            types: ["application/vnd.socialMedia+json"],
            methods: [http:DELETE]
        },
        "create-posts": {
            href: "/socialMedia/users/{id}/posts",
            types: ["text/vnd.socialMedia+plain"],
            methods: [http:POST]
        },
        "get-posts": {
            href: "/socialMedia/users/{id}/posts",
            types: ["application/vnd.socialMedia+json", "text/vnd.socialMedia+plain"],
            methods: [http:GET]
        }
    };
    record{} payload = {"id": 1, "name": "Alice", "email": "alice@gmail.com", "_links": expectedLinks};
    test:assertEquals(response, payload);
}

@test:Config {}
function testPayloadAnnotationWithServiceContract() returns error? {
    common:NewUser newUser = {name: "Alice", email: "alice@gmail.com"};
    http:Response response = check serviceContractClient->/users.post(newUser);
    test:assertEquals(response.statusCode, 415);
    common:assertTextPayload(response.getTextPayload(), "content-type : application/json is not supported");

    record{string message;} result = check serviceContractClient->/users.post(newUser, mediaType = "application/vnd.socialMedia+json");
    test:assertEquals(result.message, "User created successfully");
}

@test:Config {}
function testInterceptorWithServiceContract() returns error? {
    common:NewPost newPost = {content: "sample content"};
    http:Response response = check serviceContractClient->/users/'1/posts.post(newPost, mediaType = "application/vnd.socialMedia+json");
    test:assertEquals(response.statusCode, 500);
    common:assertJsonPayload(response.getTextPayload(), "invalid post");

    json invalidPost = {message: "sample content"};
    response = check serviceContractClient->/users/'1/posts.post(invalidPost, mediaType = "application/vnd.socialMedia+json");
    test:assertEquals(response.statusCode, 400);
    common:assertTrueTextPayload(response.getTextPayload(), "data binding failed");
}
