// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/lang.runtime as runtime;
import ballerina/test;
import ballerina/http;
import ballerina/mime;
import ballerina/url;
import ballerina/lang.'string as strings;
import ballerina/http_test_common as common;

int http2ClientDatabindingTestPort1 = common:getHttp2Port(clientDatabindingTestPort1);
int http2ClientDatabindingTestPort2 = common:getHttp2Port(clientDatabindingTestPort2);
int http2ClientDatabindingTestPort3 = common:getHttp2Port(clientDatabindingTestPort3);

listener http:Listener http2ClientDBProxyListener = new (http2ClientDatabindingTestPort1);
listener http:Listener http2ClientDBBackendListener = new (http2ClientDatabindingTestPort2);
listener http:Listener http2ClientDBBackendListener2 = new (http2ClientDatabindingTestPort3);
final http:Client http2ClientDBTestClient = check new ("http://localhost:" + http2ClientDatabindingTestPort1.toString(),
    http2Settings = {http2PriorKnowledge: true});
final http:Client http2ClientDBBackendClient = check new ("http://localhost:" + http2ClientDatabindingTestPort2.toString(),
    http2Settings = {http2PriorKnowledge: true});

int http2ClientDBCounter = 0;

service /passthrough on http2ClientDBProxyListener {

    resource function get allTypes(http:Caller caller, http:Request request) returns error? {
        string payload = "";

        json jsonPayload = check http2ClientDBBackendClient->post("/backend/getJson", "want json");
        payload = payload + jsonPayload.toJsonString();

        map<json> jsonMapPayload = check http2ClientDBBackendClient->post("/backend/getJson", "want json");
        json name = check jsonMapPayload.id;
        payload = payload + " | " + name.toJsonString();

        xml xmlPayload = check http2ClientDBBackendClient->post("/backend/getXml", "want xml");
        payload = payload + " | " + xmlPayload.toString();

        string stringPayload = check http2ClientDBBackendClient->post("/backend/getString", "want string");
        payload = payload + " | " + stringPayload;

        byte[] binaryPaylod = check http2ClientDBBackendClient->post("/backend/getByteArray", "want byte[]");
        string convertedPayload = check 'string:fromBytes(binaryPaylod);
        payload = payload + " | " + convertedPayload;

        ClientDBPerson person = check http2ClientDBBackendClient->post("/backend/getRecord", "want record");
        payload = payload + " | " + person.name;

        ClientDBPerson[] clients = check http2ClientDBBackendClient->post("/backend/getRecordArr", "want record[]");
        payload = payload + " | " + clients[0].name + " | " + clients[1].age.toString();

        http:Response response = check http2ClientDBBackendClient->post("/backend/getResponse", "want record[]");
        payload = payload + " | " + check response.getHeader("x-fact");

        check caller->respond(payload);
    }

    resource function get nillableTypes() returns string|error {
        string payload = "";

        json? jsonPayload = check http2ClientDBBackendClient->post("/backend/getJson", "want json");
        payload = payload + jsonPayload.toJsonString();

        map<json>? jsonMapPayload = check http2ClientDBBackendClient->post("/backend/getJson", "want json");
        if jsonMapPayload is map<json> {
            json name = check jsonMapPayload.id;
            payload = payload + " | " + name.toJsonString();
        }

        xml? xmlPayload = check http2ClientDBBackendClient->post("/backend/getXml", "want xml");
        if xmlPayload is xml {
            payload = payload + " | " + xmlPayload.toString();
        }

        string? stringPayload = check http2ClientDBBackendClient->post("/backend/getString", "want string");
        if stringPayload is string {
            payload = payload + " | " + stringPayload;
        }

        byte[]? binaryPaylod = check http2ClientDBBackendClient->post("/backend/getByteArray", "want byte[]");
        if binaryPaylod is byte[] {
            string convertedPayload = check 'string:fromBytes(binaryPaylod);
            payload = payload + " | " + convertedPayload;
        }

        return payload;
    }

    resource function get nillableRecordTypes() returns string|error {
        string payload = "";

        ClientDBPerson? person = check http2ClientDBBackendClient->post("/backend/getRecord", "want record");
        if person is ClientDBPerson {
            payload = payload + person.name;
        }

        ClientDBPerson[]? clients = check http2ClientDBBackendClient->post("/backend/getRecordArr", "want record[]");
        if clients is ClientDBPerson[] {
            payload = payload + " | " + clients[0].name + " | " + clients[1].age.toString();
        }

        return payload;
    }

    resource function get nilTypes() returns string|error {
        string payload = "";

        var jsonPayload = check http2ClientDBBackendClient->post("/backend/getNil", "want json", targetType = JsonOpt);
        if jsonPayload is () {
            payload = payload + "Nil Json";
        }

        var jsonMapPayload = check http2ClientDBBackendClient->post("/backend/getNil", "want json", targetType = MapJsonOpt);
        if jsonMapPayload is () {
            payload = payload + " | " + "Nil Map Json";
        }

        var xmlPayload = check http2ClientDBBackendClient->post("/backend/getNil", "want xml", targetType = XmlOpt);
        if xmlPayload is () {
            payload = payload + " | " + "Nil XML";
        }

        var stringPayload = check http2ClientDBBackendClient->post("/backend/getNil", "want string", targetType = StringOpt);
        if stringPayload is () {
            payload = payload + " | " + "Nil String";
        }

        var binaryPaylod = check http2ClientDBBackendClient->post("/backend/getNil", "want byte[]", targetType = ByteOpt);
        if binaryPaylod is () {
            payload = payload + " | " + "Nil Bytes";
        }

        return payload;
    }

    resource function get nilRecords() returns string|error {
        string payload = "";

        ClientDBPerson? person = check http2ClientDBBackendClient->post("/backend/getNil", "want record");
        if person is () {
            payload = payload + "NilRecord";
        }

        ClientDBPerson[]? clients = check http2ClientDBBackendClient->post("/backend/getNil", "want record[]");
        if clients is () {
            payload = payload + " | " + "NilRecordArr";
        }

        return payload;
    }

    resource function get errorReturns() returns string {
        string payload = "";

        map<json>|http:ClientError jsonMapPayload = http2ClientDBBackendClient->post("/backend/getNil", "want json");
        if jsonMapPayload is http:ClientError {
            payload = payload + jsonMapPayload.message();
        }

        xml|http:ClientError xmlPayload = http2ClientDBBackendClient->post("/backend/getNil", "want xml");
        if xmlPayload is http:ClientError {
            payload = payload + " | " + xmlPayload.message();
        }

        string|http:ClientError stringPaylod = http2ClientDBBackendClient->post("/backend/getNil", "want string");
        if stringPaylod is http:ClientError {
            payload = payload + " | " + stringPaylod.message();
        }

        return payload;
    }

    resource function get runtimeErrors() returns string {
        string[] payload = [];

        xml|json|http:ClientError unionPayload = http2ClientDBBackendClient->post("/backend/getJson", "want json");
        if unionPayload is http:ClientError {
            payload.push(unionPayload.message());
        } else if unionPayload is json {
            payload.push(unionPayload.toString());
        }

        int|string|http:ClientError basicTypeUnionPayload = http2ClientDBBackendClient->post("/backend/getString", "want string");
        if basicTypeUnionPayload is http:ClientError {
            payload.push(basicTypeUnionPayload.message());
        } else if basicTypeUnionPayload is string {
            payload.push(basicTypeUnionPayload);
        }
        return string:'join("|", ...payload);
    }

    resource function get runtimeErrorsNillable() returns string {
        string[] payload = [];

        xml?|http:ClientError unionPayload = http2ClientDBBackendClient->post("/backend/getJson", "want json");
        if unionPayload is http:ClientError {
            payload.push(unionPayload.message());
        }

        int?|http:ClientError basicTypeUnionPayload = http2ClientDBBackendClient->post("/backend/getString", "want string");
        if basicTypeUnionPayload is http:ClientError {
            payload.push(basicTypeUnionPayload.message());
        }

        return string:'join("|", ...payload);
    }

    resource function get allMethods(http:Caller caller, http:Request request) returns error? {
        string payload = "";

        // This is to check any compile failures with multiple default-able args
        json|error hello = http2ClientDBBackendClient->get("/backend/getJson");
        if hello is error {
            // log:printError("Error reading payload", 'error = hello);
        }
        json p = check http2ClientDBBackendClient->get("/backend/getJson");
        payload = payload + p.toJsonString();

        http:Response v = check http2ClientDBBackendClient->head("/backend/getXml");
        payload = payload + " | " + check v.getHeader("Content-type");

        string r = check http2ClientDBBackendClient->delete("/backend/getString", "want string");
        payload = payload + " | " + r;

        byte[] val = check http2ClientDBBackendClient->put("/backend/getByteArray", "want byte[]");
        string s = check 'string:fromBytes(val);
        payload = payload + " | " + s;

        ClientDBPerson t = check http2ClientDBBackendClient->execute("POST", "/backend/getRecord", "want record");
        payload = payload + " | " + t.name;

        ClientDBPerson[] u = check http2ClientDBBackendClient->forward("/backend/getRecordArr", request);
        payload = payload + " | " + u[0].name + " | " + u[1].age.toString();

        check caller->respond(payload);
    }

    resource function get redirect(http:Caller caller, http:Request req) returns error? {
        http:Client redirectClient = check new ("http://localhost:" + http2ClientDatabindingTestPort3.toString(),
                                                        {followRedirects: {enabled: true, maxCount: 5}});
        json p = check redirectClient->post("/redirect1/", "want json", targetType = json);
        check caller->respond(p);
    }

    resource function get 'retry(http:Caller caller, http:Request request) returns error? {
        http:Client retryClient = check new ("http://localhost:" + http2ClientDatabindingTestPort2.toString(), {
            retryConfig: {
                interval: 3,
                count: 3,
                backOffFactor: 2.0,
                maxWaitInterval: 2
            },
            timeout: 2
        }
        );
        string r = check retryClient->forward("/backend/getRetryResponse", request);
        check caller->respond(r);
    }

    resource function 'default '500(http:Caller caller, http:Request request) returns error? {
        json p = check http2ClientDBBackendClient->post("/backend/get5XX", "want 500");
        check caller->respond(p);
    }

    resource function 'default '500handle(http:Caller caller, http:Request request) returns error? {
        json|error res = http2ClientDBBackendClient->post("/backend/get5XX", "want 500");
        if res is http:RemoteServerError {
            http:Response resp = new;
            resp.statusCode = res.detail().statusCode;
            resp.setPayload(<string>res.detail().body);
            string[] val = res.detail().headers.get("X-Type");
            resp.setHeader("X-Type", val[0]);
            check caller->respond(resp);
        } else {
            json p = check res;
            check caller->respond(p);
        }
    }

    resource function 'default '404(http:Caller caller, http:Request request) returns error? {
        json p = check http2ClientDBBackendClient->post("/backend/getIncorrectPath404", "want 500");
        check caller->respond(p);
    }

    resource function 'default '404/[string path](http:Caller caller, http:Request request) returns error? {
        json|error res = http2ClientDBBackendClient->post("/backend/" + path, "want 500");
        if res is http:ClientRequestError {
            http:Response resp = new;
            resp.statusCode = res.detail().statusCode;
            resp.setPayload(<json>res.detail().body);
            check caller->respond(resp);
        } else {
            json p = check res;
            check caller->respond(p);
        }
    }

    resource function get testBody/[string path](http:Caller caller, http:Request request) returns error? {
        json p = check http2ClientDBBackendClient->get("/backend/" + path);
        check caller->respond(p);
    }

    resource function get mapOfString1() returns json|error {
        map<string> person = check http2ClientDBBackendClient->get("/backend/getFormData1");
        string? val1 = person["key1"];
        string? val2 = person["key2"];
        return {key1: val1, key2: val2};
    }

    resource function get mapOfString2() returns json|error {
        map<string> person = check http2ClientDBBackendClient->get("/backend/getFormData2");
        string? val1 = person["first Name"];
        string? val2 = person["tea$*m"];
        return {key1: val1, key2: val2};
    }

    resource function get mapOfString3() returns json|error {
        map<string> person = check http2ClientDBBackendClient->get("/backend/getFormData3");
        string? val1 = person["first Name"];
        string? val2 = person["tea$*m"];
        return {key1: val1, key2: val2};
    }

    resource function get mapOfString4() returns json|error {
        map<string> person = check http2ClientDBBackendClient->get("/backend/getFormData4");
        string? val1 = person["first Name"];
        string? val2 = person["tea$*m"];
        return {key1: val1, key2: val2};
    }

    resource function get mapOfString5() returns json|error {
        map<string> person = check http2ClientDBBackendClient->get("/backend/getFormData5");
        string? val1 = person["first Name"];
        string? val2 = person["tea$*m"];
        return {key1: val1, key2: val2};
    }

    resource function get mapOfString6() returns json|error {
        map<string> person = check http2ClientDBBackendClient->get("/backend/getFormData6");
        string? val1 = person["first Name"];
        string? val2 = person["tea$*m"];
        return {key1: val1, key2: val2};
    }
}

service /backend on http2ClientDBBackendListener {
    resource function 'default getJson(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setJsonPayload({id: "chamil", values: {a: 2, b: 45, c: {x: "mnb", y: "uio"}}});
        check caller->respond(response);
    }

    resource function 'default getXml(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        xml xmlStr = xml `<name>Ballerina</name>`;
        response.setXmlPayload(xmlStr);
        check caller->respond(response);
    }

    resource function 'default getString(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setTextPayload("This is my @4491*&&#$^($@");
        check caller->respond(response);
    }

    resource function 'default getByteArray(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setBinaryPayload("BinaryPayload is textVal".toBytes());
        check caller->respond(response);
    }

    resource function 'default getRecord(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setJsonPayload({name: "chamil", age: 15});
        check caller->respond(response);
    }

    resource function 'default getRecordArr(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setJsonPayload([{name: "wso2", age: 12}, {name: "ballerina", age: 3}]);
        check caller->respond(response);
    }

    resource function 'default getNil() {
    }

    resource function post getResponse(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.setJsonPayload({id: "hello"});
        response.setHeader("x-fact", "data-binding");
        check caller->respond(response);
    }

    resource function 'default getRetryResponse(http:Caller caller, http:Request req) returns error? {
        int count = 0;
        lock {
            http2ClientDBCounter = http2ClientDBCounter + 1;
            count = http2ClientDBCounter;
        }
        if count == 1 {
            runtime:sleep(5);
            check caller->respond("Not received");
        } else {
            check caller->respond("Hello World!!!");
        }
    }

    resource function post get5XX(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.statusCode = 501;
        response.setTextPayload("data-binding-failed-with-501");
        response.setHeader("X-Type", "test");
        check caller->respond(response);
    }

    resource function get get4XX(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        response.statusCode = 400;
        response.setTextPayload("data-binding-failed-due-to-bad-request");
        check caller->respond(response);
    }

    resource function get xmltype() returns http:NotFound {
        xml payload = xml `<test>Bad Request</test>`;
        return {body: payload};
    }

    resource function get jsontype() returns http:InternalServerError {
        json j = {id: "hello"};
        return {body: j};
    }

    resource function get binarytype() returns http:ServiceUnavailable {
        byte[] b = "ballerina".toBytes();
        return {body: b};
    }

    resource function 'default getErrorResponseWithErrorContentType() returns http:BadRequest {
        return {body: {name: "hello", age: 15}, mediaType: "application/xml"};
    }

    resource function get getFormData1() returns http:Ok|error {
        string encodedPayload1 = check url:encode("value 1", "UTF-8");
        string encodedPayload2 = check url:encode("value 2", "UTF-8");
        string payload = string `key1=${encodedPayload1}&key2=${encodedPayload2}`;
        return {body: payload, mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getFormData2() returns http:Ok|error {
        return {body: "first%20Name=WS%20O2&tea%24%2Am=Bal%40Dance", mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getFormData3() returns http:Ok|error {
        return {body: "first%20Name=WS%20O2&tea%24%2Am=", mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getFormData4() returns http:Ok|error {
        return {body: "first%20Name=WS%20O2&=Bal%40Dance", mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getFormData5() returns http:Ok|error {
        return {body: "", mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getFormData6() returns http:Ok|error {
        return {body: "first%20Name=WS%20O2", mediaType: "application/x-www-form-urlencoded"};
    }

    resource function get getUncommonMimeType1() returns http:Ok {
        return {body: {name: "Ballerina"}, mediaType: "text/javascript"};
    }

    resource function get getUncommonMimeType2() returns http:Ok {
        return {body: xml `<name>Ballerina</name>`, mediaType: "application+hello/vnd.xml"};
    }

    resource function get getUncommonMimeType3() returns http:Ok {
        return {body: xml `<name>Ballerina</name>`, mediaType: "openxml"};
    }

    resource function get getUncommonMimeType4() returns http:Ok {
        return {body: xml `<name>Ballerina</name>`, mediaType: "application/abcxml"};
    }

    resource function get getUncommonMimeType5() returns http:Ok {
        return {body: xml `<name>Ballerina</name>`, mediaType: "image/svg+xml"};
    }

    resource function get getJsonMimeType1() returns http:Ok {
        return {body: {name: "Ballerina"}, mediaType: "text/x-json"};
    }

    resource function get getJsonMimeType2() returns http:Ok {
        return {body: {name: "Ballerina"}, mediaType: "application/vnd.json"};
    }

    resource function get getJsonMimeType3() returns http:Ok {
        return {body: {name: "Ballerina"}, mediaType: "application/ld+json"};
    }

    resource function get getJsonMimeType4() returns http:Ok {
        return {body: {name: "Ballerina"}, mediaType: "APPLICATION/JSON"};
    }

    resource function get getJsonMimeType5() returns http:Ok {
        return {body: {name: "Ballerina"}, mediaType: "text/json"};
    }

    resource function get getJsonErrorMimeType1() returns http:Ok {
        return {body: {name: "Inferred by type"}, mediaType: "openjson"};
    }

    resource function get getJsonErrorMimeType2() returns http:Ok {
        return {body: {name: "Inferred by type"}, mediaType: "application/abcjson"};
    }

    resource function get getJsonErrorMimeType3() returns http:Ok {
        return {body: {name: "Inferred by type"}, mediaType: "application/json+go"};
    }

    resource function get getJsonErrorMimeType4() returns http:Ok {
        return {body: {name: "Inferred by type"}, mediaType: "image/svg+json"};
    }

    resource function get getXmlMimeType1() returns http:Ok {
        return {body: xml `<name>Ballerina</name>`, mediaType: "application/atom+xml"};
    }

    resource function get getXmlMimeType2() returns http:Ok {
        return {body: xml `<name>Ballerina</name>`, mediaType: "APPLICATION/XmL "};
    }

    resource function get getXmlMimeType3() returns http:Ok {
        return {body: xml `<name>Ballerina</name>`, mediaType: " text/xml"};
    }
}

@test:Config {}
public function testXmlMimeTypeVariations() returns error? {
    xml response = check http2ClientDBBackendClient->get("/backend/getXmlMimeType1");
    test:assertEquals(response, xml `<name>Ballerina</name>`);

    response = check http2ClientDBBackendClient->get("/backend/getXmlMimeType2");
    test:assertEquals(response, xml `<name>Ballerina</name>`);

    response = check http2ClientDBBackendClient->get("/backend/getXmlMimeType3");
    test:assertEquals(response, xml `<name>Ballerina</name>`);

}

@test:Config {}
public function testJsonErrorMimeTypeVariations() returns error? {
    json response = check http2ClientDBBackendClient->get("/backend/getJsonErrorMimeType1");
    test:assertEquals(response, {name: "Inferred by type"});

    response = check http2ClientDBBackendClient->get("/backend/getJsonErrorMimeType2");
    test:assertEquals(response, {name: "Inferred by type"});

    response = check http2ClientDBBackendClient->get("/backend/getJsonErrorMimeType3");
    test:assertEquals(response, {name: "Inferred by type"});

    response = check http2ClientDBBackendClient->get("/backend/getJsonErrorMimeType4");
    test:assertEquals(response, {name: "Inferred by type"});
}

@test:Config {}
public function testJsontMimeTypeVariations() returns error? {
    json response = check http2ClientDBBackendClient->get("/backend/getJsonMimeType1");
    test:assertEquals(response, {name: "Ballerina"});

    response = check http2ClientDBBackendClient->get("/backend/getJsonMimeType2");
    test:assertEquals(response, {name: "Ballerina"});

    response = check http2ClientDBBackendClient->get("/backend/getJsonMimeType3");
    test:assertEquals(response, {name: "Ballerina"});

    response = check http2ClientDBBackendClient->get("/backend/getJsonMimeType4");
    test:assertEquals(response, {name: "Ballerina"});

    response = check http2ClientDBBackendClient->get("/backend/getJsonMimeType5");
    test:assertEquals(response, {name: "Ballerina"});
}

@test:Config {}
public function testUncommonetMimeTypeVariations() returns error? {
    // all these cases does not goto to a particular builder, but binding type is inferred by the return type
    json jsonPayload = check http2ClientDBBackendClient->get("/backend/getUncommonMimeType1");
    test:assertEquals(jsonPayload, {name: "Ballerina"});

    xml xmlPayload = check http2ClientDBBackendClient->get("/backend/getUncommonMimeType2");
    test:assertEquals(xmlPayload, xml `<name>Ballerina</name>`);

    xmlPayload = check http2ClientDBBackendClient->get("/backend/getUncommonMimeType3");
    test:assertEquals(xmlPayload, xml `<name>Ballerina</name>`);

    xmlPayload = check http2ClientDBBackendClient->get("/backend/getUncommonMimeType4");
    test:assertEquals(xmlPayload, xml `<name>Ballerina</name>`);

    xmlPayload = check http2ClientDBBackendClient->get("/backend/getUncommonMimeType5");
    test:assertEquals(xmlPayload, xml `<name>Ballerina</name>`);
}

service /redirect1 on http2ClientDBBackendListener2 {

    resource function 'default .(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        check caller->redirect(res, http:REDIRECT_SEE_OTHER_303,
                        ["http://localhost:" + http2ClientDatabindingTestPort2.toString() + "/backend/getJson"]);
    }
}

// Test HTTP basic client with all binding data types(targetTypes)
@test:Config {
    groups: ["dataBinding"]
}
function testHttp2AllBindingDataTypes() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/allTypes");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "{\"id\":\"chamil\", \"values\":{\"a\":2, \"b\":45, " +
                "\"c\":{\"x\":\"mnb\", \"y\":\"uio\"}}} | \"chamil\" | <name>Ballerina</name> | " +
                "This is my @4491*&&#$^($@ | BinaryPayload is textVal | chamil | wso2 | 3 | data-binding");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {
    groups: ["dataBinding"]
}
function testHttp2AllBindingNillableTypes() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/nillableTypes");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "{\"id\":\"chamil\", \"values\":{\"a\":2, \"b\":45, " +
                "\"c\":{\"x\":\"mnb\", \"y\":\"uio\"}}} | \"chamil\" | <name>Ballerina</name> | " +
                "This is my @4491*&&#$^($@ | BinaryPayload is textVal");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {
    groups: ["dataBinding"]
}
function testHttp2AllBindingNillableDataTypes() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/nillableRecordTypes");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "chamil | wso2 | 3");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {
    groups: ["dataBinding"]
}
function testHttp2AllBindingNilTypes() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/nilTypes");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Nil Json | Nil Map Json | Nil XML | Nil String | Nil Bytes");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {
    groups: ["dataBinding"]
}
function testHttp2AllBindingNilRecords() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/nilRecords");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "NilRecord | NilRecordArr");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {
    groups: ["dataBinding"]
}
function testHttp2AllBindingErrorReturns() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/errorReturns");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "No content | No content | No content");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

@test:Config {
    groups: ["dataBinding"]
}
function testHttp2UnionBinding() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/runtimeErrors");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(),
            "{\"id\":\"chamil\",\"values\":{\"a\":2,\"b\":45,\"c\":{\"x\":\"mnb\",\"y\":\"uio\"}}}|This is my @4491*&&#$^($@");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {
    groups: ["dataBinding"]
}
function testHttp2AllBindingErrorsWithNillableTypes() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/runtimeErrorsNillable");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(),
            "Payload binding failed: incompatible expected type 'xml<(lang.xml:Element|lang.xml:Comment|" + 
            "lang.xml:ProcessingInstruction|lang.xml:Text)>?' for value '{\"id\":\"chamil\",\"values\":" + 
            "{\"a\":2,\"b\":45,\"c\":{\"x\":\"mnb\",\"y\":\"uio\"}}}'|incompatible typedesc int? found for 'text/plain' mime type");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
    return;
}

// Test basic client with all HTTP request methods
@test:Config {
    groups: ["dataBinding"]
}
function testHttp2DifferentMethods() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/allMethods");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "{\"id\":\"chamil\", \"values\":{\"a\":2, \"b\":45, " +
                "\"c\":{\"x\":\"mnb\", \"y\":\"uio\"}}} | application/xml | This is my @4491*&&#$^($@ | BinaryPayload" +
                " is textVal | chamil | wso2 | 3");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test HTTP redirect client data binding
@test:Config {}
function testHttp2RedirectClientDataBinding() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/redirect");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {id: "chamil", values: {a: 2, b: 45, c: {x: "mnb", y: "uio"}}};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test HTTP retry client data binding
@test:Config {}
function testHttp2RetryClientDataBinding() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/retry");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertTextPayload(response.getTextPayload(), "Hello World!!!");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 500 error panic
@test:Config {}
function testHttp25XXErrorPanic() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/500");
    if response is http:Response {
        test:assertEquals(response.statusCode, 501, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertHeaderValue(check response.getHeader("X-Type"), "test");
        common:assertTextPayload(response.getTextPayload(), "data-binding-failed-with-501");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 500 error handle
// todo: disabled due to missing feature
// @test:Config {}
function testHttp25XXHandleError() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/500handle");
    if response is http:Response {
        test:assertEquals(response.statusCode, 501, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:TEXT_PLAIN);
        common:assertHeaderValue(check response.getHeader("X-Type"), "test");
        common:assertTextPayload(response.getTextPayload(), "data-binding-failed-with-501");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 404 error panic
@test:Config {}
function testHttp24XXErrorPanic() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/404");
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "no matching resource found for path", "Not Found", 404,
                        "/backend/getIncorrectPath404", "POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 404 error handle
@test:Config {}
function testHttp24XXHandleError() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/404/handle");
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "no matching resource found for path", "Not Found", 404,
                        "/backend/handle", "POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

// Test 405 error handle
@test:Config {}
function testHttp2405HandleError() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/404/get4XX");
    if response is http:Response {
        test:assertEquals(response.statusCode, 405, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "Method not allowed", "Method Not Allowed", 405,
                        "/backend/get4XX", "POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2405AsApplicationResponseError() returns error? {
    json|error response = http2ClientDBTestClient->post("/passthrough/allMethods", "hi");
    if (response is http:ApplicationResponseError) {
        test:assertEquals(response.detail().statusCode, 405, msg = "Found unexpected output");
        common:assertErrorHeaderValue(response.detail().headers[common:CONTENT_TYPE], common:APPLICATION_JSON);
        check common:assertJsonErrorPayload(<json>response.detail().body, "Method not allowed", "Method Not Allowed", 405,
                        "/passthrough/allMethods", "POST");
    } else {
        test:assertFail(msg = "Found unexpected output type: json");
    }
}

@test:Config {}
function testHttp2XmlErrorSerialize() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/testBody/xmltype");
    if response is http:Response {
        test:assertEquals(response.statusCode, 404, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_XML);
        test:assertEquals(response.getXmlPayload(), xml `<test>Bad Request</test>`, msg = "Mismatched xml payload");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2JsonErrorSerialize() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/testBody/jsontype");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {id: "hello"});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2BinaryErrorSerialize() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/testBody/binarytype");
    if response is http:Response {
        test:assertEquals(response.statusCode, 503, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), mime:APPLICATION_OCTET_STREAM);
        var blobValue = response.getBinaryPayload();
        if (blobValue is byte[]) {
            test:assertEquals(strings:fromBytes(blobValue), "ballerina", msg = "Payload mismatched");
        } else {
            test:assertFail(msg = "Found unexpected output: " + blobValue.message());
        }
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2DetailBodyCreationFailure() {
    string|error response = http2ClientDBBackendClient->get("/backend/getErrorResponseWithErrorContentType");
    if (response is error) {
        test:assertEquals(response.message(),
            "http:ApplicationResponseError creation failed: 400 response payload extraction failed");
    } else {
        test:assertFail(msg = "Found unexpected output type: string");
    }
}

@test:Config {}
function testHttp2DBRecordErrorNegative() {
    ClientDBErrorPerson|error response = http2ClientDBBackendClient->post("/backend/getRecord", "want record");
    if (response is error) {
        common:assertTrueTextPayload(response.message(),
            "Payload binding failed: required field 'weight' not present in JSON");
    } else {
        test:assertFail(msg = "Found unexpected output type: ClientDBErrorPerson");
    }
}

@test:Config {}
function testHttp2DBRecordArrayNegative() {
    ClientDBErrorPerson[]|error response = http2ClientDBBackendClient->post("/backend/getRecordArr", "want record arr");
    if (response is error) {
        common:assertTrueTextPayload(response.message(),
            "Payload binding failed: required field 'weight' not present in JSON");
    } else {
        test:assertFail(msg = "Found unexpected output type: ClientDBErrorPerson[]");
    }
}

@test:Config {}
function testHttp2MapOfStringDataBinding() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/mapOfString1");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {"key1": "value 1", "key2": "value 2"};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2MapOfStringDataBindingWithJsonPayload() {
    map<string>|error response = http2ClientDBBackendClient->get("/backend/getJson");
    if (response is error) {
        common:assertTrueTextPayload(response.message(),
            "Payload binding failed: incompatible expected type 'string' for value '{\"a\":2,\"b\":45,\"c\":{\"x\":\"mnb\",\"y\":\"uio\"}}'");
    } else {
        test:assertFail(msg = "Found unexpected output type: map<string>");
    }
}

@test:Config {}
function testHttp2MapOfStringDataBindingWithEncodedKey() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/mapOfString2");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {"key1": "WS O2", "key2": "Bal@Dance"};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2MapOfStringDataBindingWithEmptyValue() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/mapOfString3");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {"key1": "WS O2", "key2": ""};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2MapOfStringDataBindingWithEmptyKey() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/mapOfString4");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {"key1": "WS O2", "key2": ()};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2MapOfStringDataBindingWithEmptyPayload() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/mapOfString5");
    if response is http:Response {
        test:assertEquals(response.statusCode, 500, msg = "Found unexpected output");
        check common:assertJsonErrorPayload(check response.getJsonPayload(), "No content", "Internal Server Error", 500,
                        "/passthrough/mapOfString5", "GET");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2MapOfStringDataBindingWithSinglePair() returns error? {
    http:Response|error response = http2ClientDBTestClient->get("/passthrough/mapOfString6");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        json j = {"key1": "WS O2", "key2": ()};
        common:assertJsonPayload(response.getJsonPayload(), j);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

@test:Config {}
function testHttp2NilableMapOfStringDataBindingWithEmptyPayload() {
    map<string>?|error response = http2ClientDBBackendClient->get("/backend/getFormData5");
    test:assertTrue(response is (), msg = "Found unexpected output");
}
