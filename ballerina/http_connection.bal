// Copyright (c) 2017 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/lang.value as val;

# The caller actions for responding to client requests.
#
# + remoteAddress - The remote address
# + localAddress - The local address
# + protocol - The protocol associated with the service endpoint
public isolated client class Caller {
    public final readonly & Remote remoteAddress;
    public final readonly & Local localAddress;
    public final string protocol;
    private ListenerConfiguration config = {};
    private boolean present = false;

    isolated function init(Remote remoteAddress, Local localAddress, string protocol) {
        self.remoteAddress = remoteAddress.cloneReadOnly();
        self.localAddress = localAddress.cloneReadOnly();
        self.protocol = protocol;
    }

    # Sends the outbound response to the caller.
    #
    # + message - The outbound response or any allowed payload
    # + return - An `http:ListenerError` if failed to respond or else `()`
    remote isolated function respond(ResponseMessage message = ()) returns ListenerError? {
        Response response = check buildResponse(message);
        return nativeRespond(self, response);
    }

    # Pushes a promise to the caller.
    #
    # + promise - Push promise message
    # + return - An `http:ListenerError` in case of failures
    remote isolated function promise(PushPromise promise) returns ListenerError? {
        return externPromise(self, promise);
    }

    # Sends a promised push response to the caller.
    #
    # + promise - Push promise message
    # + response - The outbound response
    # + return - An `http:ListenerError` in case of failures while responding with the promised response
    remote isolated function pushPromisedResponse(PushPromise promise, Response response)
                                                                returns ListenerError? {
        return externPushPromisedResponse(self, promise, response);
    }

    # Sends a `100-continue` response to the caller.
    #
    # + return - An `http:ListenerError` if failed to send the `100-continue` response or else `()`
    remote isolated function 'continue() returns ListenerError? {
        Response res = new;
        res.statusCode = STATUS_CONTINUE;
        return self->respond(res);
    }

    # Sends a redirect response to the user with the specified redirection status code.
    #
    # + response - Response to be sent to the caller
    # + code - The redirect status code to be sent
    # + locations - An array of URLs to which the caller can redirect to
    # + return - An `http:ListenerError` if failed to send the redirect response or else `()`
    remote isolated function redirect(Response response, RedirectCode code, string[] locations) returns ListenerError? {
        if (code == REDIRECT_MULTIPLE_CHOICES_300) {
            response.statusCode = STATUS_MULTIPLE_CHOICES;
        } else if (code == REDIRECT_MOVED_PERMANENTLY_301) {
            response.statusCode = STATUS_MOVED_PERMANENTLY;
        } else if (code == REDIRECT_FOUND_302) {
            response.statusCode = STATUS_FOUND;
        } else if (code == REDIRECT_SEE_OTHER_303) {
            response.statusCode = STATUS_SEE_OTHER;
        } else if (code == REDIRECT_NOT_MODIFIED_304) {
            response.statusCode = STATUS_NOT_MODIFIED;
        } else if (code == REDIRECT_USE_PROXY_305) {
            response.statusCode = STATUS_USE_PROXY;
        } else if (code == REDIRECT_TEMPORARY_REDIRECT_307) {
            response.statusCode = STATUS_TEMPORARY_REDIRECT;
        } else if (code == REDIRECT_PERMANENT_REDIRECT_308) {
            response.statusCode = STATUS_PERMANENT_REDIRECT;
        }
        string locationsStr = "";
        foreach var location in locations {
            locationsStr = locationsStr + location + ",";
        }
        locationsStr = locationsStr.substring(0, (locationsStr.length()) - 1);

        response.setHeader(LOCATION, locationsStr);
        return self->respond(response);
    }

    # Gets the hostname from the remote address. This method may trigger a DNS reverse lookup if the address was created
    # with a literal IP address.
    # ```ballerina
    # string? remoteHost = caller.getRemoteHostName();
    # ```
    #
    # + return - The hostname of the address or else `()` if it is unresolved
    public isolated function getRemoteHostName() returns string? {
        return nativeGetRemoteHostName(self);
    }

    private isolated function returnResponse(anydata|StatusCodeResponse|Response|error message, string? returnMediaType,
        HttpCacheConfig? cacheConfig) returns ListenerError? {
        Response response = new;
        boolean setETag = cacheConfig is () ? false: cacheConfig.setETag;
        boolean cacheCompatibleType = false;
        if message is () {
            boolean isCallerPresent = false;
            lock {
                isCallerPresent = self.present;
            }
            if isCallerPresent {
                InternalServerError errResponse = {};
                response = createStatusCodeResponse(errResponse);
            } else {
                Accepted AcceptedResponse = {};
                response = createStatusCodeResponse(AcceptedResponse);
            }
        } else if message is error {
            if message is ApplicationResponseError {
                InternalServerError err = {
                    headers: message.detail().headers,
                    body: message.detail().body
                };
                response = createStatusCodeResponse(err, returnMediaType);
                response.statusCode = message.detail().statusCode;
            } else {
                response.statusCode = STATUS_INTERNAL_SERVER_ERROR;
                response.setTextPayload(message.message());
            }
        } else if message is StatusCodeResponse {
            if message is SuccessStatusCodeResponse {
                response = createStatusCodeResponse(message, returnMediaType, setETag);
                cacheCompatibleType = true;
            } else {
                response = createStatusCodeResponse(message, returnMediaType);
            }
        } else if message is Response {
            response = message;
            // Update content-type header with mediaType annotation value only if the response does not already 
            // have a similar header
            if (returnMediaType is string && !response.hasHeader(CONTENT_TYPE)) {
                response.setHeader(CONTENT_TYPE, returnMediaType);
            }
        } else {
            setPayload(message, response, setETag);
            if returnMediaType is string {
                response.setHeader(CONTENT_TYPE, returnMediaType);
            }
            cacheCompatibleType = true;
        }
        if (cacheCompatibleType && (cacheConfig is HttpCacheConfig)) {
            ResponseCacheControl responseCacheControl = new;
            responseCacheControl.populateFields(cacheConfig);
            response.cacheControl = responseCacheControl;
            if (cacheConfig.setLastModified) {
                response.setLastModified();
            }
        }
        return nativeRespond(self, response);
    }
}

isolated function createStatusCodeResponse(StatusCodeResponse message, string? returnMediaType = (), boolean setETag = false)
    returns Response {
    Response response = new;
    response.statusCode = message.status.code;

    var headers = message?.headers;
    if (headers is map<string[]>) {
        foreach var [headerKey, headerValues] in headers.entries() {
            foreach string headerValue in headerValues {
                response.addHeader(headerKey, headerValue);
            }
        }
    } else if (headers is map<string>) {
        foreach var [headerKey, headerValue] in headers.entries() {
            response.setHeader(headerKey, headerValue);
        }
    } else if (headers is map<string|string[]>) {
        foreach var [headerKey, headerValue] in headers.entries() {
            if (headerValue is string[]) {
                foreach string value in headerValue {
                    response.addHeader(headerKey, value);
                }
            } else {
                response.setHeader(headerKey, headerValue);
            }
        }
    }

    setPayload(message?.body, response, setETag);

    // Update content-type header according to the priority. (Highest to lowest)
    // 1. MediaType field in response record
    // 2. Payload annotation mediaType value
    // 3. The content type header included in headers field
    // 4. Default content type related to payload
    string? mediaType = message?.mediaType;
    if (mediaType is string) {
        response.setHeader(CONTENT_TYPE, mediaType);
        return response;
    }
    if (returnMediaType is string) {
        response.setHeader(CONTENT_TYPE, returnMediaType);
    }
    return response;
}

isolated function setPayload(anydata payload, Response response, boolean setETag = false) {
    if payload is () {
        return;
    } else if payload is xml {
        response.setXmlPayload(payload);
        if setETag {
            response.setETag(payload);
        }
    } else if payload is string {
        response.setTextPayload(payload);
        if setETag {
            response.setETag(payload);
        }
    } else if payload is byte[] {
        response.setBinaryPayload(payload);
        if setETag {
            response.setETag(payload);
        }
    } else {
        castToJsonAndSetPayload(response, payload, "anydata to json conversion error: ", setETag);
    }
}

isolated function castToJsonAndSetPayload(Response response, anydata payload, string errMsg, boolean setETag = false) {
    var result = trap val:toJson(payload);
    if result is error {
        panic error InitializingOutboundResponseError(errMsg + result.message(), result);
    } else {
        response.setJsonPayload(result);
        if setETag {
            response.setETag(result);
        }
    }
}

isolated function nativeRespond(Caller caller, Response response) returns ListenerError? = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.connection.Respond",
    name: "nativeRespond"
} external;

isolated function nativeGetRemoteHostName(Caller caller) returns string? = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.connection.GetRemoteHostName",
    name: "nativeGetRemoteHostName"
} external;

# Defines the HTTP redirect codes as a type.
public type RedirectCode REDIRECT_MULTIPLE_CHOICES_300|REDIRECT_MOVED_PERMANENTLY_301|REDIRECT_FOUND_302|REDIRECT_SEE_OTHER_303|
REDIRECT_NOT_MODIFIED_304|REDIRECT_USE_PROXY_305|REDIRECT_TEMPORARY_REDIRECT_307|REDIRECT_PERMANENT_REDIRECT_308;

# Represents the HTTP redirect status code `300 - Multiple Choices`.
public const REDIRECT_MULTIPLE_CHOICES_300 = 300;
# Represents the HTTP redirect status code `301 - Moved Permanently`.
public const REDIRECT_MOVED_PERMANENTLY_301 = 301;
# Represents the HTTP redirect status code `302 - Found`.
public const REDIRECT_FOUND_302 = 302;
# Represents the HTTP redirect status code `303 - See Other`.
public const REDIRECT_SEE_OTHER_303 = 303;
# Represents the HTTP redirect status code `304 - Not Modified`.
public const REDIRECT_NOT_MODIFIED_304 = 304;
# Represents the HTTP redirect status code `305 - Use Proxy`.
public const REDIRECT_USE_PROXY_305 = 305;
# Represents the HTTP redirect status code `307 - Temporary Redirect`.
public const REDIRECT_TEMPORARY_REDIRECT_307 = 307;
# Represents the HTTP redirect status code `308 - Permanent Redirect`.
public const REDIRECT_PERMANENT_REDIRECT_308 = 308;

isolated function externPromise(Caller caller, PushPromise promise) returns ListenerError? =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.connection.Promise",
    name: "promise"
} external;

isolated function externPushPromisedResponse(Caller caller, PushPromise promise, Response response) returns ListenerError? =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.connection.PushPromisedResponse",
    name: "pushPromisedResponse"
} external;
