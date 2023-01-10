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
import ballerina/test;
import ballerina/http;
import ballerina/http_test_common as common;

listener http:Listener serviceChainingListenerEP = new (serviceChainingTestPort, httpVersion = http:HTTP_1_1);
final http:Client serviceChainingClient = check new ("http://localhost:" + serviceChainingTestPort.toString(), httpVersion = http:HTTP_1_1);

final http:Client bankInfoService = check new ("http://localhost:" + serviceChainingTestPort.toString() + "/bankinfo/product", httpVersion = http:HTTP_1_1);
final http:Client branchLocatorService = check new ("http://localhost:" + serviceChainingTestPort.toString() + "/branchlocator/product", httpVersion = http:HTTP_1_1);

service /ABCBank on serviceChainingListenerEP {

    resource function post locator(http:Caller caller, http:Request req) returns error? {

        http:Request backendServiceReq = new;
        var jsonLocatorReq = req.getJsonPayload();
        if (jsonLocatorReq is json) {
            var code = jsonLocatorReq.ATMLocator.ZipCode;
            string zipCode = code is error ? code.toString() : code.toString();
            io:println("Zip Code " + zipCode);
            map<map<json>> branchLocatorReq = {"BranchLocator": {"ZipCode": ""}};
            branchLocatorReq["BranchLocator"]["ZipCode"] = zipCode;
            backendServiceReq.setPayload(branchLocatorReq);
        } else {
            io:println("Error occurred while reading ATM locator request");
        }

        http:Response locatorResponse = new;
        http:Response|error locatorRes = branchLocatorService->post("", backendServiceReq);
        if (locatorRes is http:Response) {
            locatorResponse = locatorRes;
        } else {
            io:println("Error occurred while reading locator response");
        }

        var branchLocatorRes = locatorResponse.getJsonPayload();
        if (branchLocatorRes is json) {
            var code = branchLocatorRes.ABCBank.BranchCode;
            string branchCode = code is error ? code.toString() : code.toString();
            io:println("Branch Code " + branchCode);
            map<map<json>> bankInfoReq = {"BranchInfo": {"BranchCode": ""}};
            bankInfoReq["BranchInfo"]["BranchCode"] = branchCode;
            backendServiceReq.setJsonPayload(bankInfoReq);
        } else {
            io:println("Error occurred while reading branch locator response");
        }

        http:Response informationResponse = new;
        http:Response|error infoRes = bankInfoService->post("", backendServiceReq);
        if (infoRes is http:Response) {
            informationResponse = infoRes;
        } else {
            io:println("Error occurred while writing info response");
        }
        check caller->respond(informationResponse);
    }
}

service /bankinfo on serviceChainingListenerEP {

    resource function post product(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        var jsonRequest = req.getJsonPayload();
        if (jsonRequest is json) {
            var code = jsonRequest.BranchInfo.BranchCode;
            string branchCode = code is error ? code.toString() : code.toString();
            json payload = {};
            if (branchCode == "123") {
                payload = {"ABC Bank": {"Address": "111 River Oaks Pkwy, San Jose, CA 95999"}};
            } else {
                payload = {"ABC Bank": {"error": "No branches found."}};
            }
            res.setPayload(payload);
        } else {
            io:println("Error occurred while reading bank info request");
        }

        check caller->respond(res);
    }
}

service /branchlocator on serviceChainingListenerEP {

    resource function post product(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        var jsonRequest = req.getJsonPayload();
        if (jsonRequest is json) {
            var code = jsonRequest.BranchLocator.ZipCode;
            string zipCode = code is error ? code.toString() : code.toString();
            json payload = {};
            if (zipCode == "95999") {
                payload = {"ABCBank": {"BranchCode": "123"}};
            } else {
                payload = {"ABCBank": {"BranchCode": "-1"}};
            }
            res.setPayload(payload);
        } else {
            io:println("Error occurred while reading bank locator request");
        }

        check caller->respond(res);
    }
}

json requestMessage = {ATMLocator: {ZipCode: "95999"}};
json responseMessage = {"ABC Bank": {Address: "111 River Oaks Pkwy, San Jose, CA 95999"}};

//Test service chaining sample
@test:Config {}
function testServiceChaining() returns error? {
    http:Response|error response = serviceChainingClient->post("/ABCBank/locator", requestMessage);
    if response is http:Response {
        test:assertEquals(response.statusCode, 200, msg = "Found unexpected output");
        common:assertHeaderValue(check response.getHeader(common:CONTENT_TYPE), common:APPLICATION_JSON);
        common:assertJsonPayload(response.getJsonPayload(), responseMessage);
    } else {
        test:assertFail(msg = "Found unexpected output type: " + response.message());
    }
}
