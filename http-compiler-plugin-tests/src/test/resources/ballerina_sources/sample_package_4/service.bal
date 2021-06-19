import ballerina/http;

type Person record {|
    int id;
|};

public annotation Person Pp on parameter;

service http:Service on new http:Listener(9090) {

    resource function get dbJson(@untainted @http:Payload json abc) returns string {
        return "done";
    }

    resource function get dbXml(@http:Payload @http:Header xml abc) returns string {
        return "done";
    }

    resource function get dbString(@http:Payload string abc) returns string {
        return "done";
    }

    resource function get dbByteArr(@http:Payload byte[] abc) returns string {
        return "done";
    }

    resource function get dbRecord(@http:Payload Person abc) returns string {
        return "done";
    }

    resource function get dbRecArr(@http:Payload Person[] abc) returns string {
        return "done";
    }

    resource function get dbJsonArr(@http:Payload json[] abc) returns string {
        return "done"; // error
    }

    resource function get greeting1(int num, @http:Payload json abc, @Pp {id:0} string a) returns string {
        return "done"; // error
    }

    resource function get dbTable(table<Person> key(id)  abc) returns string {
        return "done"; // error
    }
}
