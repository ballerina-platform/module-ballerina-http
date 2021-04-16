import ballerina/http;

service http:Service on new http:Listener(9090) {

    string abc = "as";

    resource function get greeting() {
    }

    isolated resource function post noGreeting() {
    }

    private function hello() returns string {
        return "yo";
    }

    isolated remote function greeting() returns string {
        return "Hello";
    }

    function hello2() returns string {
        return "yo";
    }

    remote function greeting2() returns string|http:Response {
        return "Hello";
    }
}

service http:Service on new http:Listener(9091) {
    remote function greeting2(http:Caller caller) {
    }
}
