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
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.MapTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TableTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticProperty;
import io.ballerina.tools.diagnostics.Location;

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.Constants.BALLERINA;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.Constants.RESPONSE_OBJ_NAME;

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
        if (returnTypeSymbol.isEmpty()) {
            return;
        }
        validateReturnType(ctx, returnTypeNode, returnType, returnTypeSymbol.get(), httpDiagnosticCode, true);
        NodeList<AnnotationNode> annotations = returnTypeDescriptorNode.get().annotations();
        if (!annotations.isEmpty()) {
            reportReturnTypeAnnotationsAreNotAllowed(ctx, returnTypeDescriptorNode.get());
        }
    }

    public static void validateReturnType(SyntaxNodeAnalysisContext ctx, Node node, String returnTypeStringValue,
                                           TypeSymbol returnTypeSymbol, HttpDiagnosticCodes diagnosticCode,
                                           boolean isInterceptorType) {
        if (isInterceptorType && isServiceType(returnTypeSymbol)) {
            return;
        }
        TypeDescKind kind = returnTypeSymbol.typeKind();
        if (isBasicTypeDesc(kind) || kind == TypeDescKind.ERROR || kind == TypeDescKind.NIL) {
            return;
        }
        if (kind == TypeDescKind.UNION) {
            List<TypeSymbol> typeSymbols = ((UnionTypeSymbol) returnTypeSymbol).memberTypeDescriptors();
            for (TypeSymbol typeSymbol : typeSymbols) {
                validateReturnType(ctx, node, returnTypeStringValue, typeSymbol, diagnosticCode, isInterceptorType);
            }
        } else if (kind == TypeDescKind.ARRAY) {
            TypeSymbol memberTypeDescriptor = ((ArrayTypeSymbol) returnTypeSymbol).memberTypeDescriptor();
            validateArrayElementType(ctx, node, returnTypeStringValue, memberTypeDescriptor, diagnosticCode);
        } else if (kind == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) returnTypeSymbol).typeDescriptor();
            TypeDescKind typeDescKind = retrieveEffectiveTypeDesc(typeDescriptor);
            if (typeDescKind == TypeDescKind.OBJECT) {
                if (!isHttpModuleType(RESPONSE_OBJ_NAME, typeDescriptor)) {
                    reportInvalidReturnType(ctx, node, returnTypeStringValue, diagnosticCode);
                }
            } else if (typeDescKind == TypeDescKind.TABLE) {
                validateReturnType(ctx, node, returnTypeStringValue, typeDescriptor, diagnosticCode, isInterceptorType);
            } else if (typeDescKind != TypeDescKind.RECORD && typeDescKind != TypeDescKind.ERROR) {
                reportInvalidReturnType(ctx, node, returnTypeStringValue, diagnosticCode);
            }
        } else if (kind == TypeDescKind.MAP) {
            TypeSymbol typeSymbol = ((MapTypeSymbol) returnTypeSymbol).typeParam();
            validateReturnType(ctx, node, returnTypeStringValue, typeSymbol, diagnosticCode, isInterceptorType);
        } else if (kind == TypeDescKind.TABLE) {
            TypeSymbol typeSymbol = ((TableTypeSymbol) returnTypeSymbol).rowTypeParameter();
            if (typeSymbol == null) {
                reportInvalidReturnType(ctx, node, returnTypeStringValue, diagnosticCode);
            } else {
                validateReturnType(ctx, node, returnTypeStringValue, typeSymbol, diagnosticCode, isInterceptorType);
            }
        } else {
            reportInvalidReturnType(ctx, node, returnTypeStringValue, diagnosticCode);
        }
    }

    private static boolean isServiceType(TypeSymbol returnTypeSymbol) {
        Optional<String> optionalTypeName = returnTypeSymbol.getName();
        return optionalTypeName.filter(s -> s.equals(Constants.SERVICE) ||
                s.equals(Constants.REQUEST_INTERCEPTOR) ||
                s.equals(Constants.RESPONSE_INTERCEPTOR)).isPresent();
    }

    private static void validateArrayElementType(SyntaxNodeAnalysisContext ctx, Node node, String typeStringValue,
                                                 TypeSymbol memberTypeDescriptor, HttpDiagnosticCodes diagnosticCode) {
        TypeDescKind kind = memberTypeDescriptor.typeKind();
        if (isBasicTypeDesc(kind) || kind == TypeDescKind.MAP || kind == TypeDescKind.TABLE) {
            return;
        }
        if (kind == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) memberTypeDescriptor).typeDescriptor();
            TypeDescKind typeDescKind = retrieveEffectiveTypeDesc(typeDescriptor);
            if (typeDescKind != TypeDescKind.RECORD && typeDescKind != TypeDescKind.MAP &&
                    typeDescKind != TypeDescKind.TABLE) {
                reportInvalidReturnType(ctx, node, typeStringValue, diagnosticCode);
            }
        } else {
            reportInvalidReturnType(ctx, node, typeStringValue, diagnosticCode);
        }
    }

    public static boolean isHttpModuleType(String expectedType, TypeSymbol typeDescriptor) {
        Optional<ModuleSymbol> module = typeDescriptor.getModule();
        if (module.isEmpty()) {
            return false;
        }
        if (!BALLERINA.equals(module.get().id().orgName()) || !HTTP.equals(module.get().getName().get())) {
            return false;
        }
        Optional<String> typeName = typeDescriptor.getName();
        if (typeName.isEmpty()) {
            return false;
        }
        return expectedType.equals(typeName.get());
    }

    public static TypeDescKind retrieveEffectiveTypeDesc(TypeSymbol descriptor) {
        TypeDescKind typeDescKind = descriptor.typeKind();
        if (typeDescKind == TypeDescKind.INTERSECTION) {
            return ((IntersectionTypeSymbol) descriptor).effectiveTypeDescriptor().typeKind();
        }
        return typeDescKind;
    }

    private static boolean isBasicTypeDesc(TypeDescKind kind) {
        return kind == TypeDescKind.STRING || kind == TypeDescKind.INT || kind == TypeDescKind.FLOAT ||
                kind == TypeDescKind.DECIMAL || kind == TypeDescKind.BOOLEAN || kind == TypeDescKind.JSON ||
                kind == TypeDescKind.XML || kind == TypeDescKind.RECORD || kind == TypeDescKind.BYTE;
    }

    private static void reportInvalidReturnType(SyntaxNodeAnalysisContext ctx, Node node,
                                                String returnType, HttpDiagnosticCodes diagnosticCode) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), returnType, diagnosticCode);
    }

    private static void reportReturnTypeAnnotationsAreNotAllowed(SyntaxNodeAnalysisContext ctx, Node node) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), HttpDiagnosticCodes.HTTP_140);
    }
}
