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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.Qualifier;
import io.ballerina.compiler.api.symbols.Symbol;
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
import java.util.Optional;

/**
 * Validates a Ballerina Http Interceptor Service.
 */
public class HttpInterceptorServiceValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        List<Diagnostic> diagnostics = syntaxNodeAnalysisContext.semanticModel().diagnostics();
        boolean erroneousCompilation = diagnostics.stream()
                .anyMatch(d -> DiagnosticSeverity.ERROR.equals(d.diagnosticInfo().severity()));
        if (erroneousCompilation) {
            return;
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
                    case Constants.HTTP_RESPONSE_INTERCEPTOR:
                        if (interceptorType == null) {
                            interceptorType = Constants.RESPONSE_INTERCEPTOR;
                            break;
                        } else {
                            reportMultipleReferencesFound(ctx, (TypeReferenceNode) member);
                            return;
                        }
                }
            }
        }
        if (interceptorType != null) {
            validateInterceptorMethod(ctx, members, interceptorType);
        }
    }

    private static void validateInterceptorMethod(SyntaxNodeAnalysisContext ctx, NodeList<Node> members,
                                                          String type) {
        FunctionDefinitionNode resourceFunctionNode = null;
        FunctionDefinitionNode remoteFunctionNode = null;
        for (Node member : members) {
            if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                if (!isResourceSupported(type)) {
                    reportResourceFunctionNotAllowed(ctx, member, type);
                }
                if (resourceFunctionNode == null) {
                    resourceFunctionNode = (FunctionDefinitionNode) member;
                } else {
                    reportMultipleResourceFunctionsFound(ctx, (FunctionDefinitionNode) member);
                    return;
                }
            } else if (member instanceof FunctionDefinitionNode &&
                    isRemoteFunction(ctx, (FunctionDefinitionNode) member)) {
                if (!String.valueOf(((FunctionDefinitionNode) member).functionName()).equals("interceptResponse")) {
                    reportInvalidRemoteFunction(ctx, member,
                            String.valueOf(((FunctionDefinitionNode) member).functionName()), type);
                }
                if (isResourceSupported(type)) {
                    reportRemoteFunctionNotAllowed(ctx, member, type);
                }
                if (remoteFunctionNode == null) {
                    remoteFunctionNode = (FunctionDefinitionNode) member;
                } else {
                    reportMultipleResourceFunctionsFound(ctx, (FunctionDefinitionNode) member);
                    return;
                }
            }
        }
        if (isResourceSupported(type)) {
            if (resourceFunctionNode != null) {
                HttpInterceptorResourceValidator.validateResource(ctx, resourceFunctionNode, type);
            } else {
                reportResourceFunctionNotFound(ctx, type);
            }
        } else {
            // TODO : Add remote method validation
            if (remoteFunctionNode == null) {
                reportRemoteFunctionNotFound(ctx, type);
            }
        }
    }

    public static MethodSymbol getMethodSymbol(SyntaxNodeAnalysisContext context,
                                               FunctionDefinitionNode functionDefinitionNode) {
        MethodSymbol methodSymbol = null;
        SemanticModel semanticModel = context.semanticModel();
        Optional<Symbol> symbol = semanticModel.symbol(functionDefinitionNode);
        if (symbol.isPresent()) {
            methodSymbol = (MethodSymbol) symbol.get();
        }
        return methodSymbol;
    }

    public static boolean isRemoteFunction(SyntaxNodeAnalysisContext context,
                                           FunctionDefinitionNode functionDefinitionNode) {
        return isRemoteFunction(getMethodSymbol(context, functionDefinitionNode));
    }

    public static boolean isRemoteFunction(MethodSymbol methodSymbol) {
        return methodSymbol.qualifiers().contains(Qualifier.REMOTE);
    }

    private static boolean isResourceSupported(String type) {
        return type.equals(Constants.REQUEST_INTERCEPTOR) || type.equals(Constants.REQUEST_ERROR_INTERCEPTOR);
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

    private static void reportResourceFunctionNotFound(SyntaxNodeAnalysisContext ctx, String type) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, ctx.node().location(), type, HttpDiagnosticCodes.HTTP_132);
    }

    private static void reportRemoteFunctionNotFound(SyntaxNodeAnalysisContext ctx, String type) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, ctx.node().location(), type, HttpDiagnosticCodes.HTTP_133);
    }

    private static void reportResourceFunctionNotAllowed(SyntaxNodeAnalysisContext ctx, Node node, String type) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), type, HttpDiagnosticCodes.HTTP_134);
    }

    private static void reportRemoteFunctionNotAllowed(SyntaxNodeAnalysisContext ctx, Node node, String type) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), type, HttpDiagnosticCodes.HTTP_135);
    }

    private static void reportInvalidRemoteFunction(SyntaxNodeAnalysisContext ctx, Node node, String functionName,
                                                    String interceptorType) {
        DiagnosticInfo diagnosticInfo = HttpCompilerPluginUtil.getDiagnosticInfo(HttpDiagnosticCodes.HTTP_136,
                                        functionName, interceptorType);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location()));
    }
}
