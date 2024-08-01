import ballerina/http;
import ballerina/log;

@http:ServiceConfig {
    mediaTypeSubtypePrefix: "vnd.socialMedia",
    basePath: "/socialMedia"
}
public type Service service object {
    *http:ServiceContract;
    *http:InterceptableService;

    public function createInterceptors() returns ErrorInterceptor;

    resource function get users() returns @http:Cache {maxAge: 10} User[]|error;

    resource function get users/[int id]() returns User|UserNotFound|error;

    resource function post users(NewUser newUser) returns http:Created|error;
};

public isolated service class ErrorInterceptor {
    *http:ResponseErrorInterceptor;

    isolated remote function interceptResponseError(error err, http:Response res, http:RequestContext ctx) returns DefaultResponse {
        log:printError("error occurred", err);
        return {
            body: err.message(),
            status: new (res.statusCode)
        };
    }
}

public type User record {
    int id;
    string name;
    string email;
};

public type NewUser record {
    string name;
    string email;
};


public type UserNotFound record {|
    *http:NotFound;
    ErrorMessage body;
|};

public type DefaultResponse record {|
    *http:DefaultStatusCodeResponse;
    ErrorMessage body;
|};

public type ErrorMessage string;

service Service on new http:Listener(9090) {

    resource function get users() returns User[]|error {
        return [{id: 1, name: "Alice", email: "alice@gmail.com"}, {id: 2, name: "Bob", email: "bob@gmail.com"}];
    }

    resource function get users/[int id]() returns User|UserNotFound|error {
        return {id: 1, name: "Alice", email: "alice@gmail.com"};
    }

    resource function post users(NewUser newUser) returns http:Created|error {
        return {
            body: {
                message: "User created successfully"
            }
        };
    }

    public function createInterceptors() returns ErrorInterceptor {
        return new ();
    }
}

@http:ServiceConfig {
    serviceType:  Service
}
service Service on new http:Listener(9091) {

    resource function get users() returns User[]|error {
        return [{id: 1, name: "Alice", email: "alice@gmail.com"}, {id: 2, name: "Bob", email: "bob@gmail.com"}];
    }

    resource function get users/[int id]() returns User|UserNotFound|error {
        return {id: 1, name: "Alice", email: "alice@gmail.com"};
    }

    resource function post users(NewUser newUser) returns http:Created|error {
        return {
            body: {
                message: "User created successfully"
            }
        };
    }

    public function createInterceptors() returns ErrorInterceptor {
        return new ();
    }
}
