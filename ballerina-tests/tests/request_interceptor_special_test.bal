import ballerina/http;
import ballerina/test;

final http:Client requestInterceptorWithCallerRespondClientEP = check new("http://localhost:" + requestInterceptorWithCallerRespondTestPort.toString());

listener http:Listener requestInterceptorWithCallerRespondServerEP = new(requestInterceptorWithCallerRespondTestPort, config = {
        interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorCallerRepond(), new LastRequestInterceptor()]
    });

service / on requestInterceptorWithCallerRespondServerEP {

    resource function 'default test() returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorWithCallerRespond() returns error? {
    http:Response res = check requestInterceptorWithCallerRespondClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-caller-repond");
    assertTextPayload(check res.getTextPayload(), "Response from caller inside interceptor");
}

final http:Client requestInterceptorDataBindingClientEP1 = check new("http://localhost:" + requestInterceptorDataBindingTestPort1.toString());

listener http:Listener requestInterceptorDataBindingServerEP1 = new(requestInterceptorDataBindingTestPort1, config = {
        interceptors : [new DefaultRequestInterceptor(), new DataBindingRequestInterceptor(), new LastRequestInterceptor()]
    });

service / on requestInterceptorDataBindingServerEP1 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-interceptor", check req.getHeader("default-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

final http:Client requestInterceptorDataBindingClientEP2 = check new("http://localhost:" + requestInterceptorDataBindingTestPort2.toString());

listener http:Listener requestInterceptorDataBindingServerEP2 = new(requestInterceptorDataBindingTestPort2, config = {
        interceptors : [new DataBindingRequestInterceptor(), new LastRequestInterceptor()]
    });

service / on requestInterceptorDataBindingServerEP2 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorDataBinding() returns error? {
    http:Request req = new();
    req.setHeader("interceptor", "databinding-interceptor");
    req.setTextPayload("Request from requestInterceptorDataBindingClient");
    http:Response res = check requestInterceptorDataBindingClientEP1->post("/", req);
    assertTextPayload(check res.getTextPayload(), "Request from requestInterceptorDataBindingClient");
    assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check requestInterceptorDataBindingClientEP2->post("/", req);
    assertTextPayload(check res.getTextPayload(), "Request from requestInterceptorDataBindingClient");
    assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

@test:Config{}
function testRequestInterceptorDataBindingWithLargePayload() returns error? {
    http:Request req = new();
    string payload = "";
    int i = 0;
    while (i < 10) {
        payload += largePayload;
        i += 1;
    }
    req.setHeader("interceptor", "databinding-interceptor");
    req.setTextPayload(payload);
    http:Response res = check requestInterceptorDataBindingClientEP1->post("/", req);
    assertTextPayload(check res.getTextPayload(), payload);
    assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check requestInterceptorDataBindingClientEP2->post("/", req);
    assertTextPayload(check res.getTextPayload(), payload);
    assertHeaderValue(check res.getHeader("last-interceptor"), "databinding-interceptor");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}
