import ballerina/http;
import ballerina/test;

final http:Client requestInterceptorWithoutCtxNextClientEP = check new("http://localhost:" + requestInterceptorWithoutCtxNextTestPort.toString());

listener http:Listener requestInterceptorWithoutCtxNextServerEP = new(requestInterceptorWithoutCtxNextTestPort, config = {
        interceptors : [new DefaultRequestInterceptor(), new RequestInterceptorWithoutCtxNext(), new LastRequestInterceptor()]
    });

service / on requestInterceptorWithoutCtxNextServerEP {

    resource function 'default .() returns string {
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
