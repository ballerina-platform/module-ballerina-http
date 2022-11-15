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
import io.ballerina.compiler.api.symbols.RecordFieldSymbol;
import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TableTypeSymbol;
import io.ballerina.compiler.api.symbols.TupleTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.NameReferenceNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ParameterNode;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.RequiredParameterNode;
import io.ballerina.compiler.syntax.tree.ResourcePathParameterNode;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Location;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BSymbolicProperty;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static io.ballerina.stdlib.http.compiler.Constants.CALLER_ANNOTATION_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.EMPTY;
import static io.ballerina.stdlib.http.compiler.Constants.FIELD_RESPONSE_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.GET;
import static io.ballerina.stdlib.http.compiler.Constants.HEAD;
import static io.ballerina.stdlib.http.compiler.Constants.HEADER_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.HEADER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.Constants.LINKED_TO;
import static io.ballerina.stdlib.http.compiler.Constants.METHOD;
import static io.ballerina.stdlib.http.compiler.Constants.NAME;
import static io.ballerina.stdlib.http.compiler.Constants.OPTIONS;
import static io.ballerina.stdlib.http.compiler.Constants.PARAM;
import static io.ballerina.stdlib.http.compiler.Constants.PAYLOAD_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.RELATION;
import static io.ballerina.stdlib.http.compiler.Constants.REQUEST_CONTEXT_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.REQUEST_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.RESOURCE_CONFIG_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.Constants.SELF;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.getNodeString;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isAllowedPayloadType;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.retrieveEffectiveTypeDesc;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.updateDiagnostic;

/**
 * Validates a ballerina http resource.
 */
class HttpResourceValidator {

    static void validateResource(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                 LinksMetaData linksMetaData) {
        extractResourceAnnotationAndValidate(ctx, member, linksMetaData);
        extractInputParamTypeAndValidate(ctx, member, false);
        extractReturnTypeAndValidate(ctx, member);
        validateHttpCallerUsage(ctx, member);
    }

    private static void extractResourceAnnotationAndValidate(SyntaxNodeAnalysisContext ctx,
                                                             FunctionDefinitionNode member,
                                                             LinksMetaData linksMetaData) {
        Optional<MetadataNode> metadataNodeOptional = member.metadata();
        if (metadataNodeOptional.isEmpty()) {
            return;
        }
        NodeList<AnnotationNode> annotations = metadataNodeOptional.get().annotations();
        for (AnnotationNode annotation : annotations) {
            Node annotReference = annotation.annotReference();
            String annotName = annotReference.toString();
            if (annotReference.kind() == SyntaxKind.QUALIFIED_NAME_REFERENCE) {
                String[] strings = annotName.split(Constants.COLON);
                if (RESOURCE_CONFIG_ANNOTATION.equals(strings[strings.length - 1].trim())) {
                    validateLinksInResourceConfig(ctx, member, annotation, linksMetaData);
                    continue;
                }
            }
            reportInvalidResourceAnnotation(ctx, annotReference.location(), annotName);
        }
    }

    private static void validateLinksInResourceConfig(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                                      AnnotationNode annotation, LinksMetaData linksMetaData) {
        Optional<MappingConstructorExpressionNode> optionalMapping = annotation.annotValue();
        if (optionalMapping.isEmpty()) {
            return;
        }
        MappingConstructorExpressionNode mapping = optionalMapping.get();
        for (MappingFieldNode field : mapping.fields()) {
            if (field.kind() == SyntaxKind.SPECIFIC_FIELD) {
                String fieldName = getNodeString(((SpecificFieldNode) field).fieldName(), true);
                switch (fieldName) {
                    case NAME:
                        validateResourceNameField(ctx, member, (SpecificFieldNode) field, linksMetaData);
                        break;
                    case LINKED_TO:
                        validateLinkedToFields(ctx, (SpecificFieldNode) field, linksMetaData);
                        break;
                    default: break;
                }
            }
        }
    }

    private static void validateResourceNameField(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                                  SpecificFieldNode field, LinksMetaData linksMetaData) {
        Optional<ExpressionNode> fieldValueExpression = field.valueExpr();
        if (fieldValueExpression.isEmpty()) {
            return;
        }
        Node fieldValueNode = fieldValueExpression.get();
        if (fieldValueNode instanceof NameReferenceNode) {
            linksMetaData.markNameRefObjsAvailable();
            return;
        }
        String resourceName = getNodeString(fieldValueNode, false);
        String path = getRelativePathFromFunctionNode(member);
        String method = getNodeString(member.functionName(), false);
        if (linksMetaData.isValidLinkedResource(resourceName, path)) {
            linksMetaData.addLinkedResource(resourceName, path, method);
        } else {
            reportInvalidResourceName(ctx, field.location(), resourceName);
        }
    }

    private static String getRelativePathFromFunctionNode(FunctionDefinitionNode member) {
        NodeList<Node> nodes = member.relativeResourcePath();
        String path = EMPTY;
        for (Node node : nodes) {
            String token = node instanceof ResourcePathParameterNode ? PARAM : getNodeString(node, true);
            path = path.equals(EMPTY) ? getNodeString(node, true) : path + token;
        }
        return path;
    }

    private static void validateLinkedToFields(SyntaxNodeAnalysisContext ctx, SpecificFieldNode field,
                                               LinksMetaData linksMetaData) {
        Optional<ExpressionNode> fieldValueExpression = field.valueExpr();
        if (fieldValueExpression.isEmpty()) {
            return;
        }
        Node fieldValueNode = fieldValueExpression.get();
        Map<String, LinkedToResource> linkedResources = new HashMap<>();
        if (!(fieldValueNode instanceof ListConstructorExpressionNode)) {
            return;
        }
        for (Node node : ((ListConstructorExpressionNode) fieldValueNode).expressions()) {
            populateLinkedToResources(ctx, linkedResources, node);
        }
        linksMetaData.addLinkedToResourceMap(linkedResources);
    }

    private static void populateLinkedToResources(SyntaxNodeAnalysisContext ctx,
                                                  Map<String, LinkedToResource> linkedResources, Node node) {
        if (!(node instanceof MappingConstructorExpressionNode)) {
            return;
        }
        String name = null;
        String method = null;
        String relation = SELF;
        boolean nameRefMethodAvailable = false;
        for (Node fieldNode : ((MappingConstructorExpressionNode) node).fields()) {
            if (!(fieldNode instanceof SpecificFieldNode)) {
                continue;
            }
            String linkedToFieldName = getNodeString(((SpecificFieldNode) fieldNode).fieldName(), true);
            Optional<ExpressionNode> linkedToFieldValueExpression = ((SpecificFieldNode) fieldNode).valueExpr();
            if (linkedToFieldValueExpression.isEmpty()) {
                continue;
            }
            Node linkedToFieldValue = linkedToFieldValueExpression.get();
            if (linkedToFieldValue instanceof NameReferenceNode) {
                if (!linkedToFieldName.equals(METHOD)) {
                    break;
                } else {
                    nameRefMethodAvailable = true;
                    continue;
                }
            }
            switch (linkedToFieldName) {
                case NAME:
                    name = getNodeString(linkedToFieldValue, false);
                    break;
                case RELATION:
                    relation = getNodeString(linkedToFieldValue, false);
                    break;
                case METHOD:
                    method = getNodeString(linkedToFieldValue, false);
                    break;
                default: break;
            }
        }
        if (Objects.nonNull(name)) {
            if (linkedResources.containsKey(relation)) {
                reportInvalidLinkRelation(ctx, node.location(), relation);
                return;
            }
            linkedResources.put(relation, new LinkedToResource(name, method, node, nameRefMethodAvailable));
        }
    }

    public static void extractInputParamTypeAndValidate(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                                        boolean isErrorInterceptor) {
        boolean callerPresent = false;
        boolean requestPresent = false;
        boolean requestCtxPresent = false;
        boolean headersPresent = false;
        boolean errorPresent = false;
        boolean payloadAnnotationPresent = false;
        boolean headerAnnotationPresent = false;
        Optional<Symbol> resourceMethodSymbolOptional = ctx.semanticModel().symbol(member);
        Location paramLocation = member.location();
        if (resourceMethodSymbolOptional.isEmpty()) {
            return;
        }
        Optional<String> resourceMethodOptional = resourceMethodSymbolOptional.get().getName();
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
            if (paramLocationOptional.isPresent()) {
                paramLocation = paramLocationOptional.get();
            }
            Optional<String> nameOptional = param.getName();
            String paramName = nameOptional.isEmpty() ? "" : nameOptional.get();

            List<AnnotationSymbol> annotations = param.annotations().stream()
                    .filter(annotationSymbol -> annotationSymbol.typeDescriptor().isPresent())
                    .collect(Collectors.toList());
            if (annotations.isEmpty()) {
                TypeSymbol typeSymbol = param.typeDescriptor();
                String typeName = typeSymbol.signature();
                if (typeSymbol.typeKind() == TypeDescKind.INTERSECTION) {
                    typeSymbol = getEffectiveTypeFromReadonlyIntersection((IntersectionTypeSymbol) typeSymbol);
                    if (typeSymbol == null) {
                        reportInvalidIntersectionType(ctx, paramLocation, typeName);
                        continue;
                    }
                }
                TypeDescKind kind = typeSymbol.typeKind();
                if (kind == TypeDescKind.TYPE_REFERENCE) {
                    if (param.typeDescriptor().typeKind() == TypeDescKind.INTERSECTION) {
                        reportInvalidIntersectionObjectType(ctx, paramLocation, paramName, typeName);
                        continue;
                    }
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
                        if (!isAllowedQueryParamType(typeDescKind, typeDescriptor)) {
                            reportInvalidParameterType(ctx, paramLocation, paramType);
                        }
                    }
                } else if (isAllowedQueryParamType(kind, typeSymbol)) {
                    // Allowed query param types
                } else if (kind == TypeDescKind.MAP) {
                    TypeSymbol constrainedTypeSymbol = ((MapTypeSymbol) typeSymbol).typeParam();
                    TypeDescKind constrainedType = getReferencedTypeDescKind(constrainedTypeSymbol);
                    if (constrainedType != TypeDescKind.JSON) {
                        reportInvalidQueryParameterType(ctx, paramLocation, paramName);
                        continue;
                    }
                } else if (kind == TypeDescKind.ARRAY) {
                    // Allowed query param array types
                    TypeSymbol arrTypeSymbol = ((ArrayTypeSymbol) typeSymbol).memberTypeDescriptor();
                    TypeDescKind elementKind = getReferencedTypeDescKind(arrTypeSymbol);
                    if (elementKind == TypeDescKind.MAP) {
                        TypeSymbol constrainedTypeSymbol = ((MapTypeSymbol) arrTypeSymbol).typeParam();
                        TypeDescKind constrainedType = constrainedTypeSymbol.typeKind();
                        if (constrainedType != TypeDescKind.JSON) {
                            reportInvalidQueryParameterType(ctx, paramLocation, paramName);
                        }
                        continue;
                    }
                    if (!isAllowedQueryParamType(elementKind, arrTypeSymbol)) {
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
                        TypeDescKind elementKind = getReferencedTypeDescKind(type);
                        if (elementKind == TypeDescKind.ARRAY) {
                            TypeSymbol arrTypeSymbol = ((ArrayTypeSymbol) type).memberTypeDescriptor();
                            TypeDescKind arrElementKind = getReferencedTypeDescKind(arrTypeSymbol);
                            if (arrElementKind == TypeDescKind.MAP) {
                                TypeSymbol constrainedTypeSymbol = ((MapTypeSymbol) arrTypeSymbol).typeParam();
                                TypeDescKind constrainedType = constrainedTypeSymbol.typeKind();
                                if (constrainedType == TypeDescKind.JSON) {
                                    continue;
                                }
                            }
                            if (isAllowedQueryParamType(arrElementKind, arrTypeSymbol)) {
                                continue;
                            }
                        } else if (elementKind == TypeDescKind.MAP) {
                            TypeSymbol constrainedTypeSymbol = ((MapTypeSymbol) type).typeParam();
                            TypeDescKind constrainedType = constrainedTypeSymbol.typeKind();
                            if (constrainedType == TypeDescKind.JSON) {
                                continue;
                            }
                        } else {
                            if (elementKind == TypeDescKind.NIL || isAllowedQueryParamType(elementKind, type)) {
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
                TypeSymbol typeDescriptor = param.typeDescriptor();
                if (typeDescriptor.typeKind() == TypeDescKind.INTERSECTION) {
                    typeDescriptor = getEffectiveTypeFromReadonlyIntersection((IntersectionTypeSymbol) typeDescriptor);
                    if (typeDescriptor == null) {
                        reportInvalidIntersectionType(ctx, paramLocation, typeName);
                        continue;
                    }
                }
                TypeDescKind kind = typeDescriptor.typeKind();
                switch (typeName) {
                    case PAYLOAD_ANNOTATION_TYPE: {
                        payloadAnnotationPresent = true;
                        if (resourceMethodOptional.isPresent()) {
                            validatePayloadAnnotationUsage(ctx, paramLocation, resourceMethodOptional.get());
                        }
                        if (annotated) { // multiple annotations
                            reportInvalidMultipleAnnotation(ctx, paramLocation, paramName);
                            continue;
                        }
                        annotated = true;
                        if (isValidPayloadParamType(typeDescriptor, ctx, paramLocation, paramName, false)) {
                            continue;
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
                        if (kind == TypeDescKind.TYPE_REFERENCE) {
                            typeDescriptor = ((TypeReferenceTypeSymbol) typeDescriptor).typeDescriptor();
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
                                        updateDiagnostic(ctx, paramLocation, HttpDiagnosticCodes.HTTP_115, paramName);
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
                        headerAnnotationPresent = true;
                        if (annotated) {
                            reportInvalidMultipleAnnotation(ctx, paramLocation, paramName);
                            continue;
                        }
                        annotated = true;
                        validateHeaderParamType(ctx, paramLocation, param, paramName, typeDescriptor);
                        break;
                    }
                    default:
                        reportInvalidParameterAnnotation(ctx, paramLocation, paramName);
                        break;
                }
            }
        }
        if (isErrorInterceptor && !errorPresent) {
            HttpCompilerPluginUtil.reportMissingParameterError(ctx, member.location(), Constants.RESOURCE_KEYWORD);
        }
        if (resourceMethodOptional.isPresent() && !payloadAnnotationPresent) {
            enableAddPayloadParamCodeAction(ctx, member.functionSignature().location(), resourceMethodOptional.get());
        }
        if (!headerAnnotationPresent) {
            enableAddHeaderParamCodeAction(ctx, member.functionSignature().location());
        }
    }

    private static boolean isValidPayloadParamType(TypeSymbol typeDescriptor, SyntaxNodeAnalysisContext ctx,
                                                   Location paramLocation, String paramName, boolean isRecordField) {
        TypeDescKind kind = typeDescriptor.typeKind();
        if (kind == TypeDescKind.INTERSECTION) {
            typeDescriptor = getEffectiveTypeFromReadonlyIntersection((IntersectionTypeSymbol) typeDescriptor);
            if (typeDescriptor == null) {
                reportInvalidIntersectionType(ctx, paramLocation, paramName);
                return false;
            }
            return isValidPayloadParamType(typeDescriptor, ctx, paramLocation, paramName, isRecordField);
        }
        if (isAllowedPayloadType(kind) || kind == TypeDescKind.SINGLETON) {
            return true;
        } else if (kind == TypeDescKind.RECORD) {
            Map<String, RecordFieldSymbol> recordFieldSymbols = ((RecordTypeSymbol) typeDescriptor).fieldDescriptors();
            final TypeSymbol effectiveParentType = typeDescriptor;
            List<RecordFieldSymbol> erroneousFields = recordFieldSymbols.values().stream()
                    .filter(fieldSymbol -> {
                        TypeSymbol fieldTypeSymbol = fieldSymbol.typeDescriptor();
                        return !isValidRecordParam(
                                List.of(effectiveParentType), fieldTypeSymbol, ctx, paramLocation, paramName);
                    }).collect(Collectors.toList());
            erroneousFields.forEach(fieldSymbol -> {
                TypeSymbol fieldTypeSymbol = fieldSymbol.typeDescriptor();
                reportInvalidRecordFieldType(ctx, paramLocation, paramName, fieldTypeSymbol.signature());
            });
            return erroneousFields.isEmpty();
        } else if (kind == TypeDescKind.ARRAY) {
            TypeSymbol arrTypeSymbol = ((ArrayTypeSymbol) typeDescriptor).memberTypeDescriptor();
            TypeDescKind elementKind = arrTypeSymbol.typeKind();
            if (elementKind == TypeDescKind.INTERSECTION) {
                arrTypeSymbol = ((IntersectionTypeSymbol) arrTypeSymbol).effectiveTypeDescriptor();
                elementKind = arrTypeSymbol.typeKind();
            }
            if (elementKind == TypeDescKind.BYTE) {
                return true;
            }
            return isValidPayloadParamType(arrTypeSymbol, ctx, paramLocation, paramName, isRecordField);
        } else if (kind == TypeDescKind.TYPE_REFERENCE) {
            return isValidTypeReferencedPayloadParam(typeDescriptor, ctx, paramLocation, paramName, isRecordField);
        } else if (kind == TypeDescKind.MAP) {
            typeDescriptor = ((MapTypeSymbol) typeDescriptor).typeParam();
            return isValidPayloadParamType(typeDescriptor, ctx, paramLocation, paramName, isRecordField);
        } else if (kind == TypeDescKind.TABLE) {
            typeDescriptor = ((TableTypeSymbol) typeDescriptor).rowTypeParameter();
            return isValidPayloadParamType(typeDescriptor, ctx, paramLocation, paramName, isRecordField);
        } else if (kind == TypeDescKind.UNION) {
            List<TypeSymbol> typeDescriptors = ((UnionTypeSymbol) typeDescriptor).memberTypeDescriptors();
            for (TypeSymbol symbol: typeDescriptors) {
                if (!isValidPayloadParamType(symbol, ctx, paramLocation, paramName, isRecordField)) {
                    return false;
                }
            }
            return true;
        } else if (kind == TypeDescKind.TUPLE && isRecordField) {
            List<TypeSymbol> tupleFieldSymbols = ((TupleTypeSymbol) typeDescriptor).memberTypeDescriptors();
            tupleFieldSymbols.forEach(field -> {
                if (!isValidPayloadParamType(field, ctx, paramLocation, paramName, true)) {
                    reportInvalidRecordFieldType(ctx, paramLocation, paramName, field.signature());
                }
            });
            return true;
        }
        return false;
    }

    private static boolean isValidTypeReferencedPayloadParam(TypeSymbol typeDescriptor, SyntaxNodeAnalysisContext ctx,
                                                             Location paramLocation, String paramName,
                                                             boolean isRecordField) {
        typeDescriptor = ((TypeReferenceTypeSymbol) typeDescriptor).typeDescriptor();
        String typeName = typeDescriptor.signature();
        TypeDescKind typeDescKind = typeDescriptor.typeKind();
        if (typeDescKind == TypeDescKind.INTERSECTION) {
            typeDescriptor = getEffectiveTypeFromReadonlyIntersection((IntersectionTypeSymbol) typeDescriptor);
            if (typeDescriptor == null) {
                reportInvalidIntersectionType(ctx, paramLocation, typeName);
                return true;
            }
            typeDescKind = typeDescriptor.typeKind();
        }
        if (typeDescKind == TypeDescKind.RECORD) {
            Map<String, RecordFieldSymbol> recordFieldSymbols =
                    ((RecordTypeSymbol) typeDescriptor).fieldDescriptors();
            final TypeSymbol effectiveParentType = typeDescriptor;
            recordFieldSymbols.forEach((key, value) -> {
                TypeSymbol fieldTypeSymbol = value.typeDescriptor();
                boolean validParam = isValidRecordParam(
                        List.of(effectiveParentType), fieldTypeSymbol, ctx, paramLocation, paramName);
                if (!validParam) {
                    reportInvalidRecordFieldType(ctx, paramLocation, paramName, fieldTypeSymbol.signature());
                }
            });
            return true;
        } else {
            return isValidPayloadParamType(typeDescriptor, ctx, paramLocation, paramName, isRecordField);
        }
    }

    private static boolean isValidRecordParam(List<TypeSymbol> parentTypes, TypeSymbol typeDescriptor,
                                              SyntaxNodeAnalysisContext ctx, Location paramLocation, String paramName) {
        if (typeDescriptor.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol effectiveTypeDescriptor = ((TypeReferenceTypeSymbol) typeDescriptor).typeDescriptor();
            if (effectiveTypeDescriptor.typeKind() == TypeDescKind.RECORD) {
                List<TypeSymbol> newParentTypes = getParentTypes(effectiveTypeDescriptor, parentTypes);
                return validateRecordTypeField(
                        newParentTypes, ctx, paramLocation, paramName, (RecordTypeSymbol) effectiveTypeDescriptor);
            }
        } else if (typeDescriptor.typeKind() == TypeDescKind.RECORD) {
            List<TypeSymbol> newParentTypes = getParentTypes(typeDescriptor, parentTypes);
            return validateRecordTypeField(
                    newParentTypes, ctx, paramLocation, paramName, (RecordTypeSymbol) typeDescriptor);
        }
        return isValidPayloadParamType(typeDescriptor, ctx, paramLocation, paramName, true);
    }

    private static List<TypeSymbol> getParentTypes(TypeSymbol currentParent, List<TypeSymbol> parentTypes) {
        List<TypeSymbol> newParentTypes = new ArrayList<>(parentTypes);
        if (!newParentTypes.contains(currentParent)) {
            newParentTypes.add(currentParent);
        }
        return newParentTypes;
    }

    private static boolean validateRecordTypeField(List<TypeSymbol> parentTypes, SyntaxNodeAnalysisContext ctx,
                                                   Location paramLocation, String paramName,
                                                   RecordTypeSymbol typeDescriptor) {
        Map<String, RecordFieldSymbol> recordFields = typeDescriptor.fieldDescriptors();
        return recordFields.values().stream()
                .map(RecordFieldSymbol::typeDescriptor)
                .flatMap(ts -> getFlatTypes(ts).stream())
                .filter(ts -> parentTypes.stream().noneMatch(parentType -> parentType.equals(ts)))
                .map(ts -> isValidRecordParam(parentTypes, ts, ctx, paramLocation, paramName))
                .reduce(true, (a, b) -> a && b);
    }

    private static List<TypeSymbol> getFlatTypes(TypeSymbol typeDescriptor) {
        TypeDescKind typeKind = typeDescriptor.typeKind();
        if (typeKind == TypeDescKind.ARRAY) {
            // we have to use this approach because a collection could have elements of a reference-type, in order to
            // get the flat type, we hv to re-evaluate the member-type descriptor for a collection.
            // collection can be an array, map, table or a tuple.
            return Stream.of(((ArrayTypeSymbol) typeDescriptor).memberTypeDescriptor())
                    .flatMap(ts -> getFlatTypes(ts).stream())
                    .collect(Collectors.toList());
        } else if (typeKind == TypeDescKind.MAP) {
            return Stream.of(((MapTypeSymbol) typeDescriptor).typeParam())
                    .flatMap(ts -> getFlatTypes(ts).stream())
                    .collect(Collectors.toList());
        } else if (typeKind == TypeDescKind.TABLE) {
            return Stream.of(((TableTypeSymbol) typeDescriptor).rowTypeParameter())
                    .flatMap(ts -> getFlatTypes(ts).stream())
                    .collect(Collectors.toList());
        } else if (typeKind == TypeDescKind.TUPLE) {
            return ((TupleTypeSymbol) typeDescriptor).memberTypeDescriptors().stream()
                    .flatMap(ts -> getFlatTypes(ts).stream())
                    .collect(Collectors.toList());
        } else if (typeKind == TypeDescKind.TYPE_REFERENCE) {
            return List.of(((TypeReferenceTypeSymbol) typeDescriptor).typeDescriptor());
        }
        return List.of(typeDescriptor);
    }

    private static void validateHeaderParamType(SyntaxNodeAnalysisContext ctx, Location paramLocation, Symbol param,
                                                String paramName, TypeSymbol paramTypeDescriptor) {
        switch (paramTypeDescriptor.typeKind()) {
            case STRING:
            case INT:
            case DECIMAL:
            case FLOAT:
            case BOOLEAN:
                break;
            case ARRAY:
                TypeSymbol arrTypeSymbol = ((ArrayTypeSymbol) paramTypeDescriptor).memberTypeDescriptor();
                TypeDescKind arrElementKind = arrTypeSymbol.typeKind();
                checkAllowedHeaderParamTypes(ctx, paramLocation, param, paramName, arrElementKind);
                break;
            case UNION:
                List<TypeSymbol> symbolList = ((UnionTypeSymbol) paramTypeDescriptor).memberTypeDescriptors();
                int size = symbolList.size();
                if (size > 2) {
                    reportInvalidUnionHeaderType(ctx, paramLocation, paramName);
                    return;
                }
                if (symbolList.stream().noneMatch(type -> type.typeKind() == TypeDescKind.NIL)) {
                    reportInvalidUnionHeaderType(ctx, paramLocation, paramName);
                    return;
                }
                for (TypeSymbol type : symbolList) {
                    TypeDescKind elementKind = type.typeKind();
                    if (elementKind == TypeDescKind.ARRAY) {
                        elementKind = ((ArrayTypeSymbol) type).memberTypeDescriptor().typeKind();
                        checkAllowedHeaderParamUnionType(ctx, paramLocation, param, paramName, elementKind);
                        continue;
                    }
                    if (elementKind == TypeDescKind.TYPE_REFERENCE) {
                        validateHeaderParamType(ctx, paramLocation, param, paramName, type);
                        return;
                    }
                    checkAllowedHeaderParamTypes(ctx, paramLocation, param, paramName, elementKind);
                }
                break;
            case TYPE_REFERENCE:
                TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) paramTypeDescriptor).typeDescriptor();
                TypeDescKind typeDescKind = typeDescriptor.typeKind();
                if (typeDescKind == TypeDescKind.RECORD) {
                    validateHeaderRecordFields(ctx, paramLocation, typeDescriptor);
                } else {
                    reportInvalidHeaderParameterType(ctx, paramLocation, paramName, param);
                }
                break;
            case RECORD:
                validateHeaderRecordFields(ctx, paramLocation, paramTypeDescriptor);
                break;
            default:
                reportInvalidHeaderParameterType(ctx, paramLocation, paramName, param);
                break;
        }
    }

    private static void checkAllowedHeaderParamTypes(SyntaxNodeAnalysisContext ctx, Location paramLocation,
                                                     Symbol param, String paramName, TypeDescKind elementKind) {
        if (!isAllowedHeaderParamPureType(elementKind)) {
            reportInvalidHeaderParameterType(ctx, paramLocation, paramName, param);
        }
    }


    private static void checkAllowedHeaderParamUnionType(SyntaxNodeAnalysisContext ctx, Location paramLocation,
                                                     Symbol param, String paramName, TypeDescKind elementKind) {
        if (!isAllowedHeaderParamPureType(elementKind)) {
            reportInvalidUnionHeaderType(ctx, paramLocation, paramName);
        }
    }

    private static boolean isAllowedHeaderParamPureType(TypeDescKind elementKind) {
        return elementKind == TypeDescKind.NIL || elementKind == TypeDescKind.STRING ||
                elementKind == TypeDescKind.INT || elementKind == TypeDescKind.FLOAT ||
                elementKind == TypeDescKind.DECIMAL || elementKind == TypeDescKind.BOOLEAN;
    }

    private static void validateHeaderRecordFields(SyntaxNodeAnalysisContext ctx, Location paramLocation,
                                                   TypeSymbol typeDescriptor) {
        RecordTypeSymbol recordTypeSymbol = (RecordTypeSymbol) typeDescriptor;
        Map<String, RecordFieldSymbol> recordFieldSymbolMap = recordTypeSymbol.fieldDescriptors();
        for (Map.Entry<String, RecordFieldSymbol> entry : recordFieldSymbolMap.entrySet()) {
            RecordFieldSymbol value = entry.getValue();
            typeDescriptor = value.typeDescriptor();
            String typeName = typeDescriptor.signature();
            TypeDescKind typeDescKind = typeDescriptor.typeKind();
            if (typeDescKind == TypeDescKind.INTERSECTION) {
                typeDescriptor = getEffectiveTypeFromReadonlyIntersection((IntersectionTypeSymbol) typeDescriptor);
                if (typeDescriptor == null) {
                    reportInvalidIntersectionType(ctx, paramLocation, typeName);
                    continue;
                }
            }
            validateHeaderParamType(ctx, paramLocation, value, entry.getKey(), typeDescriptor);
        }
        Optional<TypeSymbol> restTypeDescriptor = recordTypeSymbol.restTypeDescriptor();
        if (restTypeDescriptor.isPresent()) {
            reportInvalidHeaderRecordRestFieldType(ctx, paramLocation);
        }
    }

    private static void enableAddPayloadParamCodeAction(SyntaxNodeAnalysisContext ctx, Location location,
                                                        String methodName) {
        if (!methodName.equals(GET) && !methodName.equals(HEAD) && !methodName.equals(OPTIONS)) {
            updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_HINT_101);
        }
    }

    private static void enableAddHeaderParamCodeAction(SyntaxNodeAnalysisContext ctx, Location location) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_HINT_102);
    }

    private static void validatePayloadAnnotationUsage(SyntaxNodeAnalysisContext ctx, Location location,
                                                       String methodName) {
        if (methodName.equals(GET) || methodName.equals(HEAD) || methodName.equals(OPTIONS)) {
            reportInvalidUsageOfPayloadAnnotation(ctx, location, methodName, HttpDiagnosticCodes.HTTP_129);
        }
    }

    private static boolean isObjectPresent(SyntaxNodeAnalysisContext ctx, Location location,
                                           boolean objectPresent, String paramName, HttpDiagnosticCodes code) {
        if (objectPresent) {
            updateDiagnostic(ctx, location, code, paramName);
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

    private static boolean isAllowedQueryParamType(TypeDescKind kind, TypeSymbol typeSymbol) {
        if (kind == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
            kind =  getReferencedTypeDescKind(typeDescriptor);
        }
        return kind == TypeDescKind.STRING || kind == TypeDescKind.INT || kind == TypeDescKind.FLOAT ||
                kind == TypeDescKind.DECIMAL || kind == TypeDescKind.BOOLEAN;
    }

    private static void extractReturnTypeAndValidate(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member) {
        Optional<ReturnTypeDescriptorNode> returnTypeDescriptorNode = member.functionSignature().returnTypeDesc();
        if (returnTypeDescriptorNode.isEmpty()) {
            return;
        }
        Node returnTypeNode = returnTypeDescriptorNode.get().type();
        String returnTypeStringValue = HttpCompilerPluginUtil.getReturnTypeDescription(returnTypeDescriptorNode.get());
        Optional<Symbol> functionSymbol = ctx.semanticModel().symbol(member);
        if (functionSymbol.isEmpty()) {
            return;
        }
        FunctionTypeSymbol functionTypeSymbol = ((FunctionSymbol) functionSymbol.get()).typeDescriptor();
        Optional<TypeSymbol> returnTypeSymbol = functionTypeSymbol.returnTypeDescriptor();
        if (returnTypeSymbol.isEmpty()) {
            return;
        }
        HttpCompilerPluginUtil.validateReturnType(ctx, returnTypeNode, returnTypeStringValue, returnTypeSymbol.get(),
                                                  HttpDiagnosticCodes.HTTP_102, false);
        validateAnnotationsAndEnableCodeActions(ctx, returnTypeNode, returnTypeSymbol.get(), returnTypeStringValue,
                                                returnTypeDescriptorNode.get());
    }

    private static void validateAnnotationsAndEnableCodeActions(SyntaxNodeAnalysisContext ctx, Node returnTypeNode,
                                                                TypeSymbol returnTypeSymbol, String returnTypeString,
                                                                ReturnTypeDescriptorNode returnTypeDescriptorNode) {
        boolean payloadAnnotationPresent = false;
        boolean cacheAnnotationPresent = false;
        NodeList<AnnotationNode> annotations = returnTypeDescriptorNode.annotations();
        for (AnnotationNode annotation : annotations) {
            Node annotReference = annotation.annotReference();
            String annotName = annotReference.toString();
            if (annotReference.kind() == SyntaxKind.QUALIFIED_NAME_REFERENCE) {
                String[] strings = annotName.split(Constants.COLON);
                if (Constants.PAYLOAD_ANNOTATION.equals(strings[strings.length - 1].trim())) {
                    payloadAnnotationPresent = true;
                } else if (Constants.CACHE_ANNOTATION.equals(strings[strings.length - 1].trim())) {
                    cacheAnnotationPresent = true;
                }
            }
        }
        if (checkForSupportedReturnTypes(returnTypeSymbol)) {
            if (!payloadAnnotationPresent) {
                enableConfigureReturnMediaTypeCodeAction(ctx, returnTypeNode);
            }
            if (!cacheAnnotationPresent) {
                enableResponseCacheConfigCodeAction(ctx, returnTypeNode);
            }
        } else {
            if (payloadAnnotationPresent) {
                reportInvalidUsageOfPayloadAnnotation(ctx, returnTypeNode.location(), returnTypeString,
                        HttpDiagnosticCodes.HTTP_131);
            }
            if (cacheAnnotationPresent) {
                reportInvalidUsageOfCacheAnnotation(ctx, returnTypeNode.location(), returnTypeString);
            }
        }
    }

    private static void enableConfigureReturnMediaTypeCodeAction(SyntaxNodeAnalysisContext ctx, Node node) {
        updateDiagnostic(ctx, node.location(), HttpDiagnosticCodes.HTTP_HINT_103);
    }

    private static void enableResponseCacheConfigCodeAction(SyntaxNodeAnalysisContext ctx, Node node) {
        updateDiagnostic(ctx, node.location(), HttpDiagnosticCodes.HTTP_HINT_104);
    }

    private static boolean checkForSupportedReturnTypes(TypeSymbol returnTypeSymbol) {
        TypeDescKind kind = returnTypeSymbol.typeKind();
        if (kind == TypeDescKind.ERROR || kind == TypeDescKind.NIL) {
            return false;
        }
        if (kind == TypeDescKind.UNION) {
            List<TypeSymbol> typeSymbols = ((UnionTypeSymbol) returnTypeSymbol).memberTypeDescriptors();
            if (typeSymbols.size() == 2) {
                return checkForSupportedReturnTypes(typeSymbols.get(0))
                        || checkForSupportedReturnTypes(typeSymbols.get(1));
            }
        } else if (kind == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) returnTypeSymbol).typeDescriptor();
            TypeDescKind typeDescKind = retrieveEffectiveTypeDesc(typeDescriptor);
            return typeDescKind != TypeDescKind.ERROR;
        }
        return true;
    }

    private static TypeSymbol getEffectiveTypeFromReadonlyIntersection(IntersectionTypeSymbol intersectionTypeSymbol) {
        List<TypeSymbol> effectiveTypes = new ArrayList<>();
        for (TypeSymbol typeSymbol : intersectionTypeSymbol.memberTypeDescriptors()) {
            if (typeSymbol.typeKind() == TypeDescKind.READONLY) {
                continue;
            }
            effectiveTypes.add(typeSymbol);
        }
        if (effectiveTypes.size() == 1) {
            return effectiveTypes.get(0);
        }
        return null;
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
        updateDiagnostic(ctx, returnTypeLocation, HttpDiagnosticCodes.HTTP_118,
                                                returnTypeDescription
        );
    }

    public static boolean isHttpCaller(ParameterSymbol param) {
        TypeDescKind typeDescKind = param.typeDescriptor().typeKind();
        if (TypeDescKind.TYPE_REFERENCE.equals(typeDescKind)) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) param.typeDescriptor()).typeDescriptor();
            return HttpCompilerPluginUtil.isHttpModuleType(CALLER_OBJ_NAME, typeDescriptor);
        }
        return false;
    }

    public static String getReturnTypeDescription(ReturnTypeDescriptorNode returnTypeDescriptorNode) {
        return returnTypeDescriptorNode.type().toString().trim();
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

    private static TypeDescKind getReferencedTypeDescKind(TypeSymbol typeSymbol) {
        TypeDescKind kind = typeSymbol.typeKind();
        if (kind == TypeDescKind.TYPE_REFERENCE) {
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
            kind = getReferencedTypeDescKind(typeDescriptor);
        }
        return kind;
    }

    private static void reportInvalidResourceAnnotation(SyntaxNodeAnalysisContext ctx, Location location,
                                                        String annotName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_103, annotName);
    }

    private static void reportInvalidParameterAnnotation(SyntaxNodeAnalysisContext ctx, Location location,
                                                         String paramName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_104, paramName);
    }

    private static void reportInvalidParameter(SyntaxNodeAnalysisContext ctx, Location location,
                                               String paramName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_105, paramName);
    }

    private static void reportInvalidParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                   String typeName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_106, typeName);
    }

    private static void reportInvalidPayloadParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                          String typeName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_107, typeName);
    }

    private static void reportInvalidMultipleAnnotation(SyntaxNodeAnalysisContext ctx, Location location,
                                                        String paramName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_108, paramName);
    }

    private static void reportInvalidHeaderParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                         String paramName, Symbol parameterSymbol) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_109, List.of(new BSymbolicProperty(parameterSymbol))
                , paramName);
    }

    private static void reportInvalidUnionHeaderType(SyntaxNodeAnalysisContext ctx, Location location,
                                                     String paramName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_110, paramName);
    }

    private static void reportInvalidCallerParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                         String paramName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_111, paramName);
    }

    private static void reportInvalidQueryParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                        String paramName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_112, paramName);
    }

    private static void reportInvalidUnionQueryType(SyntaxNodeAnalysisContext ctx, Location location,
                                                    String paramName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_113, paramName);
    }

    private static void reportInCompatibleCallerInfoType(SyntaxNodeAnalysisContext ctx, PositionalArgumentNode node,
                                                         String paramName) {
        updateDiagnostic(ctx, node.location(), HttpDiagnosticCodes.HTTP_114, paramName);
    }

    private static void reportInvalidUsageOfPayloadAnnotation(SyntaxNodeAnalysisContext ctx, Location location,
                                                              String name, HttpDiagnosticCodes code) {
        updateDiagnostic(ctx, location, code, name);
    }

    private static void reportInvalidUsageOfCacheAnnotation(SyntaxNodeAnalysisContext ctx, Location location,
                                                            String returnType) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_130, returnType);
    }

    private static void reportInvalidIntersectionType(SyntaxNodeAnalysisContext ctx, Location location,
                                                      String typeName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_133, typeName);
    }

    private static void reportInvalidIntersectionObjectType(SyntaxNodeAnalysisContext ctx, Location location,
                                                            String paramName, String typeName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_134, paramName, typeName);
    }

    private static void reportInvalidHeaderRecordRestFieldType(SyntaxNodeAnalysisContext ctx, Location location) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_144);
    }

    private static void reportInvalidRecordFieldType(SyntaxNodeAnalysisContext ctx, Location location,
                                                     String paramName, String typeName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_145, typeName, paramName);
    }

    private static void reportInvalidResourceName(SyntaxNodeAnalysisContext ctx, Location location,
                                                  String resourceName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_146, resourceName);
    }

    private static void reportInvalidLinkRelation(SyntaxNodeAnalysisContext ctx, Location location,
                                                  String relation) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_147, relation);
    }
}
