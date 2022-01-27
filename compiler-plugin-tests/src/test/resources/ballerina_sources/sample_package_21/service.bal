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

// Positive Cases

type NewAlbum record {|
    string id;
    string title;
    string artist;
    decimal price;
|};

type Album readonly & record {|
    string id;
    string title;
    string artist;
    decimal price;
|};

// albums table to seed record album data.
table<Album> key(id) store = table [
    {id: "1", title: "Blue Train", artist: "John Coltrane", price: 56.99},
    {id: "2", title: "Jeru", artist: "Gerry Mulligan", price: 17.99},
    {id: "3", title: "Sarah Vaughan and Clifford Brown", artist: "Sarah Vaughan", price: 39.99}
];

service / on new http:Listener(8080) {
    resource function post album(@http:Payload Album album) returns Album {
        store.add(album);
        return album;
    }

    resource function post batchUpdate(@http:Payload Album[] albums) returns Album[] {
        foreach Album album in albums {
            store.add(album);
        }
        return albums;
    }
}

service / on new http:Listener(8090) {
    resource function post album(@http:Payload readonly & NewAlbum album) returns string {
        return "album";
    }

    resource function post albumArray(@http:Payload readonly & NewAlbum[] albums) returns string {
        return "albumArray";
    }

    resource function post byteArray(@http:Payload readonly & byte[] albums) returns string {
        return "byteArray";
    }

    resource function post readonlyString(@http:Payload readonly & string album) returns string {
        return "string";
    }

    resource function post readonlyJson(@http:Payload readonly & json album) returns string {
        return "json";
    }

    resource function post readonlyXml(@http:Payload readonly & xml album) returns string {
        return "xml";
    }

    resource function post readonlyMapString(@http:Payload readonly & map<string> album) returns string {
        return "mapOfString";
    }

    resource function post inlineRecord(@http:Payload record {|string name; int age;|} person) returns string {
        return "inlineRecord";
    }

    resource function post inlineReadOnlyRecord(@http:Payload readonly & record {|string name; int age;|} person) returns string {
        return "inlineReadOnlyRecord";
    }
}
