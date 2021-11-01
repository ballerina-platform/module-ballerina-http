// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

service http:Service on new http:Listener(9090) {

    resource function get multiple1(@http:CallerInfo {respondType:string} http:Caller abc, http:Request req,
            http:Headers head, http:Caller xyz, http:Headers noo, http:Request aaa) {
        checkpanic xyz->respond("done");
    }

    resource function get multiple2(http:Caller abc, @http:CallerInfo http:Caller ccc) {
    }

    resource function get multiple3(http:Request abc, @http:CallerInfo http:Caller ccc, http:Request fwdw) {
    }

    resource function get multiple4(http:Headers abc, http:Headers ccc) {
    }
}
