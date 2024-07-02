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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ObjectTypeSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.MethodDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.NodeLocation;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.compiler.syntax.tree.TypeDescriptorNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;
import org.wso2.ballerinalang.compiler.diagnostic.BLangDiagnosticLocation;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

import static io.ballerina.stdlib.http.compiler.Constants.BALLERINA;
import static io.ballerina.stdlib.http.compiler.Constants.BASE_PATH;
import static io.ballerina.stdlib.http.compiler.Constants.COLON;
import static io.ballerina.stdlib.http.compiler.Constants.DEFAULT;
import static io.ballerina.stdlib.http.compiler.Constants.EMPTY;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.Constants.MEDIA_TYPE_SUBTYPE_PREFIX;
import static io.ballerina.stdlib.http.compiler.Constants.MEDIA_TYPE_SUBTYPE_REGEX;
import static io.ballerina.stdlib.http.compiler.Constants.PLUS;
import static io.ballerina.stdlib.http.compiler.Constants.REMOTE_KEYWORD;
import static io.ballerina.stdlib.http.compiler.Constants.SERVICE_CONFIG_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.Constants.SERVICE_CONTRACT_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.SERVICE_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.SUFFIX_SEPARATOR_REGEX;
import static io.ballerina.stdlib.http.compiler.Constants.UNNECESSARY_CHARS_REGEX;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.getCtxTypes;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isHttpModule;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.updateDiagnostic;
import static io.ballerina.stdlib.http.compiler.HttpDiagnostic.HTTP_101;
import static io.ballerina.stdlib.http.compiler.HttpDiagnostic.HTTP_119;
import static io.ballerina.stdlib.http.compiler.HttpDiagnostic.HTTP_120;

/**
 * Validates a Ballerina Http Service.
 */
public class HttpServiceValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        checkForServiceImplementationErrors(syntaxNodeAnalysisContext);
        if (diagnosticContainsErrors(syntaxNodeAnalysisContext)) {
            return;
        }

        ServiceDeclarationNode serviceDeclarationNode = getServiceDeclarationNode(syntaxNodeAnalysisContext);
        if (serviceDeclarationNode == null) {
            return;
        }

        Optional<TypeDescriptorNode> serviceTypeDesc = getServiceContractTypeDesc(
                syntaxNodeAnalysisContext.semanticModel(), serviceDeclarationNode);

        serviceTypeDesc.ifPresent(typeDescriptorNode ->
                checkBasePathExistence(syntaxNodeAnalysisContext, serviceDeclarationNode));

        Optional<MetadataNode> metadataNodeOptional = serviceDeclarationNode.metadata();
        metadataNodeOptional.ifPresent(metadataNode -> validateServiceAnnotation(syntaxNodeAnalysisContext,
                metadataNode, serviceTypeDesc.orElse(null), false));

        NodeList<Node> members = serviceDeclarationNode.members();
        if (serviceTypeDesc.isPresent()) {
            Set<String> resourcesFromServiceType = extractMethodsFromServiceType(serviceTypeDesc.get(),
                    syntaxNodeAnalysisContext.semanticModel());
            validateServiceContractResources(syntaxNodeAnalysisContext, resourcesFromServiceType, members,
                    serviceTypeDesc.get().toString().trim());
        } else {
            validateResources(syntaxNodeAnalysisContext, members);
        }
    }

    public static boolean isServiceContractImplementation(SemanticModel semanticModel, ServiceDeclarationNode node) {
        ServiceDeclarationNode serviceDeclarationNode = getServiceDeclarationNode(node, semanticModel);
        if (serviceDeclarationNode == null) {
            return false;
        }

        return getServiceContractTypeDesc(semanticModel, serviceDeclarationNode).isPresent();
    }

    private static Optional<TypeDescriptorNode> getServiceContractTypeDesc(SemanticModel semanticModel, Node node) {
        ServiceDeclarationNode serviceDeclarationNode = getServiceDeclarationNode(node, semanticModel);
        if (serviceDeclarationNode == null) {
            return Optional.empty();
        }

        return getServiceContractTypeDesc(semanticModel, serviceDeclarationNode);
    }

    public static Optional<TypeDescriptorNode> getServiceContractTypeDesc(SemanticModel semanticModel,
                                                                          ServiceDeclarationNode serviceDeclaration) {
        Optional<TypeDescriptorNode> serviceTypeDesc = serviceDeclaration.typeDescriptor();
        if (serviceTypeDesc.isEmpty()) {
            return Optional.empty();
        }

        Optional<Symbol> serviceTypeSymbol = semanticModel.symbol(serviceTypeDesc.get());
        if (serviceTypeSymbol.isEmpty() ||
                !(serviceTypeSymbol.get() instanceof TypeReferenceTypeSymbol serviceTypeRef)) {
            return Optional.empty();
        }

        Optional<Symbol> serviceContractType = semanticModel.types().getTypeByName(BALLERINA, HTTP, EMPTY,
                SERVICE_CONTRACT_TYPE);
        if (serviceContractType.isEmpty() ||
                !(serviceContractType.get() instanceof TypeDefinitionSymbol serviceContractTypeDef)) {
            return Optional.empty();
        }

        if (serviceTypeRef.subtypeOf(serviceContractTypeDef.typeDescriptor())) {
            return serviceTypeDesc;
        }
        return Optional.empty();
    }

    private static Set<String> extractMethodsFromServiceType(TypeDescriptorNode serviceTypeDesc,
                                                             SemanticModel semanticModel) {
        Optional<Symbol> serviceTypeSymbol = semanticModel.symbol(serviceTypeDesc);
        if (serviceTypeSymbol.isEmpty() ||
                !(serviceTypeSymbol.get() instanceof TypeReferenceTypeSymbol serviceTypeRef)) {
            return Collections.emptySet();
        }

        TypeSymbol serviceTypeRefSymbol = serviceTypeRef.typeDescriptor();
        if (!(serviceTypeRefSymbol instanceof ObjectTypeSymbol serviceObjTypeSymbol)) {
            return Collections.emptySet();
        }

        return serviceObjTypeSymbol.methods().keySet();
    }

    private static void checkBasePathExistence(SyntaxNodeAnalysisContext ctx,
                                               ServiceDeclarationNode serviceDeclarationNode) {
        NodeList<Node> nodes = serviceDeclarationNode.absoluteResourcePath();
        if (!nodes.isEmpty()) {
            reportBasePathNotAllowed(ctx, nodes);
        }
    }

    protected static void validateResources(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext,
                                            NodeList<Node> members) {
        LinksMetaData linksMetaData = new LinksMetaData();
        for (Node member : members) {
            if (member.kind() == SyntaxKind.OBJECT_METHOD_DEFINITION) {
                FunctionDefinitionNode node = (FunctionDefinitionNode) member;
                NodeList<Token> tokens = node.qualifierList();
                if (tokens.isEmpty()) {
                    // Object methods are allowed.
                    continue;
                }
                if (tokens.stream().anyMatch(token -> token.text().equals(REMOTE_KEYWORD))) {
                    reportInvalidFunctionType(syntaxNodeAnalysisContext, node);
                }
            } else if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                HttpResourceValidator.validateResource(syntaxNodeAnalysisContext, (FunctionDefinitionNode) member,
                                                       linksMetaData, getCtxTypes(syntaxNodeAnalysisContext));
            } else if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DECLARATION) {
                HttpResourceValidator.validateResource(syntaxNodeAnalysisContext, (MethodDeclarationNode) member,
                                                       linksMetaData, getCtxTypes(syntaxNodeAnalysisContext));
            }
        }

        validateResourceLinks(syntaxNodeAnalysisContext, linksMetaData);
    }

    private static void validateServiceContractResources(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext,
                                                         Set<String> resourcesFromServiceType, NodeList<Node> members,
                                                         String serviceTypeName) {
        for (Node member : members) {
            if (member.kind() == SyntaxKind.OBJECT_METHOD_DEFINITION) {
                FunctionDefinitionNode node = (FunctionDefinitionNode) member;
                NodeList<Token> tokens = node.qualifierList();
                if (tokens.isEmpty()) {
                    // Object methods are allowed.
                    continue;
                }
                if (tokens.stream().anyMatch(token -> token.text().equals(REMOTE_KEYWORD))) {
                    reportInvalidFunctionType(syntaxNodeAnalysisContext, node);
                }
            } else if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                // Only resources defined in the serviceTypeDes is allowed
                // No annotations are allowed in either in resource function or in the parameters
                HttpServiceContractResourceValidator.validateResource(syntaxNodeAnalysisContext,
                        (FunctionDefinitionNode) member, resourcesFromServiceType, serviceTypeName);
            }
        }
    }

    private static void checkForServiceImplementationErrors(SyntaxNodeAnalysisContext context) {
        Node node = context.node();
        Optional<TypeDescriptorNode> serviceContractTypeDesc = getServiceContractTypeDesc(context.semanticModel(),
                node);
        if (serviceContractTypeDesc.isEmpty()) {
            return;
        }
        String serviceType = serviceContractTypeDesc.get().toString().trim();

        NodeLocation location = node.location();
        for (Diagnostic diagnostic : context.semanticModel().diagnostics()) {
            Location diagnosticLocation = diagnostic.location();

            if (diagnostic.message().contains("no implementation found for the method 'resource function")
                    && diagnosticLocation.textRange().equals(location.textRange())
                    && diagnosticLocation.lineRange().equals(location.lineRange())) {
                enableImplementServiceContractCodeAction(context, serviceType, location);
                return;
            }
        }
    }

    public static boolean diagnosticContainsErrors(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        List<Diagnostic> diagnostics = syntaxNodeAnalysisContext.semanticModel().diagnostics();
        return diagnostics.stream()
                .anyMatch(d -> DiagnosticSeverity.ERROR.equals(d.diagnosticInfo().severity()));
    }

    public static ServiceDeclarationNode getServiceDeclarationNode(SyntaxNodeAnalysisContext context) {
        if (!(context.node() instanceof ServiceDeclarationNode serviceDeclarationNode)) {
            return null;
        }
        return getServiceDeclarationNode(serviceDeclarationNode, context.semanticModel());
    }

    public static ServiceDeclarationNode getServiceDeclarationNode(Node node, SemanticModel semanticModel) {
        if (!(node instanceof ServiceDeclarationNode serviceDeclarationNode)) {
            return null;
        }

        Optional<Symbol> serviceSymOptional = semanticModel.symbol(node);
        if (serviceSymOptional.isPresent()) {
            List<TypeSymbol> listenerTypes = ((ServiceDeclarationSymbol) serviceSymOptional.get()).listenerTypes();
            if (listenerTypes.stream().noneMatch(HttpServiceValidator::isListenerBelongsToHttpModule)) {
                return null;
            }
        }
        return serviceDeclarationNode;
    }

    private static boolean isListenerBelongsToHttpModule(TypeSymbol listenerType) {
        if (listenerType.typeKind() == TypeDescKind.UNION) {
            return ((UnionTypeSymbol) listenerType).memberTypeDescriptors().stream()
                    .filter(typeDescriptor -> typeDescriptor instanceof TypeReferenceTypeSymbol)
                    .map(typeReferenceTypeSymbol -> (TypeReferenceTypeSymbol) typeReferenceTypeSymbol)
                    .anyMatch(typeReferenceTypeSymbol -> isHttpModule(typeReferenceTypeSymbol.getModule().get()));
        }

        if (listenerType.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            return isHttpModule(((TypeReferenceTypeSymbol) listenerType).typeDescriptor().getModule().get());
        }
        return false;
    }

    private static void validateResourceLinks(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext,
                                       LinksMetaData linksMetaData) {
        if (!linksMetaData.hasNameReferenceObjects()) {
            for (Map<String, LinkedToResource> linkedToResourceMap : linksMetaData.getLinkedToResourceMaps()) {
                for (LinkedToResource linkedToResource : linkedToResourceMap.values()) {
                    if (!linkedToResource.hasNameRefMethodAvailable()) {
                        checkLinkedResourceExistence(syntaxNodeAnalysisContext, linksMetaData, linkedToResource);
                    }
                }
            }
        }
    }

    private static void checkLinkedResourceExistence(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext,
                                              LinksMetaData linksMetaData, LinkedToResource linkedToResource) {
        if (linksMetaData.getLinkedResourcesMap().containsKey(linkedToResource.getName())) {
            List<LinkedResource> linkedResources =
                    linksMetaData.getLinkedResourcesMap().get(linkedToResource.getName());
            if (linkedResources.size() == 1) {
                if (Objects.isNull(linkedToResource.getMethod())) {
                    return;
                } else if (linkedResources.get(0).getMethod().equalsIgnoreCase(DEFAULT) ||
                           linkedResources.get(0).getMethod().equals(linkedToResource.getMethod())) {
                    return;
                } else {
                    reportUnresolvedLinkedResourceWithMethod(syntaxNodeAnalysisContext, linkedToResource);
                    return;
                }
            }
            if (Objects.isNull(linkedToResource.getMethod())) {
                reportUnresolvedLinkedResource(syntaxNodeAnalysisContext, linkedToResource);
                return;
            }
            boolean found = false;
            for (LinkedResource linkedResource : linkedResources) {
                if (linkedResource.getMethod().equalsIgnoreCase(DEFAULT) ||
                        linkedResource.getMethod().equals(linkedToResource.getMethod())) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                reportUnresolvedLinkedResourceWithMethod(syntaxNodeAnalysisContext, linkedToResource);
            }
        } else {
            reportResourceNameDoesNotExist(syntaxNodeAnalysisContext, linkedToResource);
        }
    }

    protected static void validateServiceAnnotation(SyntaxNodeAnalysisContext ctx, MetadataNode metadataNode,
                                                    TypeDescriptorNode serviceTypeDesc,
                                                    boolean isServiceContractType) {
        NodeList<AnnotationNode> annotations = metadataNode.annotations();
        for (AnnotationNode annotation : annotations) {
            Node annotReference = annotation.annotReference();
            String annotName = annotReference.toString();
            Optional<MappingConstructorExpressionNode> annotValue = annotation.annotValue();
            if (annotReference.kind() != SyntaxKind.QUALIFIED_NAME_REFERENCE) {
                continue;
            }
            String[] annotStrings = annotName.split(COLON);
            if (SERVICE_CONFIG_ANNOTATION.equals(annotStrings[annotStrings.length - 1].trim())
                    && HTTP.equals(annotStrings[0].trim())) {
                if (Objects.nonNull(serviceTypeDesc)) {
                    validateAnnotationUsageForServiceContractType(ctx, annotation, annotValue.orElse(null),
                            serviceTypeDesc);
                    return;
                }
                annotValue.ifPresent(mappingConstructorExpressionNode ->
                        validateServiceConfigAnnotation(ctx, mappingConstructorExpressionNode, isServiceContractType));
            }
        }
    }

    private static void validateAnnotationUsageForServiceContractType(SyntaxNodeAnalysisContext ctx,
                                                                      AnnotationNode annotation,
                                                                      MappingConstructorExpressionNode annotValue,
                                                                      TypeDescriptorNode typeDescriptorNode) {
        if (Objects.isNull(annotValue) || annotValue.fields().isEmpty() || annotValue.fields().size() > 1) {
            reportInvalidServiceConfigAnnotationUsage(ctx, annotation.location());
            return;
        }

        MappingFieldNode field = annotValue.fields().get(0);
        String fieldString = field.toString();
        fieldString = fieldString.trim().replaceAll(UNNECESSARY_CHARS_REGEX, "");
        if (field.kind().equals(SyntaxKind.SPECIFIC_FIELD)) {
            String[] strings = fieldString.split(COLON, 2);
            if (SERVICE_TYPE.equals(strings[0].trim())) {
                String expectedServiceType = typeDescriptorNode.toString().trim();
                String actualServiceType = strings[1].trim();
                if (!actualServiceType.equals(expectedServiceType)) {
                    reportInvalidServiceContractType(ctx, expectedServiceType, actualServiceType,
                            annotation.location());
                }
                return;
            }
        }

        reportInvalidServiceConfigAnnotationUsage(ctx, annotation.location());
    }

    protected static void validateServiceConfigAnnotation(SyntaxNodeAnalysisContext ctx,
                                                          MappingConstructorExpressionNode mapping,
                                                          boolean isServiceContractType) {
        for (MappingFieldNode field : mapping.fields()) {
            String fieldName = field.toString();
            fieldName = fieldName.trim().replaceAll(UNNECESSARY_CHARS_REGEX, "");
            if (field.kind() == SyntaxKind.SPECIFIC_FIELD) {
                String[] strings = fieldName.split(COLON, 2);
                if (MEDIA_TYPE_SUBTYPE_PREFIX.equals(strings[0].trim())) {
                    if (!(strings[1].trim().matches(MEDIA_TYPE_SUBTYPE_REGEX))) {
                        reportInvalidMediaTypeSubtype(ctx, strings[1].trim(), field);
                        continue;
                    }
                    if (strings[1].trim().contains(PLUS)) {
                        String suffix = strings[1].trim().split(SUFFIX_SEPARATOR_REGEX, 2)[1];
                        reportErrorMediaTypeSuffix(ctx, suffix.trim(), field);
                    }
                } else if (SERVICE_TYPE.equals(strings[0].trim())) {
                    reportServiceTypeNotAllowedFound(ctx, field.location());
                } else if (BASE_PATH.equals(strings[0].trim()) && !isServiceContractType) {
                    reportBasePathFieldNotAllowed(ctx, field.location());
                }
            }
        }
    }

    private static void reportInvalidFunctionType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(HTTP_101.getCode(), HTTP_101.getMessage(),
                                                           HTTP_101.getSeverity());
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location()));
    }

    private static void reportInvalidMediaTypeSubtype(SyntaxNodeAnalysisContext ctx, String arg,
                                                            MappingFieldNode node) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(HTTP_120.getCode(), String.format(HTTP_120.getMessage(),
                arg), HTTP_120.getSeverity());
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location()));
    }

    private static void reportErrorMediaTypeSuffix(SyntaxNodeAnalysisContext ctx, String suffix,
                                                            MappingFieldNode node) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(HTTP_119.getCode(), String.format(HTTP_119.getMessage(),
                suffix), HTTP_119.getSeverity());
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location()));
    }

    private static void reportResourceNameDoesNotExist(SyntaxNodeAnalysisContext ctx, LinkedToResource resource) {
        updateDiagnostic(ctx, resource.getNode().location(), HttpDiagnostic.HTTP_148, resource.getName());
    }

    private static void reportUnresolvedLinkedResource(SyntaxNodeAnalysisContext ctx, LinkedToResource resource) {
        updateDiagnostic(ctx, resource.getNode().location(), HttpDiagnostic.HTTP_149);
    }

    private static void reportUnresolvedLinkedResourceWithMethod(SyntaxNodeAnalysisContext ctx,
                                                                 LinkedToResource resource) {
        updateDiagnostic(ctx, resource.getNode().location(), HttpDiagnostic.HTTP_150, resource.getMethod(),
                         resource.getName());
    }

    private static void reportInvalidServiceConfigAnnotationUsage(SyntaxNodeAnalysisContext ctx, Location location) {
        updateDiagnostic(ctx, location, HttpDiagnostic.HTTP_153);
    }

    private static void reportInvalidServiceContractType(SyntaxNodeAnalysisContext ctx, String expectedServiceType,
                                                         String actualServiceType, Location location) {
        updateDiagnostic(ctx, location, HttpDiagnostic.HTTP_156, expectedServiceType, actualServiceType);
    }

    private static void reportBasePathNotAllowed(SyntaxNodeAnalysisContext ctx, NodeList<Node> nodes) {
        Location startLocation = nodes.get(0).location();
        Location endLocation = nodes.get(nodes.size() - 1).location();
        BLangDiagnosticLocation location = new BLangDiagnosticLocation(startLocation.lineRange().fileName(),
                startLocation.lineRange().startLine().line(), startLocation.lineRange().endLine().line(),
                startLocation.lineRange().startLine().offset(), endLocation.lineRange().endLine().offset(), 0, 0);
        updateDiagnostic(ctx, location, HttpDiagnostic.HTTP_154);
    }

    private static void reportBasePathFieldNotAllowed(SyntaxNodeAnalysisContext ctx, Location location) {
        updateDiagnostic(ctx, location, HttpDiagnostic.HTTP_155);
    }

    private static void reportServiceTypeNotAllowedFound(SyntaxNodeAnalysisContext ctx, NodeLocation location) {
        updateDiagnostic(ctx, location, HttpDiagnostic.HTTP_157);
    }

    private static void enableImplementServiceContractCodeAction(SyntaxNodeAnalysisContext ctx, String serviceType,
                                                                 NodeLocation location) {
        updateDiagnostic(ctx, location, HttpDiagnostic.HTTP_HINT_105, serviceType);
    }
}
