import ballerina/http;
import ballerina/mime;

type Caller record {|
    int id;
|};

service http:Service on new http:Listener(9090) {

    resource function get callerInfo1(string a, int[] b, float? c, decimal[]? d) returns string {
        return "done";
    }

    resource function get callerInfo2(@untainted string a, @tainted int[] b) returns string {
        return "done";
    }

    resource function get callerInfo3(string a, int b, float c, decimal d, boolean e) returns string {
        return "done";
    }

    resource function get callerInfo4(string? a, int? b, float? c, decimal? d, boolean? e) returns string {
        return "done";
    }

    resource function get callerInfo5(string[] a, int[] b, float[] c, decimal[] d, boolean[] e) returns string {
        return "done";
    }

    resource function get callerInfo6(string[]? a, int[]? b, float[]? c, decimal[]? d, boolean[]? e) returns string {
        return "done";
    }

    resource function get callerErr1(@untainted json a) returns string {
        return "done";
    }

    resource function get callerErr2(mime:Entity abc) returns string {
        return "done";
    }

    resource function get callerErr3(int|string a) returns string {
        return "done";
    }

    resource function get callerErr4(int|string[]|float a) returns string {
        return "done";
    }

    resource function get callerErr5(int[]|json a) returns string {
        return "done";
    }

    resource function get callerErr6(json[] a) returns string {
        return "done";
    }

    resource function get callerErr7(json? a) returns string {
        return "done";
    }
}
