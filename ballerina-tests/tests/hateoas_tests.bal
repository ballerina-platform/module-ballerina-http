import ballerina/http;
import ballerina/test;

// Test representations
type Item record {|
    string name;
    string quantity;
    string milk = "TWO-PERCENT";
    string size = "GRANDE";
|};

type Order record {|
    string location;
    Item item;
    string status = "PENDING";
|};

type OrderReceipt record {|
    string id;
    *Order;
    decimal cost;
|};

type PaymentReceipt record {|
    string id;
    *Order;
    *Payment;
|};

type Payment record {|
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

@http:ServiceConfig {
    mediaTypeSubtypePrefix: "vnd.restBucks"
}
service /restBucks on new http:Listener(hateoasTestPort) {

    @http:ResourceConfig {
        name: "order",
        linkedTo: [
            {name: "orders", relation: "update", method: "put"},
            {name: "orders", relation: "status", method: "get"},
            {name: "orders", relation: "cancel", method: "delete"},
            {name: "payment", relation: "payment"}
        ]
    }
    resource function post 'order(@http:Payload Order 'order)
            returns @http:Payload{mediaType: "application/json"} OrderReceipt {
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
    resource function put payment/[string id](@http:Payload Payment payment)
            returns @http:Payload{mediaType: "application/json"} PaymentReceipt {
        return getMockPaymentReceipt(payment);
    }
}

http:Client jsonClientEP = check new(string`http://localhost:${hateoasTestPort}/restBucks`);

@test:Config {}
function testHateoasLinks1() returns error? {
    record{*http:Links; *OrderReceipt;} orderReceipt = check jsonClientEP->post("/order", mockOrder);
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
                methods: "\"\"GET\",\"POST\",\"PUT\",\"PATCH\",\"DELETE\",\"OPTIONS\",\"HEAD\"\"",
                types: "\"\"application/vnd.restBucks+json\"\""}
        },
        { 
            value: "</restBucks/orders/{id}>", 
            params: {
                rel: "\"update\"", 
                methods: "\"\"PUT\"\"",
                types: "\"\"application/vnd.restBucks+json\"\""}
        },
        { 
            value: "</restBucks/orders/{id}>", 
            params: {
                rel: "\"cancel\"", 
                methods: "\"\"DELETE\"\"",
                types: "\"\"application/vnd.restBucks+json\"\""}
        },
        { 
            value: "</restBucks/payment/{id}>", 
            params: {
                rel: "\"payment\"", 
                methods: "\"\"PUT\"\"",
                types: "\"\"application/vnd.restBucks+json\"\""}
        }
    ];
    test:assertEquals(parsedLinkHeader, expectedLinkHeader);
    
}

@test:Config {}
function testHateoasLinks2() returns error? {
    record{*http:Links; *OrderReceipt;} orderReceipt = check jsonClientEP->put("/orders/001", mockOrder);
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
                methods: "\"\"DELETE\"\"",
                types: "\"\"application/vnd.restBucks+json\"\""}
        }
    ];
    test:assertEquals(parsedLinkHeader, expectedLinkHeader);
}

@test:Config {}
function testHateoasLinks3() returns error? {
    record{*http:Links; *PaymentReceipt;} paymentReceipt = check jsonClientEP->put("/payment/001", mockPayment);
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

