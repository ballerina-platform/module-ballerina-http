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

type IntHeaders record {|
    int user\-id;
    int req\-id;
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

final http:Client albumClient = check new (string `localhost:${statusCodeBindingPort2}/api`);

@test:Config {}
function testGetSuccessStatusCodeResponse() returns error? {
    Album album = check albumClient->/albums/'1;
    Album expectedAlbum = albums.get("1");
    test:assertEquals(album, expectedAlbum, "Invalid album returned");

    AlbumFound albumFound = check albumClient->get("/albums/1");
    test:assertEquals(albumFound.body, expectedAlbum, "Invalid album returned");
    test:assertEquals(albumFound.headers.user\-id, "user-1", "Invalid user-id header");
    test:assertEquals(albumFound.headers.req\-id, 1, "Invalid req-id header");
    test:assertEquals(albumFound.mediaType, "application/json", "Invalid media type");

    http:Response res = check albumClient->/albums/'1;
    test:assertEquals(res.statusCode, 200, "Invalid status code");
    json payload = check res.getJsonPayload();
    album = check payload.fromJsonWithType();
    test:assertEquals(album, expectedAlbum, "Invalid album returned");

    Album|AlbumFound res1 = check albumClient->get("/albums/1");
    if res1 is AlbumFound {
        test:assertEquals(res1.body, expectedAlbum, "Invalid album returned");
        test:assertEquals(res1.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res1.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res1.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumFound|Album res2 = check albumClient->/albums/'1;
    if res2 is AlbumFound {
        test:assertEquals(res2.body, expectedAlbum, "Invalid album returned");
        test:assertEquals(res2.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res2.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res2.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    Album|AlbumNotFound res3 = check albumClient->get("/albums/1");
    if res3 is Album {
        test:assertEquals(res3, expectedAlbum, "Invalid album returned");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumFound|AlbumNotFound res4 = check albumClient->/albums/'1;
    if res4 is AlbumFound {
        test:assertEquals(res4.body, expectedAlbum, "Invalid album returned");
        test:assertEquals(res4.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res4.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res4.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    Album|AlbumFound|AlbumNotFound res5 = check albumClient->get("/albums/1");
    if res5 is AlbumFound {
        test:assertEquals(res5.body, expectedAlbum, "Invalid album returned");
        test:assertEquals(res5.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res5.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res5.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    Album|AlbumNotFound|http:Response res6 = check albumClient->/albums/'1;
    if res6 is Album {
        test:assertEquals(res6, expectedAlbum, "Invalid album returned");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumNotFound|http:Response res7 = check albumClient->get("/albums/1");
    if res7 is http:Response {
        test:assertEquals(res.statusCode, 200, "Invalid status code");
        payload = check res.getJsonPayload();
        album = check payload.fromJsonWithType();
        test:assertEquals(album, expectedAlbum, "Invalid album returned");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumNotFound|error res8 = albumClient->/albums/'1;
    if res8 is error {
        test:assertTrue(res8 is http:PayloadBindingError);
        test:assertEquals(res8.message(), "incompatible http_client_tests:AlbumNotFound found for response with 200",
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

    http:Response res = check albumClient->get("/albums/4");
    test:assertEquals(res.statusCode, 404, "Invalid status code");
    json payload = check res.getJsonPayload();
    ErrorMessage errorMessage = check payload.fromJsonWithType();
    test:assertEquals(errorMessage, expectedErrorMessage, "Invalid error message");

    Album|AlbumNotFound res1 = check albumClient->/albums/'4;
    if res1 is AlbumNotFound {
        test:assertEquals(res1.body, expectedErrorMessage, "Invalid error message");
        test:assertEquals(res1.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res1.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res1.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumNotFound|http:Response res2 = check albumClient->get("/albums/4");
    if res2 is AlbumNotFound {
        test:assertEquals(res2.body, expectedErrorMessage, "Invalid error message");
        test:assertEquals(res2.headers.user\-id, "user-1", "Invalid user-id header");
        test:assertEquals(res2.headers.req\-id, 1, "Invalid req-id header");
        test:assertEquals(res2.mediaType, "application/json", "Invalid media type");
    } else {
        test:assertFail("Invalid response type");
    }

    Album|http:Response res3 = check albumClient->/albums/'4;
    if res3 is http:Response {
        test:assertEquals(res3.statusCode, 404, "Invalid status code");
        payload = check res3.getJsonPayload();
        errorMessage = check payload.fromJsonWithType();
        test:assertEquals(errorMessage, expectedErrorMessage, "Invalid error message");
    } else {
        test:assertFail("Invalid response type");
    }

    http:Response|AlbumFound res4 = check albumClient->get("/albums/4");
    if res4 is http:Response {
        test:assertEquals(res4.statusCode, 404, "Invalid status code");
        payload = check res4.getJsonPayload();
        errorMessage = check payload.fromJsonWithType();
        test:assertEquals(errorMessage, expectedErrorMessage, "Invalid error message");
    } else {
        test:assertFail("Invalid response type");
    }

    Album|error res5 = albumClient->/albums/'4;
    if res5 is error {
        test:assertTrue(res5 is http:ClientRequestError);
        test:assertEquals(res5.message(), "Not Found", "Invalid error message");
        test:assertEquals(res5.detail()["statusCode"], 404, "Invalid status code");
        test:assertEquals(res5.detail()["body"], expectedErrorMessage, "Invalid error message");
        if res5.detail()["headers"] is map<string[]> {
            map<string[]> headers = check res5.detail()["headers"].ensureType();
            test:assertEquals(headers.get("user-id")[0], "user-1", "Invalid user-id header");
            test:assertEquals(headers.get("req-id")[0], "1", "Invalid req-id header");
        }

    } else {
        test:assertFail("Invalid response type");
    }

    AlbumFound|error res6 = albumClient->get("/albums/4");
    if res6 is error {
        test:assertTrue(res6 is http:ClientRequestError);
        test:assertEquals(res6.message(), "Not Found", "Invalid error message");
        test:assertEquals(res6.detail()["statusCode"], 404, "Invalid status code");
        test:assertEquals(res6.detail()["body"], expectedErrorMessage, "Invalid error message");
        if res6.detail()["headers"] is map<string[]> {
            map<string[]> headers = check res6.detail()["headers"].ensureType();
            test:assertEquals(headers.get("user-id")[0], "user-1", "Invalid user-id header");
            test:assertEquals(headers.get("req-id")[0], "1", "Invalid req-id header");
        }

    } else {
        test:assertFail("Invalid response type");
    }
}

@test:Config {}
function testUnionPayloadBindingWithStatusCodeResponse() returns error? {
    Album|AlbumNotFound|map<json>|json res1 = check albumClient->/albums/'1;
    if res1 is Album {
        test:assertEquals(res1, albums.get("1"), "Invalid album returned");
    } else {
        test:assertFail("Invalid response type");
    }

    map<json>|AlbumNotFound|Album|json res2 = check albumClient->get("/albums/1");
    if res2 is map<json> {
        test:assertEquals(res2, albums.get("1"), "Invalid album returned");
    } else {
        test:assertFail("Invalid response type");
    }

    Album|MockAlbum|AlbumNotFound res3 = check albumClient->/albums/'1;
    if res3 is Album {
        test:assertEquals(res3, albums.get("1"), "Invalid album returned");
    } else {
        test:assertFail("Invalid response type");
    }

    MockAlbum|Album|AlbumNotFound res4 = check albumClient->get("/albums/1");
    if res4 is MockAlbum {
        test:assertEquals(res4, {...albums.get("1"), "type": "mock"}, "Invalid album returned");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumUnion1|AlbumNotFound res5 = check albumClient->/albums/'1;
    if res5 is Album {
        test:assertEquals(res5, albums.get("1"), "Invalid album returned");
    } else {
        test:assertFail("Invalid response type");
    }

    AlbumUnion2|AlbumNotFound res6 = check albumClient->get("/albums/1");
    if res6 is MockAlbum {
        test:assertEquals(res6, {...albums.get("1"), "type": "mock"}, "Invalid album returned");
    } else {
        test:assertFail("Invalid response type");
    }

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

    record {|*http:Ok; IntHeaders headers;|}|error res3 = albumClient->/albums/'1;
    if res3 is error {
        test:assertTrue(res3 is http:HeaderBindingError);
        test:assertEquals(res3.message(), "header binding failed for parameter: 'user-id'", "Invalid error message");
    } else {
        test:assertFail("Invalid response type");
    }
}
