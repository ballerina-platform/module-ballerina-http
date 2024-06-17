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

import static io.ballerina.stdlib.http.compiler.Constants.ALLOWED_INTERCEPTOR_RETURN_UNION;
import static io.ballerina.stdlib.http.compiler.Constants.ALLOWED_RETURN_UNION;
import static io.ballerina.tools.diagnostics.DiagnosticSeverity.ERROR;
import static io.ballerina.tools.diagnostics.DiagnosticSeverity.INTERNAL;

/**
 * {@code DiagnosticCodes} is used to hold diagnostic codes.
 */
public enum HttpDiagnosticCodes {
    HTTP_101("HTTP_101", "remote methods are not allowed in http:Service", ERROR),
    HTTP_102("HTTP_102", "invalid resource method return type: expected '" + ALLOWED_RETURN_UNION +
            "', but found '%s'", ERROR),
    HTTP_104("HTTP_104", "invalid annotation type on param '%s': expected one of the following types: " +
            "'http:Payload', 'http:CallerInfo', 'http:Header', 'http:Query'", ERROR),
    HTTP_105("HTTP_105", "invalid resource parameter '%s'", ERROR),
    HTTP_106("HTTP_106", "invalid resource parameter type: '%s'", ERROR),
    HTTP_107("HTTP_107", "invalid payload parameter type: '%s'", ERROR),
    HTTP_108("HTTP_108", "invalid multiple resource parameter annotations for '%s': expected one of the following" +
            " types: 'http:Payload', 'http:CallerInfo', 'http:Header', 'http:Query'", ERROR),
    HTTP_109("HTTP_109", "invalid type of header param '%s': expected one of the following types is expected: " +
            "'string','int','float','decimal','boolean', an array of the above types or a record which consists of " +
            "the above types", ERROR),
    HTTP_110("HTTP_110", "invalid union type of header param '%s': expected one of the 'string','int','float'," +
            "'decimal','boolean' types, an array of the above types or a record which consists of the above types can" +
            " only be union with '()'. Eg: string|() or string[]|()", ERROR),
    HTTP_111("HTTP_111", "invalid type of caller param '%s': expected 'http:Caller'", ERROR),
    HTTP_112("HTTP_112", "invalid type of query param '%s': expected one of the 'string', 'int', 'float', " +
            "'boolean', 'decimal', 'map<anydata>' types or the array types of them", ERROR),
    HTTP_113("HTTP_113", "invalid union type of query param '%s': 'string', 'int', 'float', 'boolean', " +
            "'decimal', 'map<anydata>' type or the array types of them can only be union with '()'. Eg: string?" +
            " or int[]?", ERROR),
    HTTP_114("HTTP_114", "incompatible respond method argument type : expected '%s' according " +
            "to the 'http:CallerInfo' annotation", ERROR),
    HTTP_115("HTTP_115", "invalid multiple 'http:Caller' parameter: '%s'", ERROR),
    HTTP_116("HTTP_116", "invalid multiple 'http:Request' parameter: '%s'", ERROR),
    HTTP_117("HTTP_117", "invalid multiple 'http:Headers' parameter: '%s'", ERROR),
    HTTP_118("HTTP_118", "invalid resource method return type: can not use 'http:Caller' " +
            "and return '%s' from a resource : expected 'error' or nil",
            ERROR),
    HTTP_119("HTTP_119", "invalid media-type subtype prefix: subtype prefix should not have suffix '%s'",
            ERROR),
    HTTP_120("HTTP_120", "invalid media-type subtype '%s'", ERROR),
    HTTP_121("HTTP_121", "invalid multiple 'http:RequestContext' parameter: '%s'", ERROR),
    HTTP_122("HTTP_122", "invalid multiple 'error' parameter: '%s'", ERROR),
    HTTP_123("HTTP_123", "invalid multiple interceptor type reference: '%s'", ERROR),
    HTTP_124("HTTP_124", "invalid multiple interceptor resource functions", ERROR),
    HTTP_125("HTTP_125", "invalid annotation '%s': annotations are not supported for interceptor " +
            "resource functions", ERROR),
    HTTP_126("HTTP_126", "invalid interceptor resource method return type: expected '" +
              ALLOWED_INTERCEPTOR_RETURN_UNION + "', but found '%s'", ERROR),
    HTTP_127("HTTP_127", "invalid interceptor resource path: expected default resource path: " +
            "'[string... path]', but found '%s'", ERROR),
    HTTP_128("HTTP_128", "invalid interceptor resource method: expected default resource method: " +
            "'default', but found '%s'", ERROR),
    HTTP_129("HTTP_129", "invalid usage of payload annotation for a non entity body resource : '%s'. " +
            "Use an accessor that supports entity body", ERROR),
    HTTP_130("HTTP_130", "invalid usage of cache annotation with return type : '%s'. " +
            "Cache annotation only supports return types of anydata and SuccessStatusCodeResponse", ERROR),
    HTTP_131("HTTP_131", "invalid usage of payload annotation with return type : '%s'", ERROR),
    HTTP_132("HTTP_132", "%s must have a resource method", ERROR),
    HTTP_133("HTTP_133", "invalid intersection type : '%s'. Only readonly type is allowed", ERROR),
    HTTP_134("HTTP_134", "'readonly' intersection type is not allowed for parameter '%s' of the type '%s'", ERROR),
    HTTP_135("HTTP_135", "%s must have the remote method : '%s'", ERROR),
    HTTP_136("HTTP_136", "resource function is not allowed in %s", ERROR),
    HTTP_137("HTTP_137", "remote function is not allowed in %s", ERROR),
    HTTP_138("HTTP_138", "invalid remote function : '%s'. %s can have only '%s' remote " +
            "function", ERROR),
    HTTP_139("HTTP_139", "invalid multiple 'http:Response' parameter: '%s'", ERROR),
    HTTP_140("HTTP_140", "invalid parameter type: '%s' in '%s' remote method", ERROR),
    HTTP_141("HTTP_141", "invalid interceptor remote method return type: expected '" +
            ALLOWED_INTERCEPTOR_RETURN_UNION + "', but found '%s'", ERROR),
    HTTP_142("HTTP_142", "return type annotation is not supported in interceptor service", ERROR),
    HTTP_143("HTTP_143", "%s function should have the mandatory parameter 'error'", ERROR),
    HTTP_144("HTTP_144", "rest fields are not allowed for header binding records. Use 'http:Headers' type to access " +
            "all headers", ERROR),
    HTTP_145("HTTP_145", "invalid resource path parameter '%s': expected one of the 'string','int','float'," +
            "'decimal','boolean' types or a rest parameter with one of the above types", ERROR),
    HTTP_146("HTTP_146", "resource link name: '%s' conflicts with the path. Resource names can be reused only when " +
            "the resources have the same path", ERROR),
    HTTP_147("HTTP_147", "duplicate link relation: '%s'. Resource only supports unique relations" , ERROR),
    HTTP_148("HTTP_148", "cannot find resource with resource link name: '%s'" , ERROR),
    HTTP_149("HTTP_149", "cannot resolve linked resource without method" , ERROR),
    HTTP_150("HTTP_150", "cannot find '%s' resource with resource link name: '%s'" , ERROR),

    HTTP_151("HTTP_151", "ambiguous types for parameter '%s' and '%s'. Use annotations to avoid ambiguity", ERROR),
    HTTP_152("HTTP_152", "invalid union type for default payload param: '%s'. Use basic structured anydata types",
            ERROR),
    HTTP_153("HTTP_153", "'http:ServiceConfig' annotation is not allowed for service declaration implemented via the " +
            "'http:ServiceContract' type. The HTTP annotations are inferred from the service contract type", ERROR),
    HTTP_154("HTTP_154", "base path not allowed in the service declaration which is implemented via the " +
            "'http:ServiceContract' type. The base path is inferred from the service contract type", ERROR),
    HTTP_155("HTTP_155", "configuring base path in the 'http:ServiceConfig' annotation is not allowed for non service" +
            " contract types", ERROR),
    HTTP_156("HTTP_156", "invalid service type descriptor found in 'http:ServiceConfig' annotation. " +
            "Expected service type: '%s' but found: '%s'", ERROR),
    HTTP_157("HTTP_157", "'serviceType' is not allowed in the service which is not implemented " +
            "via the 'http:ServiceContract' type", ERROR),
    HTTP_158("HTTP_158", "resource function which is not defined in the service contract type: '%s'," +
            " is not allowed", ERROR),
    HTTP_159("HTTP_159", "'http:ResourceConfig' annotation is not allowed for resource function implemented via the " +
            "'http:ServiceContract' type. The HTTP annotations are inferred from the service contract type", ERROR),
    HTTP_160("HTTP_160", "'%s' annotation is not allowed for resource function implemented via the " +
            "'http:ServiceContract' type. The HTTP annotations are inferred from the service contract type", ERROR),

    HTTP_HINT_101("HTTP_HINT_101", "Payload annotation can be added", INTERNAL),
    HTTP_HINT_102("HTTP_HINT_102", "Header annotation can be added", INTERNAL),
    HTTP_HINT_103("HTTP_HINT_103", "Response content-type can be added", INTERNAL),
    HTTP_HINT_104("HTTP_HINT_104", "Response cache configuration can be added", INTERNAL),
    HTTP_HINT_105("HTTP_HINT_105", "Service contract: '%s', can be implemented", INTERNAL);

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
