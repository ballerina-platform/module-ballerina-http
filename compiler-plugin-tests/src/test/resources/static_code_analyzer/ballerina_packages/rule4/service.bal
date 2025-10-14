// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.org)
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

type Payload record {
    string location;
};

type RedirectResponse http:MovedPermanently|http:TemporaryRedirect|json;

service / on new http:Listener(8080) {
    resource function get .(string location) returns http:TemporaryRedirect {
        return {
            headers: {
                "Location": location
            }
        };
    }

    resource function post .(Payload payload) returns json|http:TemporaryRedirect {
        return <http:TemporaryRedirect>{
            headers: {
                "Location": payload.location
            }
        };
    }

    resource function patch .(Payload payload\-param) returns json|http:TemporaryRedirect {
        return <http:TemporaryRedirect>{
            headers: {
                "Location": payload\-param.location
            }
        };
    }

    resource function put .(Payload 'payload) returns json|http:MovedPermanently {
        return <http:MovedPermanently>{
            headers: {
                "Location": payload["location"]
            }
        };
    }

    resource function custom .(string 'type, string location = "location") returns RedirectResponse {
        match 'type {
            "moved" => {
                return <http:MovedPermanently>{
                    headers: {
                        "Location": location
                    }
                };
            }
            "temporary" => {
                return <http:TemporaryRedirect>{
                    headers: {
                        "Location": location
                    }
                };
            }
            _ => {
                return {message: "Invalid type"};
            }
        }
    }

    resource function put12 .(Payload 'payload) returns json|http:MovedPermanently => <http:MovedPermanently>{
        headers: {
            "Location": payload["location"]
        }
    };

    resource function post negative(@http:Header string location) returns http:TemporaryRedirect {
        return {
            headers: {
                "Location": "location"
            }
        };
    }
}
