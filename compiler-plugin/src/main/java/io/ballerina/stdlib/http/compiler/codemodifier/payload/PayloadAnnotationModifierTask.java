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

import io.ballerina.compiler.syntax.tree.AbstractNodeFactory;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.FunctionSignatureNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.MethodDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeFactory;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ObjectTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.ParameterNode;
import io.ballerina.compiler.syntax.tree.RequiredParameterNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.plugins.ModifierTask;
import io.ballerina.projects.plugins.SourceModifierContext;
import io.ballerina.stdlib.http.compiler.Constants;
import io.ballerina.stdlib.http.compiler.ResourceFunction;
import io.ballerina.stdlib.http.compiler.ResourceFunctionDeclaration;
import io.ballerina.stdlib.http.compiler.ResourceFunctionDefinition;
import io.ballerina.stdlib.http.compiler.codemodifier.payload.context.PayloadParamContext;
import io.ballerina.stdlib.http.compiler.codemodifier.payload.context.ResourcePayloadParamContext;
import io.ballerina.stdlib.http.compiler.codemodifier.payload.context.ServicePayloadParamContext;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.text.TextDocument;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isHttpServiceType;
import static io.ballerina.stdlib.http.compiler.HttpServiceValidator.isServiceContractImplementation;

/**
 * {@code HttpPayloadParamIdentifier} injects the @http:Payload annotation to the Payload param which found during the
 * initial analysis.
 *
 * @since 2201.5.0
 */
public class PayloadAnnotationModifierTask implements ModifierTask<SourceModifierContext> {

    private final Map<DocumentId, PayloadParamContext> documentContextMap;

    public PayloadAnnotationModifierTask(Map<DocumentId, PayloadParamContext> documentContextMap) {
        this.documentContextMap = documentContextMap;
    }

    @Override
    public void modify(SourceModifierContext modifierContext) {
        boolean erroneousCompilation = modifierContext.compilation().diagnosticResult()
                .diagnostics().stream()
                .anyMatch(d -> DiagnosticSeverity.ERROR.equals(d.diagnosticInfo().severity()));
        if (erroneousCompilation) {
            return;
        }

        for (Map.Entry<DocumentId, PayloadParamContext> entry : documentContextMap.entrySet()) {
            DocumentId documentId = entry.getKey();
            PayloadParamContext documentContext = entry.getValue();
            modifyPayloadParam(modifierContext, documentId, documentContext);
        }
    }

    private void modifyPayloadParam(SourceModifierContext modifierContext, DocumentId documentId,
                                    PayloadParamContext documentContext) {
        ModuleId moduleId = documentId.moduleId();
        Module currentModule = modifierContext.currentPackage().module(moduleId);
        Document currentDoc = currentModule.document(documentId);
        ModulePartNode rootNode = currentDoc.syntaxTree().rootNode();
        NodeList<ModuleMemberDeclarationNode> newMembers = updateMemberNodes(rootNode.members(), documentContext);
        ModulePartNode newModulePart = rootNode.modify(rootNode.imports(), newMembers, rootNode.eofToken());
        SyntaxTree updatedSyntaxTree = currentDoc.syntaxTree().modifyWith(newModulePart);
        TextDocument textDocument = updatedSyntaxTree.textDocument();
        if (currentModule.documentIds().contains(documentId)) {
            modifierContext.modifySourceFile(textDocument, documentId);
        } else {
            modifierContext.modifyTestSourceFile(textDocument, documentId);
        }
    }

    private NodeList<ModuleMemberDeclarationNode> updateMemberNodes(NodeList<ModuleMemberDeclarationNode> oldMembers,
                                                                    PayloadParamContext documentContext) {

        List<ModuleMemberDeclarationNode> updatedMembers = new ArrayList<>();
        for (ModuleMemberDeclarationNode memberNode : oldMembers) {
            int serviceId;
            NodeList<Node> members;
            if (memberNode.kind() == SyntaxKind.SERVICE_DECLARATION &&
                    !isServiceContractImplementation(documentContext.getContext().semanticModel(),
                            (ServiceDeclarationNode) memberNode)) {
                ServiceDeclarationNode serviceNode = (ServiceDeclarationNode) memberNode;
                serviceId = serviceNode.hashCode();
                members = serviceNode.members();
            } else if (memberNode.kind() == SyntaxKind.CLASS_DEFINITION) {
                ClassDefinitionNode classDefinitionNode = (ClassDefinitionNode) memberNode;
                serviceId = classDefinitionNode.hashCode();
                members = classDefinitionNode.members();
            } else if (memberNode.kind() == SyntaxKind.TYPE_DEFINITION && isHttpServiceType(documentContext.
                    getContext().semanticModel(), ((TypeDefinitionNode) memberNode).typeDescriptor())) {
                ObjectTypeDescriptorNode serviceTypeDesNode = (ObjectTypeDescriptorNode)
                        ((TypeDefinitionNode) memberNode).typeDescriptor();
                serviceId = serviceTypeDesNode.hashCode();
                members = serviceTypeDesNode.members();
            } else {
                updatedMembers.add(memberNode);
                continue;
            }

            if (!documentContext.containsService(serviceId)) {
                updatedMembers.add(memberNode);
                continue;
            }
            ServicePayloadParamContext serviceContext = documentContext.getServiceContext(serviceId);
            List<Node> resourceMembers = new ArrayList<>();
            for (Node member : members) {
                ResourceFunction resourceFunctionNode;
                if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                    resourceFunctionNode = new ResourceFunctionDefinition((FunctionDefinitionNode) member);
                } else if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DECLARATION) {
                    resourceFunctionNode = new ResourceFunctionDeclaration((MethodDeclarationNode) member);
                } else {
                    resourceMembers.add(member);
                    continue;
                }

                int resourceId = member.hashCode();

                if (!serviceContext.containsResource(resourceId)) {
                    resourceMembers.add(member);
                    continue;
                }
                ResourcePayloadParamContext resourceContext = serviceContext.getResourceContext(resourceId);
                FunctionSignatureNode functionSignatureNode = resourceFunctionNode.functionSignature();
                SeparatedNodeList<ParameterNode> parameterNodes = functionSignatureNode.parameters();
                List<Node> newParameterNodes = new ArrayList<>();
                int index = 0;
                for (ParameterNode parameterNode : parameterNodes) {
                    if (index++ != resourceContext.getIndex()) {
                        newParameterNodes.add(parameterNode);
                        newParameterNodes.add(AbstractNodeFactory.createToken(SyntaxKind.COMMA_TOKEN));
                        continue;
                    }
                    RequiredParameterNode param = (RequiredParameterNode) parameterNode;
                    //add the annotation
                    AnnotationNode payloadAnnotation = getHttpPayloadAnnotation();
                    NodeList<AnnotationNode> annotations = param.annotations();
                    if (Objects.isNull(annotations)) {
                        annotations = NodeFactory.createNodeList();
                    }
                    NodeList<AnnotationNode> updatedAnnotations = annotations.add(payloadAnnotation);
                    RequiredParameterNode.RequiredParameterNodeModifier paramModifier = param.modify();
                    paramModifier.withAnnotations(updatedAnnotations);
                    RequiredParameterNode updatedParam = paramModifier.apply();
                    newParameterNodes.add(updatedParam);
                    newParameterNodes.add(AbstractNodeFactory.createToken(SyntaxKind.COMMA_TOKEN));
                }
                if (newParameterNodes.size() > 1) {
                    newParameterNodes.remove(newParameterNodes.size() - 1);
                }

                FunctionSignatureNode.FunctionSignatureNodeModifier signatureModifier = functionSignatureNode.modify();
                SeparatedNodeList<ParameterNode> separatedNodeList = AbstractNodeFactory.createSeparatedNodeList(
                        new ArrayList<>(newParameterNodes));
                signatureModifier.withParameters(separatedNodeList);
                FunctionSignatureNode updatedFunctionNode = signatureModifier.apply();
                Node updatedResourceNode = resourceFunctionNode.modifyWithSignature(updatedFunctionNode);
                resourceMembers.add(updatedResourceNode);
            }
            NodeList<Node> resourceNodeList = AbstractNodeFactory.createNodeList(resourceMembers);
            if (memberNode instanceof ServiceDeclarationNode serviceNode) {
                ServiceDeclarationNode.ServiceDeclarationNodeModifier serviceDeclarationNodeModifier =
                        serviceNode.modify();
                ServiceDeclarationNode updatedServiceDeclarationNode =
                        serviceDeclarationNodeModifier.withMembers(resourceNodeList).apply();
                updatedMembers.add(updatedServiceDeclarationNode);
            } else if (memberNode instanceof ClassDefinitionNode classDefinitionNode) {
                ClassDefinitionNode.ClassDefinitionNodeModifier classDefinitionNodeModifier =
                        classDefinitionNode.modify();
                ClassDefinitionNode updatedClassDefinitionNode =
                        classDefinitionNodeModifier.withMembers(resourceNodeList).apply();
                updatedMembers.add(updatedClassDefinitionNode);
            } else {
                TypeDefinitionNode typeDefinitionNode = (TypeDefinitionNode) memberNode;
                ObjectTypeDescriptorNode objectTypeDescriptorNode = (ObjectTypeDescriptorNode) typeDefinitionNode
                        .typeDescriptor();
                ObjectTypeDescriptorNode.ObjectTypeDescriptorNodeModifier objectTypeDescriptorNodeModifier =
                        objectTypeDescriptorNode.modify();
                ObjectTypeDescriptorNode updatedObjectTypeDescriptorNode =
                        objectTypeDescriptorNodeModifier.withMembers(resourceNodeList).apply();
                TypeDefinitionNode.TypeDefinitionNodeModifier typeDefinitionNodeModifier = typeDefinitionNode.modify();
                TypeDefinitionNode updatedTypeDefinitionNode = typeDefinitionNodeModifier.withTypeDescriptor(
                        updatedObjectTypeDescriptorNode).apply();
                updatedMembers.add(updatedTypeDefinitionNode);
            }
        }
        return AbstractNodeFactory.createNodeList(updatedMembers);
    }

    private AnnotationNode getHttpPayloadAnnotation() {
        String payloadIdentifierString = Constants.HTTP + SyntaxKind.COLON_TOKEN.stringValue() +
                Constants.PAYLOAD_ANNOTATION + Constants.SPACE;
        IdentifierToken identifierToken = NodeFactory.createIdentifierToken(payloadIdentifierString);
        SimpleNameReferenceNode nameReferenceNode = NodeFactory.createSimpleNameReferenceNode(identifierToken);
        Token atToken = NodeFactory.createToken(SyntaxKind.AT_TOKEN);
        return NodeFactory.createAnnotationNode(atToken, nameReferenceNode, null);
    }
}
