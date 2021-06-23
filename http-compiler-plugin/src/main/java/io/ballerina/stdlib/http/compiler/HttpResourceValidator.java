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

import io.ballerina.compiler.api.symbols.AnnotationSymbol;
import io.ballerina.compiler.api.symbols.ArrayTypeSymbol;
import io.ballerina.compiler.api.symbols.FunctionSymbol;
import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.MapTypeSymbol;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TableTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ParameterNode;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.RequiredParameterNode;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.http.compiler.Constants.BALLERINA;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_ANNOTATION_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.FIELD_RESPONSE_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.HEADER_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.HEADER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.Constants.PAYLOAD_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.REQUEST_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.RESOURCE_CONFIG_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.Constants.RESPONSE_OBJ_NAME;

/**
 * Validates a ballerina http resource.
 */
class HttpResourceValidator {

    static void validateResource(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member) {
        extractResourceAnnotationAndValidate(ctx, member);
        extractInputParamTypeAndValidate(ctx, member);
        extractReturnTypeAndValidate(ctx, member);
    }

    private static void extractResourceAnnotationAndValidate(SyntaxNodeAnalysisContext ctx,
                                                             FunctionDefinitionNode member) {
        Optional<MetadataNode> metadataNodeOptional = member.metadata();
        if (metadataNodeOptional.isEmpty()) {
            return;
        } else {
            NodeList<AnnotationNode> annotations = metadataNodeOptional.get().annotations();
            for (AnnotationNode annotation : annotations) {
                Node annotReference = annotation.annotReference();
                String annotName = annotReference.toString();
                if (annotReference.kind() == SyntaxKind.QUALIFIED_NAME_REFERENCE) {
                    String[] strings = annotName.split(":");
                    if (RESOURCE_CONFIG_ANNOTATION.equals(strings[strings.length - 1].trim())) {
                        continue;
                    }
                }
                reportInvalidResourceAnnotation(ctx, member, annotName);
            }
        }
    }

    private static void extractInputParamTypeAndValidate(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member) {
        boolean callerPresent = false;
        boolean requestPresent = false;
        boolean headersPresent = false;
        Optional<Symbol> resourceMethodSymbolOptional = ctx.semanticModel().symbol(member);
        if (resourceMethodSymbolOptional.isEmpty()) {
            return;
        }
        Optional<List<ParameterSymbol>> parametersOptional =
                ((ResourceMethodSymbol) resourceMethodSymbolOptional.get()).typeDescriptor().params();
        if (parametersOptional.isEmpty()) {
            return;
        }
        int paramIndex = -1;
        for (ParameterSymbol param : parametersOptional.get()) {
            paramIndex++;
            String paramType = param.typeDescriptor().signature();
            Optional<String> nameOptional = param.getName();
            String paramName = nameOptional.isEmpty() ? "" : nameOptional.get();

            List<AnnotationSymbol> annotations = param.annotations().stream()
                    .filter(annotationSymbol -> annotationSymbol.typeDescriptor().isPresent())
                    .collect(Collectors.toList());
            if (annotations.isEmpty()) {
                TypeDescKind kind = param.typeDescriptor().typeKind();
                TypeSymbol typeSymbol = param.typeDescriptor();
                if (kind == TypeDescKind.TYPE_REFERENCE) {
                    TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
                    TypeDescKind typeDescKind = typeDescriptor.typeKind();
                    if (typeDescKind == TypeDescKind.OBJECT) {
                        Optional<ModuleSymbol> moduleSymbolOptional = typeDescriptor.getModule();
                        if (moduleSymbolOptional.isEmpty()) {
                            reportInvalidParameterType(ctx, member, paramType);
                            continue;
                        }
                        Optional<String> nameSymbolOptional = moduleSymbolOptional.get().getName();
                        if (nameSymbolOptional.isEmpty()) {
                            reportInvalidParameterType(ctx, member, paramType);
                            continue;
                        }
                        if (!HTTP.equals(nameSymbolOptional.get())) {
                            reportInvalidParameterType(ctx, member, paramType);
                            continue;
                        }

                        Optional<String> typeNameOptional = typeDescriptor.getName();
                        if (typeNameOptional.isEmpty()) {
                            reportInvalidParameterType(ctx, member, paramType);
                            continue;
                        }
                        switch (typeNameOptional.get()) {
                            case CALLER_OBJ_NAME:
                                callerPresent = isObjectPresent(ctx, member, callerPresent, paramName,
                                                                HttpDiagnosticCodes.HTTP_115);
                                break;
                            case REQUEST_OBJ_NAME:
                                requestPresent = isObjectPresent(ctx, member, requestPresent, paramName,
                                                                 HttpDiagnosticCodes.HTTP_116);
                                break;
                            case HEADER_OBJ_NAME:
                                headersPresent = isObjectPresent(ctx, member, headersPresent, paramName,
                                                                 HttpDiagnosticCodes.HTTP_117);
                                break;
                            default:
                                reportInvalidParameterType(ctx, member, paramType);
                                break;
                        }
                    } else {
                        reportInvalidParameterType(ctx, member, paramType);
                    }
                } else if (isAllowedQueryParamType(kind)) {
                    // Allowed query param types
                } else if (kind == TypeDescKind.ARRAY) {
                    // Allowed query param array types
                    TypeSymbol arrTypeSymbol = ((ArrayTypeSymbol) typeSymbol).memberTypeDescriptor();
                    TypeDescKind elementKind = arrTypeSymbol.typeKind();
                    if (isAllowedQueryParamType(elementKind)) {
                        continue;
                    }
                } else if (kind == TypeDescKind.UNION) {
                    // Allowed query param union types
                    List<TypeSymbol> symbolList = ((UnionTypeSymbol) typeSymbol).memberTypeDescriptors();
                    int size = symbolList.size();
                    if (size > 2) {
                        reportInvalidUnionQueryType(ctx, member, paramName);
                        continue;
                    }
                    if (symbolList.stream().noneMatch(type -> type.typeKind() == TypeDescKind.NIL)) {
                        reportInvalidUnionQueryType(ctx, member, paramName);
                        continue;
                    }
                    for (TypeSymbol type : symbolList) {
                        TypeDescKind elementKind = type.typeKind();
                        if (elementKind == TypeDescKind.ARRAY) {
                            TypeSymbol arrTypeSymbol = ((ArrayTypeSymbol) type).memberTypeDescriptor();
                            TypeDescKind arrElementKind = arrTypeSymbol.typeKind();
                            if (isAllowedQueryParamType(arrElementKind)) {
                                continue;
                            }
                        } else {
                            if (elementKind == TypeDescKind.NIL || isAllowedQueryParamType(elementKind)) {
                                continue;
                            }
                        }
                        reportInvalidQueryParameterType(ctx, member, paramName);
                    }
                } else {
                    reportInvalidParameterType(ctx, member, paramType);
                }
                continue;
            }

            boolean annotated = false;
            for (AnnotationSymbol annotation : annotations) {
                Optional<TypeSymbol> typeSymbolOptional = annotation.typeDescriptor();
                if (typeSymbolOptional.isEmpty()) {
                    reportInvalidParameter(ctx, member, paramName);
                    continue;
                }

                // validate annotation module
                Optional<ModuleSymbol> moduleSymbolOptional = typeSymbolOptional.get().getModule();
                if (moduleSymbolOptional.isEmpty()) {
                    reportInvalidParameter(ctx, member, paramName);
                    continue;
                }
                Optional<String> nameSymbolOptional = moduleSymbolOptional.get().getName();
                if (nameSymbolOptional.isEmpty()) {
                    reportInvalidParameter(ctx, member, paramName);
                    continue;
                }
                if (!HTTP.equals(nameSymbolOptional.get())) {
                    reportInvalidParameterAnnotation(ctx, member, paramName);
                    continue;
                }

                // validate annotation type name
                Optional<String> annotationTypeNameOptional = typeSymbolOptional.get().getName();
                if (annotationTypeNameOptional.isEmpty()) {
                    reportInvalidParameter(ctx, member, paramName);
                    continue;
                }
                String typeName = annotationTypeNameOptional.get();
                switch (typeName) {
                    case PAYLOAD_ANNOTATION_TYPE: {
                        if (annotated) { // multiple annotations
                            reportInvalidMultipleAnnotation(ctx, member, paramName);
                            continue;
                        }
                        annotated = true;
                        TypeDescKind kind = param.typeDescriptor().typeKind();
                        if (kind == TypeDescKind.JSON || kind == TypeDescKind.STRING ||
                                kind == TypeDescKind.XML) {
                            continue;
                        } else if (kind == TypeDescKind.ARRAY) {
                            TypeSymbol arrTypeSymbol =
                                    ((ArrayTypeSymbol) param.typeDescriptor()).memberTypeDescriptor();
                            TypeDescKind elementKind = arrTypeSymbol.typeKind();
                            if (elementKind == TypeDescKind.BYTE) {
                                continue;
                            } else if (elementKind == TypeDescKind.TYPE_REFERENCE) {
                                TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) arrTypeSymbol).typeDescriptor();
                                TypeDescKind typeDescKind = typeDescriptor.typeKind();
                                if (typeDescKind == TypeDescKind.RECORD) {
                                    continue;
                                }
                            }
                        } else if (kind == TypeDescKind.TYPE_REFERENCE) {
                            TypeSymbol typeDescriptor =
                                    ((TypeReferenceTypeSymbol) param.typeDescriptor()).typeDescriptor();
                            TypeDescKind typeDescKind = typeDescriptor.typeKind();
                            if (typeDescKind == TypeDescKind.RECORD) {
                                continue;
                            }
                        }
                        String paramTypeName = param.typeDescriptor().signature();
                        reportInvalidPayloadParameterType(ctx, member, paramTypeName);
                        break;
                    }
                    case CALLER_ANNOTATION_TYPE: {
                        if (annotated) {
                            reportInvalidMultipleAnnotation(ctx, member, paramName);
                            continue;
                        }
                        annotated = true;
                        TypeDescKind kind = param.typeDescriptor().typeKind();
                        if (kind == TypeDescKind.TYPE_REFERENCE) {
                            TypeSymbol typeDescriptor =
                                    ((TypeReferenceTypeSymbol) param.typeDescriptor()).typeDescriptor();
                            TypeDescKind typeDescKind = typeDescriptor.typeKind();
                            if (typeDescKind == TypeDescKind.OBJECT) {
                                moduleSymbolOptional = typeDescriptor.getModule();
                                if (moduleSymbolOptional.isEmpty()) {
                                    reportInvalidCallerParameterType(ctx, member, paramName);
                                    continue;
                                }
                                nameSymbolOptional = moduleSymbolOptional.get().getName();
                                if (nameSymbolOptional.isEmpty()) {
                                    reportInvalidCallerParameterType(ctx, member, paramName);
                                    continue;
                                }
                                if (!HTTP.equals(nameSymbolOptional.get())) {
                                    reportInvalidCallerParameterType(ctx, member, paramName);
                                    continue;
                                }

                                Optional<String> typeNameOptional = typeDescriptor.getName();
                                if (typeNameOptional.isEmpty()) {
                                    reportInvalidCallerParameterType(ctx, member, paramName);
                                    continue;
                                }
                                String callerTypeName = typeNameOptional.get();
                                if (CALLER_OBJ_NAME.equals(callerTypeName)) {
                                    if (callerPresent) {
                                        updateDiagnostic(ctx, member, paramName, HttpDiagnosticCodes.HTTP_115);
                                    } else {
                                        callerPresent = true;
                                        extractCallerInfoValueAndValidate(ctx, member, paramIndex);
                                    }
                                } else {
                                    reportInvalidCallerParameterType(ctx, member, paramName);
                                }
                            } else {
                                reportInvalidCallerParameterType(ctx, member, paramName);
                            }
                        } else {
                            reportInvalidCallerParameterType(ctx, member, paramName);
                        }
                        break;
                    }
                    case HEADER_ANNOTATION_TYPE: {
                        if (annotated) {
                            reportInvalidMultipleAnnotation(ctx, member, paramName);
                            continue;
                        }
                        annotated = true;
                        TypeSymbol typeSymbol = param.typeDescriptor();
                        TypeDescKind kind = typeSymbol.typeKind();
                        if (kind == TypeDescKind.STRING) {
                            continue;
                        } else if (kind == TypeDescKind.ARRAY) {
                            TypeSymbol arrTypeSymbol =
                                    ((ArrayTypeSymbol) typeSymbol).memberTypeDescriptor();
                            TypeDescKind arrElementKind = arrTypeSymbol.typeKind();
                            if (arrElementKind == TypeDescKind.STRING) {
                                continue;
                            } else {
                                reportInvalidHeaderParameterType(ctx, member, paramName);
                            }
                        } else if (kind == TypeDescKind.UNION) {
                            List<TypeSymbol> symbolList = ((UnionTypeSymbol) typeSymbol).memberTypeDescriptors();
                            int size = symbolList.size();
                            if (size > 2) {
                                reportInvalidUnionHeaderType(ctx, member, paramName);
                                continue;
                            }
                            if (symbolList.stream().noneMatch(type -> type.typeKind() == TypeDescKind.NIL)) {
                                reportInvalidUnionHeaderType(ctx, member, paramName);
                                continue;
                            }
                            for (TypeSymbol type : symbolList) {
                                TypeDescKind elementKind = type.typeKind();
                                if (elementKind == TypeDescKind.ARRAY) {
                                    TypeSymbol arrTypeSymbol = ((ArrayTypeSymbol) type).memberTypeDescriptor();
                                    TypeDescKind arrElementKind = arrTypeSymbol.typeKind();
                                    if (arrElementKind != TypeDescKind.STRING) {
                                        reportInvalidHeaderParameterType(ctx, member, paramName);
                                    }
                                } else if (elementKind != TypeDescKind.NIL && elementKind != TypeDescKind.STRING) {
                                    reportInvalidHeaderParameterType(ctx, member, paramName);
                                }
                            }
                        } else {
                            reportInvalidHeaderParameterType(ctx, member, paramName);
                        }
                        break;
                    }
                    default:
                        reportInvalidParameterAnnotation(ctx, member, paramName);
                        break;
                }
            }
        }
    }

    private static boolean isObjectPresent(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                           boolean objectPresent, String paramName, HttpDiagnosticCodes code) {
        if (objectPresent) {
            updateDiagnostic(ctx, member, paramName, code);
        }
        return true;
    }

    private static void extractCallerInfoValueAndValidate(SyntaxNodeAnalysisContext ctx,
                                                          FunctionDefinitionNode member, int paramIndex) {
        ParameterNode parameterNode = member.functionSignature().parameters().get(paramIndex);
        NodeList<AnnotationNode> annotations = ((RequiredParameterNode) parameterNode).annotations();
        for (AnnotationNode annotationNode : annotations) {
            if (!annotationNode.annotReference().toString().contains(CALLER_ANNOTATION_NAME)) {
                continue;
            }
            Optional<MappingConstructorExpressionNode> annotValue = annotationNode.annotValue();
            if (annotValue.isEmpty()) {
                continue;
            }
            if (annotValue.get().fields().size() == 0) {
                continue;
            }
            SeparatedNodeList fields = annotValue.get().fields();
            for (Object node : fields) {
                SpecificFieldNode specificFieldNode = (SpecificFieldNode) node;
                if (!specificFieldNode.fieldName().toString().equals(FIELD_RESPONSE_TYPE)) {
                    continue;
                }
                String expectedType = specificFieldNode.valueExpr().get().toString();
                String callerToken = ((RequiredParameterNode) parameterNode).paramName().get().text();
                List<PositionalArgumentNode> respondParamNodes = getRespondParamNode(ctx, member, callerToken);
                if (respondParamNodes.isEmpty()) {
                    continue;
                }
                for (PositionalArgumentNode argumentNode : respondParamNodes) {
                    TypeSymbol argTypeSymbol = ctx.semanticModel().type(argumentNode.expression()).get();
                    TypeSymbol annotValueSymbol =
                            (TypeSymbol) ctx.semanticModel().symbol(specificFieldNode.valueExpr().get()).get();
                    if (!argTypeSymbol.assignableTo(annotValueSymbol)) {
                        reportInCompatibleCallerInfoType(ctx, argumentNode, expectedType);
                    }
                }
            }
        }
    }

    private static List<PositionalArgumentNode> getRespondParamNode(SyntaxNodeAnalysisContext ctx,
                                                                    FunctionDefinitionNode member, String callerToken) {
        RespondExpressionVisitor respondNodeVisitor = new RespondExpressionVisitor(ctx, callerToken);
        member.accept(respondNodeVisitor);
        return respondNodeVisitor.getRespondStatementNodes();
    }

    private static boolean isAllowedQueryParamType(TypeDescKind kind) {
        return kind == TypeDescKind.STRING || kind == TypeDescKind.INT || kind == TypeDescKind.FLOAT ||
                kind == TypeDescKind.DECIMAL || kind == TypeDescKind.BOOLEAN;
    }

    private static void extractReturnTypeAndValidate(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member) {
        Optional<ReturnTypeDescriptorNode> returnTypeDescriptorNode = member.functionSignature().returnTypeDesc();
        if (returnTypeDescriptorNode.isEmpty()) {
            return;
        }
        Node returnTypeDescriptor = returnTypeDescriptorNode.get().type();
        String returnTypeStringValue = returnTypeDescriptor.toString().split(" ")[0];

        Optional<Symbol> functionSymbol = ctx.semanticModel().symbol(member);
        if (functionSymbol.isEmpty()) {
            return;
        }
        FunctionTypeSymbol functionTypeSymbol = ((FunctionSymbol) functionSymbol.get()).typeDescriptor();

        Optional<TypeSymbol> returnTypeSymbol = functionTypeSymbol.returnTypeDescriptor();
        returnTypeSymbol.ifPresent(typeSymbol -> validateReturnType(ctx, member, returnTypeStringValue, typeSymbol));
    }

    private static void validateReturnType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                           String returnTypeStringValue, TypeSymbol returnTypeSymbol) {
        TypeDescKind kind = returnTypeSymbol.typeKind();
        if (isBasicTypeDesc(kind) || kind == TypeDescKind.ERROR || kind == TypeDescKind.NIL) {
            return;
        }
        if (kind == TypeDescKind.UNION) {
            List<TypeSymbol> typeSymbols = ((UnionTypeSymbol) returnTypeSymbol).memberTypeDescriptors();
            for (TypeSymbol typeSymbol : typeSymbols) {
                validateReturnType(ctx, member, returnTypeStringValue, typeSymbol);
            }
        } else if (kind == TypeDescKind.ARRAY) {
            TypeSymbol memberTypeDescriptor = ((ArrayTypeSymbol) returnTypeSymbol).memberTypeDescriptor();
            validateArrayElementType(ctx, member, returnTypeStringValue, memberTypeDescriptor);
        } else if (kind == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) returnTypeSymbol).typeDescriptor();
            TypeDescKind typeDescKind = typeDescriptor.typeKind();
            if (typeDescKind == TypeDescKind.OBJECT) {
                if (!isHttpModuleType(RESPONSE_OBJ_NAME, typeDescriptor)) {
                    reportInvalidReturnType(ctx, member, returnTypeStringValue);
                }
            } else if (typeDescKind != TypeDescKind.RECORD && typeDescKind != TypeDescKind.ERROR) {
                reportInvalidReturnType(ctx, member, returnTypeStringValue);
            }
        } else if (kind == TypeDescKind.MAP) {
            TypeSymbol typeSymbol = ((MapTypeSymbol) returnTypeSymbol).typeParam();
            validateReturnType(ctx, member, returnTypeStringValue, typeSymbol);
        } else if (kind == TypeDescKind.TABLE) {
            TypeSymbol typeSymbol = ((TableTypeSymbol) returnTypeSymbol).rowTypeParameter();
            if (typeSymbol == null) {
                reportInvalidReturnType(ctx, member, returnTypeStringValue);
            } else {
                validateReturnType(ctx, member, returnTypeStringValue, typeSymbol);
            }
        } else {
            reportInvalidReturnType(ctx, member, returnTypeStringValue);
        }
    }

    private static void validateArrayElementType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                                 String typeStringValue, TypeSymbol memberTypeDescriptor) {
        TypeDescKind kind = memberTypeDescriptor.typeKind();
        if (isBasicTypeDesc(kind) || kind == TypeDescKind.MAP || kind == TypeDescKind.TABLE) {
            return;
        }
        if (kind == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) memberTypeDescriptor).typeDescriptor();
            TypeDescKind typeDescKind = typeDescriptor.typeKind();
            if (typeDescKind != TypeDescKind.RECORD && typeDescKind != TypeDescKind.MAP &&
                    typeDescKind != TypeDescKind.TABLE) {
                reportInvalidReturnType(ctx, member, typeStringValue);
            }
        } else {
            reportInvalidReturnType(ctx, member, typeStringValue);
        }
    }

    private static boolean isBasicTypeDesc(TypeDescKind kind) {
        return kind == TypeDescKind.STRING || kind == TypeDescKind.INT || kind == TypeDescKind.FLOAT ||
                kind == TypeDescKind.DECIMAL || kind == TypeDescKind.BOOLEAN || kind == TypeDescKind.JSON ||
                kind == TypeDescKind.XML || kind == TypeDescKind.RECORD || kind == TypeDescKind.BYTE;
    }

    private static boolean isHttpModuleType(String expectedType, TypeSymbol typeDescriptor) {
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

    private static void reportInvalidReturnType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                                String returnType) {
        updateDiagnostic(ctx, node, returnType, HttpDiagnosticCodes.HTTP_102);
    }

    private static void reportInvalidResourceAnnotation(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                                        String annotName) {
        updateDiagnostic(ctx, node, annotName, HttpDiagnosticCodes.HTTP_103);
    }

    private static void reportInvalidParameterAnnotation(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                                         String paramName) {
        updateDiagnostic(ctx, node, paramName, HttpDiagnosticCodes.HTTP_104);
    }

    private static void reportInvalidParameter(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                               String paramName) {
        updateDiagnostic(ctx, node, paramName, HttpDiagnosticCodes.HTTP_105);
    }

    private static void reportInvalidParameterType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                                   String typeName) {
        updateDiagnostic(ctx, node, typeName, HttpDiagnosticCodes.HTTP_106);
    }

    private static void reportInvalidPayloadParameterType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                                          String typeName) {
        updateDiagnostic(ctx, node, typeName, HttpDiagnosticCodes.HTTP_107);
    }

    private static void reportInvalidMultipleAnnotation(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                                        String paramName) {
        updateDiagnostic(ctx, node, paramName, HttpDiagnosticCodes.HTTP_108);
    }

    private static void reportInvalidHeaderParameterType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                                         String paramName) {
        updateDiagnostic(ctx, node, paramName, HttpDiagnosticCodes.HTTP_109);
    }

    private static void reportInvalidUnionHeaderType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                                     String paramName) {
        updateDiagnostic(ctx, node, paramName, HttpDiagnosticCodes.HTTP_110);
    }

    private static void reportInvalidCallerParameterType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                                         String paramName) {
        updateDiagnostic(ctx, node, paramName, HttpDiagnosticCodes.HTTP_111);
    }

    private static void reportInvalidQueryParameterType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                                        String paramName) {
        updateDiagnostic(ctx, node, paramName, HttpDiagnosticCodes.HTTP_112);
    }

    private static void reportInvalidUnionQueryType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                                    String paramName) {
        updateDiagnostic(ctx, node, paramName, HttpDiagnosticCodes.HTTP_113);
    }

    private static void reportInCompatibleCallerInfoType(SyntaxNodeAnalysisContext ctx, PositionalArgumentNode node,
                                                         String paramName) {
        updateDiagnostic(ctx, node, paramName, HttpDiagnosticCodes.HTTP_114);
    }

    private static void updateDiagnostic(SyntaxNodeAnalysisContext ctx, Node node, String argName,
                                         HttpDiagnosticCodes httpDiagnosticCodes) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(httpDiagnosticCodes, argName);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location()));
    }

    private static DiagnosticInfo getDiagnosticInfo(HttpDiagnosticCodes diagnostic, Object... args) {
        return new DiagnosticInfo(diagnostic.getCode(), String.format(diagnostic.getMessage(), args),
                                  diagnostic.getSeverity());
    }
}
