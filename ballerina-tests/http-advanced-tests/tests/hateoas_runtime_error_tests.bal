// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/test;

listener http:Listener hateoasRuntimeErrorServerEP = check new(hateoasRuntimeErrorPort, httpVersion = http:HTTP_1_1);

@test:Config{}
function testDuplicateResourceName() {
    http:Service duplicateResourceNameService = service object {
        @http:ResourceConfig{
            name: "resource1"
        }
        resource function get resource1() returns string {
            return "resource1";
        }

        @http:ResourceConfig{
            name: "resource1"
        }
        resource function post resource2() returns string {
            return "resource2";
        }
    };
    error? err = hateoasRuntimeErrorServerEP.attach(duplicateResourceNameService, "service1");
    if err is error {
        test:assertEquals(err.message(), "resource link generation failed: cannot duplicate resource link name:" +
                          " 'resource1' unless they have the same path");
    } else {
        test:assertFail("Found unexpected result");
    }
}

@test:Config{}
function testDuplicateLinkRelation() {
    http:Service duplicateResourceNameService = service object {
        @http:ResourceConfig{
            name: "resource1",
            linkedTo: [
                {name: "resource1", relation: "relation1"},
                {name: "resource2", relation: "relation1"}
            ]
        }
        resource function get resource1() returns string {
            return "resource1";
        }

        @http:ResourceConfig{
            name: "resource2"
        }
        resource function get resource2() returns string {
            return "resource2";
        }
    };
    error? err = hateoasRuntimeErrorServerEP.attach(duplicateResourceNameService, "service2");
    if err is error {
        test:assertEquals(err.message(), "resource link generation failed: cannot duplicate resource link relation:" +
                          " 'relation1'");
    } else {
        test:assertFail("Found unexpected result");
    }
}

@test:Config{}
function testLinkedResourceNotFound() {
    http:Service duplicateResourceNameService = service object {
        @http:ResourceConfig{
            linkedTo: [{name: "resource1"}]
        }
        resource function get resource1() returns string {
            return "resource1";
        }
    };
    error? err = hateoasRuntimeErrorServerEP.attach(duplicateResourceNameService, "service3");
    if err is error {
        test:assertEquals(err.message(), "resource link generation failed: cannot find resource with resource link name:" +
                          " 'resource1'");
    } else {
        test:assertFail("Found unexpected result");
    }
}

@test:Config{}
function testLinkedResourceNotFoundWithMethod() {
    http:Service duplicateResourceNameService = service object {
        @http:ResourceConfig{
            linkedTo: [{name: "resource1", method: "get"}]
        }
        resource function get resource1() returns string {
            return "resource1";
        }

        @http:ResourceConfig{
            name: "resource1"
        }
        resource function post resource2() returns string {
            return "resource2";
        }
    };
    error? err = hateoasRuntimeErrorServerEP.attach(duplicateResourceNameService, "service4");
    if err is error {
        test:assertEquals(err.message(), "resource link generation failed: cannot find GET resource with resource link " +
                          "name: 'resource1'");
    } else {
        test:assertFail("Found unexpected result");
    }
}

@test:Config{}
function testUnresolvedLinkedResource() {
    http:Service duplicateResourceNameService = service object {
        @http:ResourceConfig{
            name: "resource1",
            linkedTo: [{name: "resource1"}]
        }
        resource function get resource1() returns string {
            return "resource1";
        }

        @http:ResourceConfig{
            name: "resource1"
        }
        resource function post resource1() returns string {
            return "resource1";
        }
    };
    error? err = hateoasRuntimeErrorServerEP.attach(duplicateResourceNameService, "service5");
    if err is error {
        test:assertEquals(err.message(), "resource link generation failed: cannot resolve resource link name: " +
                          "'resource1' since multiple occurrences found");
    } else {
        test:assertFail("Found unexpected result");
    }
}
