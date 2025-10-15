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

type TemporaryRedirect record {|
    *http:TemporaryRedirect;
    string body;
|};

service / on new http:Listener(8080) {
    resource function get path/[string location]() returns http:TemporaryRedirect {
        return {
            headers: {
                "Location": location
            }
        };
    }

    resource function get path(string location) returns TemporaryRedirect {
        return {
            body: "Redirection",
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

    resource function head .(Payload 'payload) returns json|http:MovedPermanently => <http:MovedPermanently>{
        headers: {
            "Location": payload["location"]
        }
    };

    resource function post negative1(@http:Header string location) returns http:TemporaryRedirect {
        string _ = location;
        return {
            headers: {
                "Location": "location"
            }
        };
    }

    resource function post negative2(Payload payload\-param) returns json|http:TemporaryRedirect {
        return <json>{
            headers: {
                "Location": payload\-param.location
            }
        };
    }

    resource function post negative3(Payload payload) {
    }

    resource function post negative4() {
        string _ = "location";
    }

    resource function post negative5() returns http:TemporaryRedirect? {
    }

    resource function post negative6(@http:Header string location) returns http:TemporaryRedirect {
        http:TemporaryRedirect res = {
            headers: {
                "Location": location
            }
        };
        return res;
    }

    resource function post negative7(@http:Header string location) returns http:TemporaryRedirect {
        map<string> headers = {
            "Location": location
        };
        return {
            headers: headers
        };
    }

    resource function get negative8(string location) returns TemporaryRedirect {
        string HEADERS = "headers";
        return {
            body: "Redirection",
            [HEADERS]: {
                "Location": location
            }
        };
    }

    resource function get negative9(string location) returns TemporaryRedirect {
        TemporaryRedirect res = {
            body: "Redirection",
            headers: {
                Location: location
            }
        };
        return {
            ...res
        };
    }

    resource function get negative10(string location) returns TemporaryRedirect {
        map<string> headers = {
            "Location": location
        };
        return {
            body: "Redirection",
            headers
        };
    }

    resource function get negative11(string location) returns TemporaryRedirect {
        string loc = location;
        return {
            body: "Redirection",
            headers: {
                "Location": loc
            }
        };
    }
}
