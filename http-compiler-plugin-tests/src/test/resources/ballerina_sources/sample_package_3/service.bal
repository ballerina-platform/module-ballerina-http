import ballerina/http;
import ballerina/test;

service http:Service on new http:Listener(9090) {
    @http:ResourceConfig {
        consumes: ["fwhbw"]
    }
    resource function get greeting1() returns int|error|string {
        return error http:Error("hello") ;
    }

    @test:Config {}
    resource function get greeting2() returns int|error|string {
        return error http:Error("hello") ;
    }
}
