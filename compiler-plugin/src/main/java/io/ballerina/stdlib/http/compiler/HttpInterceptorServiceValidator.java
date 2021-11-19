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

import io.ballerina.compiler.api.symbols.ObjectTypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
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
import java.util.Objects;
import java.util.Optional;

/**
 * Validates a Ballerina Http Interceptor Service.
 */
public class HttpInterceptorServiceValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {
    String interceptorType;

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

    private void validateInterceptorTypeAndProceed(SyntaxNodeAnalysisContext ctx, NodeList<Node> members) {
        for (Node member : members) {
            if (member.kind() == SyntaxKind.TYPE_REFERENCE) {
                Optional<Symbol> optionalTypeReferenceSymbol = ctx.semanticModel().symbol(member);
                if (optionalTypeReferenceSymbol.isPresent()) {
                    TypeReferenceTypeSymbol typeReferenceSymbol = (TypeReferenceTypeSymbol)
                            optionalTypeReferenceSymbol.get();
                    populateTypeReferenceName(ctx, member, typeReferenceSymbol);
                }
            }
        }
        if (Objects.nonNull(interceptorType)) {
            validateInterceptorResourceMethod(ctx, members, interceptorType);
            interceptorType = null;
        }
    }

    private boolean populateTypeReferenceName(SyntaxNodeAnalysisContext ctx, Node node,
                                              TypeReferenceTypeSymbol typeReferenceSymbol) {
        List<TypeSymbol> typeInclusions = ((ObjectTypeSymbol) typeReferenceSymbol.typeDescriptor()).typeInclusions();

        if (typeInclusions.isEmpty()) {
            String typeName = typeReferenceSymbol.getName().isPresent() ? typeReferenceSymbol.getName().get() : null;
            if (Objects.isNull(typeName)) {
                return true;
            }
            if (typeName.equals(Constants.REQUEST_INTERCEPTOR) ||
                    typeName.equals(Constants.REQUEST_ERROR_INTERCEPTOR)) {
                if (Objects.isNull(interceptorType)) {
                    interceptorType = typeName;
                    return true;
                } else {
                    reportMultipleReferencesFound(ctx, (TypeReferenceNode) node);
                    return false;
                }
            }
        } else {
            for (TypeSymbol typeSymbol : typeInclusions) {
                if (typeSymbol instanceof TypeReferenceTypeSymbol) {
                    if (!populateTypeReferenceName(ctx, node, (TypeReferenceTypeSymbol) typeSymbol)) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    private static void validateInterceptorResourceMethod(SyntaxNodeAnalysisContext ctx, NodeList<Node> members,
                                                          String type) {
        FunctionDefinitionNode resourceFunctionNode = null;
        for (Node member : members) {
            if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                if (Objects.isNull(resourceFunctionNode)) {
                    resourceFunctionNode = (FunctionDefinitionNode) member;
                } else {
                    reportMultipleResourceFunctionsFound(ctx, (FunctionDefinitionNode) member);
                    return;
                }
            }
        }
        if (Objects.nonNull(resourceFunctionNode)) {
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
