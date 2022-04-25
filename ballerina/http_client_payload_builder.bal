// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/log;
import ballerina/io;
import ballerina/regex;

isolated function performDataBinding(Response response, TargetType targetType) returns anydata|ClientError {
    string contentType = response.getContentType();
    if contentType == "" {
        return getBuilderFromType(response, targetType);
    }
    if regex:matches(contentType, XML_PATTERN) {
        return xmlPayloadBuilder(response, targetType);
    } else if regex:matches(contentType, TEXT_PATTERN) {
        return textPayloadBuilder(response, targetType);
    } else if regex:matches(contentType, URL_ENCODED_PATTERN) {
        return formPayloadBuilder(response, targetType);
    } else if regex:matches(contentType, OCTET_STREAM_PATTERN) {
        return blobPayloadBuilder(response, targetType);
    } else if regex:matches(contentType, JSON_PATTERN) {
        return jsonPayloadBuilder(response, targetType);
    } else {
        return getBuilderFromType(response, targetType);
    }
}

isolated function getBuilderFromType(Response response, TargetType targetType) returns anydata|ClientError {
    if targetType is typedesc<string> {
        return response.getTextPayload();
    } else if targetType is typedesc<string?> {
        string|ClientError payload = response.getTextPayload();
        return payload is NoContentError ? () : payload;
    } else if targetType is typedesc<xml> {
        return response.getXmlPayload();
    } else if targetType is typedesc<xml?> {
        xml|ClientError payload = response.getXmlPayload();
        return payload is NoContentError ? () : payload;
    } else if targetType is typedesc<byte[]> {
        return response.getBinaryPayload();
    } else if targetType is typedesc<byte[]?> {
        byte[]|ClientError payload = response.getBinaryPayload();
        if payload is byte[] {
            return payload.length() == 0 ? () : payload;
        }
        return payload;
    } else {
        return jsonPayloadBuilder(response, targetType);
    }
}

isolated function xmlPayloadBuilder(Response response, TargetType targetType) returns xml|ClientError? {
    if targetType is typedesc<xml> {
        return response.getXmlPayload();
    } else if targetType is typedesc<xml?> {
        xml|ClientError payload = response.getXmlPayload();
        return payload is NoContentError ? () : payload;
    } else {
         return getCommonError(response, targetType);
    }
}

isolated function textPayloadBuilder(Response response, TargetType targetType) returns string|byte[]|ClientError? {
    if targetType is typedesc<string> {
        return response.getTextPayload();
    } else if targetType is typedesc<string?> {
        string|ClientError payload = response.getTextPayload();
        return payload is NoContentError ? () : payload;
    } else if targetType is typedesc<byte[]> {
        return response.getBinaryPayload();
    } else if targetType is typedesc<byte[]?> {
        byte[]|ClientError payload = response.getBinaryPayload();
        return payload is NoContentError ? () : payload;
    } else {
         return getCommonError(response, targetType);
    }
}

isolated function formPayloadBuilder(Response response, TargetType targetType) returns map<string>|string|ClientError? {
    if targetType is typedesc<map<string>> {
        string payload = check response.getTextPayload();
        return getFormDataMap(payload);
    } else if targetType is typedesc<map<string>?> {
        string|ClientError payload = response.getTextPayload();
        if payload is error {
            if payload is NoContentError {
                return;
            }
            return payload;
        }
        return getFormDataMap(payload);
    } else if targetType is typedesc<string> {
        return response.getTextPayload();
    } else if targetType is typedesc<string?> {
        string|ClientError payload = response.getTextPayload();
        return payload is NoContentError ? () : payload;
    } else {
        return getCommonError(response, targetType);
    }
}

isolated function blobPayloadBuilder(Response response, TargetType targetType) returns byte[]|ClientError? {
    if targetType is typedesc<byte[]> {
        return response.getBinaryPayload();
    } else if targetType is typedesc<byte[]?> {
        byte[]|ClientError payload = response.getBinaryPayload();
        if payload is byte[] {
            return payload.length() == 0 ? () : payload;
        }
        return payload;
    } else {
        return getCommonError(response, targetType);
    }
}

isolated function jsonPayloadBuilder(Response response, TargetType targetType) returns anydata|ClientError {
    if targetType is typedesc<record {| anydata...; |}> {
        return nonNilablejsonPayloadBuilder(response, targetType);
    } else if targetType is typedesc<record {| anydata...; |}?> {
        return nilablejsonPayloadBuilder(response, targetType);
    } else if targetType is typedesc<record {| anydata...; |}[]> {
        return nonNilablejsonPayloadBuilder(response, targetType);
    } else if targetType is typedesc<record {| anydata...; |}[]?> {
        return nilablejsonPayloadBuilder(response, targetType);
    } else if targetType is typedesc<map<json>> {
        json payload = check response.getJsonPayload();
        return <map<json>> payload;
    } else if targetType is typedesc<anydata> {
        return nilablejsonPayloadBuilder(response, targetType);
    } else {
        // Consume payload to avoid memory leaks
        byte[]|ClientError payload = response.getBinaryPayload();
        if payload is error {
            log:printDebug("Error releasing payload during invalid target typed data binding: " + payload.message());
        }
        return error ClientError("invalid target type, expected: http:Response, anydata or a union of such a type with nil");
    }
}

isolated function nonNilablejsonPayloadBuilder(Response response, typedesc<anydata> targetType)
        returns anydata|ClientError {
    json payload = check response.getJsonPayload();
    var result = payload.fromJsonWithType(targetType);
    return result is error ? createPayloadBindingError(result) : result;
}

isolated function nilablejsonPayloadBuilder(Response response, typedesc<anydata> targetType)
        returns anydata|ClientError {
    json|ClientError payload = response.getJsonPayload();
    if payload is json {
        var result = payload.fromJsonWithType(targetType);
        return result is error ? createPayloadBindingError(result) : result;
    } else {
        return payload is NoContentError ? () : payload;
    }
}

isolated function createPayloadBindingError(error result) returns PayloadBindingError {
    string errPrefix = "Payload binding failed: ";
    var errMsg = result.detail()["message"];
    if errMsg is string {
        return error PayloadBindingError(errPrefix + errMsg, result);
    }
    return error PayloadBindingError(errPrefix + result.message(), result);
}

isolated function getCommonError(Response response, TargetType targetType) returns PayloadBindingError {
    string contentType = response.getContentType();
    string mimeType = contentType == "" ? "no" : "'" + contentType + "'";
    return error PayloadBindingError("incompatible " + targetType.toString() + " found for " + mimeType + " mime type");
}
