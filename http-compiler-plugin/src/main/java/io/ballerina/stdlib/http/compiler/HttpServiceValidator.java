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

import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;

import static io.ballerina.stdlib.http.compiler.Constants.HTTP_101;
import static io.ballerina.stdlib.http.compiler.Constants.REMOTE_KEYWORD;
import static io.ballerina.stdlib.http.compiler.Constants.REMOTE_METHODS_NOT_ALLOWED;
import static io.ballerina.tools.diagnostics.DiagnosticSeverity.ERROR;

/**
 * Validates a Ballerina Http Service.
 */
public class HttpServiceValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) syntaxNodeAnalysisContext.node();
        NodeList<Node> members = serviceDeclarationNode.members();
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
                HttpResourceValidator.validateResource(syntaxNodeAnalysisContext, (FunctionDefinitionNode) member);
            }
        }
    }

    private void reportInvalidFunctionType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(HTTP_101, REMOTE_METHODS_NOT_ALLOWED, ERROR);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location()));
    }
}
