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

import ballerina/io;
import ballerina/lang.array;
import ballerina/lang.'string as strings;
import ballerina/mime;
import ballerina/regex;
import ballerina/java;
import ballerina/time;

# Represents an HTTP request.
#
# + rawPath - Resource path of the request URL
# + method - The HTTP request method
# + httpVersion - The HTTP version supported by the client
# + userAgent - The user-agent. This value is used when setting the `user-agent` header
# + extraPathInfo - The part of the URL, which matched to '*' if the request is dispatched to a wildcard resource
# + cacheControl - The cache-control directives for the request. This needs to be explicitly initialized if intending
#                  on utilizing HTTP caching.
# + mutualSslHandshake - A record providing mutual ssl handshake results.
public class Request {

    public string rawPath = "";
    public string method = "";
    public string httpVersion = "";
    public string userAgent = "";
    public string extraPathInfo = "";
    public RequestCacheControl? cacheControl = ();
    public MutualSslHandshake? mutualSslHandshake = ();

    private mime:Entity? entity = ();
    private boolean dirtyRequest;
    boolean noEntityBody;

    public isolated function init() {
        self.dirtyRequest = false;
        self.noEntityBody = false;
        self.entity = self.createNewEntity();
    }

    # Create a new `Entity` and link it with the request.
    #
    # + return - Newly created `Entity` that has been set to the request
    isolated function createNewEntity() returns mime:Entity {
        return externCreateNewReqEntity(self);
    }

    # Sets the provided `Entity` to the request.
    #
    # + e - The `Entity` to be set to the request
    public isolated function setEntity(mime:Entity e) {
        return externSetReqEntity(self, e);
    }

    # Sets the provided `Entity` to the request and update only the content type header in the transport message.
    #
    # + e - The `Entity` to be set to the request
    isolated function setEntityAndUpdateContentTypeHeader(mime:Entity e) {
        return externSetReqEntityAndUpdateContentTypeHeader(self, e);
    }

    # Gets the query parameters of the request as a map consisting of a string array.
    #
    # + return - String array map of the query params
    public isolated function getQueryParams() returns map<string[]> {
        return externGetQueryParams(self);
    }

    # Gets the query param value associated with the given key.
    #
    # + key - Represents the query param key
    # + return - The query param value associated with the given key as a string. If multiple param values are
    #            present, then the first value is returned. `()` is returned if no key is found.
    public isolated function getQueryParamValue(@untainted string key) returns @tainted string? {
        map<string[]> params = self.getQueryParams();
        var result = params[key];
        return result is () ? () : result[0];
    }

    # Gets all the query param values associated with the given key.
    #
    # + key - Represents the query param key
    # + return - All the query param values associated with the given key as a `string[]`. `()` is returned if no key
    #            is found.
    public isolated function getQueryParamValues(@untainted string key) returns @tainted string[]? {
        map<string[]> params = self.getQueryParams();
        return params[key];
    }

    # Gets the matrix parameters of the request.
    #
    # + path - Path to the location of matrix parameters
    # + return - A map of matrix parameters which can be found for the given path
    public isolated function getMatrixParams(string path) returns map<any> {
        return externGetMatrixParams(self, path);
    }

    # Gets the `Entity` associated with the request.
    #
    # + return - The `Entity` of the request. An `http:ClientError` is returned, if entity construction fails
    public isolated function getEntity() returns mime:Entity|ClientError {
        return externGetReqEntity(self);
    }

    // Gets the `Entity` from the request without the body and headers. This function is exposed only to be used
    // internally.
    isolated function getEntityWithoutBodyAndHeaders() returns mime:Entity {
        return externGetEntityWithoutBodyAndHeaders(self);
    }

    // Gets the `Entity` from the request with the body, but without headers. This function is used for Http level
    // functions.
    isolated function getEntityWithBodyAndWithoutHeaders() returns mime:Entity|ClientError {
        return externGetEntityWithBodyAndWithoutHeaders(self);
    }

    # Checks whether the requested header key exists in the header map.
    #
    # + headerName - The header name
    # + return - Returns true if the specified header key exists
    public isolated function hasHeader(string headerName) returns boolean {
        return externRequestHasHeader(self, headerName);
    }

    # Returns the value of the specified header. If the specified header key maps to multiple values, the first of
    # these values is returned.
    #
    # + headerName - The header name
    # + return - The first header value for the specified header name or the `HeaderNotFoundError` if the header is not
    #            found.
    public isolated function getHeader(string headerName) returns @tainted string|HeaderNotFoundError {
        return externRequestGetHeader(self, headerName);
    }

    # Gets all the header values to which the specified header key maps to.
    #
    # + headerName - The header name
    # + return - The header values the specified header key maps to or the `HeaderNotFoundError` if the header is not
    #            found.
    public isolated function getHeaders(string headerName) returns @tainted string[]|HeaderNotFoundError {
        return externRequestGetHeaders(self, headerName);
    }

    # Sets the specified header to the request. If a mapping already exists for the specified header key, the existing
    # header value is replaced with the specified header value. Panic if an illegal header is passed.
    #
    # + headerName - The header name
    # + headerValue - The header value
    public isolated function setHeader(string headerName, string headerValue) {
        externRequestSetHeader(self, headerName, headerValue);
    }

    # Adds the specified header to the request. Existing header values are not replaced. Panic if an illegal header is passed.
    #
    # + headerName - The header name
    # + headerValue - The header value
    public isolated function addHeader(string headerName, string headerValue) {
        externRequestAddHeader(self, headerName, headerValue);
    }

    # Removes the specified header from the request.
    #
    # + headerName - The header name
    public isolated function removeHeader(string headerName) {
        externRequestRemoveHeader(self, headerName);
    }

    # Removes all the headers from the request.
    public isolated function removeAllHeaders() {
        return externRequestRemoveAllHeaders(self);
    }

    # Gets all the names of the headers of the request.
    #
    # + return - An array of all the header names
    public isolated function getHeaderNames() returns @tainted string[] {
        return externRequestGetHeaderNames(self);
    }

    # Checks whether the client expects a `100-continue` response.
    #
    # + return - Returns true if the client expects a `100-continue` response
    public isolated function expects100Continue() returns boolean {
        return <@untainted> (self.hasHeader(EXPECT) ? self.getHeader(EXPECT) == "100-continue" : false);
    }

    # Sets the `content-type` header to the request.
    #
    # + contentType - Content type value to be set as the `content-type` header
    # + return - Nil if successful, error in case of invalid content-type
    public isolated function setContentType(string contentType) returns error? {
        return trap self.setHeader(mime:CONTENT_TYPE, contentType);
    }

    # Gets the type of the payload of the request (i.e: the `content-type` header value).
    #
    # + return - The `content-type` header value as a string
    public isolated function getContentType() returns @tainted string {
        string contentTypeHeaderValue = "";
        var value = self.getHeader(mime:CONTENT_TYPE);
        if (value is string) {
            contentTypeHeaderValue = value;
        }
        return contentTypeHeaderValue;
    }

    # Extracts `json` payload from the request. If the content type is not JSON, an `http:ClientError` is returned.
    #
    # + return - The `json` payload or `http:ClientError` in case of errors
    public isolated function getJsonPayload() returns @tainted json|ClientError {
        var result = self.getEntityWithBodyAndWithoutHeaders();
        if (result is error) {
            return result;
        } else {
            var payload = externGetJson(result);
            if (payload is mime:Error) {
                if (payload.cause() is mime:NoContentError) {
                    return createErrorForNoPayload(<mime:Error> payload);
                } else {
                    string message = "Error occurred while retrieving the json payload from the request";
                    return error GenericClientError(message, payload);
               }
            } else {
                return payload;
            }
        }
    }

    # Extracts `xml` payload from the request. If the content type is not XML, an `http:ClientError` is returned.
    #
    # + return - The `xml` payload or `http:ClientError` in case of errors
    public isolated function getXmlPayload() returns @tainted xml|ClientError {
        var result = self.getEntityWithBodyAndWithoutHeaders();
        if (result is error) {
            return result;
        } else {
            var payload = externGetXml(result);
            if (payload is mime:Error) {
                if (payload.cause() is mime:NoContentError) {
                    return createErrorForNoPayload(<mime:Error> payload);
                } else {
                    string message = "Error occurred while retrieving the xml payload from the request";
                    return error GenericClientError(message, payload);
                }
            } else {
                return payload;
            }
        }
    }

    # Extracts `text` payload from the request. If the content type is not of type text, an `http:ClientError` is returned.
    #
    # + return - The `text` payload or `http:ClientError` in case of errors
    public isolated function getTextPayload() returns @tainted string|ClientError {
        var result = self.getEntityWithBodyAndWithoutHeaders();
        if (result is error) {
            return result;
        } else {
            var payload = externGetText(result);
            if (payload is mime:Error) {
                if (payload.cause() is mime:NoContentError) {
                    return createErrorForNoPayload(<mime:Error> payload);
                } else {
                    string message = "Error occurred while retrieving the text payload from the request";
                    return error GenericClientError(message, payload);
                }
            } else {
                return payload;
            }
        }
    }

    # Gets the request payload as a `ByteChannel` except in the case of multiparts. To retrieve multiparts, use
    # `Request.getBodyParts()`.
    #
    # + return - A byte channel from which the message payload can be read or `http:ClientError` in case of errors
    isolated function getByteChannel() returns @tainted io:ReadableByteChannel|ClientError {
        var result = self.getEntityWithBodyAndWithoutHeaders();
        if (result is error) {
            return result;
        } else {
            var payload = externGetByteChannel(result);
            if (payload is mime:Error) {
                string message = "Error occurred while retrieving the byte channel from the request";
                return error GenericClientError(message, payload);
            } else {
                return payload;
            }
        }
    }

    # Gets the request payload as a `byte[]`.
    #
    # + return - The byte[] representation of the message payload or `http:ClientError` in case of errors
    public isolated function getBinaryPayload() returns @tainted byte[]|ClientError {
        var result = self.getEntityWithBodyAndWithoutHeaders();
        if (result is error) {
            return result;
        } else {
            var payload = externGetByteArray(result);
            if (payload is mime:Error) {
                string message = "Error occurred while retrieving the binary payload from the request";
                return error GenericClientError(message, payload);
            } else {
                return payload;
            }
        }
    }

    # Gets the form parameters from the HTTP request as a `map` when content type is application/x-www-form-urlencoded.
    #
    # + return - The map of form params or `http:ClientError` in case of errors
    public isolated function getFormParams() returns @tainted map<string>|ClientError {
        var mimeEntity = self.getEntityWithBodyAndWithoutHeaders();
        if (mimeEntity is error) {
            return mimeEntity;
        } else {
            string message = "Error occurred while retrieving form parameters from the request";
            string|error contentTypeValue = self.getHeader(mime:CONTENT_TYPE);
            if (contentTypeValue is error) {
                string errMessage = "Content-Type header is not available";
                mime:HeaderUnavailableError typeError = error mime:HeaderUnavailableError(errMessage);
                return error GenericClientError(message, typeError);
            }
            string contentTypeHeaderValue = "";
            var mediaType = mime:getMediaType(checkpanic contentTypeValue);
            if (mediaType is mime:InvalidContentTypeError) {
                return error GenericClientError(message, mediaType);
            } else {
                contentTypeHeaderValue = mediaType.primaryType + "/" + mediaType.subType;
            }
            if (!(strings:equalsIgnoreCaseAscii(mime:APPLICATION_FORM_URLENCODED, contentTypeHeaderValue))) {
                string errorMessage = "Invalid content type : expected 'application/x-www-form-urlencoded'";
                mime:InvalidContentTypeError typeError = error mime:InvalidContentTypeError(errorMessage);
                return error GenericClientError(message, typeError);
            }
            var formData = externGetText(mimeEntity);
            map<string> parameters = {};
            if (formData is error) {
                return error GenericClientError(message, formData);
            } else {
                if (formData != "") {
                    string[] entries = regex:split(formData, "&");
                    int entryIndex = 0;
                    while (entryIndex < entries.length()) {
                        int? index = entries[entryIndex].indexOf("=");
                        if (index is int && index != -1) {
                            string name = entries[entryIndex].substring(0, index);
                            name = name.trim();
                            int size = entries[entryIndex].length();
                            string value = entries[entryIndex].substring(index + 1, size);
                            value = value.trim();
                            if (value != "") {
                                parameters[name] = value;
                            }
                        }
                        entryIndex = entryIndex + 1;
                    }
                }
            }
            return parameters;
        }
    }

    # Extracts body parts from the request. If the content type is not a composite media type, an error
    # is returned.

    # + return - The body parts as an array of entities or else an `http:ClientError` if there were any errors
    #            constructing the body parts from the request
    public isolated function getBodyParts() returns mime:Entity[]|ClientError {
        var result = self.getEntity();
        if (result is ClientError) {
            return result;
        } else {
            var bodyParts = result.getBodyParts();
            if (bodyParts is mime:Error) {
                string message = "Error occurred while retrieving body parts from the request";
                return error GenericClientError(message, bodyParts);
            } else {
                return bodyParts;
            }
        }
    }

    # Sets a `json` as the payload.
    #
    # + payload - The `json` payload
    # + contentType - The content type of the payload. Set this to override the default `content-type` header value
    #                 for `json`
    public isolated function setJsonPayload(json payload, string contentType = "application/json") {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        entity.setJson(payload, contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets an `xml` as the payload.
    #
    # + payload - The `xml` payload
    # + contentType - The content type of the payload. Set this to override the default `content-type` header value
    #                 for `xml`
    public isolated function setXmlPayload(xml payload, string contentType = "application/xml") {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        entity.setXml(payload, contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets a `string` as the payload.
    #
    # + payload - The `string` payload
    # + contentType - The content type of the payload. Set this to override the default `content-type` header value
    #                 for `string`
    public isolated function setTextPayload(string payload, string contentType = "text/plain") {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        entity.setText(payload, contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets a `byte[]` as the payload.
    #
    # + payload - The `byte[]` payload
    # + contentType - The content type of the payload. Set this to override the default `content-type` header value
    #                 for `byte[]`
    public isolated function setBinaryPayload(byte[] payload, string contentType = "application/octet-stream") {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        entity.setByteArray(payload, contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Set multiparts as the payload.
    #
    # + bodyParts - The entities which make up the message body
    # + contentType - The content type of the top level message. Set this to override the default
    #                 `content-type` header value
    public isolated function setBodyParts(mime:Entity[] bodyParts, string contentType = "multipart/form-data") {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        entity.setBodyParts(bodyParts, contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets the content of the specified file as the entity body of the request.
    #
    # + filePath - Path to the file to be set as the payload
    # + contentType - The content type of the specified file. Set this to override the default `content-type`
    #                 header value
    public function setFileAsPayload(string filePath, string contentType = "application/octet-stream") {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        entity.setFileAsEntityBody(filePath, contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets a `ByteChannel` as the payload.
    #
    # + payload - A `ByteChannel` through which the message payload can be read
    # + contentType - The content type of the payload. Set this to override the default `content-type`
    #                 header value
    isolated function setByteChannel(io:ReadableByteChannel payload, string contentType = "application/octet-stream") {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        //  entity.setByteChannel(payload, contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets the request payload. Note that any string value is set as `text/plain`. To send a JSON-compatible string,
    # set the content-type header to `application/json` or use the `setJsonPayload` method instead.
    #
    # + payload - Payload can be of type `string`, `xml`, `json`, `byte[]` or `Entity[]` (i.e., a set
    # of body parts).
    public isolated function setPayload(string|xml|json|byte[]|mime:Entity[] payload) {
        if (payload is string) {
            self.setTextPayload(payload);
        } else if (payload is xml) {
            self.setXmlPayload(payload);
        } else if (payload is byte[]) {
            self.setBinaryPayload(payload);
        } else if (payload is json) {
            self.setJsonPayload(payload);
        } else {
            self.setBodyParts(payload);
        }
    }

    // For use within the module. Takes the Cache-Control header and parses it to a RequestCacheControl object.
    isolated function parseCacheControlHeader() {
        // If the request doesn't contain a cache-control header, resort to default cache control settings
        if (!self.hasHeader(CACHE_CONTROL)) {
            return;
        }

        RequestCacheControl reqCC = new;
        string cacheControl = checkpanic self.getHeader(CACHE_CONTROL);
        string[] directives = regex:split(cacheControl, ",");

        foreach var dir in directives {
            var directive = dir.trim();
            if (directive == NO_CACHE) {
                reqCC.noCache = true;
            } else if (directive == NO_STORE) {
                reqCC.noStore = true;
            } else if (directive == NO_TRANSFORM) {
                reqCC.noTransform = true;
            } else if (directive == ONLY_IF_CACHED) {
                reqCC.onlyIfCached = true;
            } else if (directive.startsWith(MAX_AGE)) {
                reqCC.maxAge = getDirectiveValue(directive);
            } else if (directive == MAX_STALE) {
                reqCC.maxStale = MAX_STALE_ANY_AGE;
            } else if (directive.startsWith(MAX_STALE)) {
                reqCC.maxStale = getDirectiveValue(directive);
            } else if (directive.startsWith(MIN_FRESH)) {
                reqCC.minFresh = getDirectiveValue(directive);
            }
            // non-standard directives are ignored
        }

        self.cacheControl = reqCC;
    }

    # Check whether the entity body is present.
    #
    # + return - A boolean indicating the availability of the entity body
    isolated function checkEntityBodyAvailability() returns boolean {
        return externCheckReqEntityBodyAvailability(self);
    }

    # Adds cookies to the request.
    #
    # + cookiesToAdd - Represents the cookies to be added
    public function addCookies(Cookie[] cookiesToAdd) {
        string cookieheader = "";
        Cookie[] sortedCookies = cookiesToAdd.sort(array:ASCENDING, isolated function(Cookie c) returns int {
            var cookiePath = c.path;
            int l = 0;
            if (cookiePath is string) {
                l = cookiePath.length();
            }
            return l;
        });
        foreach var cookie in sortedCookies {
            var cookieName = cookie.name;
            var cookieValue = cookie.value;
            if (cookieName is string && cookieValue is string) {
                cookieheader = cookieheader + cookieName + EQUALS + cookieValue + SEMICOLON + SPACE;
            }
            cookie.lastAccessedTime = time:currentTime();
        }
        if (cookieheader != "") {
            cookieheader = cookieheader.substring(0, cookieheader.length() - 2);
            if (self.hasHeader("Cookie")) {
                self.setHeader("Cookie", cookieheader);
            } else {
                self.addHeader("Cookie", cookieheader);
            }
        }
    }

    # Gets cookies from the request.
    #
    # + return - An array of cookie objects, which are included in the request
    public function getCookies() returns Cookie[] {
        Cookie[] cookiesInRequest = [];
        var cookieValue = self.getHeader("Cookie");
        if (cookieValue is string) {
            cookiesInRequest = parseCookieHeader(cookieValue);
        }
        return cookiesInRequest;
    }
}

isolated function externCreateNewReqEntity(Request request) returns mime:Entity =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternRequest",
    name: "createNewEntity"
} external;

isolated function externSetReqEntity(Request request, mime:Entity entity) =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternRequest",
    name: "setEntity"
} external;

isolated function externSetReqEntityAndUpdateContentTypeHeader(Request request, mime:Entity entity) =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternRequest",
    name: "setEntityAndUpdateContentTypeHeader"
} external;

isolated function externGetQueryParams(Request request) returns map<string[]> =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternRequest",
    name: "getQueryParams"
} external;

isolated function externGetMatrixParams(Request request, string path) returns map<any> =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternRequest",
    name: "getMatrixParams"
} external;

isolated function externGetReqEntity(Request request) returns mime:Entity|ClientError =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternRequest",
    name: "getEntity"
} external;

isolated function externGetEntityWithoutBodyAndHeaders(Request request) returns mime:Entity =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternRequest",
    name: "getEntityWithoutBodyAndHeaders"
} external;

isolated function externGetEntityWithBodyAndWithoutHeaders(Request request) returns mime:Entity =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternRequest",
    name: "getEntityWithBodyAndWithoutHeaders"
} external;

isolated function externCheckReqEntityBodyAvailability(Request request) returns boolean =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternRequest",
    name: "checkEntityBodyAvailability"
} external;

# A record for providing mutual SSL handshake results.
#
# + status - Status of the handshake.
# + base64EncodedCert - Base64 encoded certificate.
public type MutualSslHandshake record {|
    MutualSslStatus status = ();
    string? base64EncodedCert = ();
|};

# Defines the possible values for the mutual ssl status.
#
# `passed`: Mutual SSL handshake is successful.
# `failed`: Mutual SSL handshake has failed.
public type MutualSslStatus PASSED | FAILED | ();

# Mutual SSL handshake is successful.
public const PASSED = "passed";

# Mutual SSL handshake has failed.
public const FAILED = "failed";

# Not a mutual ssl connection.
public const NONE = ();

// HTTP header related external functions
isolated function externRequestGetHeader(Request request, string headerName, HeaderPosition position = LEADING)
                         returns @tainted string|HeaderNotFoundError = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHeaders",
    name: "getHeader"
} external;

isolated function externRequestGetHeaders(Request request, string headerName, HeaderPosition position = LEADING)
                          returns @tainted string[]|HeaderNotFoundError = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHeaders",
    name: "getHeaders"
} external;

isolated function externRequestGetHeaderNames(Request request, HeaderPosition position = LEADING) returns @tainted string[] =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHeaders",
    name: "getHeaderNames"
} external;

isolated function externRequestAddHeader(Request request, string headerName, string headerValue, HeaderPosition position = LEADING) =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHeaders",
    name: "addHeader"
} external;

isolated function externRequestSetHeader(Request request, string headerName, string headerValue, HeaderPosition position = LEADING) =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHeaders",
    name: "setHeader"
} external;

isolated function externRequestRemoveHeader(Request request, string headerName, HeaderPosition position = LEADING) = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHeaders",
    name: "removeHeader"
} external;

isolated function externRequestRemoveAllHeaders(Request request, HeaderPosition position = LEADING) = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHeaders",
    name: "removeAllHeaders"
} external;

isolated function externRequestHasHeader(Request request, string headerName, HeaderPosition position = LEADING) returns boolean =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHeaders",
    name: "hasHeader"
} external;
