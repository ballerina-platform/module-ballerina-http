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

import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.compiler.syntax.tree.TypeReferenceNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.List;

/**
 * Validates a Ballerina Http Interceptor Service.
 */
public class HttpInterceptorServiceValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        List<Diagnostic> diagnostics = syntaxNodeAnalysisContext.semanticModel().diagnostics();
        for (Diagnostic diagnostic : diagnostics) {
            if (diagnostic.diagnosticInfo().severity() == DiagnosticSeverity.ERROR) {
                return;
            }
        }

        ClassDefinitionNode classDefinitionNode = (ClassDefinitionNode) syntaxNodeAnalysisContext.node();
        NodeList<Token>  tokens = classDefinitionNode.classTypeQualifiers();
        if (tokens.isEmpty()) {
            return;
        }
        if (!tokens.stream().allMatch(token -> token.text().equals(Constants.SERVICE_KEYWORD))) {
            return;
        }

        NodeList<Node> members = classDefinitionNode.members();
        validateInterceptorTypeAndProceed(syntaxNodeAnalysisContext, members);
    }

    private static void validateInterceptorTypeAndProceed(SyntaxNodeAnalysisContext ctx, NodeList<Node> members) {
        String interceptorType = null;
        for (Node member : members) {
            if (member.kind() == SyntaxKind.TYPE_REFERENCE) {
                String typeReference = ((TypeReferenceNode) member).typeName().toString();
                switch (typeReference) {
                    case Constants.HTTP_REQUEST_INTERCEPTOR:
                        if (interceptorType == null) {
                            interceptorType = Constants.REQUEST_INTERCEPTOR;
                            break;
                        } else {
                            reportMultipleReferencesFound(ctx, (TypeReferenceNode) member);
                            return;
                        }
                    case Constants.HTTP_REQUEST_ERROR_INTERCEPTOR:
                        if (interceptorType == null) {
                            interceptorType = Constants.REQUEST_ERROR_INTERCEPTOR;
                            break;
                        } else {
                            reportMultipleReferencesFound(ctx, (TypeReferenceNode) member);
                            return;
                        }
                }
            }
        }
        if (interceptorType != null) {
            validateInterceptorResourceMethod(ctx, members, interceptorType);
        }
    }

    private static void validateInterceptorResourceMethod(SyntaxNodeAnalysisContext ctx, NodeList<Node> members,
                                                          String type) {
        FunctionDefinitionNode resourceFunctionNode = null;
        for (Node member : members) {
            if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                if (resourceFunctionNode == null) {
                    resourceFunctionNode = (FunctionDefinitionNode) member;
                } else {
                    reportMultipleResourceFunctionsFound(ctx, (FunctionDefinitionNode) member);
                    return;
                }
            }
        }
        if (resourceFunctionNode != null) {
            HttpInterceptorResourceValidator.validateResource(ctx, resourceFunctionNode, type);
        }
    }

    private static void reportMultipleReferencesFound(SyntaxNodeAnalysisContext ctx, TypeReferenceNode node) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), node.typeName().toString(),
                                                HttpDiagnosticCodes.HTTP_123);
    }

    private static void reportMultipleResourceFunctionsFound(SyntaxNodeAnalysisContext ctx,
                                                             FunctionDefinitionNode node) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(HttpDiagnosticCodes.HTTP_124.getCode(),
                HttpDiagnosticCodes.HTTP_124.getMessage(), HttpDiagnosticCodes.HTTP_124.getSeverity());
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location()));
    }
}
