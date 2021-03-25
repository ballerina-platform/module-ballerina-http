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
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.Optional;

/**
 * Validates a Ballerina Http Service.
 */
public class HttpServiceValidator implements AnalysisTask<SyntaxNodeAnalysisContext> {

    private static final String CODE = "HTTP_101";

    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) syntaxNodeAnalysisContext.node();
        NodeList<Node> members = serviceDeclarationNode.members();
        for (Node member : members) {
            SyntaxKind kind = member.kind();
            if (kind == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                validateResource(syntaxNodeAnalysisContext, (FunctionDefinitionNode) member);
            }
        }

        DiagnosticInfo diagnosticInfo = new DiagnosticInfo("HTTP_101", "service declaration",
                                                           DiagnosticSeverity.INFO);
        Diagnostic diagnostic = DiagnosticFactory.createDiagnostic(diagnosticInfo, serviceDeclarationNode.location());
        syntaxNodeAnalysisContext.reportDiagnostic(diagnostic);
    }

    private void validateResource(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member) {
        Optional<ReturnTypeDescriptorNode> returnTypeDescriptorNode = member.functionSignature().returnTypeDesc();
        if (returnTypeDescriptorNode.isEmpty()) {
            return;
        }

        Node returnTypeDescriptor = returnTypeDescriptorNode.get().type();
        String returnTypeStringValue = returnTypeDescriptor.toString().split(" ")[0];

        if (returnTypeDescriptor.kind() == SyntaxKind.UNION_TYPE_DESC) {
            reportReturnTypeError(ctx, member, returnTypeStringValue);
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
            reportReturnTypeError(ctx, member, returnTypeStringValue);
        }
    }

    private void reportReturnTypeError(SyntaxNodeAnalysisContext ctx,
                                       FunctionDefinitionNode functionDefinitionNode, String returnType) {
        DiagnosticInfo diagnosticInfo =
                new DiagnosticInfo(CODE, "Invalid resource method return type : expected XYZ, but found '" +
                        returnType + "'", DiagnosticSeverity.ERROR);
        ctx.reportDiagnostic(
                DiagnosticFactory.createDiagnostic(diagnosticInfo, functionDefinitionNode.location(),
                                                   functionDefinitionNode.functionName().toString()));
    }
}
