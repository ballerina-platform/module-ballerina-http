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
import http_tests.records;

public type TestRecord records:RecordA|records:RecordA;

service /unionReturnType on generalListener {
    resource function get unionResponse() returns TestRecord[] {
        records:RecordA response = {
            capacity: 10,
            elevationgain: 120,
            id: "2",
            name: "Test",
            night: false,
            status: records:HOLD
        };
        return [response];
    }
}

@test:Config {}
function testUnionReturnType() returns error? {
    http:Client 'client = check new("http://localhost:9000");
    TestRecord[] response = check 'client->get("/unionReturnType/unionResponse");
    test:assertEquals(response, [{
        capacity: 10,
        elevationgain: 120,
        id: "2",
        name: "Test",
        night: false,
        status: records:HOLD
    }]);
}
