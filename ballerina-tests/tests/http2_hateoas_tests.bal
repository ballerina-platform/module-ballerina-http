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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/test;

int http2HateoasTestPort = getHttp2Port(hateoasTestPort);

@http:ServiceConfig {
    mediaTypeSubtypePrefix: "vnd.restBucks"
}
service /restBucks on new http:Listener(http2HateoasTestPort) {

    @http:ResourceConfig {
        name: "order",
        linkedTo: [
            {name: "orders", relation: "update", method: "put"},
            {name: "orders", relation: "status", method: "get"},
            {name: "orders", relation: "cancel", method: "delete"},
            {name: "payment", relation: "payment"}
        ]
    }
    resource function post 'order(@http:Payload Order 'order, boolean closed)
            returns @http:Payload{mediaType: "application/json"} OrderReceipt|OrderReceiptClosed {
        if closed {
            return getMockOrderReceiptClosed('order);
        }        
        return getMockOrderReceipt('order);
    }

    @http:ResourceConfig {
        name: "orders",
        linkedTo: [
            {name: "orders", method: "get"},
            {name: "orders", relation: "update", method: "put"},
            {name: "orders", relation: "cancel", method: "delete"},
            {name: "payment", relation: "payment"}
        ]
    }
    resource function 'default orders/[string id]()
            returns @http:Payload{mediaType: "application/json"} Order {
        return getMockOrder();
    }

    @http:ResourceConfig {
        name: "orders",
        linkedTo: [
            {name: "orders", method: "put"},
            {name: "orders", relation: "status", method: "get"},
            {name: "orders", relation: "cancel", method: "delete"},
            {name: "payment", relation: "payment"}
        ]
    }
    resource function put orders/[string id](@http:Payload Order 'order)
            returns @http:Payload{mediaType: "application/json"} OrderReceipt {
        return getMockOrderReceipt('order);
    }

    @http:ResourceConfig {
        name: "orders",
        linkedTo : [{name: "orders", method: "delete"}]
    }
    resource function delete 'orders/[string id]()
            returns @http:Payload{mediaType: "application/json"} http:Ok {
        return http:OK;
    }

    @http:ResourceConfig {
        name: "payment",
        linkedTo : [
            {name: "payment"},
            {name: "orders", relation: "status", method: "get"}
        ]
    }
    resource function put payment/[string id](@http:Payload Payment payment, boolean closed)
            returns @http:Payload{mediaType: "application/json"} http:Accepted {
        if closed {
            return {body : getMockPaymentReceiptClosed(payment)};
        }
        return {body : getMockPaymentReceipt(payment)};
    }
}

http:Client http2JsonClientEP = check new(string`http://localhost:${http2HateoasTestPort}/restBucks`, http2Settings = { http2PriorKnowledge: true });

@test:Config {}
function testHttp2HateoasLinks1() returns error? {
    record{*http:Links; *OrderReceipt;} orderReceipt = check http2JsonClientEP->post("/order?closed=false", mockOrder);
    map<http:Link> expectedLinks = {
        "update": {
            rel: "update",
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:PUT]
        },
        "status": {
            rel: "status",
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: ["GET","POST","PUT","PATCH","DELETE","OPTIONS","HEAD"]
        },
        "cancel": {
            rel: "cancel",
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:DELETE]
        },
        "payment": {
            rel: "payment",
            href: "/restBucks/payment/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:PUT]
        }
    };
    test:assertEquals(orderReceipt._links, expectedLinks);
}

@test:Config {}
function testHttp2HateoasLinkHeaderWithClosedRecord() returns error? {
    http:Response res = check http2JsonClientEP->post("/order?closed=true", mockOrder);
    test:assertTrue(res.hasHeader("Link"));
    string linkHeader = check res.getHeader("Link");
    http:HeaderValue[] parsedLinkHeader = check http:parseHeader(linkHeader);
    http:HeaderValue[] expectedLinkHeader = [
        { 
            value: "</restBucks/orders/{id}>", 
            params: {
                rel: "\"update\"", 
                methods: "\"PUT\"",
                types: "\"application/vnd.restBucks+json\""}
        },
        { 
            value: "</restBucks/orders/{id}>", 
            params: {
                rel: "\"status\"",
                methods: "\"GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD\"",
                types: "\"application/vnd.restBucks+json\""}
        },
        { 
            value: "</restBucks/orders/{id}>", 
            params: {
                rel: "\"cancel\"",
                methods: "\"DELETE\"",
                types: "\"application/vnd.restBucks+json\""}
        },
        { 
            value: "</restBucks/payment/{id}>", 
            params: {
                rel: "\"payment\"",
                methods: "\"PUT\"",
                types: "\"application/vnd.restBucks+json\""}
        }
    ];
    test:assertEquals(parsedLinkHeader, expectedLinkHeader);
}

@test:Config {}
function testHttp2HateoasLinkHeaderWithReadOnlyPayload() returns error? {
    http:Response res = check http2JsonClientEP->get("/orders/001");
    test:assertTrue(res.hasHeader("Link"));
    string linkHeader = check res.getHeader("Link");
    http:HeaderValue[] parsedLinkHeader = check http:parseHeader(linkHeader);
    http:HeaderValue[] expectedLinkHeader = [
        { 
            value: "</restBucks/orders/{id}>", 
            params: {
                rel: "\"self\"",
                methods: "\"GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD\"",
                types: "\"application/vnd.restBucks+json\""}
        },
        { 
            value: "</restBucks/orders/{id}>", 
            params: {
                rel: "\"update\"",
                methods: "\"PUT\"",
                types: "\"application/vnd.restBucks+json\""}
        },
        { 
            value: "</restBucks/orders/{id}>", 
            params: {
                rel: "\"cancel\"",
                methods: "\"DELETE\"",
                types: "\"application/vnd.restBucks+json\""}
        },
        { 
            value: "</restBucks/payment/{id}>", 
            params: {
                rel: "\"payment\"",
                methods: "\"PUT\"",
                types: "\"application/vnd.restBucks+json\""}
        }
    ];
    test:assertEquals(parsedLinkHeader, expectedLinkHeader);
    
}

@test:Config {}
function testHttp2HateoasLinks2() returns error? {
    record{*http:Links; *OrderReceipt;} orderReceipt = check http2JsonClientEP->put("/orders/001", mockOrder);
    map<http:Link> expectedLinks = {
        "self": {
            rel: "self",
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:PUT]
        },
        "status": {
            rel: "status",
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: ["GET","POST","PUT","PATCH","DELETE","OPTIONS","HEAD"]
        },
        "cancel": {
            rel: "cancel",
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:DELETE]
        },
        "payment": {
            rel: "payment",
            href: "/restBucks/payment/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:PUT]
        }
    };
    test:assertEquals(orderReceipt._links, expectedLinks);
}

@test:Config {}
function testHttp2HateoasLinkHeaderWithoutBody() returns error? {
    http:Response res = check http2JsonClientEP->delete("/orders/001");
    test:assertTrue(res.hasHeader("Link"));
    string linkHeader = check res.getHeader("Link");
    http:HeaderValue[] parsedLinkHeader = check http:parseHeader(linkHeader);
    http:HeaderValue[] expectedLinkHeader = [
        { 
            value: "</restBucks/orders/{id}>", 
            params: {
                rel: "\"self\"",
                methods: "\"DELETE\"",
                types: "\"application/vnd.restBucks+json\""}
        }
    ];
    test:assertEquals(parsedLinkHeader, expectedLinkHeader);
}

@test:Config {}
function testHttp2HateoasLinksInBody() returns error? {
    record{*http:Links; *PaymentReceipt;} paymentReceipt = check http2JsonClientEP->put("/payment/001?closed=false", mockPayment);
    map<http:Link> expectedLinks = {
        "self": {
            rel: "self",
            href: "/restBucks/payment/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:PUT]
        },
        "status": {
            rel: "status",
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: ["GET","POST","PUT","PATCH","DELETE","OPTIONS","HEAD"]
        }
    };
    test:assertEquals(paymentReceipt._links, expectedLinks);
}

@test:Config {}
function testHttp2HateoasLinkHeaderWithClosedRecordInBody() returns error? {
    http:Response res = check http2JsonClientEP->put("/payment/001?closed=true", mockPayment);
    test:assertTrue(res.hasHeader("Link"));
    string linkHeader = check res.getHeader("Link");
    http:HeaderValue[] parsedLinkHeader = check http:parseHeader(linkHeader);
    http:HeaderValue[] expectedLinkHeader = [
        { 
            value: "</restBucks/payment/{id}>", 
            params: {
                rel: "\"self\"",
                methods: "\"PUT\"",
                types: "\"application/vnd.restBucks+json\""}
        },
        { 
            value: "</restBucks/orders/{id}>", 
            params: {
                rel: "\"status\"",
                methods: "\"GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD\"",
                types: "\"application/vnd.restBucks+json\""}
        }
    ];
    test:assertEquals(parsedLinkHeader, expectedLinkHeader);
}

