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
    if authConfig is () {
        return;
    }
    string|HeaderNotFoundError header = getAuthorizationHeader();
    if header is string {
        Unauthorized|Forbidden? result = tryAuthenticate(<ListenerAuthConfig[]>authConfig, header);
        if result is Unauthorized {
            sendResponse(create401Response());
        } else if result is Forbidden {
            sendResponse(create403Response());
        }
    } else {
        sendResponse(create401Response());
    }
}

isolated map<ListenerAuthHandler> authHandlers = {};

isolated function tryAuthenticate(ListenerAuthConfig[] authConfig, string header) returns Unauthorized|Forbidden? {
    string scheme = extractScheme(header);
    Unauthorized|Forbidden? authResult = <Unauthorized>{};
    foreach ListenerAuthConfig config in authConfig {
        if scheme is AUTH_SCHEME_BASIC {
            if config is FileUserStoreConfigWithScopes {
                authResult = authenticateWithFileUserStore(config, header);
            } else if config is LdapUserStoreConfigWithScopes {
                authResult = authenticateWithLdapUserStoreConfig(config, header);
            } else {
                log:printDebug("Invalid auth configurations for 'Basic' scheme.");
            }
        } else if scheme is AUTH_SCHEME_BEARER {
            if config is JwtValidatorConfigWithScopes {
                authResult = authenticateWithJwtValidatorConfig(config, header);
            } else if config is OAuth2IntrospectionConfigWithScopes {
                authResult = authenticateWithOAuth2IntrospectionConfig(config, header);
            } else {
                log:printDebug("Invalid auth configurations for 'Bearer' scheme.");
            }
        }
        if authResult is () || authResult is Forbidden {
            return authResult;
        }
    }
    return authResult;
}

isolated function authenticateWithFileUserStore(FileUserStoreConfigWithScopes config, string header)
                                                returns Unauthorized|Forbidden? {
    ListenerFileUserStoreBasicAuthHandler handler;
    lock {
        string key = config.fileUserStoreConfig.toString();
        if authHandlers.hasKey(key) {
            handler = <ListenerFileUserStoreBasicAuthHandler> authHandlers.get(key);
        } else {
            handler = new(config.fileUserStoreConfig.cloneReadOnly());
            authHandlers[key] = handler;
        }
    }
    auth:UserDetails|Unauthorized authn = handler.authenticate(header);
    string|string[]? scopes = config?.scopes;
    if authn is auth:UserDetails {
        if scopes is string|string[] {
            Forbidden? authz = handler.authorize(authn, scopes);
            return authz;
        }
        return;
    }
    return authn;
}

isolated function authenticateWithLdapUserStoreConfig(LdapUserStoreConfigWithScopes config, string header)
                                                      returns Unauthorized|Forbidden? {
    ListenerLdapUserStoreBasicAuthHandler handler;
    lock {
        string key = config.ldapUserStoreConfig.toString();
        if authHandlers.hasKey(key) {
            handler = <ListenerLdapUserStoreBasicAuthHandler> authHandlers.get(key);
        } else {
            handler = new(config.ldapUserStoreConfig.cloneReadOnly());
            authHandlers[key] = handler;
        }
    }
    auth:UserDetails|Unauthorized authn = handler->authenticate(header);
    string|string[]? scopes = config?.scopes;
    if authn is auth:UserDetails {
        if scopes is string|string[] {
            Forbidden? authz = handler->authorize(authn, scopes);
            return authz;
        }
        return;
    }
    return authn;
}

isolated function authenticateWithJwtValidatorConfig(JwtValidatorConfigWithScopes config, string header)
                                                     returns Unauthorized|Forbidden? {
    ListenerJwtAuthHandler handler;
    lock {
        string key = config.jwtValidatorConfig.toString();
        if authHandlers.hasKey(key) {
            handler = <ListenerJwtAuthHandler> authHandlers.get(key);
        } else {
            handler = new(config.jwtValidatorConfig.cloneReadOnly());
            authHandlers[key] = handler;
        }
    }
    jwt:Payload|Unauthorized authn = handler.authenticate(header);
    string|string[]? scopes = config?.scopes;
    if authn is jwt:Payload {
        if scopes is string|string[] {
            Forbidden? authz = handler.authorize(authn, scopes);
            return authz;
        }
        return;
    } else if authn is Unauthorized {
        return authn;
    } else {
        panic error("Unsupported record type found.");
    }
}

isolated function authenticateWithOAuth2IntrospectionConfig(OAuth2IntrospectionConfigWithScopes config, string header)
                                                            returns Unauthorized|Forbidden? {
    ListenerOAuth2Handler handler;
    lock {
        string key = config.oauth2IntrospectionConfig.toString();
        if authHandlers.hasKey(key) {
            handler = <ListenerOAuth2Handler> authHandlers.get(key);
        } else {
            handler = new(config.oauth2IntrospectionConfig.cloneReadOnly());
            authHandlers[key] = handler;
        }
    }
    oauth2:IntrospectionResponse|Unauthorized|Forbidden auth = handler->authorize(header, config?.scopes);
    if auth is oauth2:IntrospectionResponse {
        return;
    } else if auth is Unauthorized || auth is Forbidden {
        return auth;
    } else {
        panic error("Unsupported record type found.");
    }
}

isolated function getListenerAuthConfig(Service serviceRef, string methodName, string[] resourcePath)
                                        returns ListenerAuthConfig[]? {
    ListenerAuthConfig[]|Scopes? resourceAuthConfig = getResourceAuthConfig(serviceRef, methodName, resourcePath);
    if resourceAuthConfig is ListenerAuthConfig[] {
        return resourceAuthConfig;
    } else if resourceAuthConfig is Scopes {
        ListenerAuthConfig[]? serviceAuthConfig = getServiceAuthConfig(serviceRef);
        if serviceAuthConfig is ListenerAuthConfig[] {
            ListenerAuthConfig[]|error authConfig = serviceAuthConfig.cloneWithType();
            if authConfig is ListenerAuthConfig[] {
                foreach ListenerAuthConfig config in authConfig {
                    config.scopes = resourceAuthConfig.scopes;
                }
                return authConfig;
            }
        }
    }
    ListenerAuthConfig[]? serviceAuthConfig = getServiceAuthConfig(serviceRef);
    if serviceAuthConfig is ListenerAuthConfig[] {
        return serviceAuthConfig;
    }
    return;
}

isolated function getServiceAuthConfig(Service serviceRef) returns ListenerAuthConfig[]? {
    typedesc<any> serviceTypeDesc = typeof serviceRef;
    var serviceAnnotation = serviceTypeDesc.@ServiceConfig;
    if serviceAnnotation is () {
        return;
    }
    HttpServiceConfig serviceConfig = <HttpServiceConfig>serviceAnnotation;
    return serviceConfig?.auth;
}

isolated function getResourceAuthConfig(Service serviceRef, string methodName, string[] resourcePath)
                                        returns ListenerAuthConfig[]|Scopes? {
    string resourceName = "$" + methodName;
    foreach string path in resourcePath {
        resourceName += "$" + path;
    }
    any resourceAnnotation = getResourceAnnotation(serviceRef, resourceName);
    if resourceAnnotation is () {
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
    if err is error {
        log:printError("Failed to respond the 401/403 request.", 'error = err);
    }
    // This panic is added to break the execution of the implementation inside the resource function after there is
    // an authn/authz failure and responded with 401/403 internally.
    panic error("Already responded by auth desugar.");
}

isolated function getAuthorizationHeader() returns string|HeaderNotFoundError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHeaders"
} external;

isolated function getCaller() returns Caller = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternCaller"
} external;

isolated function getResourceAnnotation(service object {} serviceType, string resourceName) returns any = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResource"
} external;
