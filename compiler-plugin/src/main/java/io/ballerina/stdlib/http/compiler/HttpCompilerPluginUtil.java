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
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticProperty;
import io.ballerina.tools.diagnostics.Location;

import java.util.List;
import java.util.Optional;

/**
 * Utility class providing http compiler plugin utility methods.
 */
public class HttpCompilerPluginUtil {

    public static void updateDiagnostic(SyntaxNodeAnalysisContext ctx, Location location,
                                        HttpDiagnosticCodes httpDiagnosticCodes) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(httpDiagnosticCodes);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }

    public static void updateDiagnostic(SyntaxNodeAnalysisContext ctx, Location location, String argName,
                                         HttpDiagnosticCodes httpDiagnosticCodes) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(httpDiagnosticCodes, argName);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }

    public static void updateDiagnostic(SyntaxNodeAnalysisContext ctx, Location location, String argName,
                                         HttpDiagnosticCodes httpDiagnosticCodes,
                                         List<DiagnosticProperty<?>> diagnosticProperties) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(httpDiagnosticCodes, argName);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location, diagnosticProperties));
    }

    public static DiagnosticInfo getDiagnosticInfo(HttpDiagnosticCodes diagnostic, Object... args) {
        return new DiagnosticInfo(diagnostic.getCode(), String.format(diagnostic.getMessage(), args),
                diagnostic.getSeverity());
    }

    public static void validateHttpCallerUsage(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                               HttpDiagnosticCodes diagnosticCode) {
        Optional<Symbol> methodSymbolOptional = ctx.semanticModel().symbol(member);
        Optional<ReturnTypeDescriptorNode> returnTypeDescOpt = member.functionSignature().returnTypeDesc();
        if (methodSymbolOptional.isEmpty() || returnTypeDescOpt.isEmpty()) {
            return;
        }
        String returnTypeDescription = getReturnTypeDescription(returnTypeDescOpt.get());
        Location returnTypeLocation = returnTypeDescOpt.get().type().location();
        MethodSymbol method = (MethodSymbol) methodSymbolOptional.get();
        FunctionTypeSymbol typeDescriptor = method.typeDescriptor();
        Optional<List<ParameterSymbol>> parameterOptional = typeDescriptor.params();
        boolean isCallerPresent = parameterOptional.isPresent() &&
                parameterOptional.get().stream().anyMatch(HttpResourceValidator::isHttpCaller);
        if (!isCallerPresent) {
            return;
        }
        Optional<TypeSymbol> returnTypeDescriptorOpt = typeDescriptor.returnTypeDescriptor();
        if (returnTypeDescriptorOpt.isEmpty()) {
            return;
        }
        TypeSymbol typeSymbol = returnTypeDescriptorOpt.get();
        if (isValidReturnTypeWithCaller(typeSymbol)) {
            return;
        }
        HttpCompilerPluginUtil.updateDiagnostic(ctx, returnTypeLocation, returnTypeDescription, diagnosticCode);
    }

    private static boolean isValidReturnTypeWithCaller(TypeSymbol returnTypeDescriptor) {
        TypeDescKind typeKind = returnTypeDescriptor.typeKind();
        if (TypeDescKind.UNION.equals(typeKind)) {
            return ((UnionTypeSymbol) returnTypeDescriptor)
                    .memberTypeDescriptors().stream()
                    .map(HttpCompilerPluginUtil::isValidReturnTypeWithCaller)
                    .reduce(true, (a , b) -> a && b);
        } else if (TypeDescKind.TYPE_REFERENCE.equals(typeKind)) {
            TypeSymbol typeRef = ((TypeReferenceTypeSymbol) returnTypeDescriptor).typeDescriptor();
            TypeDescKind typeRefKind = typeRef.typeKind();
            return TypeDescKind.ERROR.equals(typeRefKind) || TypeDescKind.NIL.equals(typeRefKind);
        } else {
            return TypeDescKind.ERROR.equals(typeKind) || TypeDescKind.NIL.equals(typeKind);
        }
    }

    public static String getReturnTypeDescription(ReturnTypeDescriptorNode returnTypeDescriptorNode) {
        return returnTypeDescriptorNode.type().toString().split(" ")[0];
    }

    public static void extractInterceptorReturnTypeAndValidate(SyntaxNodeAnalysisContext ctx,
                                                               FunctionDefinitionNode member,
                                                               HttpDiagnosticCodes httpDiagnosticCode) {
        Optional<ReturnTypeDescriptorNode> returnTypeDescriptorNode = member.functionSignature().returnTypeDesc();
        if (returnTypeDescriptorNode.isEmpty()) {
            return;
        }
        Node returnTypeNode = returnTypeDescriptorNode.get().type();
        String returnType = HttpCompilerPluginUtil.getReturnTypeDescription(returnTypeDescriptorNode.get());
        Optional<Symbol> functionSymbol = ctx.semanticModel().symbol(member);
        if (functionSymbol.isEmpty()) {
            return;
        }
        FunctionTypeSymbol functionTypeSymbol = ((FunctionSymbol) functionSymbol.get()).typeDescriptor();
        Optional<TypeSymbol> returnTypeSymbol = functionTypeSymbol.returnTypeDescriptor();
        returnTypeSymbol.ifPresent(typeSymbol -> validateInterceptorReturnType(ctx, returnTypeNode, returnType,
                typeSymbol, httpDiagnosticCode));
    }

    private static void validateInterceptorReturnType(SyntaxNodeAnalysisContext ctx, Node node, String returnType,
                                                      TypeSymbol returnSymbol, HttpDiagnosticCodes diagnosticCode) {
        if (isServiceType(returnSymbol)) {
            return;
        }
        TypeDescKind kind = returnSymbol.typeKind();
        if (kind == TypeDescKind.ERROR || kind == TypeDescKind.NIL) {
            return;
        }
        if (kind == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) returnSymbol).typeDescriptor();
            validateInterceptorReturnType(ctx, node, returnType, typeDescriptor, diagnosticCode);
        } else if (kind == TypeDescKind.UNION) {
            List<TypeSymbol> typeSymbols = ((UnionTypeSymbol) returnSymbol).memberTypeDescriptors();
            for (TypeSymbol typeSymbol : typeSymbols) {
                validateInterceptorReturnType(ctx, node, returnType, typeSymbol, diagnosticCode);
            }
        } else {
            reportInvalidInterceptorReturnType(ctx, node, returnType, diagnosticCode);
        }
    }

    private static boolean isServiceType(TypeSymbol returnTypeSymbol) {
        Optional<String> optionalTypeName = returnTypeSymbol.getName();
        return optionalTypeName.filter(s -> s.equals(Constants.SERVICE) ||
                s.equals(Constants.REQUEST_INTERCEPTOR) ||
                s.equals(Constants.RESPONSE_INTERCEPTOR)).isPresent();
    }

    private static void reportInvalidInterceptorReturnType(SyntaxNodeAnalysisContext ctx, Node node, String returnType,
                                                           HttpDiagnosticCodes httpDiagnosticCode) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), returnType, httpDiagnosticCode);
    }
}
