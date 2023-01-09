// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/io;
import ballerina/http;
import ballerina/lang.'string as strings;
import ballerina/test;
import ballerina/http_test_common as common;

listener http:Listener ecommerceListenerEP = new (ecommerceTestPort, httpVersion = http:HTTP_1_1);
final http:Client ecommerceClient = check new ("http://localhost:" + ecommerceTestPort.toString(), httpVersion = http:HTTP_1_1);

service /customerservice on ecommerceListenerEP {

    resource function 'default customers(http:Caller caller, http:Request req) returns error? {
        json payload = {};
        string httpMethod = req.method;
        if strings:equalsIgnoreCaseAscii(httpMethod, "GET") {
            payload = {"Customer": {"ID": "987654", "Name": "ABC PQR", "Description": "Sample Customer."}};
        } else {
            payload = {"Status": "Customer is successfully added."};
        }

        http:Response res = new;
        res.setJsonPayload(payload);
        check caller->respond(res);
    }

    function getCustomers() {
        //This function is to test the object function holding capability in a http service
    }
}

final http:Client productsService = check new ("http://localhost:" + ecommerceTestPort.toString(), httpVersion = http:HTTP_1_1);

service /ecommerceservice on ecommerceListenerEP {

    resource function get products/[string prodId](http:Caller caller, http:Request req) returns error? {
        string reqPath = "/productsservice/" + prodId;
        http:Response|error clientResponse = productsService->get(reqPath);
        if clientResponse is http:Response {
            check caller->respond(clientResponse);
        } else {
            io:println("Error occurred while reading product response");
        }
    }

    resource function post products(http:Caller caller, http:Request req) returns error? {
        http:Request clientRequest = new;
        var jsonReq = req.getJsonPayload();
        if jsonReq is json {
            clientRequest.setPayload(jsonReq);
        } else {
            io:println("Error occurred while reading products payload");
        }

        http:Response clientResponse = new;
        http:Response|error clientRes = productsService->post("/productsservice", clientRequest);
        if clientRes is http:Response {
            clientResponse = clientRes;
        } else {
            io:println("Error occurred while reading locator response");
        }
        check caller->respond(clientResponse);
    }

    resource function get orders(http:Caller caller, http:Request req) returns error? {
        http:Response|error clientResponse = productsService->get("/orderservice/orders");
        if clientResponse is http:Response {
            check caller->respond(clientResponse);
        } else {
            io:println("Error occurred while reading orders response");
        }
    }

    resource function post orders(http:Caller caller, http:Request req) returns error? {
        http:Request clientRequest = new;
        http:Response|error clientResponse = productsService->post("/orderservice/orders", clientRequest);
        if clientResponse is http:Response {
            check caller->respond(clientResponse);
        } else {
            io:println("Error occurred while writing orders response");
        }
    }

    resource function get customers(http:Caller caller, http:Request req) returns error? {
        http:Response|error clientResponse = productsService->get("/customerservice/customers");
        if clientResponse is http:Response {
            check caller->respond(clientResponse);
        } else {
            io:println("Error occurred while reading customers response");
        }
    }

    resource function post customers(http:Caller caller, http:Request req) returns error? {
        http:Request clientRequest = new;
        http:Response|error clientResponse = productsService->post("/customerservice/customers", clientRequest);
        if clientResponse is http:Response {
            check caller->respond(clientResponse);
        } else {
            io:println("Error occurred while writing customers response");
        }
    }
}

service /orderservice on ecommerceListenerEP {

    resource function 'default orders(http:Caller caller, http:Request req) returns error? {
        json payload = {};
        string httpMethod = req.method;
        if strings:equalsIgnoreCaseAscii(httpMethod, "GET") {
            payload = {"Order": {"ID": "111999", "Name": "ABC123", "Description": "Sample order."}};
        } else {
            payload = {"Status": "Order is successfully added."};
        }

        http:Response res = new;
        res.setJsonPayload(payload);
        check caller->respond(res);
    }
}

isolated map<anydata> productsMap = populateSampleProducts().clone();

service /productsservice on ecommerceListenerEP {

    resource function get [string prodId](http:Caller caller, http:Request req) returns error? {
        lock {
            http:Response res = new;
            var result = productsMap[prodId].cloneWithType(json);
            if result is json {
                res.setPayload(result);
            } else {
                res.setPayload(result.message());
            }
            check caller->respond(res);
        }
    }

    resource function post .(http:Caller caller, http:Request req) returns error? {
        var jsonReq = req.getJsonPayload();
        if jsonReq is json {
            var id = jsonReq.Product.ID;
            string productId = id is error ? id.toString() : id.toString();
            lock {
                productsMap[productId.clone()] = jsonReq.clone();
            }
            json payload = {"Status": "Product is successfully added."};

            http:Response res = new;
            res.setPayload(payload);
            check caller->respond(res);
        } else {
            io:println("Error occurred while reading bank locator request");
        }
    }
}

function populateSampleProducts() returns (map<anydata>) {
    map<anydata> productsMap = {};
    json prod_1 = {"Product": {"ID": "123000", "Name": "ABC_1", "Description": "Sample product."}};
    json prod_2 = {"Product": {"ID": "123001", "Name": "ABC_2", "Description": "Sample product."}};
    json prod_3 = {"Product": {"ID": "123002", "Name": "ABC_3", "Description": "Sample product."}};
    productsMap["123000"] = prod_1;
    productsMap["123001"] = prod_2;
    productsMap["123002"] = prod_3;
    io:println("Sample products are added.");
    return productsMap;
}

//Test resource GET products in E-Commerce sample
@test:Config {}
function testGetProducts() returns error? {
    http:Response|error response = ecommerceClient->get("/ecommerceservice/products/123001");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {Product: {ID: "123001", Name: "ABC_2", Description: "Sample product."}});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test resource GET orders in E-Commerce sample
@test:Config {}
function testGetOrders() returns error? {
    http:Response|error response = ecommerceClient->get("/ecommerceservice/orders");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {Order: {ID: "111999", Name: "ABC123", Description: "Sample order."}});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test resource GET customers in E-Commerce sample
@test:Config {}
function testGetCustomers() returns error? {
    http:Response|error response = ecommerceClient->get("/ecommerceservice/customers");
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {Customer: {ID: "987654", Name: "ABC PQR", Description: "Sample Customer."}});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test resource POST orders in E-Commerce sample
@test:Config {}
function testPostOrder() returns error? {
    http:Request req = new;
    req.setJsonPayload({Order: {ID: "111222", Name: "XYZ123"}});
    http:Response|error response = ecommerceClient->post("/ecommerceservice/orders", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {Status: "Order is successfully added."});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test resource POST products in E-Commerce sample
@test:Config {}
function testPostProduct() returns error? {
    http:Request req = new;
    req.setJsonPayload({Product: {ID: "123345", Name: "PQR"}});
    http:Response|error response = ecommerceClient->post("/ecommerceservice/products", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {Status: "Product is successfully added."});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

//Test resource POST customers in E-Commerce sample
@test:Config {}
function testPostCustomers() returns error? {
    http:Request req = new;
    req.setJsonPayload({Customer: {ID: "97453", Name: "ABC XYZ"}});
    http:Response|error response = ecommerceClient->post("/ecommerceservice/customers", req);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), {Status: "Customer is successfully added."});
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}

