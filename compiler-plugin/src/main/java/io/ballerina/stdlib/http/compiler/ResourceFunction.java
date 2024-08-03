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
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.tools.diagnostics.Location;

import java.util.Optional;

/**
 * Represents an HTTP resource function node interface.
 *
 * @since 2.12.0
 */
public interface ResourceFunction {

    Optional<MetadataNode> metadata();

    NodeList<Node> relativeResourcePath();

    FunctionSignatureNode functionSignature();

    IdentifierToken functionName();

    Location location();

    Optional<FunctionDefinitionNode> getFunctionDefinitionNode();

    Optional<Symbol> getSymbol(SemanticModel semanticModel);

    Node modifyWithSignature(FunctionSignatureNode updatedFunctionNode);

    int getResourceIdentifierCode();
}
