/*
 * Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.compiler;

import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import static io.ballerina.stdlib.http.compiler.Constants.ALLOWED_RETURN_UNION;
import static io.ballerina.stdlib.http.compiler.Constants.RESOURCE_CONFIG_ANNOTATION;
import static io.ballerina.tools.diagnostics.DiagnosticSeverity.ERROR;

/**
 * {@code DiagnosticCodes} is used to hold diagnostic codes.
 */
public enum HttpDiagnosticCodes {
    HTTP_101("HTTP_101", "remote methods are not allowed in http:Service", ERROR),
    HTTP_102("HTTP_102", "invalid resource method return type: expected '" + ALLOWED_RETURN_UNION +
            "', but found '%s'", ERROR),
    HTTP_103("HTTP_103", "invalid resource method annotation type: expected 'http:" + RESOURCE_CONFIG_ANNOTATION +
            "', but found '%s'", ERROR),
    HTTP_104("HTTP_104", "invalid annotation type on param '%s': expected one of the following types: " +
            "'http:Payload', 'http:CallerInfo', 'http:Headers'", ERROR),
    HTTP_105("HTTP_105", "invalid resource parameter '%s'", ERROR),
    HTTP_106("HTTP_106", "invalid resource parameter type: '%s'", ERROR),
    HTTP_107("HTTP_107", "invalid payload parameter type: '%s'", ERROR),
    HTTP_108("HTTP_108", "invalid multiple resource parameter annotations for '%s'" +
            ": expected one of the following types: 'http:Payload', 'http:CallerInfo', 'http:Headers'", ERROR),
    HTTP_109("HTTP_109", "invalid type of header param '%s': expected 'string' or 'string[]'", ERROR),
    HTTP_110("HTTP_110", "invalid union type of header param '%s': a string or an array of a string can " +
            "only be union with '()'. Eg: string|() or string[]|()", ERROR),
    HTTP_111("HTTP_111", "invalid type of caller param '%s': expected 'http:Caller'", ERROR),
    HTTP_112("HTTP_112", "invalid type of query param '%s': expected one of the 'string', 'int', 'float', " +
            "'boolean', 'decimal' types or the array types of them", ERROR),
    HTTP_113("HTTP_113", "invalid union type of query param '%s': 'string', 'int', 'float', 'boolean', " +
            "'decimal' type or the array types of them can only be union with '()'. Eg: string? or int[]?", ERROR),
    HTTP_114("HTTP_114", "incompatible respond method argument type : expected '%s' according " +
            "to the 'http:CallerInfo' annotation", ERROR),
    HTTP_115("HTTP_115", "invalid multiple 'http:Caller' parameter: '%s'", ERROR),
    HTTP_116("HTTP_116", "invalid multiple 'http:Request' parameter: '%s'", ERROR),
    HTTP_117("HTTP_117", "invalid multiple 'http:Headers' parameter: '%s'", ERROR),
    HTTP_118("HTTP_118", "invalid resource method return type: can not use 'http:Caller' " +
            "and return '%s' from a resource : expected 'error' or nil",
            ERROR);

    private final String code;
    private final String message;
    private final DiagnosticSeverity severity;

    HttpDiagnosticCodes(String code, String message, DiagnosticSeverity severity) {
        this.code = code;
        this.message = message;
        this.severity = severity;
    }

    public String getCode() {
        return code;
    }

    public String getMessage() {
        return message;
    }

    public DiagnosticSeverity getSeverity() {
        return severity;
    }
}
