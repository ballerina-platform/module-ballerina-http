// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com)
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

import ballerina/http as a;

type Caller record {|
    int id;
|};

service a:Service on new a:Listener(9090) {
    r
    resource function get callerInf(@a:CallerInfo a:Caller abc) returns string {
        return "done";
    }

    resource function get callerErr1(@a:CallerInfo string abc) returns string {
        return "done"; //error
    }

    resource function post callerErr2(@a:CallerInfo @a:Payload a:Caller abc) returns string {
        return "done"; //error
    }

    resource function get callerErr3(@a:CallerInfo Caller abc) returns string {
        return "done"; //error
    }
}
