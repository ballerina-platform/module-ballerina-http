import ballerina/http;

service http:Service on new http:Listener(9090) {
    resource function get greeting() returns string|int {
        return "Hello";
    }

    resource function post noGreeting() returns json {
        return "world";
    }

    function hello() returns string {
        return "yo";
    }
}

service http:Service on new http:Listener(9091) {
    resource function get greeting2(http:Caller caller) returns http:Response {
        http:Response res = new;
        return res;
    }
}
