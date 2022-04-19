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

# The return type of an interceptor service function
public type NextService RequestInterceptor|ResponseInterceptor|Service;

# Types of HTTP interceptor services
public type Interceptor RequestInterceptor|ResponseInterceptor|RequestErrorInterceptor|ResponseErrorInterceptor;

// Default error interceptors to handle all the unhandled errors
service class DefaultErrorInterceptor {
    *ResponseErrorInterceptor;

    remote function interceptResponseError(error err, Response alreadyBuiltErrorResponse) returns Response {
        // Returning the already built response for simplicity. This has been built with proper 
        // status code and headers (for `ApplicationResponseError` types)
        // For any other custom responses the `err` object can be used with type check
        if err is ListenerAuthnError {
            Response response = new;
            response.statusCode = 401;
            return response;
        } else if err is ListenerAuthzError {
            Response response = new;
            response.statusCode = 403;
            return response;
        }
        return alreadyBuiltErrorResponse;
    }
}
