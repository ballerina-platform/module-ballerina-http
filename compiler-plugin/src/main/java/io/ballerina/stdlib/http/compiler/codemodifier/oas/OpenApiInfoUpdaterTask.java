/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package io.ballerina.stdlib.http.compiler.codemodifier.oas;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.AbstractNodeFactory;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.NodeParser;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Package;
import io.ballerina.projects.plugins.ModifierTask;
import io.ballerina.projects.plugins.SourceModifierContext;
import io.ballerina.stdlib.http.compiler.HttpDiagnostic;
import io.ballerina.stdlib.http.compiler.codemodifier.oas.context.OpenApiDocContext;
import io.ballerina.stdlib.http.compiler.codemodifier.oas.context.ServiceNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.text.TextDocument;

import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.getDiagnosticInfo;
import static io.ballerina.stdlib.http.compiler.codemodifier.oas.context.OpenApiDocContextHandler.getContextHandler;

/**
 * {@code OpenApiInfoUpdaterTask} modifies the source by including generated open-api spec for http-service
 * declarations.
 */
public class OpenApiInfoUpdaterTask implements ModifierTask<SourceModifierContext> {
    @Override
    public void modify(SourceModifierContext context) {
        boolean erroneousCompilation = context.compilation().diagnosticResult()
                .diagnostics().stream()
                .anyMatch(d -> DiagnosticSeverity.ERROR.equals(d.diagnosticInfo().severity()));
        // if the compilation already contains any error, do not proceed
        if (erroneousCompilation) {
            return;
        }

        // Mocking the code analysis task
        mockServiceAnalyzerExecution(context);

        for (OpenApiDocContext openApiContext: getContextHandler().retrieveAvailableContexts()) {
            ModuleId moduleId = openApiContext.getModuleId();
            Module currentModule = context.currentPackage().module(moduleId);
            DocumentId documentId = openApiContext.getDocumentId();
            Document currentDoc = currentModule.document(documentId);
            ModulePartNode rootNode = currentDoc.syntaxTree().rootNode();
            NodeList<ModuleMemberDeclarationNode> newMembers = updateMemberNodes(
                    rootNode.members(), openApiContext.getOpenApiDetails(), context);
            ModulePartNode newModulePart = rootNode.modify(rootNode.imports(), newMembers, rootNode.eofToken());
            SyntaxTree updatedSyntaxTree = currentDoc.syntaxTree().modifyWith(newModulePart);
            TextDocument textDocument = updatedSyntaxTree.textDocument();
            if (currentModule.documentIds().contains(documentId)) {
                context.modifySourceFile(textDocument, documentId);
            } else {
                context.modifyTestSourceFile(textDocument, documentId);
            }
        }
    }

    private static void mockServiceAnalyzerExecution(SourceModifierContext context) {
        Package currentPackage = context.currentPackage();
        HttpServiceAnalysisTask serviceAnalysisTask = new HttpServiceAnalysisTask();
        for (ModuleId moduleId : currentPackage.moduleIds()) {
            Module currentModule = currentPackage.module(moduleId);
            SemanticModel semanticModel = context.compilation().getSemanticModel(moduleId);
            for (DocumentId documentId : currentModule.documentIds()) {
                Document currentDoc = currentModule.document(documentId);
                SyntaxTree syntaxTree = currentDoc.syntaxTree();
                ModulePartNode rootNode = syntaxTree.rootNode();
                NodeList<ModuleMemberDeclarationNode> members = rootNode.members();
                for (ModuleMemberDeclarationNode member: members) {
                    if (member.kind() != SyntaxKind.SERVICE_DECLARATION) {
                        continue;
                    }
                    ServiceNodeAnalysisContext serviceNodeAnalysisContext = new ServiceNodeAnalysisContext(
                            currentPackage, moduleId, documentId, syntaxTree, semanticModel,
                            (ServiceDeclarationNode) member);
                    serviceAnalysisTask.perform(serviceNodeAnalysisContext);
                    serviceNodeAnalysisContext.diagnostics().forEach(context::reportDiagnostic);
                }
            }
        }
    }

    private NodeList<ModuleMemberDeclarationNode> updateMemberNodes(NodeList<ModuleMemberDeclarationNode> oldMembers,
                                                                    List<OpenApiDocContext.OpenApiDefinition> openApi,
                                                                    SourceModifierContext context) {
        List<ModuleMemberDeclarationNode> updatedMembers = new LinkedList<>();
        for (ModuleMemberDeclarationNode memberNode : oldMembers) {
            if (memberNode.kind() != SyntaxKind.SERVICE_DECLARATION) {
                updatedMembers.add(memberNode);
                continue;
            }
            ServiceDeclarationNode serviceNode = (ServiceDeclarationNode) memberNode;
            Optional<OpenApiDocContext.OpenApiDefinition> openApiDefOpt = openApi.stream()
                                    .filter(service -> service.getServiceId() == serviceNode.hashCode())
                                    .findFirst();
            if (openApiDefOpt.isEmpty()) {
                updatedMembers.add(memberNode);
                continue;
            }
            OpenApiDocContext.OpenApiDefinition openApiDef = openApiDefOpt.get();
            if (!openApiDef.isAutoEmbedToService()) {
                updatedMembers.add(memberNode);
                continue;
            }
            MetadataNode metadataNode = getMetadataNode(serviceNode);
            MetadataNode.MetadataNodeModifier modifier = metadataNode.modify();
            NodeList<AnnotationNode> updatedAnnotations = updateAnnotations(
                    metadataNode.annotations(), openApiDef.getDefinition(), context);
            modifier.withAnnotations(updatedAnnotations);
            MetadataNode updatedMetadataNode = modifier.apply();
            ServiceDeclarationNode.ServiceDeclarationNodeModifier serviceDecModifier = serviceNode.modify();
            serviceDecModifier.withMetadata(updatedMetadataNode);
            ServiceDeclarationNode updatedServiceDecNode = serviceDecModifier.apply();
            updatedMembers.add(updatedServiceDecNode);
        }
        return AbstractNodeFactory.createNodeList(updatedMembers);
    }

    private MetadataNode getMetadataNode(ServiceDeclarationNode serviceNode) {
        return serviceNode.metadata().orElseGet(() -> {
            NodeList<AnnotationNode> annotations = NodeFactory.createNodeList();
            return NodeFactory.createMetadataNode(null, annotations);
        });
    }

    private NodeList<AnnotationNode> updateAnnotations(NodeList<AnnotationNode> currentAnnotations,
                                                       String openApiDefinition, SourceModifierContext context) {
        NodeList<AnnotationNode> updatedAnnotations = NodeFactory.createNodeList();
        boolean openApiAnnotationUpdated = false;
        for (AnnotationNode annotation: currentAnnotations) {
            if (isHttpServiceConfigAnnotation(annotation)) {
                openApiAnnotationUpdated = true;
                SeparatedNodeList<MappingFieldNode> updatedFields = getUpdatedFields(annotation, openApiDefinition,
                        context);
                MappingConstructorExpressionNode annotationValue =
                        NodeFactory.createMappingConstructorExpressionNode(
                                NodeFactory.createToken(SyntaxKind.OPEN_BRACE_TOKEN), updatedFields,
                                NodeFactory.createToken(SyntaxKind.CLOSE_BRACE_TOKEN));
                annotation = annotation.modify().withAnnotValue(annotationValue).apply();
            }
            updatedAnnotations = updatedAnnotations.add(annotation);
        }
        if (!openApiAnnotationUpdated) {
            AnnotationNode openApiAnnotation = getHttpServiceConfigAnnotation(openApiDefinition);
            updatedAnnotations = updatedAnnotations.add(openApiAnnotation);
        }
        return updatedAnnotations;
    }

    private SeparatedNodeList<MappingFieldNode> getUpdatedFields(AnnotationNode annotation, String servicePath,
                                                                 SourceModifierContext context) {
        Optional<MappingConstructorExpressionNode> annotationValueOpt = annotation.annotValue();
        if (annotationValueOpt.isEmpty()) {
            return NodeFactory.createSeparatedNodeList(createOpenApiDefinitionField(servicePath));
        }
        List<Node> fields = new ArrayList<>();
        MappingConstructorExpressionNode annotationValue = annotationValueOpt.get();
        SeparatedNodeList<MappingFieldNode> existingFields = annotationValue.fields();
        Token separator = NodeFactory.createToken(SyntaxKind.COMMA_TOKEN);
        MappingFieldNode openApiDefNode = null;
        for (MappingFieldNode field : existingFields) {
            if (field instanceof SpecificFieldNode) {
                String fieldName = ((SpecificFieldNode) field).fieldName().toString();
                if (Constants.OPEN_API_DEFINITION_FIELD.equals(fieldName.trim())) {
                    openApiDefNode = field;
                    continue;
                }
            }
            fields.add(field);
            fields.add(separator);
        }
        fields.add(createOpenApiDefinitionField(servicePath));
        if (Objects.nonNull(openApiDefNode)) {
            context.reportDiagnostic(DiagnosticFactory.createDiagnostic(
                    getDiagnosticInfo(HttpDiagnostic.HTTP_WARNING_102), openApiDefNode.location()));
        }
        return NodeFactory.createSeparatedNodeList(fields);
    }

    private AnnotationNode getHttpServiceConfigAnnotation(String openApiDefinition) {
        String configIdentifierString = Constants.HTTP_PACKAGE_NAME + SyntaxKind.COLON_TOKEN.stringValue() +
                Constants.SERVICE_CONFIG_ANNOTATION_IDENTIFIER;
        IdentifierToken identifierToken = NodeFactory.createIdentifierToken(configIdentifierString);
        Token atToken = NodeFactory.createToken(SyntaxKind.AT_TOKEN);
        SimpleNameReferenceNode nameReferenceNode = NodeFactory.createSimpleNameReferenceNode(identifierToken);
        MappingConstructorExpressionNode annotValue = getAnnotationExpression(openApiDefinition);
        return NodeFactory.createAnnotationNode(atToken, nameReferenceNode, annotValue);
    }

    private MappingConstructorExpressionNode getAnnotationExpression(String openApiDefinition) {
        Token openBraceToken = NodeFactory.createToken(SyntaxKind.OPEN_BRACE_TOKEN);
        Token closeBraceToken = NodeFactory.createToken(SyntaxKind.CLOSE_BRACE_TOKEN);
        SpecificFieldNode specificFieldNode = createOpenApiDefinitionField(openApiDefinition);
        SeparatedNodeList<MappingFieldNode> separatedNodeList = NodeFactory.createSeparatedNodeList(specificFieldNode);
        return NodeFactory.createMappingConstructorExpressionNode(openBraceToken, separatedNodeList, closeBraceToken);
    }

    private static SpecificFieldNode createOpenApiDefinitionField(String openApiDefinition) {
        IdentifierToken fieldName = AbstractNodeFactory.createIdentifierToken(Constants.OPEN_API_DEFINITION_FIELD);
        Token colonToken = AbstractNodeFactory.createToken(SyntaxKind.COLON_TOKEN);
        String encodedValue = Base64.getEncoder().encodeToString(openApiDefinition.getBytes(Charset.defaultCharset()));
        ExpressionNode expressionNode = NodeParser.parseExpression(
                String.format("base64 `%s`.cloneReadOnly()", encodedValue));
        return NodeFactory.createSpecificFieldNode(null, fieldName, colonToken, expressionNode);
    }

    private boolean isHttpServiceConfigAnnotation(AnnotationNode annotationNode) {
        if (!(annotationNode.annotReference() instanceof QualifiedNameReferenceNode referenceNode)) {
            return false;
        }
        if (!Constants.HTTP_PACKAGE_NAME.equals(referenceNode.modulePrefix().text())) {
            return false;
        }
        return Constants.SERVICE_CONFIG_ANNOTATION_IDENTIFIER.equals(referenceNode.identifier().text());
    }
}
