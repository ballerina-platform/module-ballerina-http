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

import ballerina/jballerina.java;

# Represents an HTTP/2 `PUSH_PROMISE` frame.
#
# + path - The resource path
# + method - The HTTP method
public class PushPromise {

    public string path;
    public string method;

    # Constructs an `http:PushPromise` from a given path and a method.
    #
    # + path - The resource path
    # + method - The HTTP method
    public isolated function init(string path = "/", string method = "GET") {
        self.path = path;
        self.method = method;
    }

    # Checks whether the requested header exists.
    #
    # + headerName - The header name
    # + return - A `boolean` representing the existence of a given header
    public isolated function hasHeader(string headerName) returns boolean {
        return externPromiseHasHeader(self, headerName);
    }

    # Returns the header value with the specified header name.
    # If there are more than one header value for the specified header name, the first value is returned.
    #
    # + headerName - The header name
    # + return - The header value or `()` if there is no such header
    public isolated function getHeader(string headerName) returns string {
        return externPromiseGetHeader(self, headerName);
    }

    # Gets transport headers from the `PushPromise`.
    #
    # + headerName - The header name
    # + return - The array of header values
    public isolated function getHeaders(string headerName) returns string[] {
        return externPromiseGetHeaders(self, headerName);
    }

    # Adds the specified key/value pair as an HTTP header to the `http:PushPromise`. In the case of the `Content-Type`
    # header, the existing value is replaced with the specified value.
    #
    # + headerName - The header name
    # + headerValue - The header value
    public isolated function addHeader(string headerName, string headerValue) {
        if headerName.equalsIgnoreCaseAscii(CONTENT_TYPE) {
            return externPromiseSetHeader(self, headerName, headerValue);
        }
        return externPromiseAddHeader(self, headerName, headerValue);
    }

    # Sets the value of a transport header in the `http:PushPromise`.
    #
    # + headerName - The header name
    # + headerValue - The header value
    public isolated function setHeader(string headerName, string headerValue) {
        return externPromiseSetHeader(self, headerName, headerValue);
    }

    # Removes a transport header from the `http:PushPromise`.
    #
    # + headerName - The header name
    public isolated function removeHeader(string headerName) {
        return externPromiseRemoveHeader(self, headerName);
    }

    # Removes all transport headers from the `http:PushPromise`.
    public isolated function removeAllHeaders() {
        return externPromiseRemoveAllHeaders(self);
    }

    # Gets all transport header names from the `http:PushPromise`.
    #
    # + return - An array of all transport header names
    public isolated function getHeaderNames() returns string[] {
        return externPromiseGetHeaderNames(self);
    }
}

isolated function externPromiseHasHeader(PushPromise promise, string headerName) returns boolean =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternPushPromise",
    name: "hasHeader"
} external;

isolated function externPromiseGetHeader(PushPromise promise, string headerName) returns string =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternPushPromise",
    name: "getHeader"
} external;

isolated function externPromiseGetHeaders(PushPromise promise, string headerName) returns string[] =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternPushPromise",
    name: "getHeaders"
} external;

isolated function externPromiseAddHeader(PushPromise promise, string headerName, string headerValue) =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternPushPromise",
    name: "addHeader"
} external;

isolated function externPromiseSetHeader(PushPromise promise, string headerName, string headerValue) =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternPushPromise",
    name: "setHeader"
} external;

isolated function externPromiseRemoveHeader(PushPromise promise, string headerName) =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternPushPromise",
    name: "removeHeader"
} external;

isolated function externPromiseRemoveAllHeaders(PushPromise promise) =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternPushPromise",
    name: "removeAllHeaders"
} external;

isolated function externPromiseGetHeaderNames(PushPromise promise) returns string[] =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternPushPromise",
    name: "getHeaderNames"
} external;
