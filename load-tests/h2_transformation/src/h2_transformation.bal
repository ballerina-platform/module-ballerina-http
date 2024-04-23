// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/xmldata;

listener http:Listener securedEP = new(9090,
    secureSocket = {
        key: {
            path: "./security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
);

final http:Client nettyEP = check new("https://netty:8688",
    secureSocket = {
        cert: {
            path: "./security/ballerinaTruststore.p12",
            password: "ballerina"
        },
        verifyHostName: false
    }
);

service /transform on securedEP {
    resource function post .(http:Request req) returns http:Response|error? {
        json|error payload = req.getJsonPayload();
        if payload is json {
            xml|xmldata:Error? xmlPayload = xmldata:fromJson(payload);
            if xmlPayload is xml {
                http:Request clinetreq = new;
                clinetreq.setXmlPayload(xmlPayload);
                http:Response|http:ClientError response = nettyEP->post("/service/EchoService", clinetreq);
                if response is http:Response {
                    return response;
                } else {
                    http:Response res = new;
                    res.statusCode = 500;
                    res.setPayload(response.message());
                    return res;
                }
            } else if xmlPayload is xmldata:Error {
                http:Response res = new;
                res.statusCode = 400;
                res.setPayload(xmlPayload.message());
                return res;
            }
        } else {
            http:Response res = new;
            res.statusCode = 400;
            res.setPayload(payload.message());
            return res;
        }
    }
}
