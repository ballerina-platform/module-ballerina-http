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
import ballerina/lang.'string as strings;
import ballerina/url;
import ballerina/mime;
import http.httpscerr;
import ballerina/data.jsondata;

# The caller actions for responding to client requests.
#
# + remoteAddress - The remote address
# + localAddress - The local address
# + protocol - The protocol associated with the service endpoint
public isolated client class Caller {
    public final readonly & Remote remoteAddress;
    public final readonly & Local localAddress;
    public final string protocol;
    private string? resourceAccessor;
    private ListenerConfiguration config = {};
    private boolean present = false;

    isolated function init(Remote remoteAddress, Local localAddress, string protocol, string? resourceAccessor) {
        self.remoteAddress = remoteAddress.cloneReadOnly();
        self.localAddress = localAddress.cloneReadOnly();
        self.protocol = protocol;
        self.resourceAccessor = resourceAccessor;
    }

    # Sends the outbound response to the caller.
    #
    # + message - The outbound response or status code response or error or any allowed payload
    # + return - An `http:ListenerError` if failed to respond or else `()`
    remote isolated function respond(ResponseMessage|StatusCodeResponse|error message = ()) returns ListenerError? {
        if message is ResponseMessage {
            Response response = check buildResponse(message, self.getResourceAccessor());
            return nativeRespond(self, response);
        } else if message is StatusCodeResponse {
            return nativeRespond(self, createStatusCodeResponse(message));
        } else if message is error {
            return self.returnErrorResponse(message);
        } else {
            string errorMsg = "invalid response body type. expected one of the types: http:ResponseMessage|http:StatusCodeResponse|error";
            panic error ListenerError(errorMsg);
        }
    }

    private isolated function getResourceAccessor() returns string? {
        lock {
            return self.resourceAccessor;
        }
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
        if code == REDIRECT_MULTIPLE_CHOICES_300 {
            response.statusCode = STATUS_MULTIPLE_CHOICES;
        } else if code == REDIRECT_MOVED_PERMANENTLY_301 {
            response.statusCode = STATUS_MOVED_PERMANENTLY;
        } else if code == REDIRECT_FOUND_302 {
            response.statusCode = STATUS_FOUND;
        } else if code == REDIRECT_SEE_OTHER_303 {
            response.statusCode = STATUS_SEE_OTHER;
        } else if code == REDIRECT_NOT_MODIFIED_304 {
            response.statusCode = STATUS_NOT_MODIFIED;
        } else if code == REDIRECT_USE_PROXY_305 {
            response.statusCode = STATUS_USE_PROXY;
        } else if code == REDIRECT_TEMPORARY_REDIRECT_307 {
            response.statusCode = STATUS_TEMPORARY_REDIRECT;
        } else if code == REDIRECT_PERMANENT_REDIRECT_308 {
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

    private isolated function returnResponse(
        anydata|StatusCodeResponse|Response|stream<SseEvent, error?>|stream<SseEvent, error> message,
        string? returnMediaType, HttpCacheConfig? cacheConfig, map<Link>? links) returns ListenerError? {
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
                Accepted acceptedResponse = {};
                response = createStatusCodeResponse(acceptedResponse, links = links);
            }
        } else if message is StatusCodeResponse {
            if message is SuccessStatusCodeResponse {
                response = createStatusCodeResponse(message, returnMediaType, setETag, links);
                cacheCompatibleType = true;
            } else {
                response = createStatusCodeResponse(message, returnMediaType);
            }
        } else if message is Response {
            response = message;
            // Update content-type header with mediaType annotation value only if the response does not already 
            // have a similar header
            if returnMediaType is string && !response.hasHeader(CONTENT_TYPE) {
                response.setHeader(CONTENT_TYPE, returnMediaType);
            }
        } else if message is stream<SseEvent, error?>|stream<SseEvent, error> {
            response = createSseResponse(message);
        } else if message is anydata {
            setPayload(message, response, returnMediaType, setETag, links);
            if returnMediaType is string {
                response.setHeader(CONTENT_TYPE, returnMediaType);
            }
            if self.getResourceAccessor() == HTTP_POST {
                response.statusCode = STATUS_CREATED;
            }
            cacheCompatibleType = true;
        } else {
            string errorMsg = "invalid response body type. expected one of the types: anydata|http:StatusCodeResponse|http:Response";
            panic error ListenerError(errorMsg);
        }
        if cacheCompatibleType && (cacheConfig is HttpCacheConfig) {
            ResponseCacheControl responseCacheControl = new;
            responseCacheControl.populateFields(cacheConfig);
            response.cacheControl = responseCacheControl;
            if cacheConfig.setLastModified {
                response.setLastModified();
            }
        }
        return nativeRespond(self, response);
    }

    private isolated function returnErrorResponse(error errorResponse, string? returnMediaType = ()) returns ListenerError? {
        error err = errorResponse;
        if errorResponse is ClientConnectorError {
            err = error httpscerr:BadGatewayError(getClientConnectorErrorCause(errorResponse));
        }
        return nativeRespondError(self, getErrorResponse(errorResponse, returnMediaType), err);
    }
}

isolated function getClientConnectorErrorCause(error err) returns string {
    if err.cause() !is () {
        error cause = <error>err.cause();
        return string`${err.message()}: ${getClientConnectorErrorCause(cause)}`;
    }
    return err.message();
}

isolated function createStatusCodeResponse(StatusCodeResponse message, string? returnMediaType = (), boolean setETag = false, map<Link>? links = ())
    returns Response {
    Response response = new;
    response.statusCode = message.status.code;

    var headers = message?.headers;
    if headers is map<string[]> || headers is map<int[]> || headers is map<boolean[]> {
        foreach var [headerKey, headerValues] in headers.entries() {
            string[] mappedValues = headerValues.'map(val => val.toString());
            foreach string headerValue in mappedValues {
                response.addHeader(headerKey, headerValue);
            }
        }
    } else if headers is map<string> || headers is map<int> || headers is map<boolean> {
        foreach var [headerKey, headerValue] in headers.entries() {
            response.setHeader(headerKey, headerValue.toString());
        }
    } else if headers is map<string|int|boolean|string[]|int[]|boolean[]> {
        foreach var [headerKey, headerValue] in headers.entries() {
            if headerValue is string[] || headerValue is int[] || headerValue is boolean[] {
                string[] mappedValues = headerValue.'map(val => val.toString());
                foreach string value in mappedValues {
                    response.addHeader(headerKey, value);
                }
            } else {
                response.setHeader(headerKey, headerValue.toString());
            }
        }
    }
    string? mediaType = retrieveMediaType(message, returnMediaType);
    setPayload(message?.body, response, mediaType, setETag, links);
    // Update content-type header according to the priority. (Highest to lowest)
    // 1. MediaType field in response record
    // 2. Payload annotation mediaType value
    // 3. The content type header included in headers field
    // 4. Default content type related to payload
    if mediaType is string {
        response.setHeader(CONTENT_TYPE, mediaType);
        return response;
    }
    return response;
}

isolated function createSseResponse(stream<SseEvent, error?>|stream<SseEvent, error> eventStream) returns Response {
    Response response = new;
    response.setSseEventStream(eventStream);
    return response;
}

isolated function retrieveMediaType(StatusCodeResponse resp, string? retrievedMediaType) returns string? {
    string? mediaType = resp?.mediaType;
    if mediaType is string {
        return strings:trim(mediaType);
    }
    if retrievedMediaType is string {
        return strings:trim(retrievedMediaType);
    }
    return;
}

isolated function addLinkHeader(Response response, map<Link>? links) {
    if !response.hasHeader("Link") {
        string? headerValue = createLinkHeaderValue(links);
        if headerValue is string {
            response.addHeader("Link", headerValue);
        }
    }
}

isolated function createLinkHeaderValue(map<Link>? links) returns string? {
    if links != () {
        string[] linkValues = from var [rel, link] in links.entries() select createLink(rel, link);
        return arrayToString(linkValues);
    }
    return;
}

isolated function createLink(string rel, Link link) returns string {
    string header = string`<${link.href}>; rel="${rel}"`;
    string[]? methods = link?.methods;
    string[]? types = link?.types;
    if methods !is () {
        header += string`; methods="${arrayToString(methods)}"`;
    }
    if types !is () {
        header += string`; types="${arrayToString(types)}"`;
    }
    return header;
}

isolated function arrayToString(string[] arr) returns string {
    return string:'join(", ", ...arr);
}

isolated function addLinksToPayload(anydata message, map<Link>? links) returns [boolean, anydata] {
    if links is map<Link> {
        if message is map<anydata> && !message.hasKey("_links") {
            error? err = trap addLinksToJsonPayload(message, links);
            if err !is error {
                return [true, message];
            }
        }
    }
    return [false, message];
}

isolated function addLinksToJsonPayload(map<anydata> message, map<Link> links) {
    message["_links"] = links.toJson();
}

isolated function setPayload(anydata message, Response response, string? mediaType = (), boolean setETag = false, map<Link>? links = ()) {
    [boolean, anydata] [isLinksAddedToPayload, payload] = addLinksToPayload(message, links);
    if !isLinksAddedToPayload {
        addLinkHeader(response, links);
    }

    if payload is () {
        return;
    }

    if payload is xml {
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
        processAnydata(response, payload, mediaType, setETag);
    }
}

isolated function processAnydata(Response response, anydata payload, string? mediaType = (), boolean setETag = false) {
    match mediaType {
        mime:APPLICATION_FORM_URLENCODED => {
            map<string>|error pairs = val:cloneWithType(payload);
            if pairs is map<string> {
                string|error result = retrieveUrlEncodedData(pairs);
                if result is string {
                    response.setTextPayload(result, mime:APPLICATION_FORM_URLENCODED);
                    if setETag {
                        response.setETag(result);
                    }
                    return;
                }
                panic error InitializingOutboundResponseError("content encoding error: " + result.message(), result);
            } else {
                panic error InitializingOutboundRequestError("unsupported content for application/x-www-form-urlencoded media type");
            }
        }
        _ => {
            setJsonPayload(response, payload, setETag);
        }
    }
}

isolated function retrieveUrlEncodedData(map<string> message) returns string|error {
    string[] messageParams = [];
    foreach var ['key, value] in message.entries() {
        string encodedKey = check url:encode('key, CHARSET_UTF_8);
        string encodedValue = check url:encode(value, CHARSET_UTF_8);
        string entry = string `${'encodedKey}=${encodedValue}`;
        messageParams.push(entry);
    }
    return strings:'join("&", ...messageParams);
}

isolated function setJsonPayload(Response response, anydata payload, boolean setETag) {
    var result = trap jsondata:toJson(payload);
    if result is error {
        panic error InitializingOutboundResponseError(string `anydata to json conversion error: ${result.message()}`, result);
    }
    response.setJsonPayload(result);
    if setETag {
        response.setETag(result);
    }
}

isolated function nativeRespondError(Caller caller, Response response, error err) returns ListenerError? = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.connection.Respond",
    name: "nativeRespondError"
} external;

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
