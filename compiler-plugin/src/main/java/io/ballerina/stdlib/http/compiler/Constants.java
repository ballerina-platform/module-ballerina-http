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
public class Constants {
    public static final String BALLERINA = "ballerina";
    public static final String HTTP = "http";
    public static final String REMOTE_KEYWORD = "remote";
    public static final String RESPONSE_OBJ_NAME = "Response";
    public static final String CALLER_OBJ_NAME = "Caller";
    public static final String REQUEST_OBJ_NAME = "Request";
    public static final String HEADER_OBJ_NAME = "Headers";
    public static final String SERVICE_CONFIG_ANNOTATION = "ServiceConfig";
    public static final String MEDIA_TYPE_SUBTYPE_PREFIX = "mediaTypeSubtypePrefix";
    public static final String RESOURCE_CONFIG_ANNOTATION = "ResourceConfig";
    public static final String PAYLOAD_ANNOTATION_TYPE = "HttpPayload";
    public static final String CALLER_ANNOTATION_TYPE = "HttpCallerInfo";
    public static final String HEADER_ANNOTATION_TYPE = "HttpHeader";
    public static final String CALLER_ANNOTATION_NAME = "CallerInfo";
    public static final String FIELD_RESPONSE_TYPE = "respondType";
    public static final String RESPOND_METHOD_NAME = "respond";
    public static final String ERROR = "annotations:error";
    public static final String ALLOWED_RETURN_UNION = "anydata|http:Response|http:StatusCodeRecord|error";
}
