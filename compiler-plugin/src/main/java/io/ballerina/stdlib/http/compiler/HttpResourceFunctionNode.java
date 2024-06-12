/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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
package io.ballerina.stdlib.http.compiler;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.FunctionSignatureNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.MethodDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.tools.diagnostics.Location;

import java.util.Objects;
import java.util.Optional;

/**
 * Represents an HTTP resource function node which abstracts the function definition node and method declaration node.
 *
 * @since 2.12.0
 */
public class HttpResourceFunctionNode {

    Node functionNode;
    MetadataNode metadata = null;
    NodeList<Node> resourcePath;
    FunctionSignatureNode functionSignatureNode;
    IdentifierToken functionName;

    public HttpResourceFunctionNode(FunctionDefinitionNode functionDefinitionNode) {
        functionNode = new FunctionDefinitionNode(functionDefinitionNode.internalNode(),
                functionDefinitionNode.position(), functionDefinitionNode.parent());
        functionDefinitionNode.metadata().ifPresent(metadataNode -> metadata = metadataNode);
        resourcePath = functionDefinitionNode.relativeResourcePath();
        functionSignatureNode = functionDefinitionNode.functionSignature();
        functionName = functionDefinitionNode.functionName();
    }

    public HttpResourceFunctionNode(MethodDeclarationNode methodDeclarationNode) {
        functionNode = new MethodDeclarationNode(methodDeclarationNode.internalNode(),
                methodDeclarationNode.position(), methodDeclarationNode.parent());
        methodDeclarationNode.metadata().ifPresent(metadataNode -> metadata = metadataNode);
        resourcePath = methodDeclarationNode.relativeResourcePath();
        functionSignatureNode = methodDeclarationNode.methodSignature();
        functionName = methodDeclarationNode.methodName();
    }

    public Optional<MetadataNode> metadata() {
        return Objects.isNull(metadata) ? Optional.empty() : Optional.of(metadata);
    }

    public NodeList<Node> relativeResourcePath() {
        return resourcePath;
    }

    public FunctionSignatureNode functionSignature() {
        return new FunctionSignatureNode(functionSignatureNode.internalNode(), functionSignatureNode.position(),
                functionSignatureNode.parent());
    }

    public IdentifierToken functionName() {
        return new IdentifierToken(functionName.internalNode(), functionName.position(), functionName.parent());
    }

    public Location location() {
        return functionNode.location();
    }

    public Optional<FunctionDefinitionNode> getFunctionDefinitionNode() {
        return functionNode instanceof FunctionDefinitionNode ?
                Optional.of((FunctionDefinitionNode) functionNode) : Optional.empty();
    }

    public Optional<Symbol> getSymbol(SemanticModel semanticModel) {
        return semanticModel.symbol(functionNode);
    }
}
