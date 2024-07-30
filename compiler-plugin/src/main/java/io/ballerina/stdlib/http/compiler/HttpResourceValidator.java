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
import io.ballerina.compiler.api.symbols.FunctionSymbol;
import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.PathParameterSymbol;
import io.ballerina.compiler.api.symbols.RecordFieldSymbol;
import io.ballerina.compiler.api.symbols.RecordTypeSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.api.symbols.resourcepath.PathRestParam;
import io.ballerina.compiler.api.symbols.resourcepath.PathSegmentList;
import io.ballerina.compiler.api.symbols.resourcepath.ResourcePath;
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
import io.ballerina.stdlib.http.compiler.codemodifier.context.ParamAvailability;
import io.ballerina.stdlib.http.compiler.codemodifier.context.ParamData;
import io.ballerina.tools.diagnostics.Location;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BSymbolicProperty;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static io.ballerina.stdlib.http.compiler.Constants.ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.ARRAY_OF_MAP_OF_ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.BOOLEAN;
import static io.ballerina.stdlib.http.compiler.Constants.BOOLEAN_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_ANNOTATION_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.CALLER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.DECIMAL;
import static io.ballerina.stdlib.http.compiler.Constants.DECIMAL_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.EMPTY;
import static io.ballerina.stdlib.http.compiler.Constants.FIELD_RESPONSE_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.FLOAT;
import static io.ballerina.stdlib.http.compiler.Constants.FLOAT_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.GET;
import static io.ballerina.stdlib.http.compiler.Constants.HEAD;
import static io.ballerina.stdlib.http.compiler.Constants.HEADER_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.HEADER_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.Constants.INT;
import static io.ballerina.stdlib.http.compiler.Constants.INT_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.LINKED_TO;
import static io.ballerina.stdlib.http.compiler.Constants.MAP_OF_ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.METHOD;
import static io.ballerina.stdlib.http.compiler.Constants.NAME;
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
import static io.ballerina.stdlib.http.compiler.Constants.OPTIONS;
import static io.ballerina.stdlib.http.compiler.Constants.PARAM;
import static io.ballerina.stdlib.http.compiler.Constants.PAYLOAD_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.QUERY_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.RELATION;
import static io.ballerina.stdlib.http.compiler.Constants.REQUEST_CONTEXT_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.REQUEST_OBJ_NAME;
import static io.ballerina.stdlib.http.compiler.Constants.RESOURCE_CONFIG_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.Constants.SELF;
import static io.ballerina.stdlib.http.compiler.Constants.STRING;
import static io.ballerina.stdlib.http.compiler.Constants.STRING_ARRAY;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.getNodeString;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.retrieveEffectiveTypeDesc;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.subtypeOf;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.updateDiagnostic;
import static io.ballerina.stdlib.http.compiler.codemodifier.HttpPayloadParamIdentifier.validateAnnotatedParams;
import static io.ballerina.stdlib.http.compiler.codemodifier.HttpPayloadParamIdentifier.validateNonAnnotatedParams;

/**
 * Validates a ballerina http resource.
 */
public final class HttpResourceValidator {

    private HttpResourceValidator() {}

    static void validateResource(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                 LinksMetaData linksMetaData, Map<String, TypeSymbol> typeSymbols) {
        extractResourceAnnotationAndValidate(ctx, member, linksMetaData);
        extractInputParamTypeAndValidate(ctx, member, false, typeSymbols);
        extractReturnTypeAndValidate(ctx, member, typeSymbols);
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
                }
            }
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
                                                        boolean isErrorInterceptor,
                                                        Map<String, TypeSymbol> typeSymbols) {
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
        ResourceMethodSymbol resourceMethodSymbol = (ResourceMethodSymbol) resourceMethodSymbolOptional.get();
        Optional<String> resourceMethodOptional = resourceMethodSymbol.getName();
        Optional<List<ParameterSymbol>> parametersOptional = resourceMethodSymbol.typeDescriptor().params();
        validatePathParamType(ctx, typeSymbols, resourceMethodSymbol.resourcePath());
        if (parametersOptional.isEmpty()) {
            return;
        }
        // Mocking code modifier here since LS does not run code modifiers
        // Related issue: https://github.com/ballerina-platform/ballerina-lang/issues/39792
        List<Integer> analyzedParams = new ArrayList<>();
        if (resourceMethodOptional.isPresent()) {
            String accessor = resourceMethodOptional.get();
            if (Stream.of(GET, HEAD, OPTIONS).noneMatch(accessor::equals)) {
                analyzedParams = mockCodeModifier(ctx, typeSymbols, parametersOptional);
            }
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
            String paramName = nameOptional.orElse("");

            List<AnnotationSymbol> annotations = param.annotations().stream()
                    .filter(annotationSymbol -> annotationSymbol.typeDescriptor().isPresent())
                    .collect(Collectors.toList());
            if (annotations.isEmpty()) {
                TypeSymbol typeSymbol = param.typeDescriptor();
                String typeName = typeSymbol.signature();
                TypeDescKind kind = typeSymbol.typeKind();

                if (kind == TypeDescKind.ERROR) {
                    errorPresent = isObjectPresent(ctx, paramLocation, errorPresent, paramName,
                            HttpDiagnosticCodes.HTTP_122);
                } else if (subtypeOf(typeSymbols, typeSymbol, OBJECT)) {
                    if (kind == TypeDescKind.INTERSECTION) {
                        reportInvalidIntersectionObjectType(ctx, paramLocation, paramName, typeName);
                    } else if (subtypeOf(typeSymbols, typeSymbol, CALLER_OBJ_NAME)) {
                        callerPresent = isObjectPresent(ctx, paramLocation, callerPresent, paramName,
                                HttpDiagnosticCodes.HTTP_115);
                    } else if (subtypeOf(typeSymbols, typeSymbol, REQUEST_OBJ_NAME)) {
                        requestPresent = isObjectPresent(ctx, paramLocation, requestPresent, paramName,
                                HttpDiagnosticCodes.HTTP_116);
                    } else if (subtypeOf(typeSymbols, typeSymbol, REQUEST_CONTEXT_OBJ_NAME)) {
                        requestCtxPresent = isObjectPresent(ctx, paramLocation, requestCtxPresent, paramName,
                                HttpDiagnosticCodes.HTTP_121);
                    } else if (subtypeOf(typeSymbols, typeSymbol, HEADER_OBJ_NAME)) {
                        headersPresent = isObjectPresent(ctx, paramLocation, headersPresent, paramName,
                                HttpDiagnosticCodes.HTTP_117);
                    } else {
                        reportInvalidParameterType(ctx, paramLocation, paramType);
                    }
                } else {
                    if (!analyzedParams.contains(param.hashCode())) {
                        if (!subtypeOf(typeSymbols, typeSymbol, ANYDATA)) {
                            reportInvalidParameterType(ctx, paramLocation, paramType);
                        } else {
                            validateQueryParamType(ctx, paramLocation, paramName, typeSymbol, typeSymbols);
                        }
                    }
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
                switch (typeName) {
                    case PAYLOAD_ANNOTATION_TYPE: {
                        payloadAnnotationPresent = true;
                        if (annotated) { // multiple annotations
                            reportInvalidMultipleAnnotation(ctx, paramLocation, paramName);
                            continue;
                        }
                        validatePayloadParamType(ctx, typeSymbols, paramLocation, resourceMethodOptional.orElse(null),
                                param, typeDescriptor);
                        annotated = true;
                        break;
                    }
                    case CALLER_ANNOTATION_TYPE: {
                        if (annotated) {
                            reportInvalidMultipleAnnotation(ctx, paramLocation, paramName);
                            continue;
                        }
                        annotated = true;
                        if (subtypeOf(typeSymbols, typeDescriptor, CALLER_OBJ_NAME)) {
                            if (callerPresent) {
                                updateDiagnostic(ctx, paramLocation, HttpDiagnosticCodes.HTTP_115, paramName);
                            } else {
                                callerPresent = true;
                                extractCallerInfoValueAndValidate(ctx, member, paramIndex);
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
                        validateHeaderParamType(ctx, param, paramLocation, paramName, typeDescriptor,
                                typeSymbols, false);
                        annotated = true;
                        break;
                    }
                    case QUERY_ANNOTATION_TYPE: {
                        if (annotated) {
                            reportInvalidMultipleAnnotation(ctx, paramLocation, paramName);
                            continue;
                        }
                        annotated = true;
                        validateQueryParamType(ctx, paramLocation, paramName, typeDescriptor, typeSymbols);
                        break;
                    }
                    default:
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

    private static void validatePathParamType(SyntaxNodeAnalysisContext ctx, Map<String, TypeSymbol> typeSymbols,
                                              ResourcePath path) {
        if (path instanceof PathRestParam) {
            validatePathParam(ctx, typeSymbols, ((PathRestParam) path).parameter());
        } else if (path instanceof PathSegmentList) {
            ((PathSegmentList) path).pathParameters().forEach(param -> validatePathParam(ctx, typeSymbols, param));

            Optional<PathParameterSymbol> pathRestParam = ((PathSegmentList) path).pathRestParameter();
            pathRestParam.ifPresent(pathParameterSymbol -> validatePathParam(ctx, typeSymbols, pathParameterSymbol));
        }
    }

    private static void validatePathParam(SyntaxNodeAnalysisContext ctx, Map<String, TypeSymbol> typeSymbols,
                                          PathParameterSymbol pathParam) {
        if (!isValidBasicParamType(pathParam.typeDescriptor(), typeSymbols)) {
            reportInvalidPathParameterType(ctx, pathParam.location(), pathParam.getName().get());
        }
    }

    public static List<Integer> mockCodeModifier(SyntaxNodeAnalysisContext ctx, Map<String, TypeSymbol> typeSymbols,
                                                 Optional<List<ParameterSymbol>> parametersOptional) {
        List<ParamData> nonAnnotatedParams = new ArrayList<>();
        List<ParamData> annotatedParams = new ArrayList<>();
        List<Integer> analyzedParams = new ArrayList<>();
        ParamAvailability paramAvailability = new ParamAvailability();
        int index = 0;
        for (ParameterSymbol param : parametersOptional.get()) {
            List<AnnotationSymbol> annotations = param.annotations().stream()
                    .filter(annotationSymbol -> annotationSymbol.typeDescriptor().isPresent())
                    .collect(Collectors.toList());
            if (annotations.isEmpty()) {
                nonAnnotatedParams.add(new ParamData(param, index++));
            } else {
                annotatedParams.add(new ParamData(param, index++));
            }
        }

        for (ParamData annotatedParam : annotatedParams) {
            validateAnnotatedParams(annotatedParam.getParameterSymbol(), paramAvailability);
            if (paramAvailability.isAnnotatedPayloadParam()) {
                return analyzedParams;
            }
        }

        for (ParamData nonAnnotatedParam : nonAnnotatedParams) {
            ParameterSymbol parameterSymbol = nonAnnotatedParam.getParameterSymbol();

            if (validateNonAnnotatedParams(ctx, parameterSymbol.typeDescriptor(), paramAvailability,
                    parameterSymbol, typeSymbols)) {
                analyzedParams.add(parameterSymbol.hashCode());
            }
            if (paramAvailability.isErrorOccurred()) {
                analyzedParams.add(parameterSymbol.hashCode());
                break;
            }
        }

        return analyzedParams;
    }

    private static void validatePayloadParamType(SyntaxNodeAnalysisContext ctx, Map<String, TypeSymbol> typeSymbols,
                                                 Location paramLocation, String resourceMethodOptional,
                                                 ParameterSymbol param, TypeSymbol typeDescriptor) {
        if (resourceMethodOptional != null) {
            validatePayloadAnnotationUsage(ctx, paramLocation, resourceMethodOptional);
        }
        if (subtypeOf(typeSymbols, typeDescriptor, ANYDATA)) {
            return;
        }
        reportInvalidPayloadParameterType(ctx, paramLocation, param.typeDescriptor().signature());
    }

    public static void validateHeaderParamType(SyntaxNodeAnalysisContext ctx, ParameterSymbol param,
                                               Location paramLocation, String paramName, TypeSymbol typeSymbol,
                                               Map<String, TypeSymbol> typeSymbols, boolean isRecordField) {
        if (isValidBasicParamType(typeSymbol, typeSymbols) || isValidNilableBasicParamType(typeSymbol, typeSymbols)) {
            return;
        }
        RecordTypeSymbol recordTypeSymbol = getRecordTypeSymbol(typeSymbol);
        if (!isRecordField && recordTypeSymbol != null) {
            validateRecordFieldsOfHeaderParam(ctx, param, paramLocation, paramName, recordTypeSymbol, typeSymbols);
            return;
        }
        if (isUnionType(typeSymbol)) {
            reportInvalidUnionHeaderType(ctx, paramLocation, paramName);
            return;
        }
        reportInvalidHeaderParameterType(ctx, paramLocation, paramName, param);
    }

    private static boolean isMapOfAnydataType(TypeSymbol typeSymbol, Map<String, TypeSymbol> typeSymbols) {
        return subtypeOf(typeSymbols, typeSymbol, MAP_OF_ANYDATA) ||
                subtypeOf(typeSymbols, typeSymbol, NILABLE_MAP_OF_ANYDATA);
    }

    private static boolean isArrayOfMapOfAnydataType(TypeSymbol typeSymbol, Map<String, TypeSymbol> typeSymbols) {
        return subtypeOf(typeSymbols, typeSymbol, ARRAY_OF_MAP_OF_ANYDATA) ||
                subtypeOf(typeSymbols, typeSymbol, NILABLE_MAP_OF_ANYDATA_ARRAY);
    }

    private static boolean isValidBasicQueryParameterType(TypeSymbol typeSymbol, Map<String, TypeSymbol> typeSymbols) {
        return isValidBasicParamType(typeSymbol, typeSymbols) || isValidNilableBasicParamType(typeSymbol, typeSymbols)
                || isMapOfAnydataType(typeSymbol, typeSymbols) || isArrayOfMapOfAnydataType(typeSymbol, typeSymbols);

    }

    public static void validateQueryParamType(SyntaxNodeAnalysisContext ctx, Location paramLocation, String paramName,
                                              TypeSymbol typeSymbol, Map<String, TypeSymbol> typeSymbols) {
        if (isValidBasicQueryParameterType(typeSymbol, typeSymbols)) {
            return;
        }
        if (isUnionType(typeSymbol)) {
            reportInvalidUnionQueryType(ctx, paramLocation, paramName);
        } else if (isIntersectionType(typeSymbol)) {
            reportInvalidIntersectionType(ctx, paramLocation, paramName);
        } else {
            reportInvalidQueryParameterType(ctx, paramLocation, paramName);
        }
    }

    public static boolean isUnionType(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            List<TypeSymbol> memberTypeSymbols = ((UnionTypeSymbol) typeSymbol).memberTypeDescriptors();
            // Consider the union type as a valid type if all the member types are not nilable
            return memberTypeSymbols.stream().allMatch(type -> type.typeKind() != TypeDescKind.NIL);
        } else if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            return isUnionType(((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor());
        }
        return false;
    }

    public static boolean isIntersectionType(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() == TypeDescKind.INTERSECTION) {
            return true;
        } else if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            return isIntersectionType(((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor());
        }
        return false;
    }

    public static RecordTypeSymbol getRecordTypeSymbol(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() == TypeDescKind.RECORD) {
            return (RecordTypeSymbol) typeSymbol;
        } else if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            return getRecordTypeSymbol(((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor());
        } else if (typeSymbol.typeKind() == TypeDescKind.INTERSECTION) {
            // Only readonly record intersection types are supported
            List<TypeSymbol> memberTypeSymbols = ((IntersectionTypeSymbol) typeSymbol).memberTypeDescriptors();
            if (memberTypeSymbols.size() == 2) {
                if (memberTypeSymbols.get(0).typeKind() == TypeDescKind.READONLY) {
                    return getRecordTypeSymbol(memberTypeSymbols.get(1));
                } else if (memberTypeSymbols.get(1).typeKind() == TypeDescKind.READONLY) {
                    return getRecordTypeSymbol(memberTypeSymbols.get(0));
                }
            }
        } else if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            // Only nilable record union types are supported
            List<TypeSymbol> memberTypeSymbols = ((UnionTypeSymbol) typeSymbol).memberTypeDescriptors();
            if (memberTypeSymbols.size() == 2) {
                if (memberTypeSymbols.get(0).typeKind() == TypeDescKind.NIL) {
                    return getRecordTypeSymbol(memberTypeSymbols.get(1));
                } else if (memberTypeSymbols.get(1).typeKind() == TypeDescKind.NIL) {
                    return getRecordTypeSymbol(memberTypeSymbols.get(0));
                }
            }
        }
        return null;
    }

    public static TypeSymbol getEffectiveType(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            return getEffectiveType(getEffectiveTypeFromTypeReference(typeSymbol));
        } else if (typeSymbol.typeKind() == TypeDescKind.INTERSECTION) {
            return getEffectiveType(getEffectiveTypeFromReadonlyIntersection((IntersectionTypeSymbol) typeSymbol));
        }
        return typeSymbol;
    }

    public static TypeSymbol getEffectiveTypeFromTypeReference(TypeSymbol typeSymbol) {
        if (typeSymbol.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            return getEffectiveTypeFromTypeReference(((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor());
        }
        return typeSymbol;
    }

    public static boolean isValidBasicParamType(TypeSymbol typeSymbol, Map<String, TypeSymbol> typeSymbols) {
        return subtypeOf(typeSymbols, typeSymbol, STRING) ||
                subtypeOf(typeSymbols, typeSymbol, INT) ||
                subtypeOf(typeSymbols, typeSymbol, FLOAT) ||
                subtypeOf(typeSymbols, typeSymbol, DECIMAL) ||
                subtypeOf(typeSymbols, typeSymbol, BOOLEAN) ||
                subtypeOf(typeSymbols, typeSymbol, STRING_ARRAY) ||
                subtypeOf(typeSymbols, typeSymbol, INT_ARRAY) ||
                subtypeOf(typeSymbols, typeSymbol, FLOAT_ARRAY) ||
                subtypeOf(typeSymbols, typeSymbol, DECIMAL_ARRAY) ||
                subtypeOf(typeSymbols, typeSymbol, BOOLEAN_ARRAY);
    }

    public static boolean isValidNilableBasicParamType(TypeSymbol typeSymbol, Map<String, TypeSymbol> typeSymbols) {
        return subtypeOf(typeSymbols, typeSymbol, NILABLE_STRING) ||
                subtypeOf(typeSymbols, typeSymbol, NILABLE_INT) ||
                subtypeOf(typeSymbols, typeSymbol, NILABLE_FLOAT) ||
                subtypeOf(typeSymbols, typeSymbol, NILABLE_DECIMAL) ||
                subtypeOf(typeSymbols, typeSymbol, NILABLE_BOOLEAN) ||
                subtypeOf(typeSymbols, typeSymbol, NILABLE_STRING_ARRAY) ||
                subtypeOf(typeSymbols, typeSymbol, NILABLE_INT_ARRAY) ||
                subtypeOf(typeSymbols, typeSymbol, NILABLE_FLOAT_ARRAY) ||
                subtypeOf(typeSymbols, typeSymbol, NILABLE_DECIMAL_ARRAY) ||
                subtypeOf(typeSymbols, typeSymbol, NILABLE_BOOLEAN_ARRAY);
    }

    private static void validateRecordFieldsOfHeaderParam(SyntaxNodeAnalysisContext ctx, ParameterSymbol param,
                                                          Location paramLocation, String paramName,
                                                          TypeSymbol typeSymbol, Map<String, TypeSymbol> typeSymbols) {
        Optional<TypeSymbol> restTypeSymbol = ((RecordTypeSymbol) typeSymbol).restTypeDescriptor();
        if (restTypeSymbol.isPresent()) {
            reportInvalidHeaderRecordRestFieldType(ctx, paramLocation);
        }
        Collection<RecordFieldSymbol> recordFields = ((RecordTypeSymbol) typeSymbol).fieldDescriptors().values();
        for (RecordFieldSymbol recordField : recordFields) {
            validateHeaderParamType(ctx, param, paramLocation, recordField.getName().orElse(paramName),
                    recordField.typeDescriptor(), typeSymbols, true);
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
                    if (!argTypeSymbol.subtypeOf(annotValueSymbol)) {
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

    private static void extractReturnTypeAndValidate(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                                     Map<String, TypeSymbol> typeSymbols) {
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
        HttpCompilerPluginUtil.validateResourceReturnType(ctx, returnTypeNode, typeSymbols, returnTypeStringValue,
                                                          returnTypeSymbol.get(), HttpDiagnosticCodes.HTTP_102, false);
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
        updateDiagnostic(ctx, returnTypeLocation, HttpDiagnosticCodes.HTTP_118, returnTypeDescription);
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

    private static void reportInvalidParameter(SyntaxNodeAnalysisContext ctx, Location location,
                                               String paramName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_105, paramName);
    }

    private static void reportInvalidParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                   String typeName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_106, typeName);
    }

    public static void reportInvalidPayloadParameterType(SyntaxNodeAnalysisContext ctx, Location location,
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

    private static void reportInvalidPathParameterType(SyntaxNodeAnalysisContext ctx, Location location,
                                                       String paramName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_145, paramName);
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

    private static void reportInvalidResourceName(SyntaxNodeAnalysisContext ctx, Location location,
                                                  String resourceName) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_146, resourceName);
    }

    private static void reportInvalidLinkRelation(SyntaxNodeAnalysisContext ctx, Location location,
                                                  String relation) {
        updateDiagnostic(ctx, location, HttpDiagnosticCodes.HTTP_147, relation);
    }
}
