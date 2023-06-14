/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

package io.ballerina.stdlib.http.compiler;

import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.ListenerDeclarationNode;
import io.ballerina.compiler.syntax.tree.NewExpressionNode;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isHttpModule;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.validateListenerExpressionNode;
import static io.ballerina.stdlib.http.compiler.HttpServiceValidator.diagnosticContainsErrors;

/**
 * Validates Ballerina listener initialization.
 */
public class HttpListenerValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        if (diagnosticContainsErrors(syntaxNodeAnalysisContext)) {
            return;
        }
        ListenerDeclarationNode listenerDeclarationNode = getListenerDeclarationNode(syntaxNodeAnalysisContext);
        if (listenerDeclarationNode == null) {
            return;
        }
        validateListenerDeclarationNode(syntaxNodeAnalysisContext, listenerDeclarationNode);
    }

    private void validateListenerDeclarationNode(SyntaxNodeAnalysisContext context,
                                                 ListenerDeclarationNode listenerDeclarationNode) {
        listenerDeclarationNode.children().forEach(child -> {
            if (child instanceof NewExpressionNode) {
                validateListenerExpressionNode(context, (NewExpressionNode) child);
            }
        });
    }

    public static ListenerDeclarationNode getListenerDeclarationNode(SyntaxNodeAnalysisContext context) {
        ListenerDeclarationNode listenerDeclarationNode = (ListenerDeclarationNode) context.node();
        if (listenerDeclarationNode.typeDescriptor().isPresent()) {
            Optional<Symbol> symbol = context.semanticModel().symbol(listenerDeclarationNode.typeDescriptor().get());
            if (symbol.isPresent() && symbol.get().getModule().isPresent() &&
                    isHttpModule(symbol.get().getModule().get())) {
                return listenerDeclarationNode;
            }
        }
        return null;
    }
}
