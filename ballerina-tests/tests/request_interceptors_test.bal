import ballerina/http;
import ballerina/test;

final http:Client defaultRequestInterceptorClientEP = check new("http://localhost:" + defaultRequestInterceptorTestPort.toString());

listener http:Listener defaultRequestInterceptorServerEP = new(defaultRequestInterceptorTestPort, config = {
        interceptors : [new defaultRequestInterceptor(), new lastRequestInterceptor()]
    });

service / on defaultRequestInterceptorServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-interceptor", check req.getHeader("default-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testDefaultRequestInterceptor() returns error? {
    http:Response res = check defaultRequestInterceptorClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-interceptor");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");

    res = check defaultRequestInterceptorClientEP->post("/", "testMessage");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-interceptor");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
}

final http:Client requestInterceptorWithCallerRespondClientEP = check new("http://localhost:" + requestInterceptorWithCallerRespondTestPort.toString());

listener http:Listener requestInterceptorWithCallerRespondServerEP = new(requestInterceptorWithCallerRespondTestPort, config = {
        interceptors : [new defaultRequestInterceptor(), new requestInterceptorCallerRepond(), new lastRequestInterceptor()]
    });

service / on requestInterceptorWithCallerRespondServerEP {

    resource function 'default test(http:Caller caller, http:Request req) returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testRequestInterceptorWithCallerRespond() returns error? {
    http:Response res = check requestInterceptorWithCallerRespondClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "request-interceptor-caller-repond");
    assertTextPayload(check res.getTextPayload(), "Response from caller inside interceptor");
}

final http:Client requestInterceptorReturnsErrorClientEP = check new("http://localhost:" + requestInterceptorReturnsErrorTestPort.toString());

listener http:Listener requestInterceptorReturnsErrorServerEP = new(requestInterceptorReturnsErrorTestPort, config = {
        interceptors : [new defaultRequestInterceptor(), new requestInterceptorReturnsError(), new lastRequestInterceptor()]
    });

service / on requestInterceptorReturnsErrorServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns string {
        return "Response from resource - test";
    }
}

@test:Config{}
function testrequestInterceptorReturnsError() returns error? {
    http:Response res = check requestInterceptorReturnsErrorClientEP->get("/");
    test:assertEquals(res.statusCode, 500);
    assertTextPayload(check res.getTextPayload(), "Request interceptor returns an error");
}

final http:Client requestErrorInterceptorClientEP = check new("http://localhost:" + requestErrorInterceptorTestPort.toString());

listener http:Listener requestErrorInterceptorServerEP = new(requestErrorInterceptorTestPort, config = {
        interceptors : [new defaultRequestInterceptor(), new requestInterceptorReturnsError(), new defaultRequestErrorInterceptor(), new lastRequestInterceptor()]
    });

service / on requestErrorInterceptorServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-interceptor", check req.getHeader("default-interceptor"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        res.setHeader("request-interceptor-error", check req.getHeader("request-interceptor-error"));
        res.setHeader("default-error-interceptor", check req.getHeader("default-error-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestErrorInterceptor() returns error? {
    http:Response res = check requestErrorInterceptorClientEP->get("/");
    assertHeaderValue(check res.getHeader("last-interceptor"), "default-error-interceptor");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("request-interceptor-error"), "true");
    assertHeaderValue(check res.getHeader("default-error-interceptor"), "true");
}

final http:Client requestInterceptorDataBindingClientEP1 = check new("http://localhost:" + requestInterceptorDataBindingTestPort1.toString());

listener http:Listener requestInterceptorDataBindingServerEP1 = new(requestInterceptorDataBindingTestPort1, config = {
        interceptors : [new defaultRequestInterceptor(), new dataBindingRequestInterceptor(), new lastRequestInterceptor()]
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
        interceptors : [new dataBindingRequestInterceptor(), new lastRequestInterceptor()]
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

final http:Client requestInterceptorSetPayloadClientEP = check new("http://localhost:" + requestInterceptorSetPayloadTestPort.toString());

listener http:Listener requestInterceptorSetPayloadServerEP = new(requestInterceptorSetPayloadTestPort, config = {
        interceptors : [new defaultRequestInterceptor(), new requestInterceptorSetPayload(), new lastRequestInterceptor()]
    });

service / on requestInterceptorSetPayloadServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new();
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("last-interceptor", check req.getHeader("last-interceptor"));
        res.setHeader("default-interceptor", check req.getHeader("default-interceptor"));
        res.setHeader("interceptor-setpayload", check req.getHeader("interceptor-setpayload"));
        res.setHeader("last-request-interceptor", check req.getHeader("last-request-interceptor"));
        check caller->respond(res);
    }
}

@test:Config{}
function testRequestInterceptorSetPayload() returns error? {
    http:Request req = new();
    req.setHeader("interceptor", "databinding-interceptor");
    req.setTextPayload("Request from Client");
    http:Response res = check requestInterceptorSetPayloadClientEP->post("/", req);
    assertTextPayload(check res.getTextPayload(), "Text payload from interceptor");
    assertHeaderValue(check res.getHeader("last-interceptor"), "interceptor-setpayload");
    assertHeaderValue(check res.getHeader("default-interceptor"), "true");
    assertHeaderValue(check res.getHeader("last-request-interceptor"), "true");
    assertHeaderValue(check res.getHeader("interceptor-setpayload"), "true");
}

final http:Client requestInterceptorWithoutCtxNextClientEP = check new("http://localhost:" + requestInterceptorWithoutCtxNextTestPort.toString());

listener http:Listener requestInterceptorWithoutCtxNextServerEP = new(requestInterceptorWithoutCtxNextTestPort, config = {
        interceptors : [new defaultRequestInterceptor(), new requestInterceptorWithoutCtxNext(), new lastRequestInterceptor()]
    });

service / on requestInterceptorWithoutCtxNextServerEP {

    resource function 'default .(http:Caller caller, http:Request req) returns string {
        return "Response from resource - test";
    }
}    

@test:Config{}
function testRequestInterceptorWithoutCtxNext() returns error? {
    http:Request req = new();
    http:Response res = check requestInterceptorWithoutCtxNextClientEP->get("/");
    assertTextPayload(check res.getTextPayload(), "interceptor service should call next() method to continue execution");
    test:assertEquals(res.statusCode, 500);
}
