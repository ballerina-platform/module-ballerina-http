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

import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.Map;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.updateDiagnostic;

/**
 * Validates a ballerina http interceptor resource.
 */
public final class HttpInterceptorResourceValidator {
    private HttpInterceptorResourceValidator() {}

    public static void validateResource(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member, String type,
                                        Map<String, TypeSymbol> typeSymbols) {
        checkResourceAnnotation(ctx, member);
        if (isRequestErrorInterceptor(type)) {
            extractAndValidateMethodAndPath(ctx, member);
        }
        HttpResourceValidator.extractInputParamTypeAndValidate(ctx, member, isRequestErrorInterceptor(type),
                typeSymbols);
        HttpCompilerPluginUtil.extractInterceptorReturnTypeAndValidate(ctx, typeSymbols, member,
                HttpDiagnostic.HTTP_126);
    }

    private static boolean isRequestErrorInterceptor(String type) {
        return type.equals(Constants.REQUEST_ERROR_INTERCEPTOR);
    }

    private static void extractAndValidateMethodAndPath(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member) {
        NodeList<Node> path = member.relativeResourcePath();
        String resourcePath = path.get(0).toString().strip();
        if (!resourcePath.matches(Constants.DEFAULT_PATH_REGEX)) {
            reportInvalidResourcePath(ctx, path.get(0));
        }
        String method = member.functionName().toString().strip();
        if (!method.contains(Constants.DEFAULT)) {
            reportInvalidResourceMethod(ctx, member.functionName());
        }
    }

    private static void checkResourceAnnotation(SyntaxNodeAnalysisContext ctx,
                                                FunctionDefinitionNode member) {
        Optional<MetadataNode> metadataNodeOptional = member.metadata();
        if (metadataNodeOptional.isPresent()) {
            NodeList<AnnotationNode> annotations = metadataNodeOptional.get().annotations();
            if (!annotations.isEmpty()) {
                reportResourceAnnotationNotAllowed(ctx, annotations.get(0));
            }
        }
    }

    private static void reportResourceAnnotationNotAllowed(SyntaxNodeAnalysisContext ctx, AnnotationNode node) {
        updateDiagnostic(ctx, node.location(), HttpDiagnostic.HTTP_125,
                                                node.annotReference().toString());
    }

    private static void reportInvalidResourcePath(SyntaxNodeAnalysisContext ctx, Node node) {
        updateDiagnostic(ctx, node.location(), HttpDiagnostic.HTTP_127, node.toString());
    }

    private static void reportInvalidResourceMethod(SyntaxNodeAnalysisContext ctx, IdentifierToken identifierToken) {
        updateDiagnostic(ctx, identifierToken.location(), HttpDiagnostic.HTTP_128,
                                                identifierToken.toString().strip());
    }
}
