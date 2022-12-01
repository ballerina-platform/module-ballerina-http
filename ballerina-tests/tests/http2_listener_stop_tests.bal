import ballerina/http;
import ballerina/lang.runtime;
import ballerina/test;

service class HelloService {
    *http:Service;

    resource function get hello() returns string {
        return "Hello";
    }
}

@test:Config {}
public function testHTTP2ListenerStop1() returns error? {
    http:Listener serviceEP = check new (http2ListenerStopTest1);
    check serviceEP.attach(new HelloService());
    check serviceEP.'start();

    http:Client client1 = check new ("localhost:" + http2ListenerStopTest1.toString());
    string|error response = client1->/hello;
    if response is string {
        test:assertEquals(response, "Hello");
    } else {
        test:assertFail(msg = "Found unexpected error: " + response.message());
    }

    check serviceEP.immediateStop();
    runtime:sleep(5);

    http:Client client2 = check new ("localhost:" + http2ListenerStopTest1.toString());
    response = client2->/hello;
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response);
    }
}

@test:Config {}
public function testHTTP2ListenerStop2() returns error? {
    http:Listener serviceEP = check new (http2ListenerStopTest1);
    check serviceEP.attach(new HelloService());
    check serviceEP.'start();

    http:Client client1 = check new ("localhost:" + http2ListenerStopTest1.toString(), http2Settings = { http2PriorKnowledge: true });
    string|error response = client1->/hello;
    if response is string {
        test:assertEquals(response, "Hello");
    } else {
        test:assertFail(msg = "Found unexpected error: " + response.message());
    }

    check serviceEP.immediateStop();
    runtime:sleep(5);

    http:Client client2 = check new ("localhost:" + http2ListenerStopTest1.toString(), http2Settings = { http2PriorKnowledge: true });
    response = client2->/hello;
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response);
    }
}

@test:Config {}
public function testHTTP2SecuredListenerStop() returns error? {
    http:Listener securedEP = check new (http2SecuredListenerStopTest,
        secureSocket = {
        key: {
            certFile: "tests/certsandkeys/public.crt",
            keyFile: "tests/certsandkeys/private.key"
        }
    }
    );
    check securedEP.attach(new HelloService());
    check securedEP.'start();

    http:Client client1 = check new ("localhost:" + http2SecuredListenerStopTest.toString(),
        secureSocket = {
            cert: "tests/certsandkeys/public.crt"
        }
    );
    string|error response = client1->/hello;
    if response is string {
        test:assertEquals(response, "Hello");
    } else {
        test:assertFail(msg = "Found unexpected error: " + response.message());
    }

    check securedEP.immediateStop();
    runtime:sleep(5);

    http:Client client2 = check new ("localhost:" + http2SecuredListenerStopTest.toString(),
        secureSocket = {
            cert: "tests/certsandkeys/public.crt"
        }
    );
    response = client2->/hello;
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response);
    }
}
