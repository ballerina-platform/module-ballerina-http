// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/constraint;
import ballerina/data.xmldata;
import ballerina/http;
import ballerina/test;

type PurchaseOrder record {
    string id;
    int qty;
};

type ClosedOrder record {|
    string id;
    int qty;
|};

type Customer record {
    string name;
    string email;
};

type ConstrainedOrder record {
    string id;
    @constraint:Int {minValue: 1}
    int qty;
};

@xmldata:Name {value: "book"}
type Book record {
    @xmldata:Attribute
    string isbn;
    @xmldata:Name {value: "title"}
    string bookTitle;
    int year;
};

@xmldata:Namespace {uri: "http://example.com/library", prefix: "lib"}
type Library record {
    string name;
};

type Basket record {
    string owner;
    PurchaseOrder[] items;
};

type PurchaseOrderOk record {|
    *http:Ok;
    PurchaseOrder body;
|};

type XmlResponseBody record {|
    string kind;
    string value;
|};

listener http:Listener xmlRecordBindingEP = new (xmlRecordBindingTestPort);
final http:Client xmlRecordBindingClient = check new ("http://localhost:" + xmlRecordBindingTestPort.toString());
final http:StatusCodeClient xmlRecordBindingStatusCodeClient = check new ("http://localhost:" + xmlRecordBindingTestPort.toString());
final http:Client xmlRecordBindingLaxClient = check new ("http://localhost:" + xmlRecordBindingTestPort.toString(),
    laxDataBinding = true);

service class XmlPayloadReadInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req)
            returns http:NextService|error? {
        _ = check req.getXmlPayload();
        return ctx.next();
    }
}

service /xmlService on xmlRecordBindingEP {

    // ---------------------------------------------------------------- inbound

    resource function post 'order(PurchaseOrder payload) returns XmlResponseBody {
        return {kind: "PurchaseOrder", value: payload.id + ":" + payload.qty.toString()};
    }

    resource function post readonlyOrder(PurchaseOrder & readonly payload) returns XmlResponseBody {
        return {kind: "PurchaseOrder", value: payload.id + ":" + payload.qty.toString() + ":" + payload.isReadOnly().toString()};
    }

    resource function post closedOrder(ClosedOrder payload) returns XmlResponseBody {
        return {kind: "ClosedOrder", value: payload.id};
    }

    resource function post orders(PurchaseOrder[] payload) returns XmlResponseBody {
        return {kind: "PurchaseOrder[]", value: string:'join(",", ...from PurchaseOrder o in payload select o.id + ":" + o.qty.toString())};
    }

    resource function post union(PurchaseOrder|Customer payload) returns XmlResponseBody {
        if payload is PurchaseOrder {
            return {kind: "PurchaseOrder", value: payload.id};
        }
        if payload is Customer {
            return {kind: "Customer", value: payload.name};
        }
        return {kind: "none", value: ""};
    }

    resource function post nilable(PurchaseOrder? payload) returns XmlResponseBody {
        return {kind: "PurchaseOrder?", value: payload is () ? "nil" : payload.id};
    }

    resource function post constrained(ConstrainedOrder payload) returns XmlResponseBody {
        return {kind: "ConstrainedOrder", value: payload.id};
    }

    resource function post book(Book payload) returns XmlResponseBody {
        return {kind: "Book", value: payload.isbn + ":" + payload.bookTitle + ":" + payload.year.toString()};
    }

    resource function post library(Library payload) returns XmlResponseBody {
        return {kind: "Library", value: payload.name};
    }

    resource function post basket(Basket payload) returns XmlResponseBody {
        return {kind: "Basket", value: payload.owner + ":" + payload.items.length().toString()};
    }

    resource function post asXml(xml payload) returns xml {
        return payload;
    }

    @http:ResourceConfig {
        consumes: ["application/xml", "text/xml", "application/vnd.shop+xml"]
    }
    resource function post consumes(PurchaseOrder payload) returns XmlResponseBody {
        return {kind: "PurchaseOrder", value: payload.id};
    }

    // --------------------------------------------------------------- outbound

    resource function get orderAsXml() returns @http:Payload {mediaType: "application/xml"} PurchaseOrder {
        return {id: "A1", qty: 2};
    }

    resource function post orderAsXml(PurchaseOrder payload) returns @http:Payload {mediaType: "application/xml"} PurchaseOrder {
        return payload;
    }

    resource function get bookAsXml() returns @http:Payload {mediaType: "text/xml"} Book {
        return {isbn: "123", bookTitle: "Ballerina", year: 2026};
    }

    resource function get libraryAsXml() returns @http:Payload {mediaType: "application/xml"} Library {
        return {name: "Central"};
    }

    resource function get vendorXml() returns @http:Payload {mediaType: "application/vnd.shop+xml"} PurchaseOrder {
        return {id: "V1", qty: 5};
    }

    resource function get mapAsXml() returns @http:Payload {mediaType: "application/xml"} map<string> {
        return {name: "Alice"};
    }

    resource function get statusCodeXml() returns http:Ok {
        return {body: <PurchaseOrder>{id: "S1", qty: 7}, mediaType: "application/xml"};
    }

    resource function get listAsXml() returns @http:Payload {mediaType: "application/xml"} int[] {
        return [1, 2, 3];
    }

    // ----------------------------------------------------- backend for client

    resource function get backend/'order() returns http:Response {
        return xmlResponse(xml `<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>`);
    }

    resource function get backend/orders() returns http:Response {
        return xmlResponse(xml `<orders><PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder><PurchaseOrder><id>B2</id><qty>3</qty></PurchaseOrder></orders>`);
    }

    resource function get backend/customer() returns http:Response {
        return xmlResponse(xml `<Customer><name>Alice</name><email>alice@example.com</email></Customer>`);
    }

    resource function get backend/book() returns http:Response {
        return xmlResponse(xml `<book isbn="978"><title>Ballerina</title><year>2026</year></book>`);
    }

    resource function get backend/vendorOrder() returns http:Response {
        return xmlResponse(xml `<PurchaseOrder><id>V1</id><qty>9</qty></PurchaseOrder>`, "application/vnd.shop+xml");
    }

    resource function get backend/textXmlOrder() returns http:Response {
        return xmlResponse(xml `<PurchaseOrder><id>T1</id><qty>4</qty></PurchaseOrder>`, "text/xml");
    }

    resource function get backend/invalidOrder() returns http:Response {
        return xmlResponse(xml `<PurchaseOrder><id>A1</id><qty>abc</qty></PurchaseOrder>`);
    }

    resource function get backend/zeroQtyOrder() returns http:Response {
        return xmlResponse(xml `<ConstrainedOrder><id>A1</id><qty>0</qty></ConstrainedOrder>`);
    }

    resource function get backend/wrongRoot() returns http:Response {
        return xmlResponse(xml `<novel isbn="978"><title>Ballerina</title><year>2026</year></novel>`);
    }

    resource function get backend/extraElement() returns http:Response {
        return xmlResponse(xml `<ClosedOrder><id>A1</id><qty>2</qty><note>extra</note></ClosedOrder>`);
    }

    resource function get backend/empty() returns http:Response {
        http:Response res = new;
        res.setHeader("Content-Type", "application/xml");
        return res;
    }

    resource function post backend/echo(http:Request req) returns http:Response|error {
        http:Response res = new;
        res.setTextPayload(check req.getTextPayload());
        res.setHeader("X-Request-Content-Type", req.getContentType());
        return res;
    }

    resource function get backend/statusCodeOrder() returns http:Response {
        return xmlResponse(xml `<PurchaseOrder><id>S1</id><qty>7</qty></PurchaseOrder>`);
    }
}

service http:InterceptableService /xmlInterceptedService on xmlRecordBindingEP {
    public function createInterceptors() returns http:RequestInterceptor[] {
        return [new XmlPayloadReadInterceptor()];
    }

    resource function post 'order(PurchaseOrder payload) returns XmlResponseBody {
        return {kind: "PurchaseOrder", value: payload.id + ":" + payload.qty.toString()};
    }
}

function xmlResponse(xml payload, string contentType = "application/xml") returns http:Response {
    http:Response res = new;
    res.setXmlPayload(payload, contentType);
    return res;
}

function postXml(string path, string body, string contentType = "application/xml") returns http:Response|error {
    http:Request req = new;
    req.setTextPayload(body, contentType);
    return xmlRecordBindingClient->post(path, req);
}

function assertBody(http:Response res, string kind, string value) returns error? {
    test:assertEquals(res.statusCode, 201);
    json body = check res.getJsonPayload();
    test:assertEquals(body, {kind, value});
}

function assertErrorResponse(http:Response res, int statusCode, string messageSubstring) returns error? {
    test:assertEquals(res.statusCode, statusCode);
    string message = check res.getTextPayload();
    test:assertTrue(message.includes(messageSubstring), "unexpected error message: " + message);
}

// ------------------------------------------------------------------------ service inbound

@test:Config {}
function testXmlInboundRecordBinding() returns error? {
    http:Response res = check postXml("/xmlService/order", "<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>");
    check assertBody(res, "PurchaseOrder", "A1:2");
}

@test:Config {}
function testXmlInboundRecordBindingWithRecordTypedClientPayload() returns error? {
    http:Response res = check xmlRecordBindingClient->post("/xmlService/order", xml `<PurchaseOrder><id>A2</id><qty>3</qty></PurchaseOrder>`);
    check assertBody(res, "PurchaseOrder", "A2:3");
}

@test:Config {}
function testXmlInboundRecordBindingTextXml() returns error? {
    http:Response res = check postXml("/xmlService/order", "<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>", "text/xml");
    check assertBody(res, "PurchaseOrder", "A1:2");
}

@test:Config {}
function testXmlInboundRecordBindingPlusXml() returns error? {
    http:Response res = check postXml("/xmlService/order", "<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>",
        "application/vnd.shop+xml");
    check assertBody(res, "PurchaseOrder", "A1:2");
}

@test:Config {}
function testXmlInboundRecordBindingWithCharset() returns error? {
    http:Response res = check postXml("/xmlService/order", "<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>",
        "application/xml; charset=utf-8");
    check assertBody(res, "PurchaseOrder", "A1:2");
}

@test:Config {}
function testXmlInboundReadonlyRecordBinding() returns error? {
    http:Response res = check postXml("/xmlService/readonlyOrder", "<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>");
    check assertBody(res, "PurchaseOrder", "A1:2:true");
}

@test:Config {}
function testXmlInboundArrayBinding() returns error? {
    http:Response res = check postXml("/xmlService/orders",
        "<orders><PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder><PurchaseOrder><id>B2</id><qty>3</qty></PurchaseOrder></orders>");
    check assertBody(res, "PurchaseOrder[]", "A1:2,B2:3");
}

@test:Config {}
function testXmlInboundEmptyArrayBinding() returns error? {
    http:Response res = check postXml("/xmlService/orders", "<orders></orders>");
    check assertBody(res, "PurchaseOrder[]", "");
}

@test:Config {}
function testXmlInboundNestedArrayFieldBinding() returns error? {
    http:Response res = check postXml("/xmlService/basket",
        "<Basket><owner>Bob</owner><items><id>A1</id><qty>2</qty></items><items><id>B2</id><qty>3</qty></items></Basket>");
    check assertBody(res, "Basket", "Bob:2");
}

@test:Config {}
function testXmlInboundUnionBinding() returns error? {
    http:Response res = check postXml("/xmlService/union", "<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>");
    check assertBody(res, "PurchaseOrder", "A1");
    res = check postXml("/xmlService/union", "<Customer><name>Alice</name><email>alice@example.com</email></Customer>");
    check assertBody(res, "Customer", "Alice");
}

@test:Config {}
function testXmlInboundUnionBindingNoMatch() returns error? {
    http:Response res = check postXml("/xmlService/union", "<Vehicle><id>A1</id></Vehicle>");
    check assertErrorResponse(res, 400, "data binding failed");
}

@test:Config {}
function testXmlInboundNilableBinding() returns error? {
    http:Response res = check postXml("/xmlService/nilable", "<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>");
    check assertBody(res, "PurchaseOrder?", "A1");
    // A client with a dedicated connection pool is used, as a request without a body hangs on a reused connection
    http:Client emptyPayloadClient = check new ("http://localhost:" + xmlRecordBindingTestPort.toString(), poolConfig = {});
    res = check emptyPayloadClient->post("/xmlService/nilable", (), mediaType = "application/xml");
    check assertBody(res, "PurchaseOrder?", "nil");
}

@test:Config {}
function testXmlInboundAnnotations() returns error? {
    http:Response res = check postXml("/xmlService/book",
        "<book isbn=\"978\"><title>Ballerina</title><year>2026</year></book>");
    check assertBody(res, "Book", "978:Ballerina:2026");
}

@test:Config {}
function testXmlInboundNamespaceAnnotation() returns error? {
    http:Response res = check postXml("/xmlService/library",
        "<lib:Library xmlns:lib=\"http://example.com/library\"><name>Central</name></lib:Library>");
    check assertBody(res, "Library", "Central");
}

@test:Config {}
function testXmlInboundNamespaceMismatch() returns error? {
    http:Response res = check postXml("/xmlService/library",
        "<lib:Library xmlns:lib=\"http://example.com/other\"><name>Central</name></lib:Library>");
    check assertErrorResponse(res, 400, "data binding failed");
}

@test:Config {}
function testXmlInboundConstraintValidation() returns error? {
    http:Response res = check postXml("/xmlService/constrained", "<ConstrainedOrder><id>A1</id><qty>1</qty></ConstrainedOrder>");
    check assertBody(res, "ConstrainedOrder", "A1");
}

@test:Config {}
function testXmlInboundConstraintValidationFailure() returns error? {
    http:Response res = check postXml("/xmlService/constrained", "<ConstrainedOrder><id>A1</id><qty>0</qty></ConstrainedOrder>");
    check assertErrorResponse(res, 400, "payload validation failed");
}

@test:Config {}
function testXmlInboundMissingField() returns error? {
    http:Response res = check postXml("/xmlService/order", "<PurchaseOrder><id>A1</id></PurchaseOrder>");
    check assertErrorResponse(res, 400, "data binding failed");
}

@test:Config {}
function testXmlInboundTypeMismatch() returns error? {
    http:Response res = check postXml("/xmlService/order", "<PurchaseOrder><id>A1</id><qty>abc</qty></PurchaseOrder>");
    check assertErrorResponse(res, 400, "data binding failed");
}

@test:Config {}
function testXmlInboundRootNameMismatch() returns error? {
    http:Response res = check postXml("/xmlService/book",
        "<novel isbn=\"978\"><title>Ballerina</title><year>2026</year></novel>");
    check assertErrorResponse(res, 400, "data binding failed");
}

@test:Config {}
function testXmlInboundMalformedXml() returns error? {
    http:Response res = check postXml("/xmlService/order", "<PurchaseOrder><id>A1</id><qty>2</qty>");
    check assertErrorResponse(res, 400, "data binding failed");
}

@test:Config {}
function testXmlInboundEmptyPayload() returns error? {
    // A client with a dedicated connection pool is used, as a request without a body hangs on a reused connection
    http:Client emptyPayloadClient = check new ("http://localhost:" + xmlRecordBindingTestPort.toString(), poolConfig = {});
    http:Response res = check emptyPayloadClient->post("/xmlService/order", (), mediaType = "application/xml");
    check assertErrorResponse(res, 400, "data binding failed");
}

@test:Config {}
function testXmlInboundExtraElementForClosedRecord() returns error? {
    http:Response res = check postXml("/xmlService/closedOrder", "<ClosedOrder><id>A1</id><qty>2</qty><note>x</note></ClosedOrder>");
    check assertErrorResponse(res, 400, "data binding failed");
}

@test:Config {}
function testXmlInboundJsonPayloadStillBindsToRecord() returns error? {
    http:Response res = check xmlRecordBindingClient->post("/xmlService/order", {id: "J1", qty: 4});
    check assertBody(res, "PurchaseOrder", "J1:4");
}

@test:Config {}
function testXmlInboundXmlTypedParamIsUnchanged() returns error? {
    xml payload = xml `<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>`;
    xml response = check xmlRecordBindingClient->post("/xmlService/asXml", payload);
    test:assertEquals(response, payload);
}

@test:Config {}
function testXmlInboundConsumes() returns error? {
    http:Response res = check postXml("/xmlService/consumes", "<PurchaseOrder><id>C1</id><qty>1</qty></PurchaseOrder>",
        "application/vnd.shop+xml");
    check assertBody(res, "PurchaseOrder", "C1");
}

@test:Config {}
function testXmlInboundAfterInterceptorReadPayload() returns error? {
    http:Response res = check postXml("/xmlInterceptedService/order", "<PurchaseOrder><id>I1</id><qty>6</qty></PurchaseOrder>");
    check assertBody(res, "PurchaseOrder", "I1:6");
    res = check postXml("/xmlInterceptedService/order", "<PurchaseOrder><id>I1</id></PurchaseOrder>");
    check assertErrorResponse(res, 400, "data binding failed");
}

// ----------------------------------------------------------------------- service outbound

@test:Config {}
function testXmlOutboundRecord() returns error? {
    http:Response res = check xmlRecordBindingClient->/xmlService/orderAsXml;
    test:assertEquals(res.statusCode, 200);
    test:assertEquals(res.getContentType(), "application/xml");
    xml body = check res.getXmlPayload();
    test:assertEquals(body, xml `<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>`);
}

@test:Config {}
function testXmlOutboundRecordRoundTrip() returns error? {
    http:Response res = check xmlRecordBindingClient->post("/xmlService/orderAsXml",
        xml `<PurchaseOrder><id>R1</id><qty>8</qty></PurchaseOrder>`);
    test:assertEquals(res.statusCode, 201);
    test:assertEquals(res.getContentType(), "application/xml");
    PurchaseOrder 'order = check xmlRecordBindingClient->post("/xmlService/orderAsXml",
        xml `<PurchaseOrder><id>R1</id><qty>8</qty></PurchaseOrder>`);
    test:assertEquals('order, {id: "R1", qty: 8});
}

@test:Config {}
function testXmlOutboundRecordWithAnnotations() returns error? {
    http:Response res = check xmlRecordBindingClient->/xmlService/bookAsXml;
    test:assertEquals(res.getContentType(), "text/xml");
    xml body = check res.getXmlPayload();
    test:assertEquals(body, xml `<book isbn="123"><title>Ballerina</title><year>2026</year></book>`);
}

@test:Config {}
function testXmlOutboundRecordWithNamespaceAnnotation() returns error? {
    http:Response res = check xmlRecordBindingClient->/xmlService/libraryAsXml;
    xml body = check res.getXmlPayload();
    test:assertEquals(body, xml `<lib:Library xmlns:lib="http://example.com/library"><name>Central</name></lib:Library>`);
}

@test:Config {}
function testXmlOutboundRecordWithPlusXmlMediaType() returns error? {
    http:Response res = check xmlRecordBindingClient->/xmlService/vendorXml;
    test:assertEquals(res.getContentType(), "application/vnd.shop+xml");
    xml body = check res.getXmlPayload();
    test:assertEquals(body, xml `<PurchaseOrder><id>V1</id><qty>5</qty></PurchaseOrder>`);
}

@test:Config {}
function testXmlOutboundMap() returns error? {
    http:Response res = check xmlRecordBindingClient->/xmlService/mapAsXml;
    test:assertEquals(res.statusCode, 200);
    test:assertEquals(res.getContentType(), "application/xml");
    xml body = check res.getXmlPayload();
    test:assertEquals(body, xml `<name>Alice</name>`);
}

@test:Config {}
function testXmlOutboundStatusCodeResponse() returns error? {
    http:Response res = check xmlRecordBindingClient->/xmlService/statusCodeXml;
    test:assertEquals(res.statusCode, 200);
    test:assertEquals(res.getContentType(), "application/xml");
    xml body = check res.getXmlPayload();
    test:assertEquals(body, xml `<PurchaseOrder><id>S1</id><qty>7</qty></PurchaseOrder>`);
}

@test:Config {}
function testXmlOutboundNonRecordPayloadIsUnchanged() returns error? {
    http:Response res = check xmlRecordBindingClient->/xmlService/listAsXml;
    test:assertEquals(res.statusCode, 200);
    test:assertEquals(res.getContentType(), "application/xml");
    test:assertEquals(check res.getTextPayload(), "[1, 2, 3]");
}

// ----------------------------------------------------------------------------- client

@test:Config {}
function testXmlClientRecordBinding() returns error? {
    PurchaseOrder 'order = check xmlRecordBindingClient->/xmlService/backend/'order;
    test:assertEquals('order, {id: "A1", qty: 2});
}

@test:Config {}
function testXmlClientRecordBindingWithGetMethod() returns error? {
    PurchaseOrder 'order = check xmlRecordBindingClient->get("/xmlService/backend/order");
    test:assertEquals('order, {id: "A1", qty: 2});
}

@test:Config {}
function testXmlClientRecordBindingTextXml() returns error? {
    PurchaseOrder 'order = check xmlRecordBindingClient->/xmlService/backend/textXmlOrder;
    test:assertEquals('order, {id: "T1", qty: 4});
}

@test:Config {}
function testXmlClientRecordBindingPlusXml() returns error? {
    PurchaseOrder 'order = check xmlRecordBindingClient->/xmlService/backend/vendorOrder;
    test:assertEquals('order, {id: "V1", qty: 9});
}

@test:Config {}
function testXmlClientArrayBinding() returns error? {
    PurchaseOrder[] orders = check xmlRecordBindingClient->/xmlService/backend/orders;
    test:assertEquals(orders, [{id: "A1", qty: 2}, {id: "B2", qty: 3}]);
}

@test:Config {}
function testXmlClientUnionBinding() returns error? {
    PurchaseOrder|Customer result = check xmlRecordBindingClient->/xmlService/backend/customer;
    test:assertEquals(result, {name: "Alice", email: "alice@example.com"});
    result = check xmlRecordBindingClient->/xmlService/backend/'order;
    test:assertEquals(result, {id: "A1", qty: 2});
}

@test:Config {}
function testXmlClientAnnotations() returns error? {
    Book book = check xmlRecordBindingClient->/xmlService/backend/book;
    test:assertEquals(book, {isbn: "978", bookTitle: "Ballerina", year: 2026});
}

@test:Config {}
function testXmlClientNilableBinding() returns error? {
    PurchaseOrder? 'order = check xmlRecordBindingClient->/xmlService/backend/empty;
    test:assertEquals('order, ());
    'order = check xmlRecordBindingClient->/xmlService/backend/'order;
    test:assertEquals('order, {id: "A1", qty: 2});
}

@test:Config {}
function testXmlClientEmptyPayloadForNonNilableType() {
    PurchaseOrder|error result = xmlRecordBindingClient->/xmlService/backend/empty;
    test:assertTrue(result is http:NoContentError, "unexpected result");
}

@test:Config {}
function testXmlClientBindingFailure() {
    PurchaseOrder|error result = xmlRecordBindingClient->/xmlService/backend/invalidOrder;
    if result is http:PayloadBindingError {
        test:assertTrue(result.message().startsWith("Payload binding failed:"), result.message());
    } else {
        test:assertFail("expected http:PayloadBindingError");
    }
}

@test:Config {}
function testXmlClientRootNameMismatch() {
    Book|error result = xmlRecordBindingClient->/xmlService/backend/wrongRoot;
    test:assertTrue(result is http:PayloadBindingError, "unexpected result");
}

@test:Config {}
function testXmlClientConstraintValidationFailure() {
    ConstrainedOrder|error result = xmlRecordBindingClient->/xmlService/backend/zeroQtyOrder;
    if result is http:PayloadValidationError {
        test:assertTrue(result.message().startsWith("payload validation failed:"), result.message());
    } else {
        test:assertFail("expected http:PayloadValidationError");
    }
}

@test:Config {}
function testXmlClientConstraintValidationDisabled() returns error? {
    http:Client noValidationClient = check new ("http://localhost:" + xmlRecordBindingTestPort.toString(),
        validation = false);
    ConstrainedOrder 'order = check noValidationClient->/xmlService/backend/zeroQtyOrder;
    test:assertEquals('order, {id: "A1", qty: 0});
}

@test:Config {}
function testXmlClientExtraElementForClosedRecord() returns error? {
    ClosedOrder|error result = xmlRecordBindingClient->/xmlService/backend/extraElement;
    test:assertTrue(result is http:PayloadBindingError, "unexpected result");
    ClosedOrder 'order = check xmlRecordBindingLaxClient->/xmlService/backend/extraElement;
    test:assertEquals('order, {id: "A1", qty: 2});
}

@test:Config {}
function testXmlClientXmlTargetIsUnchanged() returns error? {
    xml payload = check xmlRecordBindingClient->/xmlService/backend/'order;
    test:assertEquals(payload, xml `<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>`);
}

@test:Config {}
function testXmlClientStatusCodeResponseBinding() returns error? {
    PurchaseOrderOk res = check xmlRecordBindingStatusCodeClient->/xmlService/backend/statusCodeOrder;
    test:assertEquals(res.body, {id: "S1", qty: 7});
}

@test:Config {}
function testXmlClientRecordRequestPayload() returns error? {
    http:Response res = check xmlRecordBindingClient->post("/xmlService/backend/echo", <PurchaseOrder>{id: "A1", qty: 2},
        mediaType = "application/xml");
    test:assertEquals(res.getHeader("X-Request-Content-Type"), "application/xml");
    xml body = check xml:fromString(check res.getTextPayload());
    test:assertEquals(body, xml `<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>`);
}

@test:Config {}
function testXmlClientRecordRequestPayloadWithAnnotations() returns error? {
    http:Response res = check xmlRecordBindingClient->post("/xmlService/backend/echo",
        <Book>{isbn: "978", bookTitle: "Ballerina", year: 2026}, mediaType = "text/xml");
    test:assertEquals(res.getHeader("X-Request-Content-Type"), "text/xml");
    xml body = check xml:fromString(check res.getTextPayload());
    test:assertEquals(body, xml `<book isbn="978"><title>Ballerina</title><year>2026</year></book>`);
}

@test:Config {}
function testXmlClientRecordRequestPayloadPlusXmlMediaType() returns error? {
    http:Response res = check xmlRecordBindingClient->post("/xmlService/backend/echo", <PurchaseOrder>{id: "A1", qty: 2},
        mediaType = "application/vnd.shop+xml; charset=utf-8");
    test:assertEquals(res.getHeader("X-Request-Content-Type"), "application/vnd.shop+xml; charset=utf-8");
    xml body = check xml:fromString(check res.getTextPayload());
    test:assertEquals(body, xml `<PurchaseOrder><id>A1</id><qty>2</qty></PurchaseOrder>`);
}

@test:Config {}
function testXmlClientRecordRequestPayloadRoundTrip() returns error? {
    PurchaseOrder 'order = check xmlRecordBindingClient->post("/xmlService/orderAsXml", <PurchaseOrder>{id: "R2", qty: 5},
        mediaType = "application/xml");
    test:assertEquals('order, {id: "R2", qty: 5});
}

@test:Config {}
function testXmlClientRecordRequestPayloadStillJsonByDefault() returns error? {
    http:Response res = check xmlRecordBindingClient->post("/xmlService/backend/echo", <PurchaseOrder>{id: "A1", qty: 2});
    test:assertEquals(res.getHeader("X-Request-Content-Type"), "application/json");
}

@test:Config {}
function testXmlClientNonRecordRequestPayloadIsUnchanged() returns error? {
    http:Response res = check xmlRecordBindingClient->post("/xmlService/backend/echo", [1, 2, 3],
        mediaType = "application/xml");
    test:assertEquals(res.getHeader("X-Request-Content-Type"), "application/xml");
    test:assertEquals(check res.getTextPayload(), "[1, 2, 3]");
}
