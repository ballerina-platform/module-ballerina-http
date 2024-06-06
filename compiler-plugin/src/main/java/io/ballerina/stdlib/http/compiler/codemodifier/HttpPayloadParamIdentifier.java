/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.compiler.codemodifier;

import io.ballerina.compiler.api.symbols.AnnotationSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.MethodDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ObjectTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.compiler.syntax.tree.TypeReferenceNode;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.http.compiler.Constants;
import io.ballerina.stdlib.http.compiler.HttpDiagnosticCodes;
import io.ballerina.stdlib.http.compiler.HttpResourceFunctionNode;
import io.ballerina.stdlib.http.compiler.HttpResourceValidator;
import io.ballerina.stdlib.http.compiler.HttpServiceValidator;
import io.ballerina.stdlib.http.compiler.codemodifier.context.DocumentContext;
import io.ballerina.stdlib.http.compiler.codemodifier.context.ParamAvailability;
import io.ballerina.stdlib.http.compiler.codemodifier.context.ParamData;
import io.ballerina.stdlib.http.compiler.codemodifier.context.ResourceContext;
import io.ballerina.stdlib.http.compiler.codemodifier.context.ServiceContext;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.http.compiler.Constants.ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.BYTE_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.GET;
import static io.ballerina.stdlib.http.compiler.Constants.HEAD;
import static io.ballerina.stdlib.http.compiler.Constants.MAP_OF_ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.NIL;
import static io.ballerina.stdlib.http.compiler.Constants.OPTIONS;
import static io.ballerina.stdlib.http.compiler.Constants.PAYLOAD_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.STRUCTURED_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.TABLE_OF_ANYDATA_MAP;
import static io.ballerina.stdlib.http.compiler.Constants.TUPLE_OF_ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.XML;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.getCtxTypes;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.subtypeOf;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.updateDiagnostic;
import static io.ballerina.stdlib.http.compiler.HttpResourceValidator.getEffectiveType;
import static io.ballerina.stdlib.http.compiler.HttpResourceValidator.isValidBasicParamType;
import static io.ballerina.stdlib.http.compiler.HttpResourceValidator.isValidNilableBasicParamType;
import static io.ballerina.stdlib.http.compiler.HttpServiceObjTypeAnalyzer.isHttpServiceType;


/**
 * {@code HttpPayloadParamIdentifier} identifies the payload param during the initial syntax node analysis.
 *
 * @since 2201.5.0
 */
public class HttpPayloadParamIdentifier extends HttpServiceValidator {
    private final Map<DocumentId, DocumentContext> documentContextMap;

    public HttpPayloadParamIdentifier(Map<DocumentId, DocumentContext> documentContextMap) {
        this.documentContextMap = documentContextMap;
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        if (diagnosticContainsErrors(syntaxNodeAnalysisContext)) {
            return;
        }
        Map<String, TypeSymbol> typeSymbols = getCtxTypes(syntaxNodeAnalysisContext);
        SyntaxKind kind = syntaxNodeAnalysisContext.node().kind();
        if (kind == SyntaxKind.SERVICE_DECLARATION) {
            validateServiceDeclaration(syntaxNodeAnalysisContext, typeSymbols);
        } else if (kind == SyntaxKind.CLASS_DEFINITION) {
            validateClassDefinition(syntaxNodeAnalysisContext, typeSymbols);
        } else if (kind == SyntaxKind.OBJECT_TYPE_DESC && isHttpServiceType(syntaxNodeAnalysisContext.semanticModel(),
                syntaxNodeAnalysisContext.node())) {
            validateServiceObjDefinition(syntaxNodeAnalysisContext, typeSymbols);
        }
    }

    private void validateServiceDeclaration(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext,
                                            Map<String, TypeSymbol> typeSymbols) {
        ServiceDeclarationNode serviceDeclarationNode = getServiceDeclarationNode(syntaxNodeAnalysisContext);
        if (serviceDeclarationNode == null) {
            return;
        }
        NodeList<Node> members = serviceDeclarationNode.members();
        ServiceContext serviceContext = new ServiceContext(serviceDeclarationNode.hashCode());
        validateResources(syntaxNodeAnalysisContext, typeSymbols, members, serviceContext);
    }

    private void validateServiceObjDefinition(SyntaxNodeAnalysisContext context, Map<String, TypeSymbol> typeSymbols) {
        ObjectTypeDescriptorNode serviceObjType = (ObjectTypeDescriptorNode) context.node();
        NodeList<Node> members = serviceObjType.members();
        ServiceContext serviceContext = new ServiceContext(serviceObjType.hashCode());
        validateResources(context, typeSymbols, members, serviceContext);
    }

    private void validateResources(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext,
                                   Map<String, TypeSymbol> typeSymbols, NodeList<Node> members,
                                   ServiceContext serviceContext) {
        for (Node member : members) {
            if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                validateResource(syntaxNodeAnalysisContext,
                        new HttpResourceFunctionNode((FunctionDefinitionNode) member), serviceContext,
                        typeSymbols);
            } else if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DECLARATION) {
                validateResource(syntaxNodeAnalysisContext,
                        new HttpResourceFunctionNode((MethodDeclarationNode) member), serviceContext,
                        typeSymbols);
            }
        }
    }

    private void validateClassDefinition(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext,
                                         Map<String, TypeSymbol> typeSymbols) {
        ClassDefinitionNode classDefinitionNode = (ClassDefinitionNode) syntaxNodeAnalysisContext.node();
        NodeList<Token> tokens = classDefinitionNode.classTypeQualifiers();
        if (tokens.isEmpty()) {
            return;
        }
        if (!tokens.stream().allMatch(token -> token.text().equals(Constants.SERVICE_KEYWORD))) {
            return;
        }
        NodeList<Node> members = classDefinitionNode.members();
        ServiceContext serviceContext = new ServiceContext(classDefinitionNode.hashCode());
        boolean proceed = false;
        for (Node member : members) {
            if (member.kind() == SyntaxKind.TYPE_REFERENCE) {
                String typeReference = ((TypeReferenceNode) member).typeName().toString();
                switch (typeReference) {
                    case Constants.HTTP_SERVICE:
                    case Constants.HTTP_REQUEST_INTERCEPTOR:
                    case Constants.HTTP_REQUEST_ERROR_INTERCEPTOR:
                        proceed = true;
                        break;
                    default:
                        break;
                }
            }
        }
        if (proceed) {
            validateResources(syntaxNodeAnalysisContext, typeSymbols, members, serviceContext);
        }
    }

    void validateResource(SyntaxNodeAnalysisContext ctx, HttpResourceFunctionNode member, ServiceContext serviceContext,
                          Map<String, TypeSymbol> typeSymbols) {
        extractInputParamTypeAndValidate(ctx, member, serviceContext, typeSymbols);
    }

    void extractInputParamTypeAndValidate(SyntaxNodeAnalysisContext ctx, HttpResourceFunctionNode member,
                                          ServiceContext serviceContext, Map<String, TypeSymbol> typeSymbols) {

        Optional<Symbol> resourceMethodSymbolOptional = member.getSymbol(ctx.semanticModel());
        int resourceId = member.hashCode();
        if (resourceMethodSymbolOptional.isEmpty()) {
            return;
        }
        Optional<String> resourceMethodOptional = resourceMethodSymbolOptional.get().getName();

        if (resourceMethodOptional.isPresent()) {
            String accessor = resourceMethodOptional.get();
            if (accessor.equals(GET) || accessor.equals(HEAD) || accessor.equals(OPTIONS)) {
                return; // No modification is done for non-entity body resources
            }
        } else {
            return; // No modification is done for non resources functions
        }

        Optional<List<ParameterSymbol>> parametersOptional =
                ((ResourceMethodSymbol) resourceMethodSymbolOptional.get()).typeDescriptor().params();
        if (parametersOptional.isEmpty()) {
            return; // No modification is done for non param resources functions
        }

        List<ParamData> nonAnnotatedParams = new ArrayList<>();
        List<ParamData> annotatedParams = new ArrayList<>();
        ParamAvailability paramAvailability = new ParamAvailability();
        // Disable error diagnostic in the code modifier since this validation is also done in the code analyzer
        paramAvailability.setErrorDiagnostic(false);
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
                return;
            }
        }

        for (ParamData nonAnnotatedParam : nonAnnotatedParams) {
            ParameterSymbol parameterSymbol = nonAnnotatedParam.getParameterSymbol();

            if (validateNonAnnotatedParams(ctx, parameterSymbol.typeDescriptor(),
                    paramAvailability, parameterSymbol, typeSymbols)) {
                ResourceContext resourceContext =
                        new ResourceContext(parameterSymbol, nonAnnotatedParam.getIndex());
                DocumentContext documentContext = documentContextMap.get(ctx.documentId());
                if (documentContext == null) {
                    documentContext = new DocumentContext(ctx);
                    documentContextMap.put(ctx.documentId(), documentContext);
                }
                serviceContext.setResourceContext(resourceId, resourceContext);
                documentContext.setServiceContext(serviceContext);
            }
            if (paramAvailability.isErrorOccurred()) {
                serviceContext.removeResourceContext(resourceId);
                return;
            }
        }
    }

    public static void validateAnnotatedParams(ParameterSymbol parameterSymbol, ParamAvailability paramAvailability) {
        List<AnnotationSymbol> annotations = parameterSymbol.annotations().stream()
                .filter(annotationSymbol -> annotationSymbol.typeDescriptor().isPresent())
                .collect(Collectors.toList());
        for (AnnotationSymbol annotation : annotations) {
            Optional<TypeSymbol> annotationTypeSymbol = annotation.typeDescriptor();
            if (annotationTypeSymbol.isEmpty()) {
                return;
            }
            Optional<String> annotationTypeNameOptional = annotationTypeSymbol.get().getName();
            if (annotationTypeNameOptional.isEmpty()) {
                return;
            }
            String typeName = annotationTypeNameOptional.get();
            if (typeName.equals(PAYLOAD_ANNOTATION_TYPE)) {
                paramAvailability.setAnnotatedPayloadParam(true);
            }
        }
    }

    public static boolean validateNonAnnotatedParams(SyntaxNodeAnalysisContext analysisContext,
                                                     TypeSymbol typeSymbol, ParamAvailability paramAvailability,
                                                     ParameterSymbol parameterSymbol,
                                                     Map<String, TypeSymbol> typeSymbols) {
        typeSymbol = getEffectiveType(typeSymbol);
        if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            if (isUnionStructuredType(analysisContext, (UnionTypeSymbol) typeSymbol, parameterSymbol,
                    paramAvailability, typeSymbols)) {
                if (!subtypeOf(typeSymbols, typeSymbol, ANYDATA)) {
                    HttpResourceValidator.reportInvalidPayloadParameterType(analysisContext,
                            parameterSymbol.getLocation().get(), parameterSymbol.typeDescriptor().signature());
                    paramAvailability.setErrorOccurred(true);
                    return false;
                }
                return checkErrorsAndReturn(analysisContext, paramAvailability, parameterSymbol);
            }
        }
        if (isStructuredType(typeSymbols, typeSymbol)) {
            if (!subtypeOf(typeSymbols, typeSymbol, ANYDATA)) {
                HttpResourceValidator.reportInvalidPayloadParameterType(analysisContext,
                        parameterSymbol.getLocation().get(), parameterSymbol.typeDescriptor().signature());
                paramAvailability.setErrorOccurred(true);
                return false;
            }
            return checkErrorsAndReturn(analysisContext, paramAvailability, parameterSymbol);
        }
        return false;
    }

    private static boolean isUnionStructuredType(SyntaxNodeAnalysisContext ctx, UnionTypeSymbol unionTypeSymbol,
                                                 ParameterSymbol parameterSymbol, ParamAvailability paramAvailability,
                                                 Map<String, TypeSymbol> typeSymbols) {
        List<TypeSymbol> typeDescriptors = unionTypeSymbol.memberTypeDescriptors();
        boolean foundNonStructuredType = false;
        boolean foundStructuredType = false;
        for (TypeSymbol symbol : typeDescriptors) {
            if (isNilableType(typeSymbols, symbol)) {
                continue;
            }
            if (isStructuredType(typeSymbols, symbol)) {
                foundStructuredType = true;
                if (foundNonStructuredType) {
                    reportInvalidUnionPayloadParam(ctx, parameterSymbol, paramAvailability);
                    return false;
                }
            } else {
                foundNonStructuredType = true;
                if (foundStructuredType) {
                    reportInvalidUnionPayloadParam(ctx, parameterSymbol, paramAvailability);
                    return false;
                }
            }
        }
        return foundStructuredType;
    }

    private static boolean isNilableType(Map<String, TypeSymbol> typeSymbols, TypeSymbol typeSymbol) {
        return subtypeOf(typeSymbols, typeSymbol, NIL);
    }

    private static boolean isStructuredType(Map<String, TypeSymbol> typeSymbols, TypeSymbol typeSymbol) {
        // Special cased byte[]
        if (subtypeOf(typeSymbols, typeSymbol, BYTE_ARRAY)) {
            return true;
        }

        // If the type is a basic type or basic array type, then it is not considered as a structured type
        if (isValidBasicParamType(typeSymbol, typeSymbols) || isValidNilableBasicParamType(typeSymbol, typeSymbols)) {
            return false;
        }

        return subtypeOf(typeSymbols, typeSymbol, MAP_OF_ANYDATA) ||
                subtypeOf(typeSymbols, typeSymbol, TABLE_OF_ANYDATA_MAP) ||
                subtypeOf(typeSymbols, typeSymbol, TUPLE_OF_ANYDATA) ||
                subtypeOf(typeSymbols, typeSymbol, STRUCTURED_ARRAY) ||
                subtypeOf(typeSymbols, typeSymbol, XML);
    }

    private static boolean checkErrorsAndReturn(SyntaxNodeAnalysisContext analysisContext,
                                                ParamAvailability availability, ParameterSymbol pSymbol) {
        if (availability.isDefaultPayloadParam() && isDistinctVariable(availability, pSymbol)) {
            reportAmbiguousPayloadParam(analysisContext, pSymbol, availability);
            availability.setErrorOccurred(true);
            return false;
        }
        availability.setPayloadParamSymbol(pSymbol);
        return true;
    }

    private static boolean isDistinctVariable(ParamAvailability availability, ParameterSymbol pSymbol) {
        return !pSymbol.getName().get().equals(availability.getPayloadParamSymbol().getName().get());
    }

    private static void reportAmbiguousPayloadParam(SyntaxNodeAnalysisContext analysisContext,
                                                    ParameterSymbol parameterSymbol,
                                                    ParamAvailability paramAvailability) {
        if (paramAvailability.isEnableErrorDiagnostic()) {
            updateDiagnostic(analysisContext, parameterSymbol.getLocation().get(), HttpDiagnosticCodes.HTTP_151,
                    paramAvailability.getPayloadParamSymbol().getName().get(), parameterSymbol.getName().get());
        }
    }

    private static void reportInvalidUnionPayloadParam(SyntaxNodeAnalysisContext analysisContext,
                                                       ParameterSymbol parameterSymbol,
                                                       ParamAvailability paramAvailability) {
        if (paramAvailability.isErrorOccurred()) {
            return;
        }
        if (!paramAvailability.isDefaultPayloadParam()) {
            if (paramAvailability.isEnableErrorDiagnostic()) {
                updateDiagnostic(analysisContext, parameterSymbol.getLocation().get(), HttpDiagnosticCodes.HTTP_152,
                        parameterSymbol.getName().get());
            }
            paramAvailability.setErrorOccurred(true);
        }
    }
}
