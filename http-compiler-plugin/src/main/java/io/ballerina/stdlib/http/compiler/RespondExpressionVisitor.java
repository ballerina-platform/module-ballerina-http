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

import io.ballerina.compiler.api.ModuleID;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.NodeVisitor;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.RemoteMethodCallActionNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.ArrayList;
import java.util.List;

/**
 * A class for visiting respond expression.
 */
public class RespondExpressionVisitor extends NodeVisitor {
    private final SyntaxNodeAnalysisContext ctx;
    private final String callerToken;
    private List<PositionalArgumentNode> respondStatementNodes = new ArrayList<>();

    RespondExpressionVisitor(SyntaxNodeAnalysisContext ctx, String callerToken) {
        this.ctx = ctx;
        this.callerToken = callerToken;
    }

    @Override
    public void visit(RemoteMethodCallActionNode node) {
        SimpleNameReferenceNode simpleNameReferenceNode = node.methodName();
        if (!simpleNameReferenceNode.name().text().equals(Constants.RESPOND_METHOD_NAME)) {
            return;
        }
        TypeSymbol typeSymbol = ctx.semanticModel().type(node.expression()).get();
        ModuleID moduleID = typeSymbol.getModule().get().id();
        if (!Constants.BALLERINA.equals(moduleID.orgName())) {
            return;
        }
        if (!Constants.HTTP.equals(moduleID.moduleName())) {
            return;
        }
        if (!Constants.CALLER_OBJ_NAME.equals(typeSymbol.getName().get())) {
            return;
        }
        if (!callerToken.equals(node.expression().toString())) {
            return;
        }
        if (node.arguments().size() > 0) {
            respondStatementNodes.add((PositionalArgumentNode) node.arguments().get(0));
        }
    }

    List<PositionalArgumentNode> getRespondStatementNodes() {
        return respondStatementNodes;
    }
}
