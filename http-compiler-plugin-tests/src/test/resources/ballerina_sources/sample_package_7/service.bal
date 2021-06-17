import ballerina/http;
import ballerina/mime;

type Caller record {|
    int id;
|};

service http:Service on new http:Listener(9090) {

    resource function get callerInfo(http:Caller abc, http:Request req, http:Headers head) returns string {
        return "done";
    }

    resource function get callerErr1(http:Response abc) returns string {
        return "done";
    }

    resource function get callerErr2(mime:Entity abc) returns string {
        return "done";
    }

    resource function get callerErr3(int a, mime:Entity abc) returns string {
        return "done";
    }

    resource function get callerErr4(int a, Caller abc) returns string {
        return "done";
    }
}
