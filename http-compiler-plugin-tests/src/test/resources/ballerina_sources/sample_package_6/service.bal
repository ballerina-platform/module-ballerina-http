import ballerina/http as a;

type Caller record {|
    int id;
|};

service a:Service on new a:Listener(9090) {

    resource function get callerInf(@a:CallerInfo a:Caller abc) returns string {
        return "done";
    }

    resource function get callerErr1(@a:CallerInfo string abc) returns string {
        return "done"; //error
    }

    resource function get callerErr2(@a:CallerInfo @a:Payload a:Caller abc) returns string {
        return "done"; //error
    }

    resource function get callerErr3(@a:CallerInfo Caller abc) returns string {
        return "done"; //error
    }
}
