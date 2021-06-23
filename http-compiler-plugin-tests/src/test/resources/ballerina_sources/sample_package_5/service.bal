import ballerina/http;

service http:Service on new http:Listener(9090) {

    resource function get headerString(@http:Header {name: "x-type"} string abc) returns string {
        return "done";
    }

    resource function get headerStringArr(@http:Header {name: "x-type"} string[] abc) returns string {
        return "done";
    }

    resource function get headerStringNil(@http:Header {name: "x-type"} string? abc) returns string {
        return "done";
    }

    resource function get headerStringArrNil(@untainted @http:Header {name: "x-type"} string[]? abc) returns string {
        return "done";
    }

    resource function get headerErr1(@http:Header {name: "x-type"} json abc) returns string {
        return "done"; //error
    }

    resource function get headerErr2(@http:Header @http:Payload string abc) returns string {
        return "done"; //error
    }

    resource function get headerErr3(@http:Header {name: "x-type"} http:Request abc) returns string {
        return "done"; //error
    }

    resource function get headerErr4(@http:Header {name: "x-type"} string|json abc) returns string {
        return "done"; //error
    }

    resource function get headerErr5(@http:Header {name: "x-type"} json? abc) returns string {
        return "done"; //error
    }

    resource function get headerErr6(@http:Header {name: "x-type"} string|json|xml abc) returns string {
        return "done"; //error
    }

    resource function get headerErr7(@http:Header {name: "x-type"} int[] abc) returns string {
        return "done"; //error
    }
}
