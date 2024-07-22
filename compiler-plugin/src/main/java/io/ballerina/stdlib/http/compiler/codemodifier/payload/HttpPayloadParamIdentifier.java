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

package io.ballerina.stdlib.http.compiler.codemodifier.payload;

import io.ballerina.compiler.api.ModuleID;
import io.ballerina.compiler.api.symbols.AnnotationSymbol;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
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
import io.ballerina.stdlib.http.compiler.HttpDiagnostic;
import io.ballerina.stdlib.http.compiler.HttpResourceValidator;
import io.ballerina.stdlib.http.compiler.HttpServiceValidator;
import io.ballerina.stdlib.http.compiler.ResourceFunction;
import io.ballerina.stdlib.http.compiler.ResourceFunctionDeclaration;
import io.ballerina.stdlib.http.compiler.ResourceFunctionDefinition;
import io.ballerina.stdlib.http.compiler.codemodifier.payload.context.PayloadParamAvailability;
import io.ballerina.stdlib.http.compiler.codemodifier.payload.context.PayloadParamContext;
import io.ballerina.stdlib.http.compiler.codemodifier.payload.context.PayloadParamData;
import io.ballerina.stdlib.http.compiler.codemodifier.payload.context.ResourcePayloadParamContext;
import io.ballerina.stdlib.http.compiler.codemodifier.payload.context.ServicePayloadParamContext;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.http.compiler.Constants.ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.BALLERINA;
import static io.ballerina.stdlib.http.compiler.Constants.BYTE_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.GET;
import static io.ballerina.stdlib.http.compiler.Constants.HEAD;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.Constants.MAP_OF_ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.NIL;
import static io.ballerina.stdlib.http.compiler.Constants.OPTIONS;
import static io.ballerina.stdlib.http.compiler.Constants.PAYLOAD_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.STRUCTURED_ARRAY;
import static io.ballerina.stdlib.http.compiler.Constants.TABLE_OF_ANYDATA_MAP;
import static io.ballerina.stdlib.http.compiler.Constants.TUPLE_OF_ANYDATA;
import static io.ballerina.stdlib.http.compiler.Constants.XML;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.diagnosticContainsErrors;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.getCtxTypes;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.getServiceDeclarationNode;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isHttpServiceType;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.subtypeOf;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.updateDiagnostic;
import static io.ballerina.stdlib.http.compiler.HttpResourceValidator.getEffectiveType;
import static io.ballerina.stdlib.http.compiler.HttpResourceValidator.isValidBasicParamType;
import static io.ballerina.stdlib.http.compiler.HttpResourceValidator.isValidNilableBasicParamType;


/**
 * {@code HttpPayloadParamIdentifier} identifies the payload param during the initial syntax node analysis.
 *
 * @since 2201.5.0
 */
public class HttpPayloadParamIdentifier extends HttpServiceValidator {
    private final Map<DocumentId, PayloadParamContext> documentContextMap;

    public HttpPayloadParamIdentifier(Map<DocumentId, PayloadParamContext> documentContextMap) {
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
        ServicePayloadParamContext serviceContext = new ServicePayloadParamContext(serviceDeclarationNode.hashCode());
        validateResources(syntaxNodeAnalysisContext, typeSymbols, members, serviceContext);
    }

    private void validateServiceObjDefinition(SyntaxNodeAnalysisContext context, Map<String, TypeSymbol> typeSymbols) {
        ObjectTypeDescriptorNode serviceObjType = (ObjectTypeDescriptorNode) context.node();
        NodeList<Node> members = serviceObjType.members();
        ServicePayloadParamContext serviceContext = new ServicePayloadParamContext(serviceObjType.hashCode());
        validateResources(context, typeSymbols, members, serviceContext);
    }

    private void validateResources(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext,
                                   Map<String, TypeSymbol> typeSymbols, NodeList<Node> members,
                                   ServicePayloadParamContext serviceContext) {
        for (Node member : members) {
            if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                validateResource(syntaxNodeAnalysisContext,
                        new ResourceFunctionDefinition((FunctionDefinitionNode) member), serviceContext,
                        typeSymbols);
            } else if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DECLARATION) {
                validateResource(syntaxNodeAnalysisContext,
                        new ResourceFunctionDeclaration((MethodDeclarationNode) member), serviceContext,
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
        ServicePayloadParamContext serviceContext = new ServicePayloadParamContext(classDefinitionNode.hashCode());
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

    void validateResource(SyntaxNodeAnalysisContext ctx, ResourceFunction member,
                          ServicePayloadParamContext serviceContext,
                          Map<String, TypeSymbol> typeSymbols) {
        extractInputParamTypeAndValidate(ctx, member, serviceContext, typeSymbols);
    }

    void extractInputParamTypeAndValidate(SyntaxNodeAnalysisContext ctx, ResourceFunction member,
                                          ServicePayloadParamContext serviceContext,
                                          Map<String, TypeSymbol> typeSymbols) {

        Optional<Symbol> resourceMethodSymbolOptional = member.getSymbol(ctx.semanticModel());
        if (resourceMethodSymbolOptional.isEmpty()) {
            return;
        }
        int resourceId = member.getResourceIdentifierCode();
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

        List<PayloadParamData> nonAnnotatedParams = new ArrayList<>();
        List<PayloadParamData> annotatedParams = new ArrayList<>();
        PayloadParamAvailability paramAvailability = new PayloadParamAvailability();
        // Disable error diagnostic in the code modifier since this validation is also done in the code analyzer
        paramAvailability.setErrorDiagnostic(false);
        int index = 0;
        for (ParameterSymbol param : parametersOptional.get()) {
            List<AnnotationSymbol> annotations = param.annotations().stream()
                    .filter(annotationSymbol -> annotationSymbol.typeDescriptor().isPresent() &&
                            isHttpPackageAnnotationTypeDesc(annotationSymbol.typeDescriptor().get()))
                    .collect(Collectors.toList());
            if (annotations.isEmpty()) {
                nonAnnotatedParams.add(new PayloadParamData(param, index++));
            } else {
                annotatedParams.add(new PayloadParamData(param, index++));
            }
        }

        for (PayloadParamData annotatedParam : annotatedParams) {
            validateAnnotatedParams(annotatedParam.getParameterSymbol(), paramAvailability);
            if (paramAvailability.isAnnotatedPayloadParam()) {
                return;
            }
        }

        for (PayloadParamData nonAnnotatedParam : nonAnnotatedParams) {
            ParameterSymbol parameterSymbol = nonAnnotatedParam.getParameterSymbol();

            if (validateNonAnnotatedParams(ctx, parameterSymbol.typeDescriptor(),
                    paramAvailability, parameterSymbol, typeSymbols)) {
                ResourcePayloadParamContext resourceContext =
                        new ResourcePayloadParamContext(parameterSymbol, nonAnnotatedParam.getIndex());
                PayloadParamContext documentContext = documentContextMap.get(ctx.documentId());
                if (documentContext == null) {
                    documentContext = new PayloadParamContext(ctx);
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

    private boolean isHttpPackageAnnotationTypeDesc(TypeSymbol typeSymbol) {
        Optional<ModuleSymbol> module = typeSymbol.getModule();
        if (module.isEmpty()) {
            return false;
        }
        ModuleID id = module.get().id();
        return id.orgName().equals(BALLERINA) && id.moduleName().startsWith(HTTP);
    }

    public static void validateAnnotatedParams(ParameterSymbol parameterSymbol,
                                               PayloadParamAvailability paramAvailability) {
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
                                                     TypeSymbol typeSymbol, PayloadParamAvailability paramAvailability,
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
                                                 ParameterSymbol parameterSymbol,
                                                 PayloadParamAvailability paramAvailability,
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
                                                PayloadParamAvailability availability, ParameterSymbol pSymbol) {
        if (availability.isDefaultPayloadParam() && isDistinctVariable(availability, pSymbol)) {
            reportAmbiguousPayloadParam(analysisContext, pSymbol, availability);
            availability.setErrorOccurred(true);
            return false;
        }
        availability.setPayloadParamSymbol(pSymbol);
        return true;
    }

    private static boolean isDistinctVariable(PayloadParamAvailability availability, ParameterSymbol pSymbol) {
        return !pSymbol.getName().get().equals(availability.getPayloadParamSymbol().getName().get());
    }

    private static void reportAmbiguousPayloadParam(SyntaxNodeAnalysisContext analysisContext,
                                                    ParameterSymbol parameterSymbol,
                                                    PayloadParamAvailability paramAvailability) {
        if (paramAvailability.isEnableErrorDiagnostic()) {
            updateDiagnostic(analysisContext, parameterSymbol.getLocation().get(), HttpDiagnostic.HTTP_151,
                    paramAvailability.getPayloadParamSymbol().getName().get(), parameterSymbol.getName().get());
        }
    }

    private static void reportInvalidUnionPayloadParam(SyntaxNodeAnalysisContext analysisContext,
                                                       ParameterSymbol parameterSymbol,
                                                       PayloadParamAvailability paramAvailability) {
        if (paramAvailability.isErrorOccurred()) {
            return;
        }
        if (!paramAvailability.isDefaultPayloadParam()) {
            if (paramAvailability.isEnableErrorDiagnostic()) {
                updateDiagnostic(analysisContext, parameterSymbol.getLocation().get(), HttpDiagnostic.HTTP_152,
                        parameterSymbol.getName().get());
            }
            paramAvailability.setErrorOccurred(true);
        }
    }
}
