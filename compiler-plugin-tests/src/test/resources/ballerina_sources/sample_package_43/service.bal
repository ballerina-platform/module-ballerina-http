import ballerina/http;

service class MyRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx) returns http:NextService|error? {
        return ctx.next();
    }
}

service class MyResponseInterceptor {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx) returns http:NextService|error? {
        return ctx.next();
    }
}

@http:ServiceConfig {interceptors: new MyResponseInterceptor()}
service / on new http:Listener(9099, interceptors = new MyRequestInterceptor()) {

    resource function get hello(http:Caller caller) returns error? {
        check caller->respond("Hello, World!");
    }
}

listener http:Listener 'listener = new (9090, interceptors = new MyRequestInterceptor());

@http:ServiceConfig {interceptors: new MyResponseInterceptor()}
service / on 'listener {

    resource function get hello(http:Caller caller) returns error? {
        check caller->respond("Hello, World!");
    }
}
