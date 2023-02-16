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

import io.ballerina.compiler.api.Types;
import io.ballerina.compiler.api.symbols.FunctionSymbol;
import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeSymbol;
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

import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.Constants.ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.BALLERINA;
import static io.ballerina.stdlib.http.compiler.Constants.BOOLEAN;
import static io.ballerina.stdlib.http.compiler.Constants.BOOLEAN_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.DECIMAL;
import static io.ballerina.stdlib.http.compiler.Constants.DECIMAL_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.EMPTY;
import static io.ballerina.stdlib.http.compiler.Constants.ERROR;
import static io.ballerina.stdlib.http.compiler.Constants.FLOAT;
import static io.ballerina.stdlib.http.compiler.Constants.FLOAT_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.Constants.INT;
import static io.ballerina.stdlib.http.compiler.Constants.INTERCEPTOR_RESOURCE_RETURN_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.INT_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.NIL;
import static io.ballerina.stdlib.http.compiler.Constants.RESOURCE_RETURN_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.STRING;
import static io.ballerina.stdlib.http.compiler.Constants.STRING_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.UNNECESSARY_CHARS_REGEX;

/**
 * Utility class providing http compiler plugin utility methods.
 */
public class HttpCompilerPluginUtil {

    public static void updateDiagnostic(SyntaxNodeAnalysisContext ctx, Location location,
                                        HttpDiagnosticCodes httpDiagnosticCodes) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(httpDiagnosticCodes);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }

    public static void updateDiagnostic(SyntaxNodeAnalysisContext ctx, Location location,
                                        HttpDiagnosticCodes httpDiagnosticCodes, Object... argName) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(httpDiagnosticCodes, argName);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }

    public static void updateDiagnostic(SyntaxNodeAnalysisContext ctx, Location location,
                                        HttpDiagnosticCodes httpDiagnosticCodes,
                                        List<DiagnosticProperty<?>> diagnosticProperties, String argName) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(httpDiagnosticCodes, argName);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location, diagnosticProperties));
    }

    public static DiagnosticInfo getDiagnosticInfo(HttpDiagnosticCodes diagnostic, Object... args) {
        return new DiagnosticInfo(diagnostic.getCode(), String.format(diagnostic.getMessage(), args),
                diagnostic.getSeverity());
    }

    public static String getReturnTypeDescription(ReturnTypeDescriptorNode returnTypeDescriptorNode) {
        return returnTypeDescriptorNode.type().toString().trim();
    }

    public static void extractInterceptorReturnTypeAndValidate(SyntaxNodeAnalysisContext ctx,
                                                               Map<String, TypeSymbol> typeSymbols,
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
        validateResourceReturnType(ctx, returnTypeNode, typeSymbols, returnType, returnTypeSymbol.get(),
                httpDiagnosticCode, true);
        NodeList<AnnotationNode> annotations = returnTypeDescriptorNode.get().annotations();
        if (!annotations.isEmpty()) {
            reportReturnTypeAnnotationsAreNotAllowed(ctx, returnTypeDescriptorNode.get());
        }
    }

    public static void validateResourceReturnType(SyntaxNodeAnalysisContext ctx, Node node,
                                                  Map<String, TypeSymbol> typeSymbols, String returnTypeStringValue,
                                                  TypeSymbol returnTypeSymbol, HttpDiagnosticCodes diagnosticCode,
                                                  boolean isInterceptorType) {
        if (subtypeOfHttpModuleType(typeSymbols, returnTypeSymbol,
                isInterceptorType ? INTERCEPTOR_RESOURCE_RETURN_TYPE : RESOURCE_RETURN_TYPE)) {
            return;
        }
        reportInvalidReturnType(ctx, node, returnTypeStringValue, diagnosticCode);
    }

    public static boolean subtypeOfHttpModuleType(Map<String, TypeSymbol> typeSymbols, TypeSymbol typeSymbol,
                                                  String targetTypeName) {
        TypeSymbol targetTypeSymbol = typeSymbols.get(targetTypeName);
        if (targetTypeSymbol != null) {
            return typeSymbol.subtypeOf(targetTypeSymbol);
        }
        return false;
    }

    public static boolean subtypeOfAnydata(Map<String, TypeSymbol> typeSymbols, TypeSymbol typeSymbol) {
        return typeSymbol.subtypeOf(typeSymbols.get(ANYDATA));
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

    private static void reportInvalidReturnType(SyntaxNodeAnalysisContext ctx, Node node,
                                                String returnType, HttpDiagnosticCodes diagnosticCode) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), diagnosticCode, returnType);
    }

    private static void reportReturnTypeAnnotationsAreNotAllowed(SyntaxNodeAnalysisContext ctx, Node node) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), HttpDiagnosticCodes.HTTP_142);
    }

    public static void reportMissingParameterError(SyntaxNodeAnalysisContext ctx, Location location, String method) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_143, method);
    }

    public static String getNodeString(Node node, boolean isCaseSensitive) {
        String nodeString = node.toString().replaceAll(UNNECESSARY_CHARS_REGEX, EMPTY).trim();
        return isCaseSensitive ? nodeString : nodeString.toLowerCase(Locale.getDefault());
    }

    public static Map<String, TypeSymbol> getCtxTypes(SyntaxNodeAnalysisContext ctx) {
        Map<String, TypeSymbol> typeSymbols = new HashMap<>();
        populateBasicTypes(ctx, typeSymbols);
        populateHttpModuleTypes(ctx, typeSymbols);
        return typeSymbols;
    }

    private static void populateHttpModuleTypes(SyntaxNodeAnalysisContext ctx, Map<String, TypeSymbol> typeSymbols) {
        String[] requiredTypeNames = {RESOURCE_RETURN_TYPE, INTERCEPTOR_RESOURCE_RETURN_TYPE, CALLER_OBJ_NAME};
        Optional<Map<String, Symbol>> optionalMap = ctx.semanticModel().types().typesInModule(BALLERINA, HTTP, EMPTY);
        if (optionalMap.isPresent()) {
            Map<String, Symbol> symbolMap = optionalMap.get();
            for (String typeName : requiredTypeNames) {
                Symbol symbol = symbolMap.get(typeName);
                if (symbol instanceof TypeSymbol) {
                    typeSymbols.put(typeName, (TypeSymbol) symbol);
                } else if (symbol instanceof TypeDefinitionSymbol) {
                    typeSymbols.put(typeName, ((TypeDefinitionSymbol) symbol).typeDescriptor());
                }
            }
        }
    }

    private static void populateBasicTypes(SyntaxNodeAnalysisContext ctx, Map<String, TypeSymbol> typeSymbols) {
        Types types = ctx.semanticModel().types();
        typeSymbols.put(ANYDATA, types.ANYDATA);
        typeSymbols.put(ERROR, types.ERROR);
        typeSymbols.put(STRING, types.builder().UNION_TYPE.withMemberTypes(types.STRING, types.NIL).build());
        typeSymbols.put(BOOLEAN, types.builder().UNION_TYPE.withMemberTypes(types.BOOLEAN, types.NIL).build());
        typeSymbols.put(INT, types.builder().UNION_TYPE.withMemberTypes(types.INT, types.NIL).build());
        typeSymbols.put(FLOAT, types.builder().UNION_TYPE.withMemberTypes(types.FLOAT, types.NIL).build());
        typeSymbols.put(DECIMAL, types.builder().UNION_TYPE.withMemberTypes(types.DECIMAL, types.NIL).build());
        typeSymbols.put(NIL, types.NIL);
        typeSymbols.put(STRING_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                types.builder().ARRAY_TYPE.withType(types.STRING).build(), types.NIL).build());
        typeSymbols.put(BOOLEAN_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                types.builder().ARRAY_TYPE.withType(types.BOOLEAN).build(), types.NIL).build());
        typeSymbols.put(INT_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                types.builder().ARRAY_TYPE.withType(types.INT).build(), types.NIL).build());
        typeSymbols.put(FLOAT_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                types.builder().ARRAY_TYPE.withType(types.FLOAT).build(), types.NIL).build());
        typeSymbols.put(DECIMAL_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                types.builder().ARRAY_TYPE.withType(types.DECIMAL).build(), types.NIL).build());
    }
}
