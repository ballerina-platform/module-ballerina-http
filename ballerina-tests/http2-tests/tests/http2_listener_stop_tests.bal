import ballerina/http;
import ballerina/lang.runtime;
import ballerina/test;
import ballerina/http_test_common as common;

service class HelloService {
    *http:Service;

    resource function get hello() returns string {
        return "Hello";
    }
}

@test:Config {}
public function testHttp2ListenerStop1() returns error? {
    http:Listener serviceEP = check new (http2ListenerStopTest);
    check serviceEP.attach(new HelloService());
    check serviceEP.'start();

    http:Client client1 = check new ("localhost:" + http2ListenerStopTest.toString());
    string|error response = client1->/hello;
    if response is string {
        test:assertEquals(response, "Hello");
    } else {
        test:assertFail("Found unexpected error: " + response.message());
    }

    check serviceEP.immediateStop();
    runtime:sleep(5);

    response = client1->/hello;
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail("Found unexpected output: " + response);
    }

    http:Client client2 = check new ("localhost:" + http2ListenerStopTest.toString());
    response = client2->/hello;
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail("Found unexpected output: " + response);
    }
}

@test:Config {}
public function testHttp2ListenerStop2() returns error? {
    http:Listener serviceEP = check new (http2ListenerStopTest);
    check serviceEP.attach(new HelloService());
    check serviceEP.'start();

    http:Client client1 = check new ("localhost:" + http2ListenerStopTest.toString(), http2Settings = {http2PriorKnowledge: true});
    string|error response = client1->/hello;
    if response is string {
        test:assertEquals(response, "Hello");
    } else {
        test:assertFail("Found unexpected error: " + response.message());
    }

    check serviceEP.immediateStop();
    runtime:sleep(5);

    response = client1->/hello;
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail("Found unexpected output: " + response);
    }

    http:Client client2 = check new ("localhost:" + http2ListenerStopTest.toString(), http2Settings = {http2PriorKnowledge: true});
    response = client2->/hello;
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail("Found unexpected output: " + response);
    }
}

@test:Config {}
public function testHttp2SecuredListenerStop1() returns error? {
    http:Listener securedEP = check new (http2SecuredListenerStopTest1,
        secureSocket = {
        key: {
            certFile: common:CERT_FILE,
            keyFile: common:KEY_FILE
        }
    }
    );
    check securedEP.attach(new HelloService());
    check securedEP.'start();

    http:Client client1 = check new ("localhost:" + http2SecuredListenerStopTest1.toString(),
        secureSocket = {
        cert: common:CERT_FILE
    }
    );
    string|error response = client1->/hello;
    if response is string {
        test:assertEquals(response, "Hello");
    } else {
        test:assertFail("Found unexpected error: " + response.message());
    }

    check securedEP.immediateStop();
    runtime:sleep(5);

    response = client1->/hello;
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail("Found unexpected output: " + response);
    }

    http:Client client2 = check new ("localhost:" + http2SecuredListenerStopTest1.toString(),
        secureSocket = {
        cert: common:CERT_FILE
    }
    );
    response = client2->/hello;
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail("Found unexpected output: " + response);
    }
}

@test:Config {}
public function testHttp2SecuredListenerStop2() returns error? {
    http:Listener securedEP = check new (http2SecuredListenerStopTest2,
        secureSocket = {
        key: {
            certFile: common:CERT_FILE,
            keyFile: common:KEY_FILE
        }
    }
    );
    check securedEP.attach(new HelloService());
    check securedEP.'start();

    http:Client client1 = check new ("localhost:" + http2SecuredListenerStopTest2.toString(),
        secureSocket = {
        cert: common:CERT_FILE
    },
        http2Settings = {http2PriorKnowledge: true}
    );
    string|error response = client1->/hello;
    if response is string {
        test:assertEquals(response, "Hello");
    } else {
        test:assertFail("Found unexpected error: " + response.message());
    }

    check securedEP.immediateStop();
    runtime:sleep(5);

    response = client1->/hello;
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail("Found unexpected output: " + response);
    }

    http:Client client2 = check new ("localhost:" + http2SecuredListenerStopTest2.toString(),
        secureSocket = {
        cert: common:CERT_FILE
    },
        http2Settings = {http2PriorKnowledge: true}
    );
    response = client2->/hello;
    if response is error {
        test:assertEquals(response.message(), "Something wrong with the connection");
    } else {
        test:assertFail("Found unexpected output: " + response);
    }
}
