// // Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
// //
// // WSO2 Inc. licenses this file to you under the Apache License,
// // Version 2.0 (the "License"); you may not use this file except
// // in compliance with the License.
// // You may obtain a copy of the License at
// //
// // http://www.apache.org/licenses/LICENSE-2.0
// //
// // Unless required by applicable law or agreed to in writing,
// // software distributed under the License is distributed on an
// // "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// // KIND, either express or implied.  See the License for the
// // specific language governing permissions and limitations
// // under the License.

// import ballerina/http;
// import ballerina/io;
// import ballerina/test;

// service /proxy on new http:Listener(proxyTestPort1) {

//     resource function post server(http:Caller caller, http:Request req) {
//         http:Response res = new;
//         res.setTextPayload("Backend server sent the response");
//         check caller->respond(res);
//     }
// }

// service on new http:Listener(proxyTestPort2) {

//     resource function 'default .(http:Caller caller, http:Request req) {
//         string url = <@untainted> req.rawPath;
//         io:println(url);
//         sendRequest(url, <@untainted> req, <@untainted> caller);
//     }
// }

// function sendRequest(string url, http:Request req, http:Caller caller) {
//     http:Client clientEP = check new(url);
//     http:Response|error response = clientEP->forward("", req);
//     if response is http:Response {
//         check caller->respond(<@untainted>response);
//     } else {
//         check caller->respond(<@untainted>response.message());
//     }
// }

// http:ClientConfiguration clientEPConfig  = {
//     http1Settings: {
//         proxy: {
//             host:"localhost",
//             port:proxyTestPort2
//         }
//     }
// };

// @test:Config {}
// public function testProxyClient() {
//     http:Client clientEP2 = check new("http://localhost:" + proxyTestPort1.toString(), clientEPConfig);
//     http:Request req = new;
//     http:Response|error resp = clientEP2->post("/proxy/server", req);
//     if resp is http:Response {
//         var payload = resp.getTextPayload();
//         if payload is string {
//             test:assertEquals(payload, "Backend server sent the response");
//         } else {
//             test:assertFail(msg = "Found unexpected output: " +  payload.message());
//         }
//     } else {
//         test:assertFail(msg = "Found unexpected output: " +  resp.message());
//     }
// }
