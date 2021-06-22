import ballerina/http;


service / on new http:Listener(9999) {
    resource function get invalid (http:Caller caller, string action) returns http:BadRequest? {
        if action == "complete" {
            error? result = caller->respond("This is successful");
        } else {
            http:BadRequest result = {
                body: "Provided `action` parameter is invalid"
            };
            return result;
        }
    }

    resource function get valid (string action) returns http:Accepted|http:BadRequest {
        if action == "complete" {
            http:Accepted result = {
                body: "Request was successfully processed"
            };
            return result;
        } else {
            http:BadRequest result = {
                body: "Provided `action` parameter is invalid"
            };
            return result;
        }
    }

    resource function get validWithCaller (http:Caller caller, string action) returns error? {
        check caller->respond("Hello, World..!");
    }
}
