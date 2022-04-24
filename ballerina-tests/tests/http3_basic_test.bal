import ballerina/http;
import ballerina/jballerina.java;
import ballerina/test;
import ballerina/io;

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

    service / on http3SslListener {

     resource function get hello(http:Caller caller,http:Request req) returns error? {

          string msg = "Hello!";
          string length = msg.length().toBalString();
          http:Response response = new;
          response.setHeader("content-length",length);
          response.setHeader("content-type","text/plain");
          response.setHeader("server","wso2");
          response.setPayload(msg);
          check caller->respond(response);
     }

     resource function post getPayload(http:Caller caller,http:Request payload) returns error? {


        string|http:ClientError textPayload = payload.getTextPayload();
        http:Response response = new;
        // io:println(textPayload);
        // io:println("textPayload");
        if textPayload is string {
            response.setPayload(textPayload); 
        }
        if textPayload is http:ClientError {
          string  msg = "Found unexpected output for TEXT: " +  textPayload.message();
          io:println(msg);
        }
          check caller->respond(response);
     }

     resource function post getJsonPayload(http:Caller caller,http:Request payload) returns error? {

        json|http:ClientError jsonPayload = payload.getJsonPayload();
            http:Response response = new;
        
        if jsonPayload is json { 
        io:println(jsonPayload);
        string msgs = "JSON PAYLOAD RECEIVED!";
                response.setPayload(msgs); 

        }
        if jsonPayload is http:ClientError {
          string  msg = "Found unexpected output for JSON: " +  jsonPayload.message();
          io:println(msg);
        }

        check caller->respond(response);

     }
    


     resource function post getXMLPayload(http:Caller caller,http:Request payload) returns error? {

        xml|http:ClientError xmlPayload = payload.getXmlPayload();
            http:Response response = new;


        if xmlPayload is xml {
            io:println(xmlPayload);
            string msgs = "XML PAYLOAD RECEIVED!";
                response.setPayload(msgs); 
        }
        if xmlPayload is http:ClientError {
          string  msg = "Found unexpected output for XML: " +  xmlPayload.message();
          io:println(msg);
        }

          check caller->respond(response);
     }
    }
    

     @test:Config {}
        public function testHttp3Get() returns string | error?  {

        string|error response = getRequests(http3TestPort,"/hello");

        // io:println(response);
        // if response is string{
        //     test:assertEquals(response, "Hello!", msg = "Payload not matched");
        // } else {
        //     test:assertFail("Invalid type");
        // }

     }

     @test:Config {}
        public function testHttp3PostWithTextPayload() returns string | error?  {

        string|error response = postRequests(http3TestPort,"/getPayload","TEXT VALUE");
        io:println("RES TEXT");
        io:println(response);

        // if response is map<string>{
        //     string? b = response["Body"];
        //     test:assertEquals(b, "JSON PAYLOAD RECEIVED!", msg = "Payload not matched");
        // } else {
        //     test:assertFail("Invalid type");
        // }
     }

    @test:Config {}
    public function testHttp3PostRequestWithJsonPayload() {
            
            map<string> payload = {"name": "sara","age": "2" };

            string|error response = sendPostRequestWithJsonPayload(http3TestPort,"/getJsonPayload",payload);
            io:println("RES JSON");
            io:println(response);


            // if response is json{
            //     test:assertEquals(response, "PAYLOAD RECEIVED!", msg = "Payload not matched");
            // } else {
            //     test:assertFail("Invalid type");
            // } 

    }

 @test:Config {}
    public function testHttp3PostRequestWithXmlPayload() {
            
            xml data = xml `<name>Hello World</name>`;
            // map<xml> payload =  data;


            string|error response = sendPostRequestWithXmlPayload(http3TestPort,"/getXMLPayload",data);
            io:println("RES XML");
            io:println(response);

            // if response is string{
    //             test:assertEquals(response, "PAYLOAD RECEIVED!", msg = "Payload not matched");
    //         } else {
    //             test:assertFail("Invalid type");
    //         } 

    }
     
isolated function getRequests(int port,string path) returns string | error= @java:Method {
    name: "sendGetRequest",
    'class: "io.ballerina.stdlib.http.testutils.ExternHttp3Client"
} external;

// isolated function postRequests(int port,string path, string payload) returns map<string> | error= @java:Method {
isolated function postRequests(int port,string path, string payload) returns string | error= @java:Method {
    name: "sendPostRequestWithStringPayload",
    'class: "io.ballerina.stdlib.http.testutils.ExternHttp3Client"
} external;

isolated function sendPostRequestWithJsonPayload(int port,string path, map<string> payload) returns string |error= @java:Method {
    name: "sendPostRequestWithJsonPayload",
    'class: "io.ballerina.stdlib.http.testutils.ExternHttp3Client"
} external;

isolated function sendPostRequestWithXmlPayload(int port, string path, xml  payload) returns string|error= @java:Method {
    name: "sendPostRequestWithXmlPayload",
    'class: "io.ballerina.stdlib.http.testutils.ExternHttp3Client"
} external;