import ballerina/http;
import ballerina/jballerina.java;
import ballerina/test;

http:ListenerConfiguration http3SslServiceConf = {
    secureSocket: {
        key: {
            path: "tests/certsandkeys/ballerinaKeystore.p12",
            password: "ballerina"
        }
    },
    httpVersion: "3.0"
};

listener http:Listener http3SslListener = new(9090,http3SslServiceConf);

    service / on http3SslListener {

     resource function get hello(http:Caller caller,http:Request req) returns error? {

          string msg = "Hello!";
          http:Response response = new;
          response.setPayload(msg);
          check caller->respond(response);
     }

     resource function post getPayload(http:Caller caller,http:Request payload) returns error? {


        string|http:ClientError textPayload = payload.getTextPayload();
        http:Response response = new;

        if textPayload is string {
            response.setPayload(textPayload); 
        }
        if textPayload is http:ClientError {
          string  msg = "Found unexpected output for TEXT: " +  textPayload.message();
        }
          check caller->respond(response);
     }

     resource function post getJsonPayload(http:Caller caller,http:Request payload) returns error? {

        json|http:ClientError jsonPayload = payload.getJsonPayload();
            http:Response response = new;
        
        if jsonPayload is json { 
            string msgs = "JSON PAYLOAD RECEIVED!";
            response.setPayload(msgs);
        }
        if jsonPayload is http:ClientError {
            string  msg = "Found unexpected output for JSON: " +  jsonPayload.message();
            response.setPayload(msg);

        }

        check caller->respond(response);

    }
    

     resource function post getXMLPayload(http:Caller caller,http:Request payload) returns error? {

        xml|http:ClientError xmlPayload = payload.getXmlPayload();
            http:Response response = new;


        if xmlPayload is xml {
            string msgs = "XML PAYLOAD RECEIVED!";
            response.setPayload(msgs);
        }
        if xmlPayload is http:ClientError {
            string  msg = "Found unexpected output for XML: " +  xmlPayload.message();
            response.setPayload(msg);
        }

          check caller->respond(response);
    }
}
    

     @test:Config {}
        public function testHttp3Get()  {

        map<string[]>|error response = getRequests(http3TestPort,"/hello");

        if response is map<string[]>{
            test:assertEquals(response["Body"], "Hello!", msg = "Payload not matched");
        } else {
            test:assertFail("Invalid type");
        }

     }

     @test:Config {}
        public function testHttp3PostWithTextPayload() {

        map<string[]>|error response = postRequests(http3TestPort,"/getPayload","TEXT VALUE");

        if response is map<string[]>{
            test:assertEquals(response["Body"], "TEXT VALUE", msg = "Payload not matched");
        } else {
            test:assertFail("Invalid type");
        }
     }

    @test:Config {}
    public function testHttp3PostRequestWithJsonPayload() {
            
            map<string> payload = {"name": "sara","age": "2" };

            map<string[]>|error response = sendPostRequestWithJsonPayload(http3TestPort,"/getJsonPayload",payload);

            if response is map<string[]>{
                test:assertEquals(response["Body"], "JSON PAYLOAD RECEIVED!", msg = "Payload not matched");
            } else {
                test:assertFail("Invalid type");
            } 

    }

 @test:Config {}
    public function testHttp3PostRequestWithXmlPayload() {
            
            xml data = xml `<name>Hello World</name>`;

            map<string[]>|error response = sendPostRequestWithXmlPayload(http3TestPort,"/getXMLPayload",data);

            if response is map<string[]>{
                test:assertEquals(response["Body"], "XML PAYLOAD RECEIVED!", msg = "Payload not matched");
            } else {
                test:assertFail("Invalid type");
            } 

    }
     
isolated function getRequests(int port,string path) returns map<string[]>  | error= @java:Method {
    name: "sendGetRequest",
    'class: "io.ballerina.stdlib.http.testutils.ExternHttp3Client"
} external;

isolated function postRequests(int port,string path, string payload) returns map<string[]> | error= @java:Method {
    name: "sendPostRequestWithStringPayload",
    'class: "io.ballerina.stdlib.http.testutils.ExternHttp3Client"
} external;

isolated function sendPostRequestWithJsonPayload(int port,string path, map<string> payload) returns map<string[]> | error= @java:Method {
    name: "sendPostRequestWithJsonPayload",
    'class: "io.ballerina.stdlib.http.testutils.ExternHttp3Client"
} external;

isolated function sendPostRequestWithXmlPayload(int port, string path, xml  payload) returns map<string[]> | error= @java:Method {
    name: "sendPostRequestWithXmlPayload",
    'class: "io.ballerina.stdlib.http.testutils.ExternHttp3Client"
} external;