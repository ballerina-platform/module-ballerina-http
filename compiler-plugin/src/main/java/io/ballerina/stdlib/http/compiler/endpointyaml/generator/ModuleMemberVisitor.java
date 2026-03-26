/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
 *
 * This software is the property of WSO2 LLC. and its suppliers, if any.
 * Dissemination of any information or reproduction of any material contained
 * herein is strictly forbidden, unless permitted by WSO2 in accordance with
 * the WSO2 Commercial License available at http://wso2.com/licenses.
 * For specific language governing the permissions and limitations under
 * this license, please see the license as well as any agreement you've
 * entered into with WSO2 governing the purchase of this software and any
 * associated services.
 */

package io.ballerina.stdlib.http.compiler.endpointyaml.generator;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.BindingPatternNode;
import io.ballerina.compiler.syntax.tree.CaptureBindingPatternNode;
import io.ballerina.compiler.syntax.tree.ConstantDeclarationNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.ListenerDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeVisitor;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.TypedBindingPatternNode;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.endpointyaml.generator.EndpointYamlGenerator.unescapeIdentifier;

public class ModuleMemberVisitor extends NodeVisitor {
    private final Map<String, VariableDeclaredValue> variableDeclarations = new LinkedHashMap<>();
    private final Map<String, ListenerDeclarationNode> listenerDeclarations = new LinkedHashMap<>();
    private final SemanticModel semanticModel;

    public record VariableDeclaredValue(String value, boolean isConfigurable) {
    }

    public ModuleMemberVisitor(SemanticModel semanticModel) {
        this.semanticModel = semanticModel;
    }

    public SemanticModel getSemanticModel() {
        return this.semanticModel;
    }

    @Override
    public void visit(ModulePartNode modulePartNode) {
        // Explicitly visit all members of the module
        modulePartNode.members().forEach(member -> member.accept(this));
    }

    @Override
    public void visit(ListenerDeclarationNode listenerDeclarationNode) {
        String listenerName = unescapeIdentifier(listenerDeclarationNode.variableName().text());
        listenerDeclarations.put(listenerName, listenerDeclarationNode);
    }

    @Override
    public void visit(ModuleVariableDeclarationNode moduleVariableDeclarationNode) {
        TypedBindingPatternNode typedBindingPatternNode = moduleVariableDeclarationNode.typedBindingPattern();
        TypeDescriptorNode typeDescriptorNode = typedBindingPatternNode.typeDescriptor();
        BindingPatternNode bindingPatternNode = typedBindingPatternNode.bindingPattern();

        boolean isConfigurable = moduleVariableDeclarationNode.qualifiers().stream()
                .anyMatch(token -> token.kind().equals(SyntaxKind.CONFIGURABLE_KEYWORD));

        if (!bindingPatternNode.kind().equals(SyntaxKind.CAPTURE_BINDING_PATTERN) ||
                !(typeDescriptorNode.kind().equals(SyntaxKind.INT_TYPE_DESC) ||
                        typeDescriptorNode.kind().equals(SyntaxKind.VAR_TYPE_DESC))) {
            return;
        }

        CaptureBindingPatternNode captureBindingPatternNode = (CaptureBindingPatternNode) bindingPatternNode;
        if (captureBindingPatternNode.variableName().isMissing()) {
            return;
        }

        String variableName = unescapeIdentifier(captureBindingPatternNode.variableName().text());
        Optional<ExpressionNode> variableValue = moduleVariableDeclarationNode.initializer();

        if (variableValue.isEmpty()) {
            variableValue.ifPresent(expressionNode -> variableDeclarations.put(variableName,
                    new VariableDeclaredValue(null, isConfigurable)));

        } else {
            variableValue.ifPresent(expressionNode -> variableDeclarations.put(variableName,
                    new VariableDeclaredValue(expressionNode.toString(), isConfigurable)));
        }
    }

    @Override
    public void visit(ConstantDeclarationNode constantDeclarationNode) {
        String variableName = unescapeIdentifier(constantDeclarationNode.variableName().text());
        Node variableValue = constantDeclarationNode.initializer();
        if (variableValue instanceof ExpressionNode valueExpression) {
            // Constant declarations are always non-configurable
            variableDeclarations.put(variableName, new VariableDeclaredValue(valueExpression.toString(), false));
        }
    }

    public Optional<ListenerDeclarationNode> getListenerDeclaration(String listenerName) {
        if (listenerDeclarations.containsKey(listenerName)) {
            return Optional.of(listenerDeclarations.get(listenerName));
        }
        return Optional.empty();
    }

    public Optional<VariableDeclaredValue> getVariableDeclaredValue(String variableName) {
        if (variableDeclarations.containsKey(variableName)) {
            return Optional.of(variableDeclarations.get(variableName));
        }
        return Optional.empty();
    }

}
