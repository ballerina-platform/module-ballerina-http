// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org).
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

import ballerina/http;

listener http:Listener securedEP = new (9090,
    secureSocket = {
        key: {
            path: "./security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    },
    httpVersion = "1.1"
);

final http:Client nettyEP = check new("https://netty:8688",
    secureSocket = {
        cert: {
            path: "./security/ballerinaTruststore.p12",
            password: "ballerina"
        },
        verifyHostName: false
    },
    httpVersion = "1.1"
);

service /passthrough on securedEP {
    resource function post .(http:Request clientRequest) returns http:Response|error {
        http:Response response = check nettyEP->forward("/service/EchoService", clientRequest);
        return response;
    }
}
