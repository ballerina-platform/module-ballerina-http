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
import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.MapTypeSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TupleTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.http.compiler.HttpDiagnosticCodes;
import io.ballerina.stdlib.http.compiler.HttpServiceValidator;
import io.ballerina.stdlib.http.compiler.codemodifier.context.ParamAvailability;
import io.ballerina.stdlib.http.compiler.codemodifier.context.ParamData;
import io.ballerina.stdlib.http.compiler.codemodifier.context.PayloadParamContext;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.http.compiler.Constants.DEFAULT;
import static io.ballerina.stdlib.http.compiler.Constants.GET;
import static io.ballerina.stdlib.http.compiler.Constants.HEAD;
import static io.ballerina.stdlib.http.compiler.Constants.OPTIONS;
import static io.ballerina.stdlib.http.compiler.Constants.PAYLOAD_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.QUERY_ANNOTATION_TYPE;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.updateDiagnostic;


/**
 * {@code HttpPayloadParamIdentifier} identifies the payload param during the initial syntax node analysis.
 *
 * @since 2201.5.0
 */
public class HttpPayloadParamIdentifier extends HttpServiceValidator {
    private final Map<DocumentId, PayloadParamContext> payloadParamContextMap;

    public HttpPayloadParamIdentifier(Map<DocumentId, PayloadParamContext> payloadParamContextMap) {
        this.payloadParamContextMap = payloadParamContextMap;
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        if (diagnosticContainsErrors(syntaxNodeAnalysisContext)) {
            return;
        }

        ServiceDeclarationNode serviceDeclarationNode = getServiceDeclarationNode(syntaxNodeAnalysisContext);
        if (serviceDeclarationNode == null) {
            return;
        }
        int serviceId = serviceDeclarationNode.hashCode();
        NodeList<Node> members = serviceDeclarationNode.members();
        for (Node member : members) {
            if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                validateResource(syntaxNodeAnalysisContext, (FunctionDefinitionNode) member, serviceId);
            }
        }
    }

    void validateResource(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member, int serviceId) {
        extractInputParamTypeAndValidate(ctx, member, serviceId);
    }

    void extractInputParamTypeAndValidate(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member,
                                          int serviceId) {

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
                                           paramAvailability)) { //TODO change name of the func
                paramAvailability.setPayloadParamSymbol(parameterSymbol);
                this.payloadParamContextMap.put(ctx.documentId(),
                                                new PayloadParamContext(ctx, parameterSymbol, serviceId, resourceId,
                                                                        nonAnnotatedParam.getIndex()));
            }
            if (paramAvailability.isErrorOccurred()) {
                return;
            }
        }
    }

    private static void validateAnnotatedParams(ParameterSymbol parameterSymbol, ParamAvailability paramAvailability) {
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
            switch (typeName) {
                case PAYLOAD_ANNOTATION_TYPE: {
                    paramAvailability.setAnnotatedPayloadParam(true);
                    break;
                }
                case QUERY_ANNOTATION_TYPE: {
                    paramAvailability.setAnnotatedQueryParam(true);
                    break;
                }
                case DEFAULT: {
                }

            }
        }
    }

    private static boolean validateNonAnnotatedParams(SyntaxNodeAnalysisContext analysisContext,
                                                      TypeSymbol typeSymbol, ParamAvailability paramAvailability) {
        if (typeSymbol.typeKind() == TypeDescKind.INTERSECTION) {
            typeSymbol = getEffectiveTypeFromReadonlyIntersection((IntersectionTypeSymbol) typeSymbol);
            if (typeSymbol == null) {
                return false;
            }
        }
        TypeDescKind kind = typeSymbol.typeKind();
        if (kind == TypeDescKind.TYPE_REFERENCE) {
            if (typeSymbol.typeKind() == TypeDescKind.INTERSECTION) {
                return false;
            }
            TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
            return validateNonAnnotatedParams(analysisContext, typeDescriptor, paramAvailability);
        } else if (kind == TypeDescKind.NIL || kind == TypeDescKind.ERROR || kind == TypeDescKind.OBJECT) {
            return false;
        } else if (kind == TypeDescKind.RECORD) {
            if (paramAvailability.isDefaultPayloadParam()) {
                reportAmbiguousPayloadParam(analysisContext, typeSymbol);
                paramAvailability.setErrorOccurred(true);
                return false;
            }
            paramAvailability.setDefaultPayloadParam(true);
            return true;
        } else if (kind == TypeDescKind.MAP) {
            TypeSymbol constrainedTypeSymbol = ((MapTypeSymbol) typeSymbol).typeParam();
            TypeDescKind constrainedType = getReferencedTypeDescKind(constrainedTypeSymbol);
            if (constrainedType == TypeDescKind.TYPE_REFERENCE) {
                TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
                return validateNonAnnotatedParams(analysisContext, typeDescriptor, paramAvailability);
            }
            if (paramAvailability.isDefaultPayloadParam()) {
                reportAmbiguousPayloadParam(analysisContext, typeSymbol);
                paramAvailability.setErrorOccurred(true);
                return false;
            }
            paramAvailability.setDefaultPayloadParam(true);
            return true;
        } else if (kind == TypeDescKind.ARRAY) {
            TypeSymbol arrTypeSymbol = ((ArrayTypeSymbol) typeSymbol).memberTypeDescriptor();
            TypeDescKind elementKind = getReferencedTypeDescKind(arrTypeSymbol);
            if (elementKind == TypeDescKind.BYTE) {
                if (paramAvailability.isDefaultPayloadParam()) {
                    reportAmbiguousPayloadParam(analysisContext, typeSymbol); // TODO Error to be specific with Byte[]
                    paramAvailability.setErrorOccurred(true);
                    return false;
                }
                paramAvailability.setDefaultPayloadParam(true);
                return true;
            } else if (isAllowedQueryParamBasicType(elementKind, arrTypeSymbol)) {
                return true;
            } else if (elementKind == TypeDescKind.MAP || elementKind == TypeDescKind.RECORD) {
                if (paramAvailability.isDefaultPayloadParam()) {
                    reportAmbiguousPayloadParam(analysisContext, typeSymbol);
                    paramAvailability.setErrorOccurred(true);
                    return false;
                }
                paramAvailability.setDefaultPayloadParam(true);
                return true;
            } else if (elementKind == TypeDescKind.TYPE_REFERENCE) {
                TypeSymbol typeDescriptor = ((TypeReferenceTypeSymbol) typeSymbol).typeDescriptor();
                return validateNonAnnotatedParams(analysisContext, typeDescriptor, paramAvailability);
            }
        } else if (kind == TypeDescKind.UNION) {
            List<TypeSymbol> typeDescriptors = ((UnionTypeSymbol) typeSymbol).memberTypeDescriptors();
            return typeDescriptors.stream().anyMatch(symbol -> validateNonAnnotatedParams(analysisContext, symbol,
                                                                                          paramAvailability));
        } else if (kind == TypeDescKind.TUPLE) {
            List<TypeSymbol> tupleFieldSymbols = ((TupleTypeSymbol) typeSymbol).memberTypeDescriptors();
            return tupleFieldSymbols.stream().anyMatch(field -> validateNonAnnotatedParams(analysisContext, field,
                                                                                           paramAvailability));
        } else if (isAllowedQueryParamBasicType(kind, typeSymbol)) {
            return false;
        }
        return false;
    }

    private static void reportAmbiguousPayloadParam(SyntaxNodeAnalysisContext analysisContext, TypeSymbol typeSymbol) {
        updateDiagnostic(analysisContext, typeSymbol.getLocation().get(), HttpDiagnosticCodes.HTTP_151,
                         typeSymbol.getName());

    }
}
