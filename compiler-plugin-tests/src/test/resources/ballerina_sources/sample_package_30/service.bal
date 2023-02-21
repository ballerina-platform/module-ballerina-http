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

public enum Status {
    SUCCESS,
    FAILURE
}

public type NewStatus Status;
public type UpdatedStatus NewStatus;

service / on new http:Listener(9090) {

    resource function get albums(Status status) returns string[] {
        return [];
    }

    resource function get artists(Status status, http:Caller caller) {}

    resource function get songs(Status status1, Status status2, http:Caller caller) {}

    resource function get tracks(Status[] status) returns string {
        return "Track 1";
    }

    resource function get newAlbums(NewStatus status) returns string {
        return "Track 1";
    }

    resource function get newTracks(NewStatus[] status) returns string {
        return "Track 1";
    }

    resource function get updatedAlbums(UpdatedStatus status) returns string {
        return "Track 1";
    }

    resource function get updatedTracks(UpdatedStatus[] status) returns string {
        return "Track 1";
    }
}
