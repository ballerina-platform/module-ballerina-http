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

import io.ballerina.compiler.api.symbols.FunctionSymbol;
import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.List;
import java.util.Optional;

/**
 * Validates a ballerina http interceptor resource.
 */
public class HttpInterceptorResourceValidator {
    public static void validateResource(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member, String type) {
        checkResourceAnnotation(ctx, member);
        if (type.equals(Constants.REQUEST_ERROR_INTERCEPTOR)) {
            extractAndValidateMethodAndPath(ctx, member);
        }
        HttpResourceValidator.extractInputParamTypeAndValidate(ctx, member);
        extractReturnTypeAndValidate(ctx, member, HttpDiagnosticCodes.HTTP_126);
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

    public static void extractReturnTypeAndValidate(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                                    HttpDiagnosticCodes httpDiagnosticCode) {
        Optional<ReturnTypeDescriptorNode> returnTypeDescriptorNode = member.functionSignature().returnTypeDesc();
        if (returnTypeDescriptorNode.isEmpty()) {
            return;
        }
        Node returnTypeNode = returnTypeDescriptorNode.get().type();
        String returnTypeStringValue = HttpResourceValidator.getReturnTypeDescription(returnTypeDescriptorNode.get());
        Optional<Symbol> functionSymbol = ctx.semanticModel().symbol(member);
        if (functionSymbol.isEmpty()) {
            return;
        }
        FunctionTypeSymbol functionTypeSymbol = ((FunctionSymbol) functionSymbol.get()).typeDescriptor();
        Optional<TypeSymbol> returnTypeSymbol = functionTypeSymbol.returnTypeDescriptor();
        returnTypeSymbol.ifPresent(typeSymbol -> validateReturnType(ctx, returnTypeNode, returnTypeStringValue,
                typeSymbol, httpDiagnosticCode));
    }

    private static void validateReturnType(SyntaxNodeAnalysisContext ctx, Node node, String returnTypeStringValue,
                                           TypeSymbol returnTypeSymbol, HttpDiagnosticCodes httpDiagnosticCode) {
        if (isServiceType(returnTypeSymbol)) {
            return;
        }
        TypeDescKind kind = returnTypeSymbol.typeKind();
        if (kind == TypeDescKind.ERROR || kind == TypeDescKind.NIL) {
            return;
        }
        if (kind == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) returnTypeSymbol).typeDescriptor();
            validateReturnType(ctx, node, returnTypeStringValue, typeDescriptor, httpDiagnosticCode);
        } else if (kind == TypeDescKind.UNION) {
            List<TypeSymbol> typeSymbols = ((UnionTypeSymbol) returnTypeSymbol).memberTypeDescriptors();
            for (TypeSymbol typeSymbol : typeSymbols) {
                validateReturnType(ctx, node, returnTypeStringValue, typeSymbol, httpDiagnosticCode);
            }
        } else {
            reportInvalidReturnType(ctx, node, returnTypeStringValue, httpDiagnosticCode);
        }
    }

    private static boolean isServiceType(TypeSymbol returnTypeSymbol) {
        Optional<String> optionalTypeName = returnTypeSymbol.getName();
        return optionalTypeName.filter(s -> s.equals(Constants.SERVICE) ||
                                       s.equals(Constants.REQUEST_INTERCEPTOR) ||
                                       s.equals(Constants.RESPONSE_INTERCEPTOR)).isPresent();
    }

    private static void reportResourceAnnotationNotAllowed(SyntaxNodeAnalysisContext ctx, AnnotationNode node) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), node.annotReference().toString(),
                                                HttpDiagnosticCodes.HTTP_125);
    }

    private static void reportInvalidReturnType(SyntaxNodeAnalysisContext ctx, Node node, String returnType,
                                                HttpDiagnosticCodes httpDiagnosticCode) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), returnType, httpDiagnosticCode);
    }

    private static void reportInvalidResourcePath(SyntaxNodeAnalysisContext ctx, Node node) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), node.toString(), HttpDiagnosticCodes.HTTP_127);
    }

    private static void reportInvalidResourceMethod(SyntaxNodeAnalysisContext ctx, IdentifierToken identifierToken) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, identifierToken.location(), identifierToken.toString().strip(),
                                                HttpDiagnosticCodes.HTTP_128);
    }
}
