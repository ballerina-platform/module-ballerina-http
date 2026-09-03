// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com)
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

service /redirects on new http:Listener(9090) {

    // A path parameter chooses the redirect target
    resource function get byPath/[string target](http:Caller caller) returns error? {
        http:Response response = new;
        check caller->redirect(response, http:REDIRECT_FOUND_302, [target]);
    }

    // A query parameter chooses the redirect target
    resource function get byQuery(http:Caller caller, string target) returns error? {
        http:Response response = new;
        check caller->redirect(response, http:REDIRECT_TEMPORARY_REDIRECT_307, [target]);
    }

    // The target is supplied through a named argument
    resource function get byNamedArgument(http:Caller caller, string target) returns error? {
        http:Response response = new;
        check caller->redirect(response, code = http:REDIRECT_FOUND_302, locations = [target]);
    }

    // Only one of several targets is caller controlled
    resource function get mixedTargets(http:Caller caller, string target) returns error? {
        http:Response response = new;
        check caller->redirect(response, http:REDIRECT_FOUND_302, ["https://example.com", target]);
    }

    // Negative case - a fixed redirect target
    resource function get fixedTarget(http:Caller caller) returns error? {
        http:Response response = new;
        check caller->redirect(response, http:REDIRECT_FOUND_302, ["https://example.com"]);
    }

    // Negative case - the parameter is not used as the target
    resource function get unusedParameter(http:Caller caller, string label) returns error? {
        http:Response response = new;
        response.setTextPayload(label);
        check caller->redirect(response, http:REDIRECT_FOUND_302, ["https://example.com"]);
    }
}
