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
import ballerina/test;

public enum Status {
    OLD,
    NEW
}

public enum GENRE {
    ROCK,
    POP
}

public type NewStatus Status;
public type UpdatedStatus NewStatus;

service /enumQueryParam on generalListener {
    resource function get album(Status status) returns string {
        if status is OLD {
            return "Old album";
        }
        return "New album";
    }

    resource function get artist(Status status, GENRE genre) returns string {
            if status is OLD && genre is ROCK {
                return "Old & Rock Artist";
            }
            return "Unknown Artist";
        }

    resource function get song(Status[] status) returns string {
        if status[0] is OLD && status[1] is NEW {
            return "Old & New Song";
        }
        return "Unknown Song";
    }

    resource function get newSong(NewStatus newStatus) returns string {
        if newStatus is OLD {
            return "Old Song";
        }
        return "Unknown Song";
    }

    resource function get updatedSong(UpdatedStatus updatedStatus) returns string {
        if updatedStatus is OLD {
            return "Old Song";
        }
        return "Unknown Song";
    }
}

@test:Config {}
function testEnumTypeForQueryParam() returns error? {
    http:Client 'client = check new("http://localhost:9000");
    string response = check 'client->get("/enumQueryParam/album?status=OLD");
    test:assertEquals(response, "Old album");
}

@test:Config {}
function testMulitpleEnumsForQueryParam() returns error? {
    http:Client 'client = check new("http://localhost:9000");
    string response = check 'client->get("/enumQueryParam/artist?status=OLD&genre=ROCK");
    test:assertEquals(response, "Old & Rock Artist");
}

@test:Config {}
function testEnumArrayTypeForQueryParam() returns error? {
    http:Client 'client = check new("http://localhost:9000");
    string response = check 'client->get("/enumQueryParam/song?status=OLD&status=NEW");
    test:assertEquals(response, "Old & New Song");
}

@test:Config {}
function testReferredEnumTypeForQueryParam() returns error? {
    http:Client 'client = check new("http://localhost:9000");
    string response = check 'client->get("/enumQueryParam/newSong?newStatus=OLD");
    test:assertEquals(response, "Old Song");
}

@test:Config {}
function testNestedReferredEnumTypeForQueryParam() returns error? {
    http:Client 'client = check new("http://localhost:9000");
    string response = check 'client->get("/enumQueryParam/updatedSong?updatedStatus=OLD");
    test:assertEquals(response, "Old Song");
}

@test:Config {}
function testNestedReferredInvalidEnumTypeForQueryParam() returns error? {
    http:Client 'client = check new("http://localhost:9000");
    http:Response response = check 'client->get("/enumQueryParam/updatedSong?updatedStatus=Unknown");
    test:assertEquals(response.statusCode, 400, "Unexpected response status code");
}

@test:Config {}
function testInvalidParamForEnumQueryParam() returns error? {
    http:Client 'client = check new("http://localhost:9000");
    http:Response response = check 'client->get("/enumQueryParam/album?status=UNKNOWN");
    test:assertEquals(response.statusCode, 400, "Unexpected response status code");
}

@test:Config {}
function testInvalidParamForSecondEnumQueryParam() returns error? {
    http:Client 'client = check new("http://localhost:9000");
    http:Response response = check 'client->get("/enumQueryParam/artist?status=OLD&genre=HIPHOP");
    test:assertEquals(response.statusCode, 400, "Unexpected response status code");
}

@test:Config {}
function testInvalidParamForEnumArrayQueryParam() returns error? {
    http:Client 'client = check new("http://localhost:9000");
    http:Response response = check 'client->get("/enumQueryParam/song?status=UNKNOWN&status=NEW");
    test:assertEquals(response.statusCode, 400, "Unexpected response status code");
}
