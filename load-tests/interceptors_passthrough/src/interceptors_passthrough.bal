// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

listener http:Listener serverEP = new (9091);

service /passthrough on serverEP {

    isolated resource function get .() returns error? {
        worker A returns error? {check testGetUsers();}
        worker B returns error? {check testGetUser();}
        worker C returns error? {check testPostUser();}
        worker D returns error? {check testNotImplemented();}
        worker E returns error? {check testUnsupportedMediaType();}
        worker F returns error? {check testNotFound();}
        worker G returns error? {check testBadRequest();}
        var results = wait {A, B, C, D, E, F, G};
        foreach var result in results {
            if result is error {
                return result;
            }
        }
    }
}
