// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

type Location record {|
    string name;
    string id;
    string address;
|};

type Locations record {|
    *http:Links;
    Location[] locations;
|};

function areMapsSimilar(map<anydata> target, map<anydata> input) returns boolean {
    foreach string key in target.keys() {
        if !input.hasKey(key) {
            return false;
        }
        if target[key] != input[key] {
            return false;
        }
    }
    return true;
}

final http:Client snowpeakEP = check new("http://snowpeak:9090");

service /passthrough on new http:Listener(9091) {
    resource function get .() returns http:Ok|http:InternalServerError|error {
        Locations locations = check snowpeakEP->get("/snowpeak/locations");
        map<http:Link> links = locations._links;
        map<http:Link> targetLinks = {
            room: {
                href: "/snowpeak/locations/{id}/rooms",
                methods: [http:GET],
                types: ["application/vnd.snowpeak.resort+json"]
            }
        };
        if areMapsSimilar(targetLinks, links) {
            return http:OK;
        }
        return http:INTERNAL_SERVER_ERROR;
    }
}
