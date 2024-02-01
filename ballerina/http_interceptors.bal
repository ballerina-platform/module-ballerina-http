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

import ballerina/jwt;
import ballerina/log;

# The HTTP request interceptor service object type
public type RequestInterceptor distinct service object {

};

# The HTTP response interceptor service object type
public type ResponseInterceptor distinct service object {

};

# The HTTP request error interceptor service object type
public type RequestErrorInterceptor distinct service object {

};

# The HTTP response error interceptor service object type
public type ResponseErrorInterceptor distinct service object {

};

# The service type to be used when engaging interceptors at the service level
public type InterceptableService distinct service object {
    *Service;

    # Function to define interceptor pipeline
    #
    # + return - The `http:Interceptor|http:Interceptor[]`
    public function createInterceptors() returns Interceptor|Interceptor[];
};

# The return type of an interceptor service function
public type NextService RequestInterceptor|ResponseInterceptor|Service;

# Types of HTTP interceptor services
public type Interceptor RequestInterceptor|ResponseInterceptor|RequestErrorInterceptor|ResponseErrorInterceptor;

// Default error interceptors to handle all the unhandled errors
service class DefaultErrorInterceptor {
    *ResponseErrorInterceptor;

    remote function interceptResponseError(error err, Request request) returns Response {
        if err !is InternalError {
            log:printError("unhandled error returned from the service", err, path = request.rawPath, method = request.method);
        }
        return getErrorResponseForInterceptor(err, request);
    }
}

# The class used by the runtime to invoke the `decodeJwt` method to add jwt values to the request context.
isolated class JwtDecoder {

    # Decodes a jwt string to `[jwt:Header, jwt:Payload]`.
    #
    # + jwt - The jwt value as a string
    # + return - `[jwt:Header, jwt:Payload]` if successful or else an `error`
    isolated function decodeJwt(string jwt) returns [jwt:Header, jwt:Payload]|error {
        return jwt:decode(jwt);
    }
}
