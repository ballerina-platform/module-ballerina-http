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
import static io.ballerina.stdlib.http.compiler.Constants.ARRAY_OF_MAP_OF_ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.BALLERINA;
import static io.ballerina.stdlib.http.compiler.Constants.BOOLEAN;
import static io.ballerina.stdlib.http.compiler.Constants.BOOLEAN_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.BYTE_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.DECIMAL;
import static io.ballerina.stdlib.http.compiler.Constants.DECIMAL_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.EMPTY;
import static io.ballerina.stdlib.http.compiler.Constants.ERROR;
import static io.ballerina.stdlib.http.compiler.Constants.FLOAT;
import static io.ballerina.stdlib.http.compiler.Constants.FLOAT_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.HEADER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.Constants.INT;
import static io.ballerina.stdlib.http.compiler.Constants.INTERCEPTOR_RESOURCE_RETURN_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.INT_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.JSON;
import static io.ballerina.stdlib.http.compiler.Constants.MAP_OF_ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.NIL;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_BOOLEAN;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_BOOLEAN_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_DECIMAL;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_DECIMAL_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_FLOAT;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_FLOAT_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_INT;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_INT_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_MAP_OF_ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_MAP_OF_ANYDATA_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_STRING;
import static io.ballerina.stdlib.http.compiler.Constants.NILABLE_STRING_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.OBJECT;
import static io.ballerina.stdlib.http.compiler.Constants.REQUEST_CONTEXT_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.REQUEST_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.RESOURCE_RETURN_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.RESPONSE_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.STRING;
import static io.ballerina.stdlib.http.compiler.Constants.STRING_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.STRUCTURED_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.TABLE_OF_ANYDATA_MAP;
import static io.ballerina.stdlib.http.compiler.Constants.TUPLE_OF_ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.UNNECESSARY_CHARS_REGEX;
import static io.ballerina.stdlib.http.compiler.Constants.XML;

/**
 * Utility class providing http compiler plugin utility methods.
 */
public final class HttpCompilerPluginUtil {

    private HttpCompilerPluginUtil() {}

    public static void updateDiagnostic(SyntaxNodeAnalysisContext ctx, Location location,
                                        HttpDiagnostic httpDiagnosticCodes) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(httpDiagnosticCodes);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }

    public static void updateDiagnostic(SyntaxNodeAnalysisContext ctx, Location location,
                                        HttpDiagnostic httpDiagnosticCodes, Object... argName) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(httpDiagnosticCodes, argName);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location));
    }

    public static void updateDiagnostic(SyntaxNodeAnalysisContext ctx, Location location,
                                        HttpDiagnostic httpDiagnosticCodes,
                                        List<DiagnosticProperty<?>> diagnosticProperties, String argName) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(httpDiagnosticCodes, argName);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, location, diagnosticProperties));
    }

    public static DiagnosticInfo getDiagnosticInfo(HttpDiagnostic diagnostic, Object... args) {
        return new DiagnosticInfo(diagnostic.getCode(), String.format(diagnostic.getMessage(), args),
                diagnostic.getSeverity());
    }

    public static String getReturnTypeDescription(ReturnTypeDescriptorNode returnTypeDescriptorNode) {
        return returnTypeDescriptorNode.type().toString().trim();
    }

    public static void extractInterceptorReturnTypeAndValidate(SyntaxNodeAnalysisContext ctx,
                                                               Map<String, TypeSymbol> typeSymbols,
                                                               FunctionDefinitionNode member,
                                                               HttpDiagnostic httpDiagnosticCode) {
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
                                                  TypeSymbol returnTypeSymbol, HttpDiagnostic diagnosticCode,
                                                  boolean isInterceptorType) {
        if (subtypeOf(typeSymbols, returnTypeSymbol,
                isInterceptorType ? INTERCEPTOR_RESOURCE_RETURN_TYPE : RESOURCE_RETURN_TYPE)) {
            return;
        }
        reportInvalidReturnType(ctx, node, returnTypeStringValue, diagnosticCode);
    }

    public static boolean subtypeOf(Map<String, TypeSymbol> typeSymbols, TypeSymbol typeSymbol,
                                    String targetTypeName) {
        TypeSymbol targetTypeSymbol = typeSymbols.get(targetTypeName);
        if (targetTypeSymbol != null) {
            return typeSymbol.subtypeOf(targetTypeSymbol);
        }
        return false;
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

    public static boolean isHttpModule(ModuleSymbol moduleSymbol) {
        return HTTP.equals(moduleSymbol.getName().get()) && BALLERINA.equals(moduleSymbol.id().orgName());
    }

    public static TypeDescKind retrieveEffectiveTypeDesc(TypeSymbol descriptor) {
        TypeDescKind typeDescKind = descriptor.typeKind();
        if (typeDescKind == TypeDescKind.INTERSECTION) {
            return ((IntersectionTypeSymbol) descriptor).effectiveTypeDescriptor().typeKind();
        }
        return typeDescKind;
    }

    private static void reportInvalidReturnType(SyntaxNodeAnalysisContext ctx, Node node,
                                                String returnType, HttpDiagnostic diagnosticCode) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), diagnosticCode, returnType);
    }

    private static void reportReturnTypeAnnotationsAreNotAllowed(SyntaxNodeAnalysisContext ctx, Node node) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), HttpDiagnostic.HTTP_142);
    }

    public static void reportMissingParameterError(SyntaxNodeAnalysisContext ctx, Location location, String method) {
        updateDiagnostic(ctx, location, HttpDiagnostic.HTTP_143, method);
    }

    public static String getNodeString(Node node, boolean isCaseSensitive) {
        String nodeString = node.toString().replaceAll(UNNECESSARY_CHARS_REGEX, EMPTY).trim();
        return isCaseSensitive ? nodeString : nodeString.toLowerCase(Locale.getDefault());
    }

    public static Map<String, TypeSymbol> getCtxTypes(SyntaxNodeAnalysisContext ctx) {
        Map<String, TypeSymbol> typeSymbols = new HashMap<>();
        populateRequiredLangTypes(ctx, typeSymbols);
        populateHttpModuleTypes(ctx, typeSymbols);
        return typeSymbols;
    }

    private static void populateHttpModuleTypes(SyntaxNodeAnalysisContext ctx, Map<String, TypeSymbol> typeSymbols) {
        String[] requiredTypeNames = {RESOURCE_RETURN_TYPE, INTERCEPTOR_RESOURCE_RETURN_TYPE,
                CALLER_OBJ_NAME, REQUEST_OBJ_NAME, REQUEST_CONTEXT_OBJ_NAME, HEADER_OBJ_NAME, RESPONSE_OBJ_NAME};
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

    private static void populateRequiredLangTypes(SyntaxNodeAnalysisContext ctx, Map<String, TypeSymbol> typeSymbols) {
        Types types = ctx.semanticModel().types();
        populateBasicTypes(typeSymbols, types);
        populateNilableBasicTypes(typeSymbols, types);
        populateBasicArrayTypes(typeSymbols, types);
        populateNilableBasicArrayTypes(typeSymbols, types);
    }

    private static void populateBasicArrayTypes(Map<String, TypeSymbol> typeSymbols, Types types) {
        typeSymbols.put(STRING_ARRAY, types.builder().ARRAY_TYPE.withType(types.STRING).build());
        typeSymbols.put(BOOLEAN_ARRAY, types.builder().ARRAY_TYPE.withType(types.BOOLEAN).build());
        typeSymbols.put(INT_ARRAY, types.builder().ARRAY_TYPE.withType(types.INT).build());
        typeSymbols.put(FLOAT_ARRAY, types.builder().ARRAY_TYPE.withType(types.FLOAT).build());
        typeSymbols.put(DECIMAL_ARRAY, types.builder().ARRAY_TYPE.withType(types.DECIMAL).build());
        typeSymbols.put(ARRAY_OF_MAP_OF_ANYDATA, types.builder().ARRAY_TYPE.withType(
                types.builder().MAP_TYPE.withTypeParam(types.ANYDATA).build()).build());
        typeSymbols.put(STRUCTURED_ARRAY, types.builder().ARRAY_TYPE
                .withType(
                        types.builder().UNION_TYPE
                                .withMemberTypes(
                                        typeSymbols.get(MAP_OF_ANYDATA),
                                        typeSymbols.get(TABLE_OF_ANYDATA_MAP),
                                        typeSymbols.get(TUPLE_OF_ANYDATA)).build()).build());
        typeSymbols.put(BYTE_ARRAY, types.builder().ARRAY_TYPE.withType(types.BYTE).build());
    }

    private static void populateBasicTypes(Map<String, TypeSymbol> typeSymbols, Types types) {
        typeSymbols.put(ANYDATA, types.ANYDATA);
        typeSymbols.put(JSON, types.JSON);
        typeSymbols.put(ERROR, types.ERROR);
        typeSymbols.put(STRING, types.STRING);
        typeSymbols.put(BOOLEAN, types.BOOLEAN);
        typeSymbols.put(INT, types.INT);
        typeSymbols.put(FLOAT, types.FLOAT);
        typeSymbols.put(DECIMAL, types.DECIMAL);
        typeSymbols.put(XML, types.XML);
        typeSymbols.put(NIL, types.NIL);
        typeSymbols.put(OBJECT, types.builder().OBJECT_TYPE.build());
        typeSymbols.put(MAP_OF_ANYDATA, types.builder().MAP_TYPE.withTypeParam(types.ANYDATA).build());
        typeSymbols.put(TABLE_OF_ANYDATA_MAP, types.builder().TABLE_TYPE.withRowType(
                typeSymbols.get(MAP_OF_ANYDATA)).build());
        typeSymbols.put(TUPLE_OF_ANYDATA, types.builder().TUPLE_TYPE.withRestType(types.ANYDATA).build());
    }

    private static void populateNilableBasicTypes(Map<String, TypeSymbol> typeSymbols, Types types) {
        typeSymbols.put(NILABLE_STRING, types.builder().UNION_TYPE.withMemberTypes(types.STRING, types.NIL).build());
        typeSymbols.put(NILABLE_BOOLEAN, types.builder().UNION_TYPE.withMemberTypes(types.BOOLEAN, types.NIL).build());
        typeSymbols.put(NILABLE_INT, types.builder().UNION_TYPE.withMemberTypes(types.INT, types.NIL).build());
        typeSymbols.put(NILABLE_FLOAT, types.builder().UNION_TYPE.withMemberTypes(types.FLOAT, types.NIL).build());
        typeSymbols.put(NILABLE_DECIMAL, types.builder().UNION_TYPE.withMemberTypes(types.DECIMAL, types.NIL).build());
        typeSymbols.put(NILABLE_MAP_OF_ANYDATA, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(MAP_OF_ANYDATA), types.NIL).build());
    }

    private static void populateNilableBasicArrayTypes(Map<String, TypeSymbol> typeSymbols, Types types) {
        typeSymbols.put(NILABLE_STRING_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(STRING_ARRAY), types.NIL).build());
        typeSymbols.put(NILABLE_BOOLEAN_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(BOOLEAN_ARRAY), types.NIL).build());
        typeSymbols.put(NILABLE_INT_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(INT_ARRAY), types.NIL).build());
        typeSymbols.put(NILABLE_FLOAT_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(FLOAT_ARRAY), types.NIL).build());
        typeSymbols.put(NILABLE_DECIMAL_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(DECIMAL_ARRAY), types.NIL).build());
        typeSymbols.put(NILABLE_MAP_OF_ANYDATA_ARRAY, types.builder().UNION_TYPE.withMemberTypes(
                typeSymbols.get(ARRAY_OF_MAP_OF_ANYDATA), types.NIL).build());
    }
}
