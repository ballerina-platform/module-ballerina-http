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
import ballerina/jwt;
import ballerina/oauth2;
import ballerina/reflect;

// HTTP module version for auth annotations.
const string HTTP_MODULE = "ballerina/http:1.0.5";

// Service level annotation name.
const string SERVICE_ANNOTATION = "ServiceConfig";

// Resource level annotation name.
const string RESOURCE_ANNOTATION = "ResourceConfig";

# Representation of the filter used for authentication and authorization.
public class AuthFilter {

    *RequestFilter;

    # The request filter method, which attempts to authenticate the request.
    #
    # + caller - The HTTP caller
    # + request - An inbound HTTP request message
    # + context - The `http:FilterContext` instance
    # + return - A flag to indicate if the request flow should be continued(true) or aborted(false)
    public isolated function filterRequest(Caller caller, Request request, FilterContext context) returns boolean {
        ListenerAuthConfig[]? authHandlers = getAuthHandlers(context);
        if (authHandlers is ()) {
            return true;
        }
        Unauthorized|Forbidden? result = tryAuthenticate(<ListenerAuthConfig[]>authHandlers, request);
        if (result is Unauthorized) {
            send401(caller);
        } else if (result is Forbidden) {
            send403(caller);
        } else {
            return true;
        }
        return false;
    }
}

isolated function tryAuthenticate(ListenerAuthConfig[] authHandlers, Request req) returns Unauthorized|Forbidden? {
    foreach ListenerAuthConfig config in authHandlers {
        if (config is FileUserStoreConfigWithScopes) {
            ListenerFileUserStoreBasicAuthHandler handler = new(config.fileUserStoreConfig);
            auth:UserDetails|Unauthorized authn = handler.authenticate(req);
            if (authn is auth:UserDetails && !(config?.scopes is ())) {
                Forbidden? authz = handler.authorize(authn, <string|string[]>config?.scopes);
                if (authz is ()) {
                    return;
                }
                return <Forbidden>authz;
            }
            return <Unauthorized>authn;
        } else if (config is LdapUserStoreConfigWithScopes) {
            ListenerLdapUserStoreBasicAuthProvider handler = new(config.ldapUserStoreConfig);
            auth:UserDetails|Unauthorized authn = handler->authenticate(req);
            if (authn is auth:UserDetails && !(config?.scopes is ())) {
                Forbidden? authz = handler->authorize(authn, <string|string[]>config?.scopes);
                if (authz is ()) {
                    return;
                }
                return <Forbidden>authz;
            }
            return <Unauthorized>authn;
        } else if (config is JwtValidatorConfigWithScopes) {
            ListenerJwtAuthHandler handler = new(config.validatorConfig);
            jwt:Payload|Unauthorized authn = handler.authenticate(req);
            if (authn is jwt:Payload && !(config?.scopes is ())) {
                Forbidden? authz = handler.authorize(authn, <string|string[]>config?.scopes);
                if (authz is ()) {
                    return;
                }
                return <Forbidden>authz;
            }
            return <Unauthorized>authn;
        } else {
            // Here, config is OAuth2IntrospectionConfigWithScopes
            ListenerOAuth2Handler handler = new(config.introspectionConfig);
            oauth2:IntrospectionResponse|Unauthorized|Forbidden auth = handler->authorize(req, <string|string[]>config?.scopes);
            if (auth is oauth2:IntrospectionResponse) {
                return;
            }
            return <Unauthorized|Forbidden>auth;
        }
    }
    Unauthorized unauthorized = {};
    return unauthorized;
}

isolated function getAuthHandlers(FilterContext context) returns ListenerAuthConfig[]? {
    ListenerAuthConfig[]? resourceAuthConfig = getResourceAuthConfig(context);
    ListenerAuthConfig[]? serviceAuthConfig = getServiceAuthConfig(context);
    if (resourceAuthConfig is ListenerAuthConfig[]) {
        return resourceAuthConfig;
    } else if (serviceAuthConfig is ListenerAuthConfig[]) {
        return serviceAuthConfig;
    }
}

isolated function getServiceAuthConfig(FilterContext context) returns ListenerAuthConfig[]? {
    any annData = reflect:getServiceAnnotations(context.getService(), SERVICE_ANNOTATION, HTTP_MODULE);
    if (annData is ()) {
        return;
    }
    HttpServiceConfig serviceConfig = <HttpServiceConfig>annData;
    return serviceConfig?.auth;
}

isolated function getResourceAuthConfig(FilterContext context) returns ListenerAuthConfig[]? {
    any annData = reflect:getResourceAnnotations(context.getService(), context.getResourceName(),
                                                 RESOURCE_ANNOTATION, HTTP_MODULE);
    if (annData is ()) {
        return;
    }
    HttpResourceConfig resourceConfig = <HttpResourceConfig>annData;
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
