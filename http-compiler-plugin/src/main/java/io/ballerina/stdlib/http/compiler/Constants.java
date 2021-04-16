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

import io.ballerina.compiler.api.symbols.ArrayTypeSymbol;
import io.ballerina.compiler.api.symbols.FunctionSymbol;
import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;

import java.util.List;
import java.util.Optional;

import static io.ballerina.tools.diagnostics.DiagnosticSeverity.ERROR;

/**
 * Constants related to compiler plugin implementation.
 */
public class Constants {

    public static final String HTTP_101 = "HTTP_101";
    public static final String HTTP_102 = "HTTP_102";
    public static final String HTTP_103 = "HTTP_103";
    public static final String HTTP_104 = "HTTP_104";
    public static final String HTTP_105 = "HTTP_105";
    public static final String HTTP_106 = "HTTP_106";

    public static final String HTTP = "http";
    public static final String REMOTE_KEYWORD = "remote";
    public static final String RESPONSE_OBJ_NAME = "Response";
    public static final String CALLER_OBJ_NAME = "Caller";
    public static final String REQUEST_OBJ_NAME = "Request";
    public static final String HEADER_OBJ_NAME = "Headers";
    public static final String RESOURCE_CONFIG_ANNOTATION = "ResourceConfig";
    public static final String PAYLOAD_ANNOTATION_TYPE = "HttpPayload";
    public static final String CALLER_ANNOTATION_TYPE = "HttpCallerInfo";
    public static final String HEADER_ANNOTATION_TYPE = "HttpHeader";
    public static final String ALLOWED_RETURN_UNION = "anydata|http:Response|http:StatusCodeRecord|error";
    public static final String REMOTE_METHODS_NOT_ALLOWED = "`remote` methods are not allowed in http:Service";
}
