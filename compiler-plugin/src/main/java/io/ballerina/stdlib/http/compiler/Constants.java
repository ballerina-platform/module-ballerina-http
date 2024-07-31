/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.compiler;

/**
 * Constants related to compiler plugin implementation.
 */
public final class Constants {
    private Constants() {}

    public static final String BALLERINA = "ballerina";
    public static final String HTTP = "http";
    public static final String SERVICE_KEYWORD = "service";
    public static final String REMOTE_KEYWORD = "remote";
    public static final String RESOURCE_KEYWORD = "resource";
    public static final String RESPONSE_OBJ_NAME = "Response";
    public static final String ANYDATA = "anydata";
    public static final String JSON = "json";
    public static final String ERROR = "error";
    public static final String STRING = "string";
    public static final String STRING_ARRAY = "string[]";
    public static final String INT = "int";
    public static final String INT_ARRAY = "int[]";
    public static final String FLOAT = "float";
    public static final String FLOAT_ARRAY = "float[]";
    public static final String DECIMAL = "decimal";
    public static final String DECIMAL_ARRAY = "decimal[]";
    public static final String BOOLEAN = "boolean";
    public static final String BOOLEAN_ARRAY = "boolean[]";
    public static final String ARRAY_OF_MAP_OF_ANYDATA = "map<anydata>[]";
    public static final String NIL = "nil";
    public static final String BYTE_ARRAY = "byte[]";
    public static final String XML = "xml";
    public static final String MAP_OF_ANYDATA = "map<anydata>";
    public static final String TABLE_OF_ANYDATA_MAP = "table<anydata>";
    public static final String TUPLE_OF_ANYDATA = "[anydata...]";
    public static final String STRUCTURED_ARRAY = "(map<anydata>|table<map<anydata>>|[anydata...])[]";
    public static final String NILABLE_STRING = "string?";
    public static final String NILABLE_INT = "int?";
    public static final String NILABLE_FLOAT = "float?";
    public static final String NILABLE_DECIMAL = "decimal?";
    public static final String NILABLE_BOOLEAN = "boolean?";
    public static final String NILABLE_MAP_OF_ANYDATA = "map<anydata>?";
    public static final String NILABLE_STRING_ARRAY = "string[]?";
    public static final String NILABLE_INT_ARRAY = "int[]?";
    public static final String NILABLE_FLOAT_ARRAY = "float[]?";
    public static final String NILABLE_DECIMAL_ARRAY = "decimal[]?";
    public static final String NILABLE_BOOLEAN_ARRAY = "boolean[]?";
    public static final String NILABLE_MAP_OF_ANYDATA_ARRAY = "map<anydata>[]?";

    public static final String RESOURCE_RETURN_TYPE = "ResourceReturnType";
    public static final String INTERCEPTOR_RESOURCE_RETURN_TYPE = "InterceptorResourceReturnType";
    public static final String CALLER_OBJ_NAME = "Caller";
    public static final String REQUEST_OBJ_NAME = "Request";
    public static final String REQUEST_CONTEXT_OBJ_NAME = "RequestContext";
    public static final String OBJECT = "object";
    public static final String HEADER_OBJ_NAME = "Headers";
    public static final String PAYLOAD_ANNOTATION = "Payload";
    public static final String CACHE_ANNOTATION = "Cache";
    public static final String SERVICE_CONFIG_ANNOTATION = "ServiceConfig";
    public static final String MEDIA_TYPE_SUBTYPE_PREFIX = "mediaTypeSubtypePrefix";
    public static final String INTERCEPTABLE_SERVICE = "InterceptableService";
    public static final String RESOURCE_CONFIG_ANNOTATION = "ResourceConfig";
    public static final String PAYLOAD_ANNOTATION_TYPE = "HttpPayload";
    public static final String CALLER_ANNOTATION_TYPE = "HttpCallerInfo";
    public static final String HEADER_ANNOTATION_TYPE = "HttpHeader";
    public static final String QUERY_ANNOTATION_TYPE = "HttpQuery";
    public static final String CALLER_ANNOTATION_NAME = "CallerInfo";
    public static final String FIELD_RESPONSE_TYPE = "respondType";
    public static final String RESPOND_METHOD_NAME = "respond";
    public static final String ALLOWED_RETURN_UNION = "anydata|http:Response|http:StatusCodeResponse|" +
            "stream<http:SseEvent, error?>|stream<http:SseEvent, error>|error";
    public static final String REQUEST_INTERCEPTOR = "RequestInterceptor";
    public static final String RESPONSE_INTERCEPTOR = "ResponseInterceptor";
    public static final String REQUEST_ERROR_INTERCEPTOR = "RequestErrorInterceptor";
    public static final String RESPONSE_ERROR_INTERCEPTOR = "ResponseErrorInterceptor";
    public static final String HTTP_SERVICE = "http:Service";
    public static final String HTTP_REQUEST_INTERCEPTOR = "http:RequestInterceptor";
    public static final String HTTP_REQUEST_ERROR_INTERCEPTOR = "http:RequestErrorInterceptor";
    public static final String HTTP_RESPONSE_INTERCEPTOR = "http:ResponseInterceptor";
    public static final String HTTP_RESPONSE_ERROR_INTERCEPTOR = "http:ResponseErrorInterceptor";
    public static final String ALLOWED_INTERCEPTOR_RETURN_UNION = "anydata|http:Response|http:StatusCodeResponse|" +
                                                                  "http:NextService|error?";
    public static final String DEFAULT = "default";
    public static final String GET = "get";
    public static final String HEAD = "head";
    public static final String OPTIONS = "options";
    public static final String INTERCEPT_RESPONSE = "interceptResponse";
    public static final String INTERCEPT_RESPONSE_ERROR = "interceptResponseError";
    public static final String NAME = "name";
    public static final String LINKED_TO = "linkedTo";
    public static final String METHOD = "method";
    public static final String RELATION = "relation";
    public static final String PARAM = "$param$";
    public static final String SELF = "self";

    public static final String EMPTY = "";
    public static final String COLON = ":";
    public static final String PLUS = "+";
    public static final String SPACE = " ";
    public static final String COMMA_WITH_SPACE = ", ";
    public static final String DEFAULT_PATH_REGEX = "\\[\\s*(string)\\s*(\\.{3})\\s*\\w+\\s*\\]";
    public static final String SUFFIX_SEPARATOR_REGEX = "\\+";
    public static final String MEDIA_TYPE_SUBTYPE_REGEX = "^(\\w)+(\\s*\\.\\s*(\\w)+)*(\\s*\\+\\s*(\\w)+)*";
    public static final String UNNECESSARY_CHARS_REGEX = "^'|\"|\\n";
}
