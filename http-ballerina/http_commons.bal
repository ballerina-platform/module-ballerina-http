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

final boolean observabilityEnabled = observe:isObservabilityEnabled();

//////////////////////////////
/// Native implementations ///
//////////////////////////////

# Parses the given header value to extract its value and parameter map.
#
# + headerValue - The header value
# + return - A tuple containing the value and its parameter map or else an `http:ClientError` if the header parsing fails
//TODO: Make the error nillable
public isolated function parseHeader(string headerValue) returns [string, map<any>]|ClientError = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ParseHeader",
    name: "parseHeader"
} external;

isolated function buildRequest(RequestMessage message) returns Request {
    Request request = new;
    if (message is ()) {
        request.noEntityBody = true;
        return request;
    } else if (message is Request) {
        request = message;
        request.noEntityBody = !request.checkEntityBodyAvailability();
    } else if (message is string) {
        request.setTextPayload(message);
    } else if (message is xml) {
        request.setXmlPayload(message);
    } else if (message is byte[]) {
        request.setBinaryPayload(message);
    } else if (message is stream<byte[], io:Error?>) {
        request.setByteStream(message);
    } else if (message is mime:Entity[]) {
        request.setBodyParts(message);
    } else if (message is json) {
        request.setJsonPayload(message);
    } else {
        var result = trap val:toJson(message);
        if (result is error) {
            panic error InitializingOutboundRequestError("json conversion error: " + result.message(), result);
        } else {
            request.setJsonPayload(result);
        }
    }
    return request;
}

isolated function buildResponse(ResponseMessage message) returns Response {
    Response response = new;
    if (message is ()) {
        return response;
    } else if (message is Response) {
        response = message;
    } else if (message is string) {
        response.setTextPayload(message);
    } else if (message is xml) {
        response.setXmlPayload(message);
    } else if (message is byte[]) {
        response.setBinaryPayload(message);
    } else if (message is stream<byte[], io:Error?>) {
        response.setByteStream(message);
    } else if (message is mime:Entity[]) {
        response.setBodyParts(message);
    } else if (message is json) {
        response.setJsonPayload(message);
    } else {
        var result = trap val:toJson(message);
        if (result is error) {
            panic error InitializingOutboundResponseError("json conversion error: " + result.message(), result);
        } else {
            response.setJsonPayload(result);
        }
    }
    return response;
}

isolated function populateOptions(Request request, string? mediaType, map<string|string[]>? headers) {
    // This method is called after setting the payload. Hence default content type header will be overriden.
    // Update content-type header according to the priority. (Highest to lowest)
    // 1. MediaType arg in client method
    // 2. Headers arg in client method
    // 3. Default content type related to payload
    populateHeaders(request, headers);
    if (mediaType is string) {
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
    if (headers is map<string[]>) {
        foreach var [headerKey, headerValues] in headers.entries() {
            foreach string headerValue in headerValues {
                request.addHeader(headerKey, headerValue);
            }
        }
    } else if (headers is map<string>) {
        foreach var [headerKey, headerValue] in headers.entries() {
            request.setHeader(headerKey, headerValue);
        }
    } else if (headers is map<string|string[]>) {
        foreach var [headerKey, headerValue] in headers.entries() {
            if (headerValue is string[]) {
                foreach string value in headerValue {
                    request.addHeader(headerKey, value);
                }
            } else {
                request.setHeader(headerKey, headerValue);
            }
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
public isolated function invokeEndpoint (string path, Request outRequest, HttpOperation requestAction, HttpClient httpClient,
        string verb = "") returns @tainted HttpResponse|ClientError {

    if (HTTP_GET == requestAction) {
        var result = httpClient->get(path, message = outRequest);
        return result;
    } else if (HTTP_POST == requestAction) {
        var result = httpClient->post(path, outRequest);
        return result;
    } else if (HTTP_OPTIONS == requestAction) {
        var result = httpClient->options(path, message = outRequest);
        return result;
    } else if (HTTP_PUT == requestAction) {
        var result = httpClient->put(path, outRequest);
        return result;
    } else if (HTTP_DELETE == requestAction) {
        var result = httpClient->delete(path, outRequest);
        return result;
    } else if (HTTP_PATCH == requestAction) {
        var result = httpClient->patch(path, outRequest);
        return result;
    } else if (HTTP_FORWARD == requestAction) {
        var result = httpClient->forward(path, outRequest);
        return result;
    } else if (HTTP_HEAD == requestAction) {
        var result = httpClient->head(path, message = outRequest);
        return result;
    } else if (HTTP_SUBMIT == requestAction) {
        return httpClient->submit(verb, path, outRequest);
    } else {
        return getError();
    }
}

// Extracts HttpOperation from the Http verb passed in.
isolated function extractHttpOperation (string httpVerb) returns HttpOperation {
    HttpOperation inferredConnectorAction = HTTP_NONE;
    if ("GET" == httpVerb) {
        inferredConnectorAction = HTTP_GET;
    } else if ("POST" == httpVerb) {
        inferredConnectorAction = HTTP_POST;
    } else if ("OPTIONS" == httpVerb) {
        inferredConnectorAction = HTTP_OPTIONS;
    } else if ("PUT" == httpVerb) {
        inferredConnectorAction = HTTP_PUT;
    } else if ("DELETE" == httpVerb) {
        inferredConnectorAction = HTTP_DELETE;
    } else if ("PATCH" == httpVerb) {
        inferredConnectorAction = HTTP_PATCH;
    } else if ("FORWARD" == httpVerb) {
        inferredConnectorAction = HTTP_FORWARD;
    } else if ("HEAD" == httpVerb) {
        inferredConnectorAction = HTTP_HEAD;
    } else if ("SUBMIT" == httpVerb) {
        inferredConnectorAction = HTTP_SUBMIT;
    }
    return inferredConnectorAction;
}

// Populate boolean index array by looking at the configured Http status codes to get better performance
// at runtime.
isolated function populateErrorCodeIndex (int[] errorCode) returns boolean[] {
    boolean[] result = [];
    foreach var i in errorCode {
        result[i] = true;
    }
    return result;
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
    if (isMultipartRequest(inRequest)) {
        mime:Entity[] bodyParts = check inRequest.getBodyParts();
        foreach var bodyPart in bodyParts {
            if (isNestedEntity(bodyPart)) {
                mime:Entity[]|error result = bodyPart.getBodyParts();

                if (result is error) {
                    return error GenericClientError(result.message(), result);
                }

                mime:Entity[] childParts = <mime:Entity[]> checkpanic result;

                foreach var childPart in childParts {
                    // When performing passthrough scenarios, message needs to be built before
                    // invoking the endpoint to create a message datasource.
                    byte[]|error childBlobContent = childPart.getByteArray();
                }
                bodyPart.setBodyParts(childParts, <@untainted> bodyPart.getContentType());
            } else {
                byte[]|error bodyPartBlobContent = bodyPart.getByteArray();
            }
        }
        inRequest.setBodyParts(bodyParts, <@untainted> inRequest.getContentType());
    }
    return inRequest;
}

isolated function isMultipartRequest(Request request) returns @tainted boolean {
    return request.hasHeader(mime:CONTENT_TYPE) &&
        request.getContentType().startsWith(MULTIPART_AS_PRIMARY_TYPE);
}

isolated function isNestedEntity(mime:Entity entity) returns @tainted boolean {
    return entity.hasHeader(mime:CONTENT_TYPE) &&
        entity.getContentType().startsWith(MULTIPART_AS_PRIMARY_TYPE);
}

isolated function createFailoverRequest(Request request, mime:Entity requestEntity) returns Request|ClientError {
    if (isMultipartRequest(request)) {
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

isolated function createErrorForNoPayload(mime:Error err) returns GenericClientError {
    string message = "No payload";
    return error GenericClientError(message, err);
}

isolated function getStatusCodeRange(string statusCode) returns string {
    return statusCode.substring(0, 1) + STATUS_CODE_GROUP_SUFFIX;
}

# Returns a random UUID string.
#
# + return - The random string
isolated function uuid() returns string {
    var result = java:toString(nativeUuid());
    if (result is string) {
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

    _ = checkpanic observe:addTagToMetrics(HTTP_URL, path);
    _ = checkpanic observe:addTagToMetrics(HTTP_METHOD, method);
    _ = checkpanic observe:addTagToMetrics(HTTP_BASE_URL, url);
    _ = checkpanic observe:addTagToMetrics(HTTP_STATUS_CODE_GROUP, getStatusCodeRange(statusCodeConverted));
}

//Resolve a given path against a given URI.
isolated function resolve(string baseUrl, string path) returns string|ClientError = @java:Method {
    'class: "org.ballerinalang.net.uri.nativeimpl.Resolve",
    name: "resolve"
} external;

//Returns a random UUID string.
isolated function nativeUuid() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;

// Non-blocking payload retrieval common external isolated functions
isolated function externGetJson(mime:Entity entity) returns @tainted json|mime:ParserError = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHttpDataSourceBuilder",
    name: "getNonBlockingJson"
} external;

isolated function externGetXml(mime:Entity entity) returns @tainted xml|mime:ParserError = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHttpDataSourceBuilder",
    name: "getNonBlockingXml"
} external;

isolated function externGetText(mime:Entity entity) returns @tainted string|mime:ParserError = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHttpDataSourceBuilder",
    name: "getNonBlockingText"
} external;

isolated function externGetByteArray(mime:Entity entity) returns @tainted byte[]|mime:ParserError = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHttpDataSourceBuilder",
    name: "getNonBlockingByteArray"
} external;

isolated function externGetByteChannel(mime:Entity entity) returns @tainted io:ReadableByteChannel|mime:ParserError =
@java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHttpDataSourceBuilder",
    name: "getByteChannel"
} external;

isolated function externPopulateInputStream(mime:Entity entity) = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternHttpDataSourceBuilder",
    name: "populateInputStream"
} external;

// Returns utc value from a given string and pattern.
isolated function utcFromString(string input, string pattern) returns time:Utc|error = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternFormatter"
} external;

// Returns the formatted string from a given utc value and pattern.
isolated function utcToString(time:Utc utc, string pattern) returns string|error = @java:Method {
    'class: "org.ballerinalang.net.http.nativeimpl.ExternFormatter"
} external;
