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

import ballerina/auth;
import ballerina/jballerina.java;
import ballerina/jwt;
import ballerina/log;
import ballerina/oauth2;

// This function is used for declarative auth design, where the authentication/authorization decision is taken by
// reading the auth annotations provided in service/resource and the `Authorization` header taken with an interop call.
// This function is injected to the first lines of an http resource function. Then the logic will be executed during
// the runtime.
// If this function returns `()`, it will be moved to the execution of business logic, else there will be a 401/403
// response sent by the `http:Caller` which is taken with an interop call. The execution flow will be broken by panic
// with a distinct error.
# Uses for declarative auth design, where the authentication/authorization decision is taken
# by reading the auth annotations provided in service/resource and the `Authorization` header of request.
# 
# + serviceRef - The service reference where the resource locates
# + methodName - The name of the subjected resource
# + resourcePath - The relative path
public isolated function authenticateResource(Service serviceRef, string methodName, string[] resourcePath) {
    ListenerAuthConfig[]? authConfig = getListenerAuthConfig(serviceRef, methodName, resourcePath);
    if (authConfig is ()) {
        return;
    }
    string|HeaderNotFoundError header = getAuthorizationHeader();
    if (header is string) {
        Unauthorized|Forbidden? result = tryAuthenticate(<ListenerAuthConfig[]>authConfig, header);
        if (result is Unauthorized) {
            sendResponse(create401Response());
        } else if (result is Forbidden) {
            sendResponse(create403Response());
        }
    } else {
        sendResponse(create401Response());
    }
}

isolated function tryAuthenticate(ListenerAuthConfig[] authHandlers, string header) returns Unauthorized|Forbidden? {
    foreach ListenerAuthConfig config in authHandlers {
        if (config is FileUserStoreConfigWithScopes) {
            ListenerFileUserStoreBasicAuthHandler handler = new(config.fileUserStoreConfig);
            auth:UserDetails|Unauthorized authn = handler.authenticate(header);
            string|string[]? scopes = config?.scopes;
            if (authn is auth:UserDetails) {
                if (scopes is string|string[]) {
                    Forbidden? authz = handler.authorize(authn, scopes);
                    return authz;
                }
                return;
            }
        } else if (config is LdapUserStoreConfigWithScopes) {
            ListenerLdapUserStoreBasicAuthProvider handler = new(config.ldapUserStoreConfig);
            auth:UserDetails|Unauthorized authn = handler->authenticate(header);
            string|string[]? scopes = config?.scopes;
            if (authn is auth:UserDetails) {
                if (scopes is string|string[]) {
                    Forbidden? authz = handler->authorize(authn, scopes);
                    return authz;
                }
                return;
            }
        } else if (config is JwtValidatorConfigWithScopes) {
            ListenerJwtAuthHandler handler = new(config.jwtValidatorConfig);
            jwt:Payload|Unauthorized authn = handler.authenticate(header);
            string|string[]? scopes = config?.scopes;
            if (authn is jwt:Payload) {
                if (scopes is string|string[]) {
                    Forbidden? authz = handler.authorize(authn, scopes);
                    return authz;
                }
                return;
            }
        } else {
            // Here, config is OAuth2IntrospectionConfigWithScopes
            ListenerOAuth2Handler handler = new(config.oauth2IntrospectionConfig);
            oauth2:IntrospectionResponse|Unauthorized|Forbidden auth = handler->authorize(header, config?.scopes);
            if (auth is oauth2:IntrospectionResponse) {
                return;
            } else if (auth is Forbidden) {
                return auth;
            }
        }
    }
    Unauthorized unauthorized = {};
    return unauthorized;
}

isolated function getListenerAuthConfig(Service serviceRef, string methodName, string[] resourcePath)
                                        returns ListenerAuthConfig[]? {
    ListenerAuthConfig[]? resourceAuthConfig = getResourceAuthConfig(serviceRef, methodName, resourcePath);
    if (resourceAuthConfig is ListenerAuthConfig[]) {
        return resourceAuthConfig;
    }
    ListenerAuthConfig[]? serviceAuthConfig = getServiceAuthConfig(serviceRef);
    if (serviceAuthConfig is ListenerAuthConfig[]) {
        return serviceAuthConfig;
    }
}

isolated function getServiceAuthConfig(Service serviceRef) returns ListenerAuthConfig[]? {
    typedesc<any> serviceTypeDesc = typeof serviceRef;
    var serviceAnnotation = serviceTypeDesc.@ServiceConfig;
    if (serviceAnnotation is ()) {
        return;
    }
    HttpServiceConfig serviceConfig = <HttpServiceConfig>serviceAnnotation;
    return serviceConfig?.auth;
}

isolated function getResourceAuthConfig(Service serviceRef, string methodName, string[] resourcePath)
                                        returns ListenerAuthConfig[]? {
    string resourceName = "$" + methodName;
    foreach string path in resourcePath {
        resourceName += "$" + path;
    }
    any resourceAnnotation = getResourceAnnotation(serviceRef, resourceName);
    if (resourceAnnotation is ()) {
        return;
    }
    HttpResourceConfig resourceConfig = <HttpResourceConfig>resourceAnnotation;
    return resourceConfig?.auth;
}

isolated function create401Response() returns Response {
    Response response = new;
    response.statusCode = 401;
    return response;
}

isolated function create403Response() returns Response {
    Response response = new;
    response.statusCode = 403;
    return response;
}

isolated function sendResponse(Response response) {
    Caller caller = getCaller();
    error? err = caller->respond(response);
    if (err is error) {
        log:printError("Failed to respond the 401/403 request.", 'error = err);
    }
    // This panic is added to break the execution of the implementation inside the resource function after there is
    // an authn/authz failure and responded with 401/403 internally.
    panic error("Already responded by auth desugar.");
}

isolated function getAuthorizationHeader() returns string|HeaderNotFoundError = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHeaders"
} external;

isolated function getCaller() returns Caller = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternCaller"
} external;

isolated function getResourceAnnotation(service object {} serviceType, string resourceName) returns any = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternResource"
} external;
