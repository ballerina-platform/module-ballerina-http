// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

type SupplierInfo record {
    Quote[] quotes?;
};

type Quote record {
    SupplierInfo supplier?;
};

service on new http:Listener(8081) {
    resource function post quotes(@http:Payload Quote quote) returns Quote|error {
        return quote;
    }

    resource function post suppliers(@http:Payload SupplierInfo supplier) returns SupplierInfo|error {
        return supplier;
    }

    resource function post inline(@http:Payload record {string id; SupplierInfo supplier;} request) returns string|error {
        return request.id;
    }
}
