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

import ballerina/constraint;
import ballerina/data.jsondata;
import ballerina/jballerina.java;
import ballerina/log;

type nilType typedesc<()>;
type xmlType typedesc<xml>;
type stringType typedesc<string>;
type byteArrType typedesc<byte[]>;
type mapStringType typedesc<map<string>>;

isolated function performDataBinding(Response response, TargetType targetType) returns anydata|ClientError {
    string contentType = response.getContentType().trim();
    if contentType == "" {
        return getBuilderFromType(response, targetType);
    }
    if XML_PATTERN.isFullMatch(contentType) {
        return xmlPayloadBuilder(response, targetType);
    } else if TEXT_PATTERN.isFullMatch(contentType) {
        return textPayloadBuilder(response, targetType);
    } else if URL_ENCODED_PATTERN.isFullMatch(contentType) {
        return formPayloadBuilder(response, targetType);
    } else if OCTET_STREAM_PATTERN.isFullMatch(contentType) {
        return blobPayloadBuilder(response, targetType);
    } else if JSON_PATTERN.isFullMatch(contentType) {
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
        // Due to the limitation of https://github.com/ballerina-platform/ballerina-spec/issues/1090
        // all the other types including union are considered as json subtypes.
        return jsonPayloadBuilder(response, targetType);
    }
}

isolated function xmlPayloadBuilder(Response response, TargetType targetType) returns xml|ClientError? {
    if targetType is typedesc<xml> {
        return response.getXmlPayload();
    } else if matchingType(targetType, xmlType) {
        xml|ClientError payload = response.getXmlPayload();
        return payload is NoContentError ? (matchingType(targetType, nilType) ? () : payload) : payload;
    } else {
        return getCommonError(response, targetType);
    }
}

isolated function textPayloadBuilder(Response response, TargetType targetType) returns string|byte[]|ClientError? {
    if targetType is typedesc<string> {
        return response.getTextPayload();
    } else if matchingType(targetType, string) {
        string|ClientError payload = response.getTextPayload();
        return payload is NoContentError ? (matchingType(targetType, nilType) ? () : payload) : payload;
    } else if targetType is typedesc<byte[]> {
        return response.getBinaryPayload();
    } else if matchingType(targetType, byteArrType) {
        string|ClientError payload = response.getTextPayload();
        if payload is string {
            return payload.toBytes();
        } else if payload is NoContentError {
            return matchingType(targetType, nilType) ? () : payload;
        }
        return payload;
    } else {
        return getCommonError(response, targetType);
    }
}

isolated function formPayloadBuilder(Response response, TargetType targetType) returns map<string>|string|ClientError? {
    if targetType is typedesc<map<string>> {
        string payload = check response.getTextPayload();
        return getFormDataMap(payload);
    } else if matchingType(targetType, mapStringType) {
        string|ClientError payload = response.getTextPayload();
        return payload is NoContentError ? (matchingType(targetType, nilType) ? () : payload) :
            getFormDataMap(check payload);
    } else if targetType is typedesc<string> {
        return response.getTextPayload();
    } else if matchingType(targetType, stringType) {
        string|ClientError payload = response.getTextPayload();
        return payload is NoContentError ? (matchingType(targetType, nilType) ? () : payload) : payload;
    } else {
        return getCommonError(response, targetType);
    }
}

isolated function blobPayloadBuilder(Response response, TargetType targetType) returns byte[]|ClientError? {
    if targetType is typedesc<byte[]> {
        return response.getBinaryPayload();
    } else if matchingType(targetType, byteArrType) {
        byte[]|ClientError payload = response.getBinaryPayload();
        if payload is byte[] && payload.length() == 0 {
            return matchingType(targetType, nilType) ? () : payload;
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
    var result = jsondata:parseAsType(payload, {enableConstraintValidation: false, allowDataProjection: false}, targetType);
    return result is error ? createPayloadBindingError(result) : result;
}

isolated function nilablejsonPayloadBuilder(Response response, typedesc<anydata> targetType)
        returns anydata|ClientError {
    json|ClientError payload = response.getJsonPayload();
    if payload is json {
        var result = jsondata:parseAsType(payload, {enableConstraintValidation: false, allowDataProjection: false}, targetType);
        return result is error ? createPayloadBindingError(result) : result;
    } else {
        return payload is NoContentError ? () : payload;
    }
}

isolated function createPayloadBindingError(error result) returns PayloadBindingClientError {
    string errPrefix = "Payload binding failed: ";
    var errMsg = result.detail()["message"];
    if errMsg is string {
        return error PayloadBindingClientError(errPrefix + errMsg, result);
    }
    return error PayloadBindingClientError(errPrefix + result.message(), result);
}

isolated function getCommonError(Response response, TargetType targetType) returns PayloadBindingClientError {
    string contentType = response.getContentType();
    string mimeType = contentType == "" ? "no" : "'" + contentType + "'";
    return error PayloadBindingClientError("incompatible " + targetType.toString() + " found for " + mimeType + " mime type");
}

isolated function performDataValidation(anydata payload, typedesc<anydata> targetType) returns anydata|ClientError {
    anydata|error validationResult = constraint:validate(payload, targetType);
    if validationResult is error {
        return error PayloadValidationClientError("payload validation failed: " + validationResult.message(), validationResult);
    }
    return payload;
}

isolated function matchingType(typedesc unionType, any targetType) returns boolean = @java:Method {
    'class: "io.ballerina.stdlib.http.api.service.signature.builder.AbstractPayloadBuilder"
} external;
