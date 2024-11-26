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
import ballerina/lang.'string as strings;
import ballerina/mime;
import ballerina/crypto;
import ballerina/time;
import ballerina/jballerina.java;
import ballerina/log;
import ballerina/data.jsondata;

# Represents an HTTP response.
#
# + statusCode - The response status code
# + reasonPhrase - The status code reason phrase
# + server - The server header
# + resolvedRequestedURI - The ultimate request URI that was made to receive the response when redirect is on
# + cacheControl - The cache-control directives for the response. This needs to be explicitly initialized if
#                  intending on utilizing HTTP caching. For incoming responses, this will already be populated
#                  if the response was sent with cache-control directives
public class Response {

    public int statusCode = 200;
    public string reasonPhrase = "";
    public string server = "";
    public string resolvedRequestedURI = "";
    public ResponseCacheControl? cacheControl = ();

    time:Utc receivedTime = [0, 0.0];
    time:Utc requestTime = [0, 0.0];
    private mime:Entity? entity = ();
    
    public isolated function init() {
        self.entity = self.createNewEntity();
    }

    # Create a new `Entity` and link it with the response.
    #
    # + return - Newly created `Entity` that has been set to the response
    isolated function createNewEntity() returns mime:Entity {
        return externCreateNewResEntity(self);
    }

    # Gets the `Entity` associated with the response.
    #
    # + return - The `Entity` of the response. An `http:ClientError` is returned, if entity construction fails
    public isolated function getEntity() returns mime:Entity|ClientError {
        return externGetResEntity(self);
    }

    // Gets the `Entity` from the response without the entity body. This function is exposed only to be used
    // internally.
    isolated function getEntityWithoutBodyAndHeaders() returns mime:Entity {
        return externGetResEntityWithoutBodyAndHeaders(self);
    }

    // Gets the `Entity` from the response with the body, but without headers. This function is used for Http level
    // functions.
    isolated function getEntityWithBodyAndWithoutHeaders() returns mime:Entity|ClientError {
        return externGetResEntityWithBodyAndWithoutHeaders(self);
    }

    # Sets the provided `Entity` to the response.
    #
    # + e - The `Entity` to be set to the response
    public isolated function setEntity(mime:Entity e) {
        return externSetResEntity(self, e);
    }

    # Sets the provided `Entity` to the request and update only the content type header in the transport message.
    #
    # + e - The `Entity` to be set to the request
    isolated function setEntityAndUpdateContentTypeHeader(mime:Entity e) {
        return externSetResEntityAndUpdateContentTypeHeader(self, e);
    }

    # Checks whether the requested header key exists in the header map.
    #
    # + headerName - The header name
    # + position - Represents the position of the header as an optional parameter
    # + return - `true` if the specified header key exists
    public isolated function hasHeader(string headerName, HeaderPosition position = LEADING) returns boolean {
        return externResponseHasHeader(self, headerName, position);
    }

    # Returns the value of the specified header. If the specified header key maps to multiple values, the first of
    # these values is returned.
    #
    # + headerName - The header name
    # + position - Represents the position of the header as an optional parameter. If the position is `http:TRAILING`,
    #              the entity-body of the `Response` must be accessed initially.
    # + return - The first header value for the specified header name or the `HeaderNotFoundError` if the header is not
    #            found.
    public isolated function getHeader(string headerName, HeaderPosition position = LEADING)
            returns string|HeaderNotFoundError {
        return externResponseGetHeader(self, headerName, position);
    }

    # Adds the specified header to the response. Existing header values are not replaced, except for the `Content-Type`
    # header. In the case of the `Content-Type` header, the existing value is replaced with the specified value.
    #. Panic if an illegal header is passed.
    #
    # + headerName - The header name
    # + headerValue - The header value
    # + position - Represents the position of the header as an optional parameter. If the position is `http:TRAILING`,
    #              the entity-body of the `Response` must be accessed initially.
    public isolated function addHeader(string headerName, string headerValue, HeaderPosition position = LEADING) {
        if headerName.equalsIgnoreCaseAscii(CONTENT_TYPE) {
            return externResponseSetHeader(self, headerName, headerValue, position);
        }
        return externResponseAddHeader(self, headerName, headerValue, position);
    }

    # Gets all the header values to which the specified header key maps to.
    #
    # + headerName - The header name
    # + position - Represents the position of the header as an optional parameter. If the position is `http:TRAILING`,
    #              the entity-body of the `Response` must be accessed initially.
    # + return - The header values the specified header key maps to or the `HeaderNotFoundError` if the header is not
    #            found.
    public isolated function getHeaders(string headerName, HeaderPosition position = LEADING)
            returns string[]|HeaderNotFoundError {
        return externResponseGetHeaders(self, headerName, position);
    }

    # Sets the specified header to the response. If a mapping already exists for the specified header key, the
    # existing header value is replaced with the specified header value. Panic if an illegal header is passed.
    #
    # + headerName - The header name
    # + headerValue - The header value
    # + position - Represents the position of the header as an optional parameter. If the position is `http:TRAILING`,
    #              the entity-body of the `Response` must be accessed initially.
    public isolated function setHeader(string headerName, string headerValue, HeaderPosition position = LEADING) {
        externResponseSetHeader(self, headerName, headerValue, position);


        // TODO: see if this can be handled in a better manner
        if strings:equalsIgnoreCaseAscii(SERVER, headerName) {
            self.server = headerValue;
        }
    }

    # Removes the specified header from the response.
    #
    # + headerName - The header name
    # + position - Represents the position of the header as an optional parameter. If the position is `http:TRAILING`,
    #              the entity-body of the `Response` must be accessed initially.
    public isolated function removeHeader(string headerName, HeaderPosition position = LEADING) {
        externResponseRemoveHeader(self, headerName, position);
    }

    # Removes all the headers from the response.
    #
    # + position - Represents the position of the header as an optional parameter. If the position is `http:TRAILING`,
    #              the entity-body of the `Response` must be accessed initially.
    public isolated function removeAllHeaders(HeaderPosition position = LEADING) {
        externResponseRemoveAllHeaders(self, position);
    }

    # Gets all the names of the headers of the response.
    #
    # + position - Represents the position of the header as an optional parameter. If the position is `http:TRAILING`,
    #              the entity-body of the `Response` must be accessed initially.
    # + return - An array of all the header names
    public isolated function getHeaderNames(HeaderPosition position = LEADING) returns string[] {
        return externResponseGetHeaderNames(self, position);
    }

    # Sets the `content-type` header to the response.
    #
    # + contentType - Content type value to be set as the `content-type` header
    # + return - Nil if successful, error in case of invalid content-type
   public isolated function setContentType(string contentType) returns error? {
        return trap self.setHeader(mime:CONTENT_TYPE, contentType);
    }

    # Gets the type of the payload of the response (i.e., the `content-type` header value).
    #
    # + return - The `content-type` header value as a string
    public isolated function getContentType() returns string {
        string contentTypeHeaderValue = "";
        var value = self.getHeader(mime:CONTENT_TYPE);
        if value is string {
            contentTypeHeaderValue = value;
        }
        return contentTypeHeaderValue;
    }

    # Extract `json` payload from the response. For an empty payload, `http:NoContentError` is returned.
    #
    # If the content type is not JSON, an `http:ClientError` is returned.
    #
    # + return - The `json` payload or `http:ClientError` in case of errors
    public isolated function getJsonPayload() returns json|ClientError {
        var result = self.getEntityWithBodyAndWithoutHeaders();
        if result is error {
            return result;
        } else {
            var payload = externGetJson(result);
            if payload is mime:Error {
                if payload.cause() is mime:NoContentError {
                    return createErrorForNoPayload(<mime:Error> payload);
                } else {
                    string message = "Error occurred while retrieving the json payload from the response";
                    return error GenericClientError(message, payload);
               }
            } else {
                return payload;
            }
        }
    }

    # Extracts `xml` payload from the response. For an empty payload, `http:NoContentError` is returned.
    #
    # If the content type is not XML, an `http:ClientError` is returned.
    #
    # + return - The `xml` payload or `http:ClientError` in case of errors
    public isolated function getXmlPayload() returns xml|ClientError {
        var result = self.getEntityWithBodyAndWithoutHeaders();
        if result is error {
            return result;
        } else {
            var payload = externGetXml(result);
            if payload is mime:Error {
                if payload.cause() is mime:NoContentError {
                    return createErrorForNoPayload(<mime:Error> payload);
                } else {
                    string message = "Error occurred while retrieving the xml payload from the response";
                    return error GenericClientError(message, payload);
               }
            } else {
                return payload;
            }
        }
    }

    # Extracts `text` payload from the response. For an empty payload, `http:NoContentError` is returned.
    #
    # If the content type is not of type text, an `http:ClientError` is returned.
    #
    # + return - The string representation of the message payload or `http:ClientError` in case of errors
    public isolated function getTextPayload() returns string|ClientError {
        var result = self.getEntityWithBodyAndWithoutHeaders();
        if result is error {
            return result;
        } else {
            var payload = externGetText(result);
            if payload is mime:Error {
                if payload.cause() is mime:NoContentError {
                    return createErrorForNoPayload(<mime:Error> payload);
                } else {
                    string message = "Error occurred while retrieving the text payload from the response";
                    return error GenericClientError(message, payload);
               }
            } else {
                return payload;
            }
        }
    }

    # Gets the response payload as a `ByteChannel`, except in the case of multiparts. To retrieve multiparts, use
    # `Response.getBodyParts()`.
    #
    # + return - A byte channel from which the message payload can be read or `http:ClientError` in case of errors
    isolated function getByteChannel() returns io:ReadableByteChannel|ClientError {
        var result = self.getEntityWithBodyAndWithoutHeaders();
        if result is error {
            return result;
        } else {
            var payload = externGetByteChannel(result);
            if payload is mime:Error {
                string message = "Error occurred while retrieving the byte channel from the response";
                return error GenericClientError(message, payload);
            } else {
                return payload;
            }
        }
    }

    # Gets the response payload as  a stream of byte[], except in the case of multiparts. To retrieve multiparts, use
    # `Response.getBodyParts()`.
    #
    # + arraySize - A defaultable parameter to state the size of the byte array. Default size is 8KB
    # + return - A byte stream from which the message payload can be read or `http:ClientError` in case of errors
    public isolated function getByteStream(int arraySize = 8192) returns stream<byte[], io:Error?>|ClientError {
        var result = self.getEntityWithBodyAndWithoutHeaders();
        if result is error {
            return result;
        } else {
            externPopulateInputStream(result);
            var byteStream = result.getByteStream(arraySize);
            if byteStream is mime:Error {
                string message = "Error occurred while retrieving the byte stream from the response";
                return error GenericClientError(message, byteStream);
            } else {
                return byteStream;
            }
        }
    }

    # Gets the response payload as a `byte[]`.
    #
    # + return - The byte[] representation of the message payload or `http:ClientError` in case of errors
    public isolated function getBinaryPayload() returns byte[]|ClientError {
        var result = self.getEntityWithBodyAndWithoutHeaders();
        if result is error {
            return result;
        } else {
            var payload = externGetByteArray(result);
            if payload is mime:Error {
                string message = "Error occurred while retrieving the binary payload from the response";
                return error GenericClientError(message, payload);
            } else {
                return payload;
            }
        }
    }

    # Gets the response payload as a `stream` of SseEvent.
    #
    # + return - A SseEvent stream from which the `http:SseEvent` can be read or `http:ClientError` in case of errors
    public isolated function getSseEventStream() returns stream<SseEvent, error?>|ClientError {
        return getSseEventStream(self);
    }

    # Extracts body parts from the response. If the content type is not a composite media type, an error is returned.
    #
    # + return - The body parts as an array of entities or else an `http:ClientError` if there were any errors in
    #            constructing the body parts from the response
    public isolated function getBodyParts() returns mime:Entity[]|ClientError {
        var result = self.getEntity();
        if result is ClientError {
            // TODO: Confirm whether this is actually a ClientError or not.
            return result;
        } else {
            var bodyParts = result.getBodyParts();
            if bodyParts is mime:Error {
                string message = "Error occurred while retrieving body parts from the response: " + bodyParts.message();
                return error GenericClientError(message, bodyParts);
            } else {
                return bodyParts;
            }
        }
    }

    # Sets the `etag` header for the given payload. The ETag is generated using a CRC32 hash isolated function.
    #
    # + payload - The payload for which the ETag should be set
    public isolated function setETag(json|xml|string|byte[] payload) {
        string etag = payload is byte[] ? crypto:crc32b(payload) : crypto:crc32b(payload.toString().toBytes());
        self.setHeader(ETAG, etag);
    }

    # Sets the current time as the `last-modified` header.
    public isolated function setLastModified() {
        time:Utc currentT = time:utcNow();
        var lastModified = utcToString(currentT, RFC_1123_DATE_TIME);
        if lastModified is string {
            self.setHeader(LAST_MODIFIED, lastModified);
        } else {
            //This error is unlikely as the format is a constant and time is
            //the current time which  does not returns an error.
            panic lastModified;
        }
    }

    # Sets a `json` as the payload. If the content-type header is not set then this method set content-type
    # headers with the default content-type, which is `application/json`. Any existing content-type can be
    # overridden by passing the content-type as an optional parameter.
    #
    # + payload - The `json` payload
    # + contentType - The content type of the payload. This is an optional parameter.
    #                 The `application/json` is the default value
    public isolated function setJsonPayload(json payload, string? contentType = ()) {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        setJson(entity, jsondata:toJson(payload), self.getContentType(), contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets a `anydata` payaload, as a `json` payload. If the content-type header is not set then this method set content-type
    # headers with the default content-type, which is `application/json`. Any existing content-type can be
    # overridden by passing the content-type as an optional parameter.
    #
    # + payload - The `json` payload
    # + contentType - The content type of the payload. This is an optional parameter.
    #                 The `application/json` is the default value
    public isolated function setAnydataAsJsonPayload(anydata payload, string? contentType = ()) {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        setJson(entity, jsondata:toJson(payload), self.getContentType(), contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets an `xml` as the payload. If the content-type header is not set then this method set content-type
    # headers with the default content-type, which is `application/xml`. Any existing content-type can be
    # overridden by passing the content-type as an optional parameter.
    #
    # + payload - The `xml` payload
    # + contentType - The content type of the payload. This is an optional parameter.
    #                 The `application/xml` is the default value
    public isolated function setXmlPayload(xml payload, string? contentType = ()) {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        setXml(entity, payload, self.getContentType(), contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets a `string` as the payload. If the content-type header is not set then this method set
    # content-type headers with the default content-type, which is `text/plain`. Any
    # existing content-type can be overridden by passing the content-type as an optional parameter.
    #
    # + payload - The `string` payload
    # + contentType - The content type of the payload. This is an optional parameter.
    #                 The `text/plain` is the default value
    public isolated function setTextPayload(string payload, string? contentType = ()) {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        setText(entity, payload, self.getContentType(), contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets a `byte[]` as the payload. If the content-type header is not set then this method set content-type
    # headers with the default content-type, which is `application/octet-stream`. Any existing content-type
    # can be overridden by passing the content-type as an optional parameter.
    #
    # + payload - The `byte[]` payload
    # + contentType - The content type of the payload. This is an optional parameter.
    #                 The `application/octet-stream` is the default value
    public isolated function setBinaryPayload(byte[] payload, string? contentType = ()) {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        setByteArray(entity, payload, self.getContentType(), contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Set multiparts as the payload. If the content-type header is not set then this method
    # set content-type headers with the default content-type, which is `multipart/form-data`.
    # Any existing content-type can be overridden by passing the content-type as an optional parameter.
    #
    # + bodyParts - The entities which make up the message body
    # + contentType - The content type of the top level message. This is an optional parameter.
    #                 The `multipart/form-data` is the default value
    public isolated function setBodyParts(mime:Entity[] bodyParts, string? contentType = ()) {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        setBodyParts(entity, bodyParts, self.getContentType(), contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets the content of the specified file as the entity body of the response. If the content-type header
    # is not set then this method set content-type headers with the default content-type, which is
    # `application/octet-stream`. Any existing content-type can be overridden by passing the content-type
    # as an optional parameter.
    #
    # + filePath - Path to the file to be set as the payload
    # + contentType - The content type of the specified file. This is an optional parameter.
    #                 The `application/octet-stream` is the default value
    public isolated function setFileAsPayload(string filePath, string? contentType = ()) {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        setFile(entity, filePath, self.getContentType(), contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets a `ByteChannel` as the payload.
    #
    # + payload - A `ByteChannel` through which the message payload can be read
    # + contentType - The content type of the payload. Set this to override the default `content-type`
    #                 header value
    isolated function setByteChannel(io:ReadableByteChannel payload, string contentType = "application/octet-stream") {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        // entity.setByteChannel(payload, contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets a `Stream` as the payload. If the content-type header is not set then this method set content-type
    # headers with the default content-type, which is `application/octet-stream`. Any existing content-type can
    # be overridden by passing the content-type as an optional parameter.
    #
    # + byteStream - Byte stream, which needs to be set to the response
    # + contentType - Content-type to be used with the payload. This is an optional parameter.
    #                 The `application/octet-stream` is the default value
    public isolated function setByteStream(stream<byte[], io:Error?> byteStream, string? contentType = ()) {
        mime:Entity entity = self.getEntityWithoutBodyAndHeaders();
        setByteStream(entity, byteStream, self.getContentType(), contentType);
        self.setEntityAndUpdateContentTypeHeader(entity);
    }

    # Sets an `http:SseEvent` stream as the payload, along with the Content-Type and Cache-Control 
    # headers set to 'text/event-stream' and 'no-cache', respectively.
    #
    # + eventStream - SseEvent stream, which needs to be set to the response
    public isolated function setSseEventStream(stream<SseEvent, error?>|stream<SseEvent, error> eventStream) {
        ResponseCacheControl cacheControl = new;
        cacheControl.noCache = true;
        self.cacheControl = cacheControl;
        SseEventToByteStreamGenerator byteStreamGen = new(eventStream);
        self.setByteStream(new (byteStreamGen), mime:TEXT_EVENT_STREAM);
    }
    
    # Sets the response payload. This method overrides any existing content-type by passing the content-type
    # as an optional parameter. If the content type parameter is not provided then the default value derived
    # from the payload will be used as content-type only when there are no existing content-type header. If
    # the payload is non-json typed value then the value is converted to json using the `toJson` method.
    #
    # + payload - Payload can be of type `string`, `xml`, `byte[]`, `json`, `stream<byte[], io:Error?>`,
    #             stream<SseEvent, error?>(represents Server-Sent events), `Entity[]` (i.e., a set of body
    #             parts) or any other value of type `anydata` which will be converted to `json` using the
    #             `toJson` method.
    # + contentType - Content-type to be used with the payload. This is an optional parameter
    public isolated function setPayload(anydata|mime:Entity[]|stream<byte[], io:Error?>|stream<SseEvent, error?> payload,
            string? contentType = ()) {
        if contentType is string {
            error? err = self.setContentType(contentType);
            if err is error {
                log:printDebug(err.message());
            }
        }

        if payload is string {
            self.setTextPayload(payload);
        } else if payload is xml {
            self.setXmlPayload(payload);
        } else if payload is byte[] {
            self.setBinaryPayload(payload);
        } else if payload is json {
            self.setJsonPayload(payload);
        } else if payload is stream<byte[], io:Error?> {
            self.setByteStream(payload);
        } else if payload is mime:Entity[] {
            self.setBodyParts(payload);
        } else if payload is stream<SseEvent, error?> {
            self.setSseEventStream(payload);
        } else if payload is anydata {
            self.setAnydataAsJsonPayload(payload);
        } else {
            panic error Error("invalid entity body type." +
                "expected one of the types: string|xml|json|byte[]|mime:Entity[]|stream<byte[],io:Error?>");
        }
    }

    # Adds the cookie to response.
    #
    # + cookie - The cookie, which is added to response
    public isolated function addCookie(Cookie cookie) {
        var result = cookie.isValid();
        if result is boolean {
            self.addHeader("Set-Cookie", cookie.toStringValue());
        } else {
            log:printError("Invalid Cookie", 'error = result);
        }
    }

    # Deletes the cookies in the client's cookie store.
    #
    # + cookiesToRemove - Cookies to be deleted
    public isolated function removeCookiesFromRemoteStore(Cookie...cookiesToRemove) {
        foreach var cookie in cookiesToRemove {
            string expires = "1994-03-12 08:12:22";
            int maxAge = 0;
            Cookie newCookie = getCloneWithExpiresAndMaxAge(cookie, expires, maxAge);
            self.addCookie(newCookie);
        }
    }

    # Gets cookies from the response.
    #
    # + return - An array of cookie objects, which are included in the response
    public isolated function getCookies() returns Cookie[] {
        Cookie[] cookiesInResponse = [];
        string[]|error cookiesStringValues = self.getHeaders("Set-Cookie");
        if cookiesStringValues is string[] {
            foreach string cookiesStringValue in cookiesStringValues {
                cookiesInResponse.push(parseSetCookieHeader(cookiesStringValue));
            }
        }
        return cookiesInResponse;
    }

    isolated function buildStatusCodeResponse(typedesc<anydata>? payloadType, typedesc<StatusCodeResponse> statusCodeResType,
        boolean requireValidation, boolean requireLaxDataBinding, Status status, map<string|int|boolean|string[]|int[]|boolean[]> headers, string? mediaType,
        boolean fromDefaultStatusCodeMapping) returns StatusCodeResponse|ClientError {
        if payloadType !is () {
            anydata|ClientError payload = self.performDataBinding(payloadType, requireValidation, requireLaxDataBinding);
            if payload is ClientError {
                return self.getStatusCodeResponseDataBindingError(payload.message(), fromDefaultStatusCodeMapping, PAYLOAD, payload);
            }
            return externBuildStatusCodeResponse(statusCodeResType, status, headers, payload, mediaType);
        } else {
            return externBuildStatusCodeResponse(statusCodeResType, status, headers, (), ());
        }
    }

    isolated function performDataBinding(typedesc<anydata> targetType, boolean requireValidation, boolean requireLaxDataBinding) returns anydata|ClientError {
        anydata payload = check performDataBinding(self, targetType, requireLaxDataBinding);
        if requireValidation {
            return performDataValidation(payload, targetType);
        }
        return payload;
    }

    isolated function getStatusCodeResponseBindingError(string reasonPhrase) returns ClientError {
        map<string[]> headers = getHeaders(self);
        anydata|error payload = getPayload(self);
        int statusCode = self.statusCode;
        if payload is error {
            if payload is NoContentError {
                return createStatusCodeResponseBindingError(statusCode, reasonPhrase, headers);
            }
            return error PayloadBindingClientError("http:StatusCodeBindingError creation failed: " + statusCode.toString() +
                " response payload extraction failed", payload);
        } else {
            return createStatusCodeResponseBindingError(statusCode, reasonPhrase, headers, payload);
        }
    }

    isolated function getStatusCodeResponseDataBindingError(string reasonPhrase, boolean fromDefaultStatusCodeMapping,
        DataBindingErrorType errorType, error? cause) returns ClientError {
        map<string[]> headers = getHeaders(self);
        anydata|error payload = getPayload(self);
        int statusCode = self.statusCode;
        if payload is error {
            if payload is NoContentError {
                return createStatusCodeResponseDataBindingError(errorType, fromDefaultStatusCodeMapping, statusCode, reasonPhrase, headers, cause = cause);
            }
            return error PayloadBindingClientError("http:StatusCodeBindingError creation failed: " + statusCode.toString() +
                " response payload extraction failed", payload);
        } else {
            return createStatusCodeResponseDataBindingError(errorType, fromDefaultStatusCodeMapping, statusCode, reasonPhrase, headers, payload, cause);
        }
    }
}

isolated function externCreateNewResEntity(Response response) returns mime:Entity =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResponse",
    name: "createNewEntity"
} external;

isolated function externSetResEntity(Response response, mime:Entity entity) =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResponse",
    name: "setEntity"
} external;

isolated function externSetResEntityAndUpdateContentTypeHeader(Response response, mime:Entity entity) =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResponse",
    name: "setEntityAndUpdateContentTypeHeader"
} external;

isolated function externGetResEntity(Response response) returns mime:Entity|ClientError =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResponse",
    name: "getEntity"
} external;

isolated function externGetResEntityWithoutBodyAndHeaders(Response response) returns mime:Entity =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResponse",
    name: "getEntityWithoutBodyAndHeaders"
} external;

isolated function externGetResEntityWithBodyAndWithoutHeaders(Response response) returns mime:Entity =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResponse",
    name: "getEntityWithBodyAndWithoutHeaders"
} external;

// HTTP header related external functions
isolated function externResponseGetHeader(Response response, string headerName, HeaderPosition position)
                         returns string|HeaderNotFoundError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHeaders",
    name: "getHeader"
} external;

isolated function externResponseGetHeaders(Response response, string headerName, HeaderPosition position)
                          returns string[]|HeaderNotFoundError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHeaders",
    name: "getHeaders"
} external;

isolated function externResponseGetHeaderNames(Response response, HeaderPosition position) returns string[] =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHeaders",
    name: "getHeaderNames"
} external;

isolated function externResponseAddHeader(Response response, string headerName, string headerValue, HeaderPosition position) =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHeaders",
    name: "addHeader"
} external;

isolated function externResponseSetHeader(Response response, string headerName, string headerValue, HeaderPosition position) =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHeaders",
    name: "setHeader"
} external;

isolated function externResponseRemoveHeader(Response response, string headerName, HeaderPosition position) = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHeaders",
    name: "removeHeader"
} external;

isolated function externResponseRemoveAllHeaders(Response response, HeaderPosition position) = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHeaders",
    name: "removeAllHeaders"
} external;

isolated function externResponseHasHeader(Response response, string headerName, HeaderPosition position) returns boolean =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHeaders",
    name: "hasHeader"
} external;

isolated function externBuildStatusCodeResponse(typedesc<StatusCodeResponse> statusCodeResType, Status status,
    map<string|int|boolean|string[]|int[]|boolean[]> headers, anydata body, string? mediaType)
                                  returns StatusCodeResponse|ClientError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternResponseProcessor",
    name: "buildStatusCodeResponse"
} external;
