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

# The representation of an client authentication handler object type for HTTP traffic.
public type ClientAuthHandler object {

    # Enrich the request with the relevant authentication requirements.
    #
    # + req - The `http:Request` instance
    # + return - The updated `http:Request` instance or else an `http:ClientAuthError` in case of an error
    public isolated function enrich(Request req) returns Request|ClientAuthError;
};
