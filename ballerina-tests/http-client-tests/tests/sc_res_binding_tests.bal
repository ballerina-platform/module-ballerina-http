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

import ballerina/constraint;
import ballerina/http;
import ballerina/test;

type Album record {|
    readonly string id;
    string name;
    string artist;
    string genre;
|};

type MockAlbum record {|
    *Album;
    string 'type = "mock";
|};

type AlbumUnion1 Album|MockAlbum;

type AlbumUnion2 MockAlbum|Album;

table<Album> key(id) albums = table [
    {id: "1", name: "The Dark Side of the Moon", artist: "Pink Floyd", genre: "Progressive Rock"},
    {id: "2", name: "Back in Black", artist: "AC/DC", genre: "Hard Rock"},
    {id: "3", name: "The Wall", artist: "Pink Floyd", genre: "Progressive Rock"}
];

type ErrorMessage record {|
    string albumId;
    string message;
|};

type Headers record {|
    string user\-id;
    int req\-id;
|};

type ArrayHeaders record {|
    string[] user\-id;
    int[] req\-id;
|};

type ArrayHeaderWithUnion record {|
    string[]|int[] user\-id;
    int[]|boolean[] req\-id;
|};

type ReqIdUnionType int|boolean[];

enum UserIds {
    USER1 = "user-1",
    USER2 = "user-2",
    USER3 = "user-3"
}

type ArrayHeaderWithTypes record {|
    UserIds user\-id;
    ReqIdUnionType req\-id;
|};

type IntHeaders record {|
    int user\-id;
    int req\-id;
|};

type AdditionalHeaders record {|
    string user\-id;
    int req\-id;
    string content\-type;
|};

type AdditionalMissingHeaders record {|
    string user\-id;
    int req\-id;
    string x\-content\-type;
|};

type AdditionalOptionalHeaders record {|
    string user\-id;
    int req\-id;
    string x\-content\-type?;
|};

type AlbumNotFound record {|
    *http:NotFound;
    ErrorMessage body;
    Headers headers;
|};

type AlbumFound record {|
    *http:Ok;
    Album body;
    Headers headers;
|};

type AlbumFoundMock1 record {|
    *http:Ok;
    Album|MockAlbum body;
    Headers headers;
|};

type AlbumFoundMock2 record {|
    *http:Ok;
    AlbumUnion1 body;
    Headers headers;
|};

type AlbumFoundMock3 record {|
    *http:Ok;
    AlbumUnion2 body;
    Headers headers;
|};

type AlbumInvalid record {|
    *Album;
    string invalidField;
|};

type AlbumFoundInvalid record {|
    *http:Ok;
    AlbumInvalid body;
    Headers headers;
|};

enum AllowedMediaTypes {
    APPLICATION_JSON = "application/json",
    APPLICATION_XML = "application/xml"
}

@constraint:String {pattern: re `application/json|application/xml`}
type MediaTypeWithConstraint string;

type AlbumFoundWithConstraints record {|
    *http:Ok;
    record {|
        @constraint:String {minLength: 1, maxLength: 10}
        string id;
        string name;
        string artist;
        @constraint:String {pattern: re `Hard Rock|Progressive Rock`}
        string genre;
    |} body;
    record {|
        @constraint:String {minLength: 1, maxLength: 10}
        string user\-id;
        @constraint:Int {minValue: 1, maxValue: 10}
        int req\-id;
    |} headers;
    MediaTypeWithConstraint mediaType;
|};

type AlbumFoundWithInvalidConstraints1 record {|
    *http:Ok;
    record {|
        @constraint:String {minLength: 1, maxLength: 10}
        string id;
        string name;
        string artist;
        @constraint:String {pattern: re `Hard-Rock|Progressive-Rock`}
        string genre;
    |} body;
    record {|
        @constraint:String {minLength: 1, maxLength: 10}
        string user\-id;
        @constraint:Int {minValue: 1, maxValue: 10}
        int req\-id;
    |} headers;
    MediaTypeWithConstraint mediaType;
|};

type AlbumFoundWithInvalidConstraints2 record {|
    *http:Ok;
    record {|
        @constraint:String {minLength: 1, maxLength: 10}
        string id;
        string name;
        string artist;
        @constraint:String {pattern: re `Hard Rock|Progressive Rock`}
        string genre;
    |} body;
    record {|
        @constraint:String {minLength: 1, maxLength: 10}
        string user\-id;
        @constraint:Int {minValue: 10}
        int req\-id;
    |} headers;
    MediaTypeWithConstraint mediaType;
|};

@constraint:String {pattern: re `application+org/json|application/xml`}
type MediaTypeWithInvalidPattern string;

type AlbumFoundWithInvalidConstraints3 record {|
    *http:Ok;
    record {|
        @constraint:String {minLength: 1, maxLength: 10}
        string id;
        string name;
        string artist;
        @constraint:String {pattern: re `Hard Rock|Progressive Rock`}
        string genre;
    |} body;
    record {|
        @constraint:String {minLength: 1, maxLength: 10}
        string user\-id;
        @constraint:Int {minValue: 1, maxValue: 10}
        int req\-id;
    |} headers;
    MediaTypeWithInvalidPattern mediaType;
|};

service /api on new http:Listener(statusCodeBindingPort2) {

    resource function get albums/[string id]() returns AlbumFound|AlbumNotFound {
        if albums.hasKey(id) {
            return {
                body: albums.get(id),
                headers: {user\-id: "user-1", req\-id: 1}
            };
        }
        return {
            body: {albumId: id, message: "Album not found"},
            headers: {user\-id: "user-1", req\-id: 1}
        };
    }
}

final http:StatusCodeClient albumClient = check new (string `localhost:${statusCodeBindingPort2}/api`);

@test:Config {}
function testGetSuccessStatusCodeResponse() returns error? {
    AlbumFound albumFound = check albumClient->get("/albums/1");
    Album expectedAlbum = albums.get("1");
    test:assertEquals(albumFound.body, expectedAlbum, "Invalid album returned");
    test:assertEquals(albumFound.headers.user\-id, "user-1", "Invalid user-id header");
    test:assertEquals(albumFound.headers.req\-id, 1, "Invalid req-id header");
    test:assertEquals(albumFound.mediaType, "application/json", "Invalid media type");

    AlbumFound|AlbumNotFound res4 = check albumClient->/albums/'1;
    if res4 is AlbumFound {
        test:assertEquals(res4.body, expectedAlbum, "Invalid album returned");
        test:assertEquals(res4.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res4.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res4.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumNotFound|error res8 = albumClient->/albums/'1;
    if res8 is error {
        test:assertTrue(res8 is http:StatusCodeResponseBindingError);
        test:assertEquals(res8.message(), "incompatible AlbumNotFound found for response with 200",
            "Invalid error message");
        error? cause = res8.cause();
        if cause is error {
            test:assertEquals(cause.message(), "no 'anydata' type found in the target type", "Invalid cause error message");
        }
    } else {
        test:assertFail("Invalid response type");
    }
}

@test:Config {}
function testGetFailureStatusCodeResponse() returns error? {
    AlbumNotFound albumNotFound = check albumClient->/albums/'4;
    ErrorMessage expectedErrorMessage = {albumId: "4", message: "Album not found"};
    test:assertEquals(albumNotFound.body, expectedErrorMessage, "Invalid error message");
    test:assertEquals(albumNotFound.headers.user\-id, "user-1", "Invalid user-id header");
    test:assertEquals(albumNotFound.headers.req\-id, 1, "Invalid req-id header");
    test:assertEquals(albumNotFound.mediaType, "application/json", "Invalid media type");

    AlbumFound|error res6 = albumClient->get("/albums/4");
    if res6 is error {
        test:assertTrue(res6 is http:ClientRequestError);
        test:assertTrue(res6 is http:StatusCodeResponseBindingError);
        test:assertEquals(res6.message(), "incompatible AlbumFound found for response with 404", "Invalid error message");
        test:assertEquals(res6.detail()["statusCode"], 404, "Invalid status code");
        test:assertEquals(res6.detail()["body"], expectedErrorMessage, "Invalid error message");
        if res6.detail()["headers"] is map<string[]> {
            map<string[]> headers = check res6.detail()["headers"].ensureType();
            test:assertEquals(headers.get("user-id")[0], "user-1", "Invalid user-id header");
            test:assertEquals(headers.get("req-id")[0], "1", "Invalid req-id header");
        } else {
            test:assertFail("Invalid headers type");
        }
    } else {
        test:assertFail("Invalid response type");
    }
}

@test:Config {}
function testUnionPayloadBindingWithStatusCodeResponse() returns error? {
    AlbumFound|AlbumNotFound|AlbumFoundMock1 res7 = check albumClient->/albums/'1;
    if res7 is AlbumFound {
        test:assertEquals(res7.body, albums.get("1"), "Invalid album returned");
        test:assertEquals(res7.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res7.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res7.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumFoundMock1|AlbumFound|AlbumNotFound res8 = check albumClient->get("/albums/1");
    if res8 is AlbumFoundMock1 {
        test:assertEquals(res8.body, albums.get("1"), "Invalid album returned");
        test:assertEquals(res8.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res8.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res8.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumFoundMock2|AlbumFound|AlbumFoundMock1|AlbumNotFound res9 = check albumClient->/albums/'1;
    if res9 is AlbumFoundMock2 {
        test:assertEquals(res9.body, albums.get("1"), "Invalid album returned");
        test:assertEquals(res9.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res9.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res9.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumFoundMock3|AlbumFound|AlbumFoundMock1|AlbumFoundMock2|AlbumNotFound res10 = check albumClient->get("/albums/1");
    if res10 is AlbumFoundMock3 {
        test:assertEquals(res10.body, {...albums.get("1"), "type": "mock"}, "Invalid album returned");
        test:assertEquals(res10.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res10.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res10.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumFoundInvalid|AlbumFound|AlbumNotFound|error res11 = albumClient->/albums/'1;
    if res11 is error {
        test:assertTrue(res11 is http:PayloadBindingError);
        test:assertTrue(res11.message().includes("Payload binding failed: 'map<json>' value cannot be" +
        " converted to 'http_client_tests:AlbumInvalid"), "Invalid error message");
    } else {
        test:assertFail("Invalid response type");
    }
}

@test:Config {}
function testStatusCodeBindingWithDifferentHeaders() returns error? {
    record {|*http:Ok; ArrayHeaders headers;|} res1 = check albumClient->/albums/'1;
    test:assertEquals(res1?.body, albums.get("1"), "Invalid album returned");
    test:assertEquals(res1.headers.user\-id, ["user-1"], "Invalid user-id header");
    test:assertEquals(res1.headers.req\-id, [1], "Invalid req-id header");
    test:assertEquals(res1.mediaType, "application/json", "Invalid media type");

    record {|*http:Ok; ArrayHeaderWithUnion headers;|} res2 = check albumClient->/albums/'1;
    test:assertEquals(res2?.body, albums.get("1"), "Invalid album returned");
    test:assertEquals(res2.headers.user\-id, ["user-1"], "Invalid user-id header");
    test:assertEquals(res2.headers.req\-id, [1], "Invalid req-id header");
    test:assertEquals(res2.mediaType, "application/json", "Invalid media type");

    record {|*http:Ok; ArrayHeaderWithTypes headers;|} res3 = check albumClient->/albums/'1;
    test:assertEquals(res3?.body, albums.get("1"), "Invalid album returned");
    test:assertEquals(res3.headers.user\-id, USER1, "Invalid user-id header");
    test:assertEquals(res3.headers.req\-id, 1, "Invalid req-id header");
    test:assertEquals(res3.mediaType, "application/json", "Invalid media type");

    record {|*http:Ok; IntHeaders headers;|}|error res4 = albumClient->/albums/'1;
    if res4 is error {
        test:assertTrue(res4 is http:HeaderBindingError);
        test:assertEquals(res4.message(), "header binding failed for parameter: 'user-id'", "Invalid error message");
    } else {
        test:assertFail("Invalid response type");
    }

    record {|*http:Ok; AdditionalHeaders headers;|} res5 = check albumClient->/albums/'1;
    test:assertEquals(res5?.body, albums.get("1"), "Invalid album returned");
    test:assertEquals(res5.headers.user\-id, "user-1", "Invalid user-id header");
    test:assertEquals(res5.headers.req\-id, 1, "Invalid req-id header");
    test:assertEquals(res5.headers.content\-type, "application/json", "Invalid content-type header");
    test:assertEquals(res5.mediaType, "application/json", "Invalid media type");

    record {|*http:Ok; AdditionalMissingHeaders headers;|}|error res6 = albumClient->/albums/'1;
    if res6 is error {
        test:assertTrue(res6 is http:HeaderNotFoundError);
        test:assertEquals(res6.message(), "no header value found for 'x-content-type'", "Invalid error message");
    } else {
        test:assertFail("Invalid response type");
    }

    record {|*http:Ok; AdditionalOptionalHeaders headers;|} res7 = check albumClient->/albums/'1;
    test:assertEquals(res7?.body, albums.get("1"), "Invalid album returned");
    test:assertEquals(res7.headers.user\-id, "user-1", "Invalid user-id header");
    test:assertEquals(res7.headers.req\-id, 1, "Invalid req-id header");
    test:assertEquals(res7.headers.x\-content\-type, (), "Invalid x-content-type header");
    test:assertEquals(res7.mediaType, "application/json", "Invalid media type");
}

@test:Config {}
function testStatusCodeBindingWithMediaTypes() returns error? {
    record {|*http:Ok; "application/json" mediaType;|} res1 = check albumClient->/albums/'1;
    test:assertEquals(res1?.body, albums.get("1"), "Invalid album returned");
    test:assertEquals(res1.mediaType, "application/json", "Invalid media type");
    map<string|int|boolean|string[]|int[]|boolean[]> headers = res1.headers ?: {};
    test:assertEquals(headers.get("user-id"), "user-1", "Invalid user-id header");
    test:assertEquals(headers.get("req-id"), "1", "Invalid req-id header");

    record {|*http:Ok; "application/xml"|"application/json" mediaType;|} res2 = check albumClient->/albums/'1;
    test:assertEquals(res2?.body, albums.get("1"), "Invalid album returned");
    test:assertEquals(res2.mediaType, "application/json", "Invalid media type");
    headers = res2.headers ?: {};
    test:assertEquals(headers.get("user-id"), "user-1", "Invalid user-id header");
    test:assertEquals(headers.get("req-id"), "1", "Invalid req-id header");

    record {|*http:Ok; AllowedMediaTypes mediaType;|} res3 = check albumClient->/albums/'1;
    test:assertEquals(res3?.body, albums.get("1"), "Invalid album returned");
    test:assertEquals(res3.mediaType, APPLICATION_JSON, "Invalid media type");
    headers = res3.headers ?: {};
    test:assertEquals(headers.get("user-id"), "user-1", "Invalid user-id header");
    test:assertEquals(headers.get("req-id"), "1", "Invalid req-id header");

    record {|*http:Ok; "application/xml" mediaType;|}|error res4 = albumClient->/albums/'1;
    if res4 is error {
        test:assertTrue(res4 is http:MediaTypeBindingError);
        test:assertEquals(res4.message(), "media-type binding failed", "Invalid error message");
    } else {
        test:assertFail("Invalid response type");
    }
}

@test:Config {}
function testStatusCodeBindingWithConstraintsSuccess() returns error? {
    AlbumFoundWithConstraints res1 = check albumClient->/albums/'2;
    test:assertEquals(res1.body, albums.get("2"), "Invalid album returned");
    test:assertEquals(res1.headers.user\-id, "user-1", "Invalid user-id header");
    test:assertEquals(res1.headers.req\-id, 1, "Invalid req-id header");
    test:assertEquals(res1.mediaType, "application/json", "Invalid media type");

    AlbumFoundWithConstraints|AlbumFound res2 = check albumClient->get("/albums/2");
    if res2 is AlbumFoundWithConstraints {
        test:assertEquals(res2.body, albums.get("2"), "Invalid album returned");
        test:assertEquals(res2.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res2.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res2.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumFound|AlbumFoundWithConstraints res3 = check albumClient->/albums/'2;
    if res3 is AlbumFound {
        test:assertEquals(res3.body, albums.get("2"), "Invalid album returned");
        test:assertEquals(res3.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res3.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res3.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }
}

@test:Config {}
function testStatusCodeBindingWithConstraintsFailure() returns error? {
    AlbumFoundWithInvalidConstraints1|error res1 = albumClient->/albums/'2;
    if res1 is error {
        test:assertTrue(res1 is http:PayloadValidationError);
        test:assertEquals(res1.message(), "payload validation failed: Validation failed for " +
        "'$.genre:pattern' constraint(s).", "Invalid error message");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumFoundWithInvalidConstraints2|AlbumFound|error res2 = albumClient->get("/albums/2");
    if res2 is error {
        test:assertTrue(res2 is http:HeaderValidationError);
        test:assertEquals(res2.message(), "header binding failed: Validation failed for " +
        "'$.req-id:minValue' constraint(s).", "Invalid error message");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumFoundWithInvalidConstraints3|error res3 = albumClient->/albums/'2;
    if res3 is error {
        test:assertTrue(res3 is http:MediaTypeValidationError);
        test:assertEquals(res3.message(), "media-type binding failed: Validation failed for " +
        "'$:pattern' constraint(s).", "Invalid error message");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumFound|AlbumFoundWithInvalidConstraints1|error res4 = albumClient->get("/albums/2");
    if res4 is AlbumFound {
        test:assertEquals(res4.body, albums.get("2"), "Invalid album returned");
        test:assertEquals(res4.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res4.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res4.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }
}
