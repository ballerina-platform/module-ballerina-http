import ballerina/http;

service class MyRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx)
            returns http:NextService|error? {
        return ctx.next();
    }
}

service class MyResponseInterceptor {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx)
            returns http:NextService|error? {
        return ctx.next();
    }
}

service http:InterceptableService / on new http:Listener(9099) {

    public function createInterceptors() returns [MyRequestInterceptor, MyResponseInterceptor] {
        return [new MyRequestInterceptor(), new MyResponseInterceptor()];
    }

    resource function get hello(http:Caller caller) returns error? {
        check caller->respond("Hello, World!");
    }
}

service http:InterceptableService / on new http:Listener(9100) {

    public function createInterceptors() returns MyRequestInterceptor {
        return new MyRequestInterceptor();
    }

    resource function get hello(http:Caller caller) returns error? {
        check caller->respond("Hello, World!");
    }
}
