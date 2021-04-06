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
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;

import java.util.Optional;

import static io.ballerina.tools.diagnostics.DiagnosticSeverity.ERROR;

/**
 * Validates a Ballerina Http Service.
 */
public class HttpServiceValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    private static final String HTTP_101 = "HTTP_101";
    private static final String HTTP_102 = "HTTP_102";
    private static final String REMOTE = "remote";

    public static final String REMOTE_METHODS_NOT_ALLOWED = "`remote` methods are not allowed in http:Service";

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
                if (tokens.stream().anyMatch(token -> token.text().equals(REMOTE))) {
                    reportInvalidFunctionType(syntaxNodeAnalysisContext, node);
                }
            } else if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                validateResource(syntaxNodeAnalysisContext, (FunctionDefinitionNode) member);
            }
        }

//        DiagnosticInfo diagnosticInfo = new DiagnosticInfo("HTTP_101", "service declaration",
//                                                           DiagnosticSeverity.INFO);
//        Diagnostic diagnostic = DiagnosticFactory.createDiagnostic(diagnosticInfo, serviceDeclarationNode.location());
//        syntaxNodeAnalysisContext.reportDiagnostic(diagnostic);
    }

    private void reportInvalidFunctionType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(HTTP_101, REMOTE_METHODS_NOT_ALLOWED, ERROR);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location()));
    }

    private void validateResource(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member) {
        Optional<ReturnTypeDescriptorNode> returnTypeDescriptorNode = member.functionSignature().returnTypeDesc();
        if (returnTypeDescriptorNode.isEmpty()) {
            return;
        }

        Node returnTypeDescriptor = returnTypeDescriptorNode.get().type();
        String returnTypeStringValue = returnTypeDescriptor.toString().split(" ")[0];

        if (returnTypeDescriptor.kind() == SyntaxKind.UNION_TYPE_DESC) {
            reportInvalidReturnType(ctx, member, returnTypeStringValue);
        } else if (returnTypeDescriptor.kind() == SyntaxKind.STRING_TYPE_DESC ||
                returnTypeDescriptor.kind() == SyntaxKind.INT_TYPE_DESC ||
                returnTypeDescriptor.kind() == SyntaxKind.FLOAT_TYPE_DESC ||
                returnTypeDescriptor.kind() == SyntaxKind.DECIMAL_TYPE_DESC ||
                returnTypeDescriptor.kind() == SyntaxKind.BOOLEAN_TYPE_DESC ||
                returnTypeDescriptor.kind() == SyntaxKind.JSON_TYPE_DESC ||
                returnTypeDescriptor.kind() == SyntaxKind.XML_TYPE_DESC ||
                returnTypeDescriptor.kind() == SyntaxKind.RECORD_TYPE_DESC) {
            return;
        } else {
            reportInvalidReturnType(ctx, member, returnTypeStringValue);
        }
    }

    private void reportInvalidReturnType(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode node,
                                         String returnType) {
        DiagnosticInfo diagnosticInfo =
                new DiagnosticInfo(HTTP_101, "Invalid resource method return type : expected XYZ, but found '" +
                        returnType + "'", ERROR);
        ctx.reportDiagnostic(
                DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location(), node.functionName().toString()));
    }
}
