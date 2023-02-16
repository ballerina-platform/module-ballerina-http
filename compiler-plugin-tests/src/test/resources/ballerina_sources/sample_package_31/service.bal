// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/io;

public type BaseMessage record {|
    string mtype;
    string id?;
|};

public type SimpleMessage record {|
    *BaseMessage;
    "stype" mtype = "stype";
    Meta meta?;
    string message;
|};

public type MetaA record {|
    string mversion;
    Meta metadata?;
    string strId;
|};

public type MetaB record {|
    string mversion;
    Meta metadata?;
    int intId;
|};

public type Meta MetaA | MetaB;

service / on new http:Listener(9090) {
    resource function post greeting(@http:Payload SimpleMessage msg) returns string|error {
        io:println(msg.message);

        return "Received";
    }
}
