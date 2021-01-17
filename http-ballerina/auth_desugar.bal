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
import ballerina/java;
import ballerina/jwt;
import ballerina/oauth2;
import ballerina/reflect;

// HTTP module version for auth annotations.
const string HTTP_MODULE = "ballerina/http:1.0.5";

// Service level annotation name.
const string SERVICE_ANNOTATION = "ServiceConfig";

// Resource level annotation name.
const string RESOURCE_ANNOTATION = "ResourceConfig";

public function authenticateResource(Service servieRef, string resourceName) returns Unauthorized|Forbidden? {
    ListenerAuthConfig[]? authHandlers = getAuthHandlers(servieRef, resourceName);
    if (authHandlers is ()) {
        return;
    }
    string header = getAuthorizationHeader();
    Unauthorized|Forbidden? result = tryAuthenticate(<ListenerAuthConfig[]>authHandlers, header);
    return result;
}

isolated function tryAuthenticate(ListenerAuthConfig[] authHandlers, string header) returns Unauthorized|Forbidden? {
    foreach ListenerAuthConfig config in authHandlers {
        if (config is FileUserStoreConfigWithScopes) {
            ListenerFileUserStoreBasicAuthHandler handler = new(config.fileUserStoreConfig);
            auth:UserDetails|Unauthorized authn = handler.authenticate(header);
            if (authn is auth:UserDetails) {
                Forbidden? authz = handler.authorize(authn, <string|string[]>config?.scopes);
                return authz;
            }
        } else if (config is LdapUserStoreConfigWithScopes) {
            ListenerLdapUserStoreBasicAuthProvider handler = new(config.ldapUserStoreConfig);
            auth:UserDetails|Unauthorized authn = handler->authenticate(header);
            if (authn is auth:UserDetails) {
                Forbidden? authz = handler->authorize(authn, <string|string[]>config?.scopes);
                return authz;
            }
        } else if (config is JwtValidatorConfigWithScopes) {
            ListenerJwtAuthHandler handler = new(config.jwtValidatorConfig);
            jwt:Payload|Unauthorized authn = handler.authenticate(header);
            if (authn is jwt:Payload) {
                Forbidden? authz = handler.authorize(authn, <string|string[]>config?.scopes);
                return authz;
            }
        } else {
            // Here, config is OAuth2IntrospectionConfigWithScopes
            ListenerOAuth2Handler handler = new(config.oauth2IntrospectionConfig);
            oauth2:IntrospectionResponse|Unauthorized|Forbidden auth = handler->authorize(header, <string|string[]>config?.scopes);
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

isolated function getAuthHandlers(Service serviceRef, string resourceName) returns ListenerAuthConfig[]? {
    ListenerAuthConfig[]? resourceAuthConfig = getResourceAuthConfig(serviceRef, resourceName);
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

isolated function getResourceAuthConfig(Service serviceRef, string resourceName) returns ListenerAuthConfig[]? {
    any resourceAnnotation = reflect:getResourceAnnotations(serviceRef, resourceName, RESOURCE_ANNOTATION, HTTP_MODULE);
    if (resourceAnnotation is ()) {
        return;
    }
    HttpResourceConfig resourceConfig = <HttpResourceConfig>resourceAnnotation;
    return resourceConfig?.auth;
}

isolated function send401(Caller caller) {
    Response response = new;
    response.statusCode = 401;
    error? err = caller->respond(response);
    if (err is error) {
        panic <error>err;
    }
}

isolated function send403(Caller caller) {
    Response response = new;
    response.statusCode = 403;
    error? err = caller->respond(response);
    if (err is error) {
        panic <error>err;
    }
}

function getAuthorizationHeader() returns string = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHeaders"
} external;
