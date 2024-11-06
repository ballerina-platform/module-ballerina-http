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

import ballerina/jballerina.java;
import ballerina/lang.value as val;
import ballerina/mime;
import ballerina/io;
import ballerina/observe;
import ballerina/time;
import ballerina/log;
import ballerina/lang.'string as strings;
import ballerina/url;
import ballerina/data.jsondata;

final boolean observabilityEnabled = observe:isObservabilityEnabled();

# Parses the header value which contains multiple values or parameters.
# ```ballerina
#  http:HeaderValue[] values = check http:parseHeader("text/plain;level=1;q=0.6, application/xml;level=2");
# ```
#
# + headerValue - The header value
# + return - An array of `http:HeaderValue` typed record containing the value and its parameter map
#            or else an `http:ClientError` if the header parsing fails
public isolated function parseHeader(string headerValue) returns HeaderValue[]|ClientError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ParseHeader",
    name: "parseHeader"
} external;

# Converts the headers represented as a map of `anydata` to a map of `string` or `string` array. The `value:toString`
# method will be used to convert the values to `string`. Additionally if the header name is specified by the
# `http:Header` annotation, then it will be used as the header name.
# ```ballerina
# type Headers record {
#   @http:Header {name: "X-API-VERSION"}
#   string apiVersion;
#   int id;
# };
#
# Headers headers = {apiVersion: "v1", id: 1};
# map<string|string[]> headersMap = http:getHeaderMap(headers); // { "X-API-VERSION": "v1", "id": "1" }
# ```
#
# + headers - The headers represented as a map of anydata
# + return - A map of string or string array representing the headers
public isolated function getHeaderMap(map<anydata> headers) returns map<string|string[]> {
    return map from var [key, value] in headers.entries()
        select [getHeaderName(key, typeof headers), getHeaderValue(value)];
}

# If the query name is specified by the `http:Query` annotation, then this function will return the queries map
# with the specified query name. Otherwise, it will return the map as it is.
# ```ballerina
# type Queries record {
#   @http:Query {name: "filter_ids"}
#   string[] ids;
# };
#
# Queries queries = {ids: ["1", "2"]};
# map<anydata> queriesMap = http:getQueryMap(queries); // { "filter_ids": ["1", "2"] }
# ```
#
# + queries - The queries represented as a map of anydata
# + return - The queries map with names specified by the `http:Query` annotation
public isolated function getQueryMap(map<anydata> queries) returns map<anydata> {
    return map from var [key, value] in queries.entries()
        select [getQueryName(key, typeof queries), value];
}

isolated function getQueryName(string key, typedesc<map<anydata>> queryParamType) returns string = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternUtils",
    name: "getQueryName"
} external;

isolated function getHeaderName(string key, typedesc<map<anydata>> headerParamType) returns string = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternUtils",
    name: "getHeaderName"
} external;

isolated function getHeaderValue(anydata value) returns string|string[] => value is anydata[] ? value.'map(v => v.toString()) : value.toString();

isolated function buildRequest(RequestMessage message, string? mediaType) returns Request|ClientError {
    Request request = new;
    if message is () {
        request.noEntityBody = true;
        return request;
    } else if message is Request {
        request = message;
        request.noEntityBody = !request.checkEntityBodyAvailability();
    } else if message is string {
        request.setTextPayload(message);
    } else if message is xml {
        request.setXmlPayload(message);
    } else if message is byte[] {
        request.setBinaryPayload(message);
    } else if message is stream<byte[], io:Error?> {
        request.setByteStream(message);
    } else if message is mime:Entity[] {
        request.setBodyParts(message);
    } else if message is anydata {
        match mediaType {
            mime:APPLICATION_FORM_URLENCODED => {
                map<string>|error pairs = val:cloneWithType(message);
                if pairs is error {
                    return error InitializingOutboundRequestError("unsupported content for application/x-www-form-urlencoded media type");
                }
                string payload = check processUrlEncodedContent(pairs);
                request.setTextPayload(payload, mime:APPLICATION_FORM_URLENCODED);
            }
            _ => {
                json payload = check processJsonContent(message);
                request.setJsonPayload(payload);
            }
        }
    } else {
        string errorMsg = "invalid request body type. expected one of the types: http:Request|xml|json|table<map<json>>|(map<json>|table<map<json>>)[]|mime:Entity[]|stream<byte[], io:Error?>";
        panic error InitializingOutboundRequestError(errorMsg);
    }
    return request;
}

isolated function processUrlEncodedContent(map<string> message) returns string|ClientError {
    do {
        string[] messageParams = [];
        foreach var ['key, value] in message.entries() {
            string encodedValue = check url:encode(value, "UTF-8");
            string entry = string `${'key}=${encodedValue}`;
            messageParams.push(entry);
        }
        return strings:'join("&", ...messageParams);
    } on fail var e {
        return error InitializingOutboundRequestError("content encoding error: " + e.message(), e);
    }
}

isolated function processJsonContent(anydata message) returns json|ClientError {
    var result = trap jsondata:toJson(message);
    if result is error {
        return error InitializingOutboundRequestError("json conversion error: " + result.message(), result);
    }
    return result;
}

isolated function buildResponse(ResponseMessage message, string? resourceAccessor) returns Response|ListenerError {
    if message is () {
        return new Response();
    }
    if message is Response {
        return message;
    }
    Response response = new;
    if message is string {
        response.setTextPayload(message);
    } else if message is xml {
        response.setXmlPayload(message);
    } else if message is byte[] {
        response.setBinaryPayload(message);
    } else if message is stream<byte[], io:Error?> {
        response.setByteStream(message);
    } else if message is stream<SseEvent, error?> {
        response.setSseEventStream(message);
    } else if message is mime:Entity[] {
        response.setBodyParts(message);
    } else if message is anydata {
        var result = trap jsondata:toJson(message);
        if result is error {
            return error InitializingOutboundResponseError("json conversion error: " + result.message(), result);
        } else {
            response.setJsonPayload(result);
        }
    } else {
        string errorMsg = "invalid response body type. expected one of the types: http:Response|xml|json|table<map<json>>|(map<json>|table<map<json>>)[]|mime:Entity[]|stream<byte[], io:Error?>";
        panic error InitializingOutboundResponseError(errorMsg);
    }
    if resourceAccessor == HTTP_POST {
        response.statusCode = STATUS_CREATED;
    }
    return response;
}

isolated function populateOptions(Request request, string? mediaType, map<string|string[]>? headers) {
    // This method is called after setting the payload. Hence default content type header will be overridden.
    // Update content-type header according to the priority. (Highest to lowest)
    // 1. MediaType arg in client method
    // 2. Headers arg in client method
    // 3. Default content type related to payload
    populateHeaders(request, headers);
    if mediaType is string {
        request.setHeader(CONTENT_TYPE, mediaType);
    }
}

isolated function buildRequestWithHeaders(map<string|string[]>? headers) returns Request {
    Request request = new;
    request.noEntityBody = true;
    populateHeaders(request, headers);
    return request;
}

isolated function populateHeaders(Request request, map<string|string[]>? headers) {
    if headers is () {
        return;
    }

    foreach var [headerKey, headerValue] in getHeaderMap(headers).entries() {
        if headerValue is string[] {
            foreach string value in headerValue {
                request.addHeader(headerKey, value);
            }
        } else {
            request.setHeader(headerKey, headerValue);
        }
    }
}

# The HEAD remote function implementation of the Circuit Breaker. This wraps the `head` function of the underlying
# HTTP remote function provider.

# + path - Resource path
# + outRequest - A Request struct
# + requestAction - `HttpOperation` related to the request
# + httpClient - HTTP client which uses to call the relevant functions
# + verb - HTTP verb used for submit method
# + return - The response for the request or an `http:ClientError` if failed to establish communication with the upstream server
isolated function invokeEndpoint (string path, Request outRequest, HttpOperation requestAction, HttpClient httpClient,
        string verb = "") returns  HttpResponse|ClientError {

    if HTTP_GET == requestAction {
        var result = httpClient->get(path, message = outRequest);
        return result;
    } else if HTTP_POST == requestAction {
        var result = httpClient->post(path, outRequest);
        return result;
    } else if HTTP_OPTIONS == requestAction {
        var result = httpClient->options(path, message = outRequest);
        return result;
    } else if HTTP_PUT == requestAction {
        var result = httpClient->put(path, outRequest);
        return result;
    } else if HTTP_DELETE == requestAction {
        var result = httpClient->delete(path, outRequest);
        return result;
    } else if HTTP_PATCH == requestAction {
        var result = httpClient->patch(path, outRequest);
        return result;
    } else if HTTP_FORWARD == requestAction {
        var result = httpClient->forward(path, outRequest);
        return result;
    } else if HTTP_HEAD == requestAction {
        var result = httpClient->head(path, message = outRequest);
        return result;
    } else if HTTP_SUBMIT == requestAction {
        return httpClient->submit(verb, path, outRequest);
    } else {
        return getError();
    }
}

// Extracts HttpOperation from the Http verb passed in.
isolated function extractHttpOperation (string httpVerb) returns HttpOperation {
    HttpOperation inferredConnectorAction = HTTP_NONE;
    if "GET" == httpVerb {
        inferredConnectorAction = HTTP_GET;
    } else if "POST" == httpVerb {
        inferredConnectorAction = HTTP_POST;
    } else if "OPTIONS" == httpVerb {
        inferredConnectorAction = HTTP_OPTIONS;
    } else if "PUT" == httpVerb {
        inferredConnectorAction = HTTP_PUT;
    } else if "DELETE" == httpVerb {
        inferredConnectorAction = HTTP_DELETE;
    } else if "PATCH" == httpVerb {
        inferredConnectorAction = HTTP_PATCH;
    } else if "FORWARD" == httpVerb {
        inferredConnectorAction = HTTP_FORWARD;
    } else if "HEAD" == httpVerb {
        inferredConnectorAction = HTTP_HEAD;
    } else if "SUBMIT" == httpVerb {
        inferredConnectorAction = HTTP_SUBMIT;
    }
    return inferredConnectorAction;
}

isolated function getError() returns UnsupportedActionError {
    return error UnsupportedActionError("Unsupported connector action received.");
}

isolated function populateRequestFields (Request originalRequest, Request newRequest)  {
    newRequest.rawPath = originalRequest.rawPath;
    newRequest.method = originalRequest.method;
    newRequest.httpVersion = originalRequest.httpVersion;
    newRequest.cacheControl = originalRequest.cacheControl;
    newRequest.userAgent = originalRequest.userAgent;
    newRequest.extraPathInfo = originalRequest.extraPathInfo;
}

isolated function populateMultipartRequest(Request inRequest) returns Request|ClientError {
    if isMultipartRequest(inRequest) {
        mime:Entity[] bodyParts = check inRequest.getBodyParts();
        foreach var bodyPart in bodyParts {
            if isNestedEntity(bodyPart) {
                mime:Entity[]|error childParts = bodyPart.getBodyParts();

                if childParts is error {
                    return error GenericClientError(childParts.message(), childParts);
                }

                foreach var childPart in childParts {
                    // When performing passthrough scenarios, message needs to be built before
                    // invoking the endpoint to create a message datasource.
                    byte[]|error childBlobContent = childPart.getByteArray();
                    if childBlobContent is error {
                        log:printDebug("Error building datasource for multipart request: " + childBlobContent.message());
                    }
                }
                bodyPart.setBodyParts(childParts, bodyPart.getContentType());
            } else {
                byte[]|error bodyPartBlobContent = bodyPart.getByteArray();
                if bodyPartBlobContent is error {
                    log:printDebug("Error building datasource for multipart request: " + bodyPartBlobContent.message());
                }
            }
        }
        inRequest.setBodyParts(bodyParts, inRequest.getContentType());
    }
    return inRequest;
}

isolated function isMultipartRequest(Request request) returns boolean {
    return request.hasHeader(mime:CONTENT_TYPE) &&
        request.getContentType().startsWith(MULTIPART_AS_PRIMARY_TYPE);
}

isolated function isNestedEntity(mime:Entity entity) returns boolean {
    return entity.hasHeader(mime:CONTENT_TYPE) &&
        entity.getContentType().startsWith(MULTIPART_AS_PRIMARY_TYPE);
}

isolated function createFailoverRequest(Request request, mime:Entity requestEntity) returns Request|ClientError {
    if isMultipartRequest(request) {
        return populateMultipartRequest(request);
    } else {
        Request newOutRequest = new;
        populateRequestFields(request, newOutRequest);
        newOutRequest.setEntity(requestEntity);
        return newOutRequest;
    }
}

isolated function getInvalidTypeError() returns ClientError {
    return error GenericClientError("Invalid return type found for the HTTP operation");
}

isolated function createErrorForNoPayload(mime:Error err) returns ClientError {
    return error NoContentError("No content", err);
}

isolated function getStatusCodeRange(string statusCode) returns string {
    return statusCode.substring(0, 1) + STATUS_CODE_GROUP_SUFFIX;
}

# Returns a random UUID string.
#
# + return - The random string
isolated function uuid() returns string {
    var result = java:toString(nativeUuid());
    if result is string {
        return result;
    } else {
        panic error("Error occured when converting the UUID to string.");
    }
}

# Add observability information as tags
#
# + path - Resource path
# + method - http method of the request
# + statusCode - status code of the response
# + url - The request URL
isolated function addObservabilityInformation(string path, string method, int statusCode, string url) {
    string statusCodeConverted = statusCode.toString();
    _ = checkpanic observe:addTagToSpan(HTTP_URL, path);
    _ = checkpanic observe:addTagToSpan(HTTP_METHOD, method);
    _ = checkpanic observe:addTagToSpan(HTTP_STATUS_CODE, statusCodeConverted);
    _ = checkpanic observe:addTagToSpan(HTTP_BASE_URL, url);

    _ = checkpanic observe:addTagToMetrics(HTTP_METHOD, method);
    _ = checkpanic observe:addTagToMetrics(HTTP_BASE_URL, url);
    _ = checkpanic observe:addTagToMetrics(HTTP_STATUS_CODE_GROUP, getStatusCodeRange(statusCodeConverted));
}

//Resolve a given path against a given URI.
isolated function resolve(string baseUrl, string path) returns string|ClientError = @java:Method {
    'class: "io.ballerina.stdlib.http.uri.nativeimpl.Resolve",
    name: "resolve"
} external;

//Returns a random UUID string.
isolated function nativeUuid() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;

// Non-blocking payload retrieval common external isolated functions
isolated function externGetJson(mime:Entity entity) returns json|mime:ParserError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHttpDataSourceBuilder",
    name: "getNonBlockingJson"
} external;

isolated function externGetXml(mime:Entity entity) returns xml|mime:ParserError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHttpDataSourceBuilder",
    name: "getNonBlockingXml"
} external;

isolated function externGetText(mime:Entity entity) returns string|mime:ParserError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHttpDataSourceBuilder",
    name: "getNonBlockingText"
} external;

isolated function externGetByteArray(mime:Entity entity) returns byte[]|mime:ParserError = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHttpDataSourceBuilder",
    name: "getNonBlockingByteArray"
} external;

isolated function externGetByteChannel(mime:Entity entity) returns io:ReadableByteChannel|mime:ParserError =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHttpDataSourceBuilder",
    name: "getByteChannel"
} external;

isolated function externPopulateInputStream(mime:Entity entity) = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternHttpDataSourceBuilder",
    name: "populateInputStream"
} external;

// Returns utc value from a given string and pattern.
isolated function utcFromString(string input, string pattern) returns time:Utc|error = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternFormatter"
} external;

// Returns the formatted string from a given utc value and pattern.
isolated function utcToString(time:Utc utc, string pattern) returns string|error = @java:Method {
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternFormatter"
} external;

// Overrides the Entity object content-type by newContentType. If `newContentType` is not provided and
// `existingContentType` is not set, then the content-type will be set to default : `application/json`
isolated function setJson(mime:Entity entity, json payload, string existingContentType, string? newContentType) {
    if newContentType is string {
        entity.setJson(payload, newContentType);
    } else {
        if existingContentType == "" {
            entity.setJson(payload);
        } else {
            entity.setJson(payload, existingContentType);
        }
    }
}

// Overrides the Entity object content-type by newContentType. If `newContentType` is not provided and
// `existingContentType` is not set, then the content-type will be set to default : `application/xml`
isolated function setXml(mime:Entity entity, xml payload, string existingContentType, string? newContentType) {
    if newContentType is string {
        entity.setXml(payload, newContentType);
    } else {
        if existingContentType == "" {
            entity.setXml(payload);
        } else {
            entity.setXml(payload, existingContentType);
        }
    }
}

// Overrides the Entity object content-type by newContentType. If `newContentType` is not provided and
// `existingContentType` is not set, then the content-type will be set to default : `text/plain`
isolated function setText(mime:Entity entity, string payload, string existingContentType, string? newContentType) {
    if newContentType is string {
        entity.setText(payload, newContentType);
    } else {
        if existingContentType == "" {
            entity.setText(payload);
        } else {
            entity.setText(payload, existingContentType);
        }
    }
}

// Overrides the Entity object content-type by newContentType. If `newContentType` is not provided and
// `existingContentType` is not set, then the content-type will be set to default : `application/octet-stream`
isolated function setByteArray(mime:Entity entity, byte[] payload, string existingContentType, string? newContentType) {
    if newContentType is string {
        entity.setByteArray(payload, newContentType);
    } else {
        if existingContentType == "" {
            entity.setByteArray(payload);
        } else {
            entity.setByteArray(payload, existingContentType);
        }
    }
}

// Overrides the Entity object content-type by newContentType. If `newContentType` is not provided and
// `existingContentType` is not set, then the content-type will be set to default : `multipart/form-data`
isolated function setBodyParts(mime:Entity entity, mime:Entity[] bodyParts, string existingContentType,
        string? newContentType) {
    if newContentType is string {
        entity.setBodyParts(bodyParts, newContentType);
    } else {
        if existingContentType == "" {
            entity.setBodyParts(bodyParts);
        } else {
            entity.setBodyParts(bodyParts, existingContentType);
        }
    }
}

// Overrides the Entity object content-type by newContentType. If `newContentType` is not provided and
// `existingContentType` is not set, then the content-type will be set to default : `application/octet-stream`
isolated function setFile(mime:Entity entity, string filePath, string existingContentType, string? newContentType) {
    if newContentType is string {
        entity.setFileAsEntityBody(filePath, newContentType);
    } else {
        if existingContentType == "" {
            entity.setFileAsEntityBody(filePath);
        } else {
            entity.setFileAsEntityBody(filePath, existingContentType);
        }
    }
}

// Overrides the Entity object content-type by newContentType. If `newContentType` is not provided and
// `existingContentType` is not set, then the content-type will be set to default : `application/octet-stream`
isolated function setByteStream(mime:Entity entity, stream<byte[], io:Error?> byteStream, string existingContentType,
        string? newContentType) {
    if newContentType is string {
        entity.setByteStream(byteStream, newContentType);
    } else {
        if existingContentType == "" {
            entity.setByteStream(byteStream);
        } else {
            entity.setByteStream(byteStream, existingContentType);
        }
    }
}

isolated function getFormDataMap(string formData) returns map<string>|ClientError {
    map<string> parameters = {};
    if formData == "" {
        return parameters;
    }
    var decodedValue = decode(formData);
    if decodedValue is error {
        return error ClientError("form data decode failure");
    }
    if strings:indexOf(decodedValue, "=") is () {
        return error ClientError("Datasource does not contain form data");
    }
    string[] entries = re`&`.split(decodedValue);
    foreach string entry in entries {
        int? index = entry.indexOf("=");
        if index is int && index != -1 {
            string name = entry.substring(0, index);
            name = name.trim();
            string value = entry.substring(index + 1);
            value = value.trim();
            parameters[name] = value;
        }
    }
    return parameters;
}

# Defines the path parameter types.
public type PathParamType boolean|int|float|decimal|string;

# Defines the possible simple query parameter types.
public type SimpleQueryParamType boolean|int|float|decimal|string;

# Defines the query parameter type supported with client resource methods.
public type QueryParamType SimpleQueryParamType[]|SimpleQueryParamType;

# Defines the record type of query parameters supported with client resource methods.
# + headers - headers which cannot be used as a query field
# + targetType - targetType which cannot be used as a query field
# + message - message which cannot be used as a query field
# + mediaType - mediaType which cannot be used as a query field
public type QueryParams record {|
    never headers?;
    never targetType?;
    never message?;
    never mediaType?;
    QueryParamType...;
|};
