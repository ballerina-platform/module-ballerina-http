import ballerina/http;

type Person record {|
    readonly int id;
    string name;
|};

type PersonTable table<Person> key(id);

service http:Service on new http:Listener(9090) {
    resource function get greeting() returns int|error|string {
        return error http:Error("hello") ;
    }

    resource function get greeting2() returns http:Error {
        return error http:ListenerError("hello") ;
    }

    resource function post greeting3() returns () {
        // Request hangs without a response
        return;
    }

    resource function get greeting4() returns http:Client { // Compiler error
        http:Client httpClient = checkpanic new("path");
        return httpClient;
    }

    resource function get greeting5() returns Person {
        return {id:123, name: "john"};
    }

    resource function get greeting6() returns string[] {
        return ["Abc", "Xyz"];
    }

    resource function get greeting7() returns int[] {
        return [15, 34];
    }

    resource function get greeting8() returns error[] { // Compiler error
        error e1 = error http:ListenerError("hello1");
        error e2 = error http:ListenerError("hello2");
        return [e1, e2];
    }

    resource function get greeting9() returns byte[] {
        byte[] binaryValue = "Sample Text".toBytes();
        return binaryValue;
    }

    resource function get greeting10() returns map<string> {
        return {};
    }

    resource function get greeting11() returns PersonTable {
        PersonTable tbPerson = table [
            {id: 1, name: "John"},
            {id: 2, name: "Bella"}
        ];
        return tbPerson;
    }

    resource function get greeting12() returns table<Person> key(id) {
        PersonTable tbPerson = table [
            {id: 1, name: "John"},
            {id: 2, name: "Bella"}
        ];
        return tbPerson;
    }

    resource function get greeting13() returns map<http:Client> {
        http:Client httpClient = checkpanic new("path");
        return {name:httpClient};
    }

    resource function get greeting14() returns http:Ok {
        return {};
    }
}
