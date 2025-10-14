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
import io.ballerina.compiler.syntax.tree.OnFailClauseNode;
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

/**
 * Utility methods for HTTP static analysis.
 *
 * @since 2.15.0
 */
public final class HttpStaticAnalysisUtils {

    private HttpStaticAnalysisUtils() {
    }

    /**
     * Get the HTTP service from the given syntax node context.
     *
     * @param context Syntax node analysis context
     * @return HTTP service if the context node is a service declaration, object type descriptor or class definition
     */
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

    /**
     * A record to hold an expression node and a flag indicating if the expression is part of a return statement.
     *
     * @param expression The expression node
     * @param returnExpr True if the expression is part of a return statement, false otherwise
     */
    public record ExpressionNodeInfo(ExpressionNode expression, boolean returnExpr) {

        public ExpressionNodeInfo(ExpressionNode expression) {
            this(expression, false);
        }
    }

    /**
     * Extract all expression nodes from the given function body.
     *
     * @param functionBody The function body node
     * @return List of expression nodes found in the function body
     */
    public static List<ExpressionNodeInfo> extractExpressions(FunctionBodyNode functionBody) {
        switch (functionBody) {
            case ExpressionFunctionBodyNode expressionFunctionBodyNode -> {
                ExpressionNode expressionNode = getEffectiveExpression(expressionFunctionBodyNode.expression());
                // If the function body is an expression, then that is the returnType
                return List.of(new ExpressionNodeInfo(expressionNode, true));
            }
            case FunctionBodyBlockNode functionBodyBlockNode -> {
                List<ExpressionNodeInfo> expressions = new ArrayList<>();
                addExpressions(functionBodyBlockNode.statements(), expressions);
                return expressions;
            }
            default -> {
                // Other type is the external function body which does not have a body to analyze
                return List.of();
            }
        }
    }

    private static void addExpressions(NodeList<StatementNode> statements, List<ExpressionNodeInfo> expressions) {
        for (StatementNode statement : statements) {
            addExpression(expressions, statement);
        }
    }

    /**
     * Recursively extract expressions from various statement nodes.
     * At compiler level there is no abstraction for block statements, hence we need to handle each statement type
     * separately.
     * Currently supported direct expressions are:
     * - ReturnStatementNode
     * - AssignmentStatementNode - analyze the right-hand side expression
     * - VariableDeclarationNode - analyze the initializer expression
     * Also supports block statements like:
     * - MatchStatementNode
     * - DoStatementNode
     * - OnFailClauseNode
     * - LockStatementNode
     * - IfElseStatementNode
     * - ForEachStatementNode
     * - WhileStatementNode
     *
     * @param expressions List to collect expression nodes
     * @param statement   The statement node to analyze
     */
    private static void addExpression(List<ExpressionNodeInfo> expressions, Node statement) {
        switch (statement) {
            case ReturnStatementNode returnStatementNode -> returnStatementNode.expression()
                    .map(HttpStaticAnalysisUtils::getEffectiveExpression)
                    .ifPresent(expr -> expressions.add(new ExpressionNodeInfo(expr, true)));
            case AssignmentStatementNode assignmentNode -> expressions
                    .add(new ExpressionNodeInfo(getEffectiveExpression(assignmentNode.expression())));
            case VariableDeclarationNode variableDeclarationNode ->
                variableDeclarationNode.initializer()
                    .map(HttpStaticAnalysisUtils::getEffectiveExpression)
                    .ifPresent(expr -> expressions.add(new ExpressionNodeInfo(expr)));
            case MatchStatementNode matchStatementNode -> matchStatementNode.matchClauses()
                    .forEach(matchClause ->
                            addExpressions(matchClause.blockStatement().statements(), expressions));
            case DoStatementNode doStatementNode ->
                    addExpressions(doStatementNode.blockStatement().statements(), expressions);
            case OnFailClauseNode onFailClauseNode ->
                    addExpressions(onFailClauseNode.blockStatement().statements(), expressions);
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

    /**
     * Get the effective expression by unwrapping expressions.
     * Currently unwraps:
     * - CheckExpressionNode
     * - TypeCastExpressionNode
     *
     * @param expressionNode The original expression node
     * @return The unwrapped effective expression node
     */
    public static ExpressionNode getEffectiveExpression(ExpressionNode expressionNode) {
        return switch (expressionNode) {
            case CheckExpressionNode checkExpressionNode -> checkExpressionNode.expression();
            case TypeCastExpressionNode castExpressionNode -> castExpressionNode.expression();
            default -> expressionNode;
        };
    }

    /**
     * Unescape the given identifier name by removing leading escape quote and backslashes.
     *
     * @param identifierName The identifier name to unescape
     * @return The unescaped identifier name
     */
    public static String unescapeIdentifier(String identifierName) {
        String result = identifierName;
        if (result.startsWith("'")) {
            result = result.substring(1);
        }
        return result.replace("\\\\", "");
    }

    /**
     * Recursively extract the parameter name used in the given expression node.
     * Currently, supports:
     * - SimpleNameReferenceNode
     * - FieldAccessExpressionNode - {param}.{field}
     * - IndexedExpressionNode - {param}[{field/index}]
     *
     * @param expressionNode The expression node to analyze
     * @return Optional containing the parameter name if found, empty otherwise
     */
    public static Optional<String> getUsedParamName(ExpressionNode expressionNode) {
        return switch (expressionNode) {
            case SimpleNameReferenceNode simpleNameRef -> Optional.of(unescapeIdentifier(simpleNameRef.name().text()));
            case FieldAccessExpressionNode fieldAccessExpr -> getUsedParamName(fieldAccessExpr.expression());
            case IndexedExpressionNode indexedExpr -> getUsedParamName((indexedExpr).containerExpression());
            default -> Optional.empty();
        };
    }
}
