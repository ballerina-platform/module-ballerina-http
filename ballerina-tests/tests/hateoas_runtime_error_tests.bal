import ballerina/http;
import ballerina/test;

listener http:Listener hateoasRuntimeErrorServerEP = check new(hateoasRuntimeErrorPort);

@test:Config{}
function testDuplicateResourceName() {
    http:Service duplicateResourceNameService = service object {
        @http:ResourceConfig{
            name: "resource1",
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
    error? err = hateoasRuntimeErrorServerEP.attach(duplicateResourceNameService, "service1");
    if err is error {
        test:assertEquals(err.message(), "service registration failed: cannot duplicate resource name:" +
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
        test:assertEquals(err.message(), "service registration failed: cannot duplicate resource relation:" +
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
        test:assertEquals(err.message(), "service registration failed: cannot find resource with name:" +
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
        test:assertEquals(err.message(), "service registration failed: cannot find GET resource with name:" +
                          " 'resource1'");
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
        test:assertEquals(err.message(), "service registration failed: cannot resolve resource name: " +
                          "'resource1' since multiple occurrences found");
    } else {
        test:assertFail("Found unexpected result");
    }
}
