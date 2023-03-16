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
import io.ballerina.compiler.api.symbols.ArrayTypeSymbol;
import io.ballerina.compiler.api.symbols.MapTypeSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TableTypeSymbol;
import io.ballerina.compiler.api.symbols.TupleTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.compiler.syntax.tree.TypeReferenceNode;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.http.compiler.Constants;
import io.ballerina.stdlib.http.compiler.HttpDiagnosticCodes;
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

import static io.ballerina.stdlib.http.compiler.Constants.GET;
import static io.ballerina.stdlib.http.compiler.Constants.HEAD;
import static io.ballerina.stdlib.http.compiler.Constants.OPTIONS;
import static io.ballerina.stdlib.http.compiler.Constants.PAYLOAD_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.updateDiagnostic;
import static io.ballerina.stdlib.http.compiler.HttpResourceValidator.getEffectiveType;


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
        SyntaxKind kind = syntaxNodeAnalysisContext.node().kind();
        if (kind == SyntaxKind.SERVICE_DECLARATION) {
            validateServiceDeclaration(syntaxNodeAnalysisContext);
        } else if (kind == SyntaxKind.CLASS_DEFINITION) {
            validateClassDefinition(syntaxNodeAnalysisContext);
        }
    }

    private void validateServiceDeclaration(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        ServiceDeclarationNode serviceDeclarationNode = getServiceDeclarationNode(syntaxNodeAnalysisContext);
        if (serviceDeclarationNode == null) {
            return;
        }
        NodeList<Node> members = serviceDeclarationNode.members();
        ServiceContext serviceContext = new ServiceContext(serviceDeclarationNode.hashCode());
        for (Node member : members) {
            if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                validateResource(syntaxNodeAnalysisContext, (FunctionDefinitionNode) member, serviceContext);
            }
        }
    }

    private void validateClassDefinition(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
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
            for (Node member : members) {
                if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                    validateResource(syntaxNodeAnalysisContext, (FunctionDefinitionNode) member, serviceContext);
                }
            }
        }
    }

    void validateResource(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member, ServiceContext serviceContext) {
        extractInputParamTypeAndValidate(ctx, member, serviceContext);
    }

    void extractInputParamTypeAndValidate(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                          ServiceContext serviceContext) {

        Optional<Symbol> resourceMethodSymbolOptional = ctx.semanticModel().symbol(member);
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
                    paramAvailability, parameterSymbol)) {
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
                                                     ParameterSymbol parameterSymbol) {
        typeSymbol = getEffectiveType(typeSymbol);
        if (typeSymbol.typeKind() == TypeDescKind.UNION) {
            if (isUnionStructuredType(analysisContext, (UnionTypeSymbol) typeSymbol, parameterSymbol,
                    paramAvailability)) {
                if (!typeSymbol.subtypeOf(analysisContext.semanticModel().types().ANYDATA)) {
                    HttpResourceValidator.reportInvalidPayloadParameterType(analysisContext,
                            parameterSymbol.getLocation().get(), parameterSymbol.typeDescriptor().signature());
                    paramAvailability.setErrorOccurred(true);
                    return false;
                }
                return checkErrorsAndReturn(analysisContext, paramAvailability, parameterSymbol);
            }
        }
        if (isStructuredType(analysisContext, typeSymbol)) {
            if (!typeSymbol.subtypeOf(analysisContext.semanticModel().types().ANYDATA)) {
                HttpResourceValidator.reportInvalidPayloadParameterType(analysisContext,
                        parameterSymbol.getLocation().get(), parameterSymbol.typeDescriptor().signature());
                paramAvailability.setErrorOccurred(true);
                return false;
            }
            return checkErrorsAndReturn(analysisContext, paramAvailability, parameterSymbol);
        }
        return false;
    }

    private static boolean isUnionStructuredType(SyntaxNodeAnalysisContext analysisContext,
                                                 UnionTypeSymbol unionTypeSymbol, ParameterSymbol parameterSymbol,
                                                 ParamAvailability paramAvailability) {
        List<TypeSymbol> typeDescriptors = unionTypeSymbol.memberTypeDescriptors();
        boolean foundNonStructuredType = false;
        boolean foundStructuredType = false;
        for (TypeSymbol symbol : typeDescriptors) {
            if (isNilableType(analysisContext, symbol)) {
                continue;
            }
            if (isStructuredType(analysisContext, symbol)) {
                foundStructuredType = true;
                if (foundNonStructuredType) {
                    reportInvalidUnionPayloadParam(analysisContext, parameterSymbol, paramAvailability);
                    return false;
                }
            } else {
                foundNonStructuredType = true;
                if (foundStructuredType) {
                    reportInvalidUnionPayloadParam(analysisContext, parameterSymbol, paramAvailability);
                    return false;
                }
            }
        }
        return foundStructuredType;
    }

    private static boolean isNilableType(SyntaxNodeAnalysisContext analysisContext, TypeSymbol typeSymbol) {
        return typeSymbol.subtypeOf(analysisContext.semanticModel().types().NIL);
    }

    private static boolean isStructuredType(SyntaxNodeAnalysisContext analysisContext, TypeSymbol typeSymbol) {
        TypeSymbol anydataType = analysisContext.semanticModel().types().ANYDATA;
        // map<anydata> is allowed
        MapTypeSymbol mapOfAnydata = analysisContext.semanticModel().types().builder().MAP_TYPE
                .withTypeParam(anydataType).build();
        // table<map<anydata>> is allowed
        TableTypeSymbol tableOfAnydataMap = analysisContext.semanticModel().types().builder().TABLE_TYPE
                .withRowType(mapOfAnydata).build();
        // [anydata...] is allowed
        TupleTypeSymbol tupleOfAnydata = analysisContext.semanticModel().types().builder().TUPLE_TYPE
                .withRestType(anydataType).build();
        // (map<anydata>|table<map<anydata>>|[anydata...])[] is allowed
        ArrayTypeSymbol structuredArray = analysisContext.semanticModel().types().builder().ARRAY_TYPE
                .withType(
                        analysisContext.semanticModel().types().builder().UNION_TYPE
                                .withMemberTypes(
                                        mapOfAnydata,
                                        tableOfAnydataMap,
                                        tupleOfAnydata).build()).build();
        // Byte[] is allowed
        ArrayTypeSymbol byteArray = analysisContext.semanticModel().types().builder().ARRAY_TYPE.withType(
                analysisContext.semanticModel().types().BYTE).build();
        // xml is allowed
        TypeSymbol xmlType = analysisContext.semanticModel().types().XML;
        return typeSymbol.subtypeOf(mapOfAnydata) || typeSymbol.subtypeOf(tableOfAnydataMap) ||
                typeSymbol.subtypeOf(tupleOfAnydata) || typeSymbol.subtypeOf(structuredArray) ||
                typeSymbol.subtypeOf(byteArray) || typeSymbol.subtypeOf(xmlType);
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
