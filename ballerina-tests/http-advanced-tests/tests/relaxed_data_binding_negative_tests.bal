// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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

import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

type Employee record {
    int id;
    string name;
    string address?;
};

type Department record {
    string name;
    int? employeeCount;
};

type Lead record {|
    int id;
    string name;
|};

listener http:Listener laxDataBindingNegativeEP = new (laxDataBindingNegativeTestPort, httpVersion = http:HTTP_2_0);
final http:Client laxNegativeClient = check new ("http://localhost:" + laxDataBindingNegativeTestPort.toString());

service /company on laxDataBindingNegativeEP {

    resource function post test1(Employee employee) returns Employee {
        return employee;
    }

    resource function post test2(Department department) returns Department {
        return department;
    }

    resource function post test3(Lead lead) returns Lead {
        return lead;
    }

    resource function get test4() returns json {
        return {
            "id": 1001,
            "name": "Tharmigan",
            "address": null
        };
    }

    resource function get test5() returns json {
        return {
            "name": "Engineering"
        };
    }

    resource function get test6() returns json {
        return {
            "id": 1001,
            "name": "Danesh",
            "address": "Piliyandala",
            "Experience": 10
        };
    }
}

@test:Config
function testNullForOptionalFieldNegative() returns error? {
    Employee|error response = laxNegativeClient->/company/test1.post({ "id": 1001, "name": "Tharmigan", "address": null});
    if response is http:ClientRequestError {
        common:assertErrorMessage(response, "Bad Request");
    } else {
        test:assertFail("Found unexpected output");
    }
}

@test:Config
function testMissingRequiredFieldNegative() returns error? {
    Department|error response = laxNegativeClient->/company/test2.post({"name": "Tharmigan"});
    if response is http:ClientRequestError {
        common:assertErrorMessage(response, "Bad Request");
    } else {
        test:assertFail("Found unexpected output");
    }
}

@test:Config
function testExtraFieldsIgnoredNegative() returns error? {
    Lead|error response = laxNegativeClient->/company/test3.post({"id": 2001, "name": "Danesh", "address": "Piliyandala"});
    if response is http:ClientRequestError {
        common:assertErrorMessage(response, "Bad Request");
    } else {
        test:assertFail("Found unexpected output");
    }
}

@test:Config
function testNullForOptionalFieldClientNegative() returns error? {
    Employee|error response = laxNegativeClient->/company/test4;
    if response is http:PayloadBindingError {
        common:assertErrorMessage(response, "Payload binding failed: incompatible value 'null' for type 'string' in field 'address'");
    } else {
        test:assertFail("Found unexpected output");
    }
}

@test:Config
function testMissingRequiredFieldClientNegative() returns error? {
    Department|error response = laxNegativeClient->/company/test5;
    if response is http:PayloadBindingError {
        common:assertErrorMessage(response, "Payload binding failed: required field 'employeeCount' not present in JSON");
    } else {
        test:assertFail("Found unexpected output");
    }
}

@test:Config
function testExtraFieldsIgnoreClientNegative() returns error? {
    Lead|error response = laxNegativeClient->/company/test6;
    if response is http:PayloadBindingError {
        common:assertErrorMessage(response, "Payload binding failed: undefined field 'address'");
    } else {
        test:assertFail("Found unexpected output");
    }
}
