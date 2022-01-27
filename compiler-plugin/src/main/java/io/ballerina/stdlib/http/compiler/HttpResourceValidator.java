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
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
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
import io.ballerina.tools.diagnostics.Location;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BSymbolicProperty;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.http.compiler.Constants.BALLERINA;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_ANNOTATION_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.FIELD_RESPONSE_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.GET;
import static io.ballerina.stdlib.http.compiler.Constants.HEAD;
import static io.ballerina.stdlib.http.compiler.Constants.HEADER_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.HEADER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.Constants.OPTIONS;
import static io.ballerina.stdlib.http.compiler.Constants.PAYLOAD_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.REQUEST_CONTEXT_OBJ_NAME;
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
        validateHttpCallerUsage(ctx, member);
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
                reportInvalidResourceAnnotation(ctx, annotReference.location(), annotName);
            }
        }
    }

    public static void extractInputParamTypeAndValidate(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member) {
        boolean callerPresent = false;
        boolean requestPresent = false;
        boolean requestCtxPresent = false;
        boolean headersPresent = false;
        boolean errorPresent = false;
        Optional<Symbol> resourceMethodSymbolOptional = ctx.semanticModel().symbol(member);
        Location paramLocation = member.location();
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
            Optional<Location> paramLocationOptional = param.getLocation();
            if (!paramLocationOptional.isEmpty()) {
                paramLocation = paramLocationOptional.get();
            }
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
                            reportInvalidParameterType(ctx, paramLocation, paramType);
                            continue;
                        }
                        Optional<String> nameSymbolOptional = moduleSymbolOptional.get().getName();
                        if (nameSymbolOptional.isEmpty()) {
                            reportInvalidParameterType(ctx, paramLocation, paramType);
                            continue;
                        }
                        if (!HTTP.equals(nameSymbolOptional.get())) {
                            reportInvalidParameterType(ctx, paramLocation, paramType);
                            continue;
                        }

                        Optional<String> typeNameOptional = typeDescriptor.getName();
                        if (typeNameOptional.isEmpty()) {
                            reportInvalidParameterType(ctx, paramLocation, paramType);
                            continue;
                        }
                        switch (typeNameOptional.get()) {
                            case CALLER_OBJ_NAME:
                                callerPresent = isObjectPresent(ctx, paramLocation, callerPresent, paramName,
                                                                HttpDiagnosticCodes.HTTP_115);
                                break;
                            case REQUEST_OBJ_NAME:
                                requestPresent = isObjectPresent(ctx, paramLocation, requestPresent, paramName,
                                                                 HttpDiagnosticCodes.HTTP_116);
                                break;
                            case REQUEST_CONTEXT_OBJ_NAME:
                                requestCtxPresent = isObjectPresent(ctx, paramLocation, requestCtxPresent, paramName,
                                                                    HttpDiagnosticCodes.HTTP_121);
                                break;
                            case HEADER_OBJ_NAME:
                                headersPresent = isObjectPresent(ctx, paramLocation, headersPresent, paramName,
                                                                 HttpDiagnosticCodes.HTTP_117);
                                break;
                            default:
                                reportInvalidParameterType(ctx, paramLocation, paramType);
                                break;
                        }
                    } else {
                        reportInvalidParameterType(ctx, paramLocation, paramType);
                    }
                } else if (isAllowedQueryParamType(kind)) {
                    // Allowed query param types
                } else if (kind == TypeDescKind.MAP) {
                    TypeSymbol constrainedTypeSymbol = ((MapTypeSymbol) typeSymbol).typeParam();
                    TypeDescKind constrainedType = constrainedTypeSymbol.typeKind();
                    if (constrainedType != TypeDescKind.JSON) {
                        reportInvalidQueryParameterType(ctx, paramLocation, paramName);
                        continue;
                    }
                } else if (kind == TypeDescKind.ARRAY) {
                    // Allowed query param array types
                    TypeSymbol arrTypeSymbol = ((ArrayTypeSymbol) typeSymbol).memberTypeDescriptor();
                    TypeDescKind elementKind = arrTypeSymbol.typeKind();
                    if (elementKind == TypeDescKind.MAP) {
                        TypeSymbol constrainedTypeSymbol = ((MapTypeSymbol) arrTypeSymbol).typeParam();
                        TypeDescKind constrainedType = constrainedTypeSymbol.typeKind();
                        if (constrainedType != TypeDescKind.JSON) {
                            reportInvalidQueryParameterType(ctx, paramLocation, paramName);
                        }
                        continue;
                    }
                    if (!isAllowedQueryParamType(elementKind)) {
                        reportInvalidQueryParameterType(ctx, paramLocation, paramName);
                        continue;
                    }
                } else if (kind == TypeDescKind.UNION) {
                    // Allowed query param union types
                    List<TypeSymbol> symbolList = ((UnionTypeSymbol) typeSymbol).memberTypeDescriptors();
                    int size = symbolList.size();
                    if (size > 2) {
                        reportInvalidUnionQueryType(ctx, paramLocation, paramName);
                        continue;
                    }
                    if (symbolList.stream().noneMatch(type -> type.typeKind() == TypeDescKind.NIL)) {
                        reportInvalidUnionQueryType(ctx, paramLocation, paramName);
                        continue;
                    }
                    for (TypeSymbol type : symbolList) {
                        TypeDescKind elementKind = type.typeKind();
                        if (elementKind == TypeDescKind.ARRAY) {
                            TypeSymbol arrTypeSymbol = ((ArrayTypeSymbol) type).memberTypeDescriptor();
                            TypeDescKind arrElementKind = arrTypeSymbol.typeKind();
                            if (arrElementKind == TypeDescKind.MAP) {
                                TypeSymbol constrainedTypeSymbol = ((MapTypeSymbol) arrTypeSymbol).typeParam();
                                TypeDescKind constrainedType = constrainedTypeSymbol.typeKind();
                                if (constrainedType == TypeDescKind.JSON) {
                                    continue;
                                }
                            }
                            if (isAllowedQueryParamType(arrElementKind)) {
                                continue;
                            }
                        } else if (elementKind == TypeDescKind.MAP) {
                            TypeSymbol constrainedTypeSymbol = ((MapTypeSymbol) type).typeParam();
                            TypeDescKind constrainedType = constrainedTypeSymbol.typeKind();
                            if (constrainedType == TypeDescKind.JSON) {
                                continue;
                            }
                        } else {
                            if (elementKind == TypeDescKind.NIL || isAllowedQueryParamType(elementKind)) {
                                continue;
                            }
                        }
                        reportInvalidQueryParameterType(ctx, paramLocation, paramName);
                    }
                } else if (kind == TypeDescKind.ERROR) {
                    errorPresent = isObjectPresent(ctx, paramLocation, errorPresent, paramName,
                            HttpDiagnosticCodes.HTTP_122);
                } else {
                    reportInvalidParameterType(ctx, paramLocation, paramType);
                }
                continue;
            }

            boolean annotated = false;
            for (AnnotationSymbol annotation : annotations) {
                Optional<TypeSymbol> typeSymbolOptional = annotation.typeDescriptor();
                if (typeSymbolOptional.isEmpty()) {
                    reportInvalidParameter(ctx, paramLocation, paramName);
                    continue;
                }
                // validate annotation module
                Optional<ModuleSymbol> moduleSymbolOptional = typeSymbolOptional.get().getModule();
                if (moduleSymbolOptional.isEmpty()) {
                    reportInvalidParameter(ctx, paramLocation, paramName);
                    continue;
                }
                Optional<String> nameSymbolOptional = moduleSymbolOptional.get().getName();
                if (nameSymbolOptional.isEmpty()) {
                    reportInvalidParameter(ctx, paramLocation, paramName);
                    continue;
                }
                if (!HTTP.equals(nameSymbolOptional.get())) {
                    reportInvalidParameterAnnotation(ctx, paramLocation, paramName);
                    continue;
                }

                // validate annotation type name
                Optional<String> annotationTypeNameOptional = typeSymbolOptional.get().getName();
                if (annotationTypeNameOptional.isEmpty()) {
                    reportInvalidParameter(ctx, paramLocation, paramName);
                    continue;
                }
                String typeName = annotationTypeNameOptional.get();
                switch (typeName) {
                    case PAYLOAD_ANNOTATION_TYPE: {
                        Optional<String> resourceMethodOptional = resourceMethodSymbolOptional.get().getName();
                        if (resourceMethodOptional.isPresent()) {
                            validatePayloadAnnotationUsage(ctx, paramLocation, resourceMethodOptional.get());
                        }
                        if (annotated) { // multiple annotations
                            reportInvalidMultipleAnnotation(ctx, paramLocation, paramName);
                            continue;
                        }
                        annotated = true;
                        TypeSymbol paramTypeDescriptor = param.typeDescriptor();
                        if (paramTypeDescriptor.typeKind() == TypeDescKind.INTERSECTION) {
                            paramTypeDescriptor =
                                    ((IntersectionTypeSymbol) param.typeDescriptor()).effectiveTypeDescriptor();
                        }
                        TypeDescKind kind = paramTypeDescriptor.typeKind();
                        if (kind == TypeDescKind.JSON || kind == TypeDescKind.STRING ||
                                kind == TypeDescKind.XML || kind == TypeDescKind.RECORD) {
                            continue;
                        } else if (kind == TypeDescKind.ARRAY) {
                            TypeSymbol arrTypeSymbol =
                                    ((ArrayTypeSymbol) paramTypeDescriptor).memberTypeDescriptor();
                            TypeDescKind elementKind = arrTypeSymbol.typeKind();
                            if (elementKind == TypeDescKind.INTERSECTION) {
                                arrTypeSymbol = ((IntersectionTypeSymbol) arrTypeSymbol).effectiveTypeDescriptor();
                                elementKind = arrTypeSymbol.typeKind();
                            }
                            if (elementKind == TypeDescKind.BYTE) {
                                continue;
                            } else if (elementKind == TypeDescKind.TYPE_REFERENCE) {
                                TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) arrTypeSymbol).typeDescriptor();
                                TypeDescKind typeDescKind = retrieveEffectiveTypeDesc(typeDescriptor);
                                if (typeDescKind == TypeDescKind.RECORD) {
                                    continue;
                                }
                            }
                        } else if (kind == TypeDescKind.TYPE_REFERENCE) {
                            TypeSymbol typeDescriptor =
                                    ((TypeReferenceTypeSymbol) paramTypeDescriptor).typeDescriptor();
                            TypeDescKind typeDescKind = retrieveEffectiveTypeDesc(typeDescriptor);
                            if (typeDescKind == TypeDescKind.RECORD) {
                                continue;
                            }
                        } else if (kind == TypeDescKind.MAP) {
                            TypeSymbol typeDescriptor = ((MapTypeSymbol) paramTypeDescriptor).typeParam();
                            TypeDescKind typeDescKind = typeDescriptor.typeKind();
                            if (typeDescKind == TypeDescKind.STRING) {
                                continue;
                            }
                        }
                        String paramTypeName = param.typeDescriptor().signature();
                        reportInvalidPayloadParameterType(ctx, paramLocation, paramTypeName);
                        break;
                    }
                    case CALLER_ANNOTATION_TYPE: {
                        if (annotated) {
                            reportInvalidMultipleAnnotation(ctx, paramLocation, paramName);
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
                                    reportInvalidCallerParameterType(ctx, paramLocation, paramName);
                                    continue;
                                }
                                nameSymbolOptional = moduleSymbolOptional.get().getName();
                                if (nameSymbolOptional.isEmpty()) {
                                    reportInvalidCallerParameterType(ctx, paramLocation, paramName);
                                    continue;
                                }
                                if (!HTTP.equals(nameSymbolOptional.get())) {
                                    reportInvalidCallerParameterType(ctx, paramLocation, paramName);
                                    continue;
                                }

                                Optional<String> typeNameOptional = typeDescriptor.getName();
                                if (typeNameOptional.isEmpty()) {
                                    reportInvalidCallerParameterType(ctx, paramLocation, paramName);
                                    continue;
                                }
                                String callerTypeName = typeNameOptional.get();
                                if (CALLER_OBJ_NAME.equals(callerTypeName)) {
                                    if (callerPresent) {
                                        HttpCompilerPluginUtil.updateDiagnostic(ctx, paramLocation, paramName,
                                                                                HttpDiagnosticCodes.HTTP_115);
                                    } else {
                                        callerPresent = true;
                                        extractCallerInfoValueAndValidate(ctx, member, paramIndex);
                                    }
                                } else {
                                    reportInvalidCallerParameterType(ctx, paramLocation, paramName);
                                }
                            } else {
                                reportInvalidCallerParameterType(ctx, paramLocation, paramName);
                            }
                        } else {
                            reportInvalidCallerParameterType(ctx, paramLocation, paramName);
                        }
                        break;
                    }
                    case HEADER_ANNOTATION_TYPE: {
                        if (annotated) {
                            reportInvalidMultipleAnnotation(ctx, paramLocation, paramName);
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
                                reportInvalidHeaderParameterType(ctx, paramLocation, paramName, param);
                            }
                        } else if (kind == TypeDescKind.UNION) {
                            List<TypeSymbol> symbolList = ((UnionTypeSymbol) typeSymbol).memberTypeDescriptors();
                            int size = symbolList.size();
                            if (size > 2) {
                                reportInvalidUnionHeaderType(ctx, paramLocation, paramName);
                                continue;
                            }
                            if (symbolList.stream().noneMatch(type -> type.typeKind() == TypeDescKind.NIL)) {
                                reportInvalidUnionHeaderType(ctx, paramLocation, paramName);
                                continue;
                            }
                            for (TypeSymbol type : symbolList) {
                                TypeDescKind elementKind = type.typeKind();
                                if (elementKind == TypeDescKind.ARRAY) {
                                    TypeSymbol arrTypeSymbol = ((ArrayTypeSymbol) type).memberTypeDescriptor();
                                    TypeDescKind arrElementKind = arrTypeSymbol.typeKind();
                                    if (arrElementKind != TypeDescKind.STRING) {
                                        reportInvalidHeaderParameterType(ctx, paramLocation, paramName, param);
                                    }
                                } else if (elementKind != TypeDescKind.NIL && elementKind != TypeDescKind.STRING) {
                                    reportInvalidHeaderParameterType(ctx, paramLocation, paramName, param);
                                }
                            }
                        } else {
                            reportInvalidHeaderParameterType(ctx, paramLocation, paramName, param);
                        }
                        break;
                    }
                    default:
                        reportInvalidParameterAnnotation(ctx, paramLocation, paramName);
                        break;
                }
            }
        }
    }

    private static void validatePayloadAnnotationUsage(SyntaxNodeAnalysisContext ctx, Location location,
                                                       String methodName) {
        if (methodName.equals(GET) || methodName.equals(HEAD) || methodName.equals(OPTIONS)) {
            reportInvalidUsageOfPayloadAnnotation(ctx, location, methodName);
        }
    }

    private static boolean isObjectPresent(SyntaxNodeAnalysisContext ctx, Location location,
                                           boolean objectPresent, String paramName, HttpDiagnosticCodes code) {
        if (objectPresent) {
            HttpCompilerPluginUtil.updateDiagnostic(ctx, location, paramName, code);
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
        Node returnTypeNode = returnTypeDescriptorNode.get().type();
        String returnTypeStringValue = getReturnTypeDescription(returnTypeDescriptorNode.get());
        Optional<Symbol> functionSymbol = ctx.semanticModel().symbol(member);
        if (functionSymbol.isEmpty()) {
            return;
        }
        FunctionTypeSymbol functionTypeSymbol = ((FunctionSymbol) functionSymbol.get()).typeDescriptor();
        Optional<TypeSymbol> returnTypeSymbol = functionTypeSymbol.returnTypeDescriptor();
        returnTypeSymbol.ifPresent(typeSymbol -> validateReturnType(ctx, returnTypeNode, returnTypeStringValue,
                typeSymbol));
    }

    private static void validateReturnType(SyntaxNodeAnalysisContext ctx, Node node,
                                           String returnTypeStringValue, TypeSymbol returnTypeSymbol) {
        TypeDescKind kind = returnTypeSymbol.typeKind();
        if (isBasicTypeDesc(kind) || kind == TypeDescKind.ERROR || kind == TypeDescKind.NIL) {
            return;
        }
        if (kind == TypeDescKind.UNION) {
            List<TypeSymbol> typeSymbols = ((UnionTypeSymbol) returnTypeSymbol).memberTypeDescriptors();
            for (TypeSymbol typeSymbol : typeSymbols) {
                validateReturnType(ctx, node, returnTypeStringValue, typeSymbol);
            }
        } else if (kind == TypeDescKind.ARRAY) {
            TypeSymbol memberTypeDescriptor = ((ArrayTypeSymbol) returnTypeSymbol).memberTypeDescriptor();
            validateArrayElementType(ctx, node, returnTypeStringValue, memberTypeDescriptor);
        } else if (kind == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) returnTypeSymbol).typeDescriptor();
            TypeDescKind typeDescKind = retrieveEffectiveTypeDesc(typeDescriptor);
            if (typeDescKind == TypeDescKind.OBJECT) {
                if (!isHttpModuleType(RESPONSE_OBJ_NAME, typeDescriptor)) {
                    reportInvalidReturnType(ctx, node, returnTypeStringValue);
                }
            } else if (typeDescKind == TypeDescKind.TABLE) {
                validateReturnType(ctx, node, returnTypeStringValue, typeDescriptor);
            } else if (typeDescKind != TypeDescKind.RECORD && typeDescKind != TypeDescKind.ERROR) {
                reportInvalidReturnType(ctx, node, returnTypeStringValue);
            }
        } else if (kind == TypeDescKind.MAP) {
            TypeSymbol typeSymbol = ((MapTypeSymbol) returnTypeSymbol).typeParam();
            validateReturnType(ctx, node, returnTypeStringValue, typeSymbol);
        } else if (kind == TypeDescKind.TABLE) {
            TypeSymbol typeSymbol = ((TableTypeSymbol) returnTypeSymbol).rowTypeParameter();
            if (typeSymbol == null) {
                reportInvalidReturnType(ctx, node, returnTypeStringValue);
            } else {
                validateReturnType(ctx, node, returnTypeStringValue, typeSymbol);
            }
        } else {
            reportInvalidReturnType(ctx, node, returnTypeStringValue);
        }
    }

    private static void validateArrayElementType(SyntaxNodeAnalysisContext ctx, Node node, String typeStringValue,
                                                    TypeSymbol memberTypeDescriptor) {
        TypeDescKind kind = memberTypeDescriptor.typeKind();
        if (isBasicTypeDesc(kind) || kind == TypeDescKind.MAP || kind == TypeDescKind.TABLE) {
            return;
        }
        if (kind == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) memberTypeDescriptor).typeDescriptor();
            TypeDescKind typeDescKind = retrieveEffectiveTypeDesc(typeDescriptor);
            if (typeDescKind != TypeDescKind.RECORD && typeDescKind != TypeDescKind.MAP &&
                    typeDescKind != TypeDescKind.TABLE) {
                reportInvalidReturnType(ctx, node, typeStringValue);
            }
        } else {
            reportInvalidReturnType(ctx, node, typeStringValue);
        }
    }

    private static TypeDescKind retrieveEffectiveTypeDesc(TypeSymbol descriptor) {
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

    public static void validateHttpCallerUsage(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member) {
        Optional<Symbol> resourceMethodSymbolOptional = ctx.semanticModel().symbol(member);
        Optional<ReturnTypeDescriptorNode> returnTypeDescOpt = member.functionSignature().returnTypeDesc();
        if (resourceMethodSymbolOptional.isEmpty() || returnTypeDescOpt.isEmpty()) {
            return;
        }
        String returnTypeDescription = getReturnTypeDescription(returnTypeDescOpt.get());
        Location returnTypeLocation = returnTypeDescOpt.get().type().location();
        ResourceMethodSymbol resourceMethod = (ResourceMethodSymbol) resourceMethodSymbolOptional.get();
        FunctionTypeSymbol typeDescriptor = resourceMethod.typeDescriptor();
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
        HttpCompilerPluginUtil.updateDiagnostic(ctx, returnTypeLocation, returnTypeDescription,
                                                HttpDiagnosticCodes.HTTP_118);
    }

    private static boolean isHttpCaller(ParameterSymbol param) {
        TypeDescKind typeDescKind = param.typeDescriptor().typeKind();
        if (TypeDescKind.TYPE_REFERENCE.equals(typeDescKind)) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) param.typeDescriptor()).typeDescriptor();
            return isHttpModuleType(CALLER_OBJ_NAME, typeDescriptor);
        }
        return false;
    }

    public static String getReturnTypeDescription(ReturnTypeDescriptorNode returnTypeDescriptorNode) {
        return returnTypeDescriptorNode.type().toString().split(" ")[0];
    }

    private static boolean isValidReturnTypeWithCaller(TypeSymbol returnTypeDescriptor) {
        TypeDescKind typeKind = returnTypeDescriptor.typeKind();
        if (TypeDescKind.UNION.equals(typeKind)) {
            return ((UnionTypeSymbol) returnTypeDescriptor)
                    .memberTypeDescriptors().stream()
                    .map(HttpResourceValidator::isValidReturnTypeWithCaller)
                    .reduce(true, (a , b) -> a && b);
        } else if (TypeDescKind.TYPE_REFERENCE.equals(typeKind)) {
            TypeSymbol typeRef = ((TypeReferenceTypeSymbol) returnTypeDescriptor).typeDescriptor();
            TypeDescKind typeRefKind = typeRef.typeKind();
            return TypeDescKind.ERROR.equals(typeRefKind) || TypeDescKind.NIL.equals(typeRefKind);
        } else {
            return TypeDescKind.ERROR.equals(typeKind) || TypeDescKind.NIL.equals(typeKind);
        }
    }

    private static void reportInvalidReturnType(SyntaxNodeAnalysisContext ctx, Node node,
                                                String returnType) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), returnType, HttpDiagnosticCodes.HTTP_102);
    }

    private static void reportInvalidResourceAnnotation(SyntaxNodeAnalysisContext ctx, Location location,
                                                        String annotName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, annotName, HttpDiagnosticCodes.HTTP_103);
    }

    private static void reportInvalidParameterAnnotation(SyntaxNodeAnalysisContext ctx, Location location,
                                                         String paramName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, paramName, HttpDiagnosticCodes.HTTP_104);
    }

    private static void reportInvalidParameter(SyntaxNodeAnalysisContext ctx, Location location,
                                               String paramName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, paramName, HttpDiagnosticCodes.HTTP_105);
    }

    private static void reportInvalidParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                   String typeName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, typeName, HttpDiagnosticCodes.HTTP_106);
    }

    private static void reportInvalidPayloadParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                          String typeName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, typeName, HttpDiagnosticCodes.HTTP_107);
    }

    private static void reportInvalidMultipleAnnotation(SyntaxNodeAnalysisContext ctx, Location location,
                                                        String paramName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, paramName, HttpDiagnosticCodes.HTTP_108);
    }

    private static void reportInvalidHeaderParameterType(SyntaxNodeAnalysisContext ctx, Location location, 
                                                         String paramName, ParameterSymbol parameterSymbol) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, paramName, HttpDiagnosticCodes.HTTP_109,
                List.of(new BSymbolicProperty(parameterSymbol)));
    }

    private static void reportInvalidUnionHeaderType(SyntaxNodeAnalysisContext ctx, Location location,
                                                     String paramName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, paramName, HttpDiagnosticCodes.HTTP_110);
    }

    private static void reportInvalidCallerParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                         String paramName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, paramName, HttpDiagnosticCodes.HTTP_111);
    }

    private static void reportInvalidQueryParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                        String paramName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, paramName, HttpDiagnosticCodes.HTTP_112);
    }

    private static void reportInvalidUnionQueryType(SyntaxNodeAnalysisContext ctx, Location location,
                                                    String paramName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, paramName, HttpDiagnosticCodes.HTTP_113);
    }

    private static void reportInCompatibleCallerInfoType(SyntaxNodeAnalysisContext ctx, PositionalArgumentNode node,
                                                         String paramName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, node.location(), paramName, HttpDiagnosticCodes.HTTP_114);
    }

    private static void reportInvalidUsageOfPayloadAnnotation(SyntaxNodeAnalysisContext ctx, Location location,
                                                              String methodName) {
        HttpCompilerPluginUtil.updateDiagnostic(ctx, location, methodName, HttpDiagnosticCodes.HTTP_129);
    }
}
