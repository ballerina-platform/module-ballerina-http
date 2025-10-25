import ballerina/io;
import ballerina/http;
import ballerina/test;

http:Client testClient = check new ("http://localhost:9090");
configurable int port = ?; 
configurable string host = ?;
configurable string user = ?;
configurable string database = ?;
configurable string password = ?;

// Before Suite Function
@test:BeforeSuite
function beforeSuiteFunc() {
    io:println("I'm the before suite function!");
}

// Test function
@test:Config {}
function testServiceWithProperName() {
    string|error response = testClient->/greeting(name = "John");
    test:assertEquals(response, "Hello, John");
}

// Negative test function
@test:Config {}
function testServiceWithEmptyName() returns error? {
    http:Response response = check testClient->/greeting;
    test:assertEquals(response.statusCode, 500);
    json errorPayload = check response.getJsonPayload();
    test:assertEquals(errorPayload.message, "name should not be empty!");
}

// After Suite Function
@test:AfterSuite
function afterSuiteFunc() {
    io:println("I'm the after suite function!");
}
