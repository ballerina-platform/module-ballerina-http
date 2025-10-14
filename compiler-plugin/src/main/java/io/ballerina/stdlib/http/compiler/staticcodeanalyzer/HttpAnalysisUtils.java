/*
 * Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
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

package io.ballerina.stdlib.http.compiler.staticcodeanalyzer;

import io.ballerina.compiler.syntax.tree.AssignmentStatementNode;
import io.ballerina.compiler.syntax.tree.CheckExpressionNode;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.DoStatementNode;
import io.ballerina.compiler.syntax.tree.ExpressionFunctionBodyNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FieldAccessExpressionNode;
import io.ballerina.compiler.syntax.tree.ForEachStatementNode;
import io.ballerina.compiler.syntax.tree.FunctionBodyBlockNode;
import io.ballerina.compiler.syntax.tree.FunctionBodyNode;
import io.ballerina.compiler.syntax.tree.IfElseStatementNode;
import io.ballerina.compiler.syntax.tree.IndexedExpressionNode;
import io.ballerina.compiler.syntax.tree.LockStatementNode;
import io.ballerina.compiler.syntax.tree.MatchStatementNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ObjectTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.ReturnStatementNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.StatementNode;
import io.ballerina.compiler.syntax.tree.TypeCastExpressionNode;
import io.ballerina.compiler.syntax.tree.VariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.WhileStatementNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.models.HttpService;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.models.HttpServiceClass;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.models.HttpServiceDeclaration;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.models.HttpServiceObjectType;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isHttpServiceType;

public final class HttpAnalysisUtils {

    private HttpAnalysisUtils() {
    }

    public static HttpService getHttpService(SyntaxNodeAnalysisContext context) {
        return switch (context.node().kind()) {
            case SERVICE_DECLARATION -> {
                ServiceDeclarationNode serviceDeclarationNode = HttpCompilerPluginUtil
                        .getServiceDeclarationNode(context);
                yield serviceDeclarationNode == null ? null : new HttpServiceDeclaration(serviceDeclarationNode);
            }
            case OBJECT_TYPE_DESC -> isHttpServiceType(context.semanticModel(), context.node()) ?
                    new HttpServiceObjectType((ObjectTypeDescriptorNode) context.node()) : null;
            case CLASS_DEFINITION -> {
                ClassDefinitionNode serviceClassDefinitionNode = HttpCompilerPluginUtil
                        .getServiceClassDefinitionNode(context);
                yield serviceClassDefinitionNode == null ? null : new HttpServiceClass(serviceClassDefinitionNode);
            }
            default -> null;
        };
    }

    public record ExpressionNodeInfo(ExpressionNode expression, boolean returnExpr) {

        public ExpressionNodeInfo(ExpressionNode expression) {
            this(expression, false);
        }
    }

    public static List<ExpressionNodeInfo> extractExpressions(FunctionBodyNode functionBody) {
        switch (functionBody) {
            case ExpressionFunctionBodyNode expressionFunctionBodyNode -> {
                ExpressionNode expressionNode = getEffectiveExpression(expressionFunctionBodyNode.expression());
                return List.of(new ExpressionNodeInfo(expressionNode, true));
            }
            case FunctionBodyBlockNode functionBodyBlockNode -> {
                List<ExpressionNodeInfo> expressions = new ArrayList<>();
                addExpressions(functionBodyBlockNode.statements(), expressions);
                return expressions;
            }
            default -> {
                return List.of();
            }
        }
    }

    private static void addExpressions(NodeList<StatementNode> statements, List<ExpressionNodeInfo> expressions) {
        for (StatementNode statement : statements) {
            addExpression(expressions, statement);
        }
    }

    private static void addExpression(List<ExpressionNodeInfo> expressions, Node statement) {
        switch (statement) {
            case ReturnStatementNode returnStatementNode -> returnStatementNode.expression()
                    .map(HttpAnalysisUtils::getEffectiveExpression)
                    .ifPresent(expr -> expressions.add(new ExpressionNodeInfo(expr, true)));
            case AssignmentStatementNode assignmentNode -> expressions
                    .add(new ExpressionNodeInfo(getEffectiveExpression(assignmentNode.expression())));
            case VariableDeclarationNode variableDeclarationNode ->
                variableDeclarationNode.initializer()
                    .map(HttpAnalysisUtils::getEffectiveExpression)
                    .ifPresent(expr -> expressions.add(new ExpressionNodeInfo(expr)));
            case MatchStatementNode matchStatementNode -> matchStatementNode.matchClauses()
                    .forEach(matchClause ->
                            addExpressions(matchClause.blockStatement().statements(), expressions));
            case DoStatementNode doStatementNode ->
                    addExpressions(doStatementNode.blockStatement().statements(), expressions);
            case LockStatementNode lockStatementNode ->
                    addExpressions(lockStatementNode.blockStatement().statements(), expressions);
            case IfElseStatementNode ifElseStatementNode -> {
                addExpressions(ifElseStatementNode.ifBody().statements(), expressions);
                ifElseStatementNode.elseBody().ifPresent(value -> addExpression(expressions, value));
            }
            case ForEachStatementNode forEachStatementNode ->
                    addExpressions(forEachStatementNode.blockStatement().statements(), expressions);
            case WhileStatementNode whileStatementNode ->
                    addExpressions(whileStatementNode.whileBody().statements(), expressions);
            default -> {
            }
        }
    }

    public static ExpressionNode getEffectiveExpression(ExpressionNode expressionNode) {
        return switch (expressionNode) {
            case CheckExpressionNode checkExpressionNode -> checkExpressionNode.expression();
            case TypeCastExpressionNode castExpressionNode -> castExpressionNode.expression();
            default -> expressionNode;
        };
    }

    public static String unescapeIdentifier(String identifierName) {
        String result = identifierName;
        if (result.startsWith("'")) {
            result = result.substring(1);
        }
        return result.replace("\\\\", "");
    }

    public static Optional<String> getUsedParamName(ExpressionNode expressionNode) {
        return switch (expressionNode) {
            case SimpleNameReferenceNode simpleNameRef -> Optional.of(unescapeIdentifier(simpleNameRef.name().text()));
            case FieldAccessExpressionNode fieldAccessExpr -> getUsedParamName(fieldAccessExpr.expression());
            case IndexedExpressionNode indexedExpr -> getUsedParamName((indexedExpr).containerExpression());
            default -> Optional.empty();
        };
    }
}
