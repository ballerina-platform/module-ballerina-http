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
