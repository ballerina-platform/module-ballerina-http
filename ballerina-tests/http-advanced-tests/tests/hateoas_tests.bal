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

// Test representations
public type Item record {|
    string name;
    string quantity;
    string milk = "TWO-PERCENT";
    string size = "GRANDE";
|};

public type Order record {|
    string location;
    Item item;
    string status = "PENDING";
|};

public type OrderReceipt record {
    string id;
    *Order;
    decimal cost;
};

type OrderReceiptClosed record {|
    string id;
    *Order;
    decimal cost;
|};

type PaymentReceipt record {
    string id;
    *Order;
    *Payment;
};

type PaymentReceiptClosed record {|
    string id;
    *Order;
    *Payment;
|};

public type Payment record {|
    decimal amount;
    string cardHolderName;
    string cardNumber;
|};

final readonly & Order mockOrder = {
    location: "take-out",
    item: {name: "latte", quantity: "1", milk: "WHOLE"},
    status: "PAYMENT_PENDING"
};

final readonly & Payment mockPayment = {
    amount: 25,
    cardHolderName: "John",
    cardNumber: "123456789"
};

function getMockOrderReceipt(Order 'order) returns OrderReceipt {
    return {
        id: "001",
        location: 'order.location,
        item: 'order.item,
        status: "PAYMENT_REQUIRED",
        cost: 23.50
    };
}

function getMockOrderReceiptClosed(Order 'order) returns OrderReceiptClosed {
    return {
        id: "001",
        location: 'order.location,
        item: 'order.item,
        status: "PAYMENT_REQUIRED",
        cost: 23.50
    };
}

function getMockOrder() returns Order {
    return mockOrder;
}

function getMockPaymentReceipt(Payment payment) returns PaymentReceipt {
    return {
        id: "001",
        location: mockOrder.location,
        item: mockOrder.item,
        status: "PREPARING",
        amount: payment.amount,
        cardHolderName: payment.cardHolderName,
        cardNumber: payment.cardNumber
    };
}

function getMockPaymentReceiptClosed(Payment payment) returns PaymentReceiptClosed {
    return {
        id: "001",
        location: mockOrder.location,
        item: mockOrder.item,
        status: "PREPARING",
        amount: payment.amount,
        cardHolderName: payment.cardHolderName,
        cardNumber: payment.cardNumber
    };
}

@http:ServiceConfig {
    mediaTypeSubtypePrefix: "vnd.restBucks"
}
service /restBucks on new http:Listener(hateoasTestPort, httpVersion = http:HTTP_1_1) {

    @http:ResourceConfig {
        name: "order",
        linkedTo: [
            {name: "orders", relation: "update", method: "put"},
            {name: "orders", relation: "status", method: "get"},
            {name: "orders", relation: "cancel", method: "delete"},
            {name: "payment", relation: "payment"}
        ]
    }
    resource function post 'order(@http:Payload Order 'order, boolean closed) returns OrderReceipt|OrderReceiptClosed {
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
    resource function 'default orders/[string id]() returns Order {
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
    resource function put orders/[string id](@http:Payload Order 'order) returns OrderReceipt {
        return getMockOrderReceipt('order);
    }

    @http:ResourceConfig {
        name: "orders",
        linkedTo : [{name: "orders", method: "delete"}]
    }
    resource function delete 'orders/[string id]() returns http:Ok {
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

http:Client jsonClientEP = check new(string`http://localhost:${hateoasTestPort}/restBucks`, httpVersion = http:HTTP_1_1);

@test:Config {}
function testHateoasLinks1() returns error? {
    record{*http:Links; *OrderReceipt;} orderReceipt = check jsonClientEP->post("/order?closed=false", mockOrder);
    map<http:Link> expectedLinks = {
        "update": {
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:PUT]
        },
        "status": {
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: ["GET","POST","PUT","PATCH","DELETE","OPTIONS","HEAD"]
        },
        "cancel": {
            href: "/restBucks/orders/{id}",
            methods: [http:DELETE]
        },
        "payment": {
            href: "/restBucks/payment/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:PUT]
        }
    };
    test:assertEquals(orderReceipt._links, expectedLinks);
}

@test:Config {}
function testHateoasLinkHeaderWithClosedRecord() returns error? {
    http:Response res = check jsonClientEP->post("/order?closed=true", mockOrder);
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
                methods: "\"DELETE\""}
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
function testHateoasLinkHeaderWithReadOnlyPayload() returns error? {
    http:Response res = check jsonClientEP->get("/orders/001");
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
                methods: "\"DELETE\""}
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
function testHateoasLinks2() returns error? {
    record{*http:Links; *OrderReceipt;} orderReceipt = check jsonClientEP->put("/orders/001", mockOrder);
    map<http:Link> expectedLinks = {
        "self": {
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:PUT]
        },
        "status": {
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: ["GET","POST","PUT","PATCH","DELETE","OPTIONS","HEAD"]
        },
        "cancel": {
            href: "/restBucks/orders/{id}",
            methods: [http:DELETE]
        },
        "payment": {
            href: "/restBucks/payment/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:PUT]
        }
    };
    test:assertEquals(orderReceipt._links, expectedLinks);
}

@test:Config {}
function testHateoasLinkHeaderWithoutBody() returns error? {
    http:Response res = check jsonClientEP->delete("/orders/001");
    test:assertTrue(res.hasHeader("Link"));
    string linkHeader = check res.getHeader("Link");
    http:HeaderValue[] parsedLinkHeader = check http:parseHeader(linkHeader);
    http:HeaderValue[] expectedLinkHeader = [
        { 
            value: "</restBucks/orders/{id}>", 
            params: {
                rel: "\"self\"", 
                methods: "\"DELETE\""}
        }
    ];
    test:assertEquals(parsedLinkHeader, expectedLinkHeader);
}

@test:Config {}
function testHateoasLinksInBody() returns error? {
    record{*http:Links; *PaymentReceipt;} paymentReceipt = check jsonClientEP->put("/payment/001?closed=false", mockPayment);
    map<http:Link> expectedLinks = {
        "self": {
            href: "/restBucks/payment/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: [http:PUT]
        },
        "status": {
            href: "/restBucks/orders/{id}",
            types: ["application/vnd.restBucks+json"],
            methods: ["GET","POST","PUT","PATCH","DELETE","OPTIONS","HEAD"]
        }
    };
    test:assertEquals(paymentReceipt._links, expectedLinks);
}

@test:Config {}
function testHateoasLinkHeaderWithClosedRecordInBody() returns error? {
    http:Response res = check jsonClientEP->put("/payment/001?closed=true", mockPayment);
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
