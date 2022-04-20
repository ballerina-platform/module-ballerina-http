import ballerina/http;
import ballerina/jballerina.java;


http:ListenerConfiguration http3SslServiceConf = {
    secureSocket: {
        key: {
            path: "/home/dilhanivm/Documents/ballerina/module-ballerina-http/ballerina-tests/tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        }
    },
    httpVersion: "3.0"

};

listener http:Listener http3SslListener = new(9090,http3SslServiceConf);

    service / on http2SslListener {
     
        resource function post getHello() returns string {
            handle hello = getHello("http://localhost:9090/hello",9090,"getHello");
            return "done!";
        }
    }

    function getHello(string path, int port, string method) returns handle = @java:Method {
            name: "getHello",
            'class: "tests.datafiles.http3_basic_test"
    } external;