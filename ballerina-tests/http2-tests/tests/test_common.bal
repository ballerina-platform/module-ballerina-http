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
import ballerina/http_test_common as common;

http:ListenerConfiguration http2SslServiceConf = {
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
};

type ClientDBPerson record {|
    string name;
    int age;
|};

type JsonOpt json?;
type MapJsonOpt map<json>?;
type XmlOpt xml?;
type StringOpt string?;
type ByteOpt byte[]?;

function getLargeHeader() returns string {
    string header = "x";
    int i = 0;
    while(i < 9000) {
        header = header + "x";
        i = i + 1;
    }
    return header.toString();
}

function getStringLengthOf(int length) returns string {
    string builder = "";
    int i = 0;
    while (i < length) {
        builder = builder + "a";
        i = i + 1;
    }
    return builder;
}

function sendResponse(http:Caller caller, http:Response res) {
    error? result = caller->respond(res);
    if result is error {
        // log:printError("Error sending backend response", 'error = result);
    }
}

function getSingletonResponse() returns http:Response {
    http:Response res = new;
    return res;
}

function setErrorResponse(http:Response response, error err) {
    response.statusCode = 500;
    response.setPayload(err.message());
}

listener http:Listener generalListener = new(generalPort, httpVersion = http:HTTP_1_1);

listener http:Listener generalHTTP2Listener = new http:Listener(http2GeneralPort);
listener http:Listener generalHTTPS2Listener = new http:Listener(http2SslGeneralPort, http2SslServiceConf);
listener http:Listener HTTP2BackendListener = new http:Listener(http2BackendPort);

http:ClientConfiguration http2headerLimitConfig = {
    responseLimits: {
        maxHeaderSize: 1024
    }
};

function setError(http:Response res, error err) {
    res.statusCode = 500;
    res.setPayload(err.message());
}

type ClientDBErrorPerson record {|
    string name;
    int age;
    float weight;
|};

final http:Client http2headerLimitClient = check new("http://localhost:" + responseLimitsTestPort2.toString()
        + "/backend/headertest2", http2headerLimitConfig);


// HATEOAS test common
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

// Interceptors test common
public type Person record {|
    string name;
    int age;
|};

service class DefaultRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("default-request-interceptor", "true");
       ctx.set("last-interceptor", "default-request-interceptor");
       return ctx.next();
    }
}

service class DataBindingRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, @http:Payload string payload, @http:Header {name: "interceptor"} string header) returns http:NextService|error? {
       ctx.set("request-payload", payload);
       ctx.set("last-interceptor", header);
       return ctx.next();
    }
}


service class LastRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       string|error val = ctx.get("last-interceptor").ensureType(string);
       string header = val is string ? val : "last-request-interceptor";
       req.setHeader("last-request-interceptor", "true");
       req.setHeader("last-interceptor", header);
       return ctx.next();
    }
}

string largePayload = "WSO2 was founded by Sanjiva Weerawarana, Paul Fremantle and Davanum Srinivas in August 2005, " +
    "backed by Intel Capital, Toba Capital, and Pacific Controls. Weerawarana[3] was an IBM researcher and a founder " +
    "of the Web services platform.[4][5] He led the creation of IBM SOAP4J,[6] which later became Apache SOAP, and was" +
    " the architect of other notable projects. Fremantle was one of the authors of IBM's Web Services Invocation Framework" +
    " and the Web Services Gateway.[7] An Apache member since the original Apache SOAP project, Freemantle oversaw the " +
    "donation of WSIF and WSDL4J to Apache and led IBM's involvement in the Axis C/C++ project. Fremantle became WSO2's chief" +
    " technology officer (CTO) in 2008,[8] and was named one of Infoworld's Top 25 CTOs that year.[9] In 2017, Tyler Jewell " +
    "took over as CEO.[10] In 2019, Vinny Smith became the Executive Chairman.[11] WSO2's first product was code-named Tungsten," +
    " and was meant for the development of web applications. Tungsten was followed by WSO2 Titanium, which later became WSO2 " +
    "Enterprise Service Bus (ESB).[12] In 2006, Intel Capital invested $4 million in WSO2,[13] and continued to invest in " +
    "subsequent years. In 2010, Godel Technologies invested in WSO2 for an unspecified amount,[14] and in 2012 the company " +
    "raised a third round of $10 million.[15][16] Official WSO2 records point to this being from Toba Capital, Cisco and " +
    "Intel Capital.[17] In August 2015, a funding round led by Pacific Controls and Toba raised another $20 million.[18][19]" +
    " The company gained recognition from a 2011 report in Information Week that eBay used WSO2 ESB as a key element of their" +
    " transaction-processing software.[20] Research firm Gartner noted that WSO2 was a leading competitor in the application " +
    "infrastructure market of 2014.[21] As of 2019, WSO2 has offices in: Mountain View, California; New York City; London, UK;" +
    " São Paulo, Brazil; Sydney, Australia; Berlin, Germany and Colombo, Sri Lanka. The bulk of its research and operations " +
    "are conducted from its main office in Colombo.[22] A subsidiary, WSO2Mobile, was launched in 2013, with Harsha Purasinghe" +
    " of Microimage as the CEO and co-founder.[23] In March 2015, WSO2.Telco was launched in partnership with Malaysian " +
    "telecommunications company Axiata,[24] which held a majority stake in the venture.[25] WSO2Mobile has since been " +
    "re-absorbed into its parent company. Historically, WSO2 has had a close connection to the Apache community, with " +
    "a significant portion of their products based on or contributing to the Apache product stack.[26] Likewise, many of " +
    "WSO2's top leadership have contributed to Apache projects. In 2013, WSO2 donated its Stratos project to Apache. ";
