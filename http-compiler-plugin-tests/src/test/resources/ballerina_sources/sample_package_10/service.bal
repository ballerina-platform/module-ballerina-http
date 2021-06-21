import ballerina/http;

type Person record {|
    int id;
    string name;
|};

type AA record {|
    string a;
|};

service http:Service on new http:Listener(9090) {
    resource function get callerInfo1(int xyz, @http:CallerInfo {respondType: string} http:Caller abc) {
        checkpanic abc->respond("done");
    }

    resource function get callerInfo2(@http:CallerInfo {respondType: int} http:Caller abc) {
        error? err = abc->respond(56);
    }

    resource function get callerInfo3(@http:CallerInfo {respondType: int} http:Caller abc) {
        var err = abc->respond({a:"abc"});
        if (err is error) {
        }
    }

    resource function get callerInfo4(@http:CallerInfo {respondType: decimal} http:Caller abc) returns error? {
        return abc->respond(5.6);
    }

    resource function get callerInfo5(@http:CallerInfo {respondType: string} http:Caller abc) returns error? {
        var a = check abc->respond("done");
    }

    resource function get callerInfo6(@http:CallerInfo {respondType: decimal} http:Caller abc) returns error? {
        return abc->respond(5565.6d);
    }

    resource function get callerInfo7(@http:CallerInfo {} http:Caller abc) returns error? {
        return abc->respond(54341.6); // no validation
    }

    resource function get callerInfo8(@http:CallerInfo http:Caller abc) returns error? {
        var a = abc->respond("ufww"); // no validation
        if (a is error) {
        }
    }

    resource function get callerInfo9(@http:CallerInfo {respondType: Person}http:Caller abc) returns error? {
       error? a = abc->respond({id:123, name:"elle"});
    }

    resource function get callerInfo10(@http:CallerInfo {} http:Caller abc) returns error? {
       checkpanic abc->respond(); // empty annotation value exp
    }

    resource function get callerInfo11(@http:CallerInfo {respondType: Person}http:Caller abc) returns error? {
       return abc->'continue(); // different remote method call
    }

    resource function get callerInfo12(int xyz, @http:CallerInfo {respondType: string} http:Caller abc) {
       int a = 5;
       if (a > 0) {
           checkpanic abc->respond("Go");
       } else {
           error? ab = abc->respond({a:"hello"});   //error
       }
    }

    resource function get callerInfo13(@http:CallerInfo {respondType: string} http:Caller abc, http:Caller xyz) {
       checkpanic xyz->respond("done"); // error:multiple callers
    }

    resource function get callerInfo14(@untainted @http:CallerInfo {respondType: string} http:Caller abc) {
       checkpanic abc->respond("done"); // multiple annotations
    }

    resource function get callerInfo15(@http:CallerInfo {respondType: string} http:Caller abc) returns error? {
       http:Client c = check new("path");
       http:Response|error a = c->get("done"); // different remote method call
       if (a is error) {
       }
    }

    resource function get callerInfo16(@http:CallerInfo {respondType: Person}http:Caller abc) returns error? {
        Person p = {id:123, name:"elle"};
        error? a = abc->respond(p);
    }

    resource function get callerInfo17(@http:CallerInfo {respondType: Person}http:Caller abc) returns error? {
        error? a = abc->respond({school:1.23}); // This getting passed as map<json> and this is a limitation
    }

    resource function get callerInfo18(@http:CallerInfo {respondType: Person}http:Caller abc) returns error? {
        AA val = { a: "hello" };
        error? a = abc->respond(val); // error
    }
}
