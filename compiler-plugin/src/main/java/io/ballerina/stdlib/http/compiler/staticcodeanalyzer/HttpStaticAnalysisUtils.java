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

import io.ballerina.compiler.api.symbols.IntersectionTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.AssignmentStatementNode;
import io.ballerina.compiler.syntax.tree.BasicLiteralNode;
import io.ballerina.compiler.syntax.tree.BlockStatementNode;
import io.ballerina.compiler.syntax.tree.CheckExpressionNode;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.DoStatementNode;
import io.ballerina.compiler.syntax.tree.ElseBlockNode;
import io.ballerina.compiler.syntax.tree.ExpressionFunctionBodyNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.ExpressionStatementNode;
import io.ballerina.compiler.syntax.tree.FieldAccessExpressionNode;
import io.ballerina.compiler.syntax.tree.ForEachStatementNode;
import io.ballerina.compiler.syntax.tree.FunctionBodyBlockNode;
import io.ballerina.compiler.syntax.tree.FunctionBodyNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.IfElseStatementNode;
import io.ballerina.compiler.syntax.tree.IndexedExpressionNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.LockStatementNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MatchStatementNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ObjectTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.OnFailClauseNode;
import io.ballerina.compiler.syntax.tree.ReturnStatementNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.StatementNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeCastExpressionNode;
import io.ballerina.compiler.syntax.tree.TypeCastParamNode;
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
            default -> {
                String errorMessage = String.format("Unexpected node kind: %s. Expected SERVICE_DECLARATION, " +
                        "OBJECT_TYPE_DESC or CLASS_DEFINITION.", context.node().kind());
                throw new IllegalStateException(errorMessage);
            }
        };
    }

    /**
     * Extract all expression nodes from the given function body.
     *
     * @param functionBody The function body node
     * @return List of expression nodes found in the function body
     */
    public static List<ExpressionNodeInfo> extractExpressions(FunctionBodyNode functionBody) {
        switch (functionBody) {
            case ExpressionFunctionBodyNode expressionFunctionBodyNode:
                ExpressionNode expressionNode = expressionFunctionBodyNode.expression();
                // If the function body is an expression, then that is the returnType
                return List.of(new ExpressionNodeInfo(expressionNode, true));
            case FunctionBodyBlockNode functionBodyBlockNode:
                List<ExpressionNodeInfo> expressions = new ArrayList<>();
                addExpressions(functionBodyBlockNode.statements(), expressions);
                return expressions;
            default:
                // Other type is the external function body which does not have a body to analyze
                // Will not reach here since external resource functions are not supported
                // for services yet
                return List.of();
        }
    }

    private static void addExpressions(NodeList<StatementNode> statements, List<ExpressionNodeInfo> expressions) {
        for (StatementNode statement : statements) {
            addExpression(expressions, statement);
        }
    }

    /**
     * Recursively extract expressions from various statement nodes.
     * At the compiler level there is no abstraction for all block statements, hence we need to handle each
     * statement type separately.
     * Currently supported direct expressions are:
     * - BlockStatementNode - analyze inner statements recursively
     * - ReturnStatementNode
     * - AssignmentStatementNode - analyze the right-hand side expression
     * - VariableDeclarationNode - analyze the initializer expression
     * - ExpressionStatementNode - a call or action invoked for its effect, with its result unused
     * Also supports block statements like:
     * - MatchStatementNode
     * - DoStatementNode
     * - OnFailClauseNode
     * - LockStatementNode
     * - IfElseStatementNode
     * - ElseBlockNode
     * - ForEachStatementNode
     * - WhileStatementNode
     *
     * @param expressions List to collect expression nodes
     * @param statement   The statement node to analyze
     */
    private static void addExpression(List<ExpressionNodeInfo> expressions, Node statement) {
        switch (statement) {
            case BlockStatementNode blockStatementNode ->
                    addExpressions(blockStatementNode.statements(), expressions);
            case ReturnStatementNode returnStatementNode -> returnStatementNode.expression()
                    .ifPresent(expr -> expressions.add(new ExpressionNodeInfo(expr, true)));
            case AssignmentStatementNode assignmentNode -> expressions
                    .add(new ExpressionNodeInfo(assignmentNode.expression()));
            case VariableDeclarationNode variableDeclarationNode ->
                variableDeclarationNode.initializer()
                    .ifPresent(expr -> expressions.add(new ExpressionNodeInfo(expr)));
            case MatchStatementNode matchStatementNode -> matchStatementNode.matchClauses()
                    .forEach(matchClause ->
                            addExpressions(matchClause.blockStatement().statements(), expressions));
            case DoStatementNode doStatementNode -> {
                    addExpressions(doStatementNode.blockStatement().statements(), expressions);
                    doStatementNode.onFailClause().ifPresent(value -> addExpression(expressions, value));
            }
            case OnFailClauseNode onFailClauseNode ->
                    addExpressions(onFailClauseNode.blockStatement().statements(), expressions);
            case LockStatementNode lockStatementNode ->
                    addExpressions(lockStatementNode.blockStatement().statements(), expressions);
            case IfElseStatementNode ifElseStatementNode -> {
                addExpressions(ifElseStatementNode.ifBody().statements(), expressions);
                ifElseStatementNode.elseBody().ifPresent(value -> addExpression(expressions, value));
            }
            case ElseBlockNode elseBlockNode ->
                    addExpression(expressions, elseBlockNode.elseBody());
            case ExpressionStatementNode expressionStatementNode -> expressions
                    .add(new ExpressionNodeInfo(expressionStatementNode.expression()));
            case ForEachStatementNode forEachStatementNode ->
                    addExpressions(forEachStatementNode.blockStatement().statements(), expressions);
            case WhileStatementNode whileStatementNode ->
                    addExpressions(whileStatementNode.whileBody().statements(), expressions);
            default -> {
                // Other statement types are not handled currently
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
     * If the given expression node is a TypeCastExpressionNode, return the casting type node.
     *
     * @param expressionNode The expression node to analyze
     * @return Optional containing the casting type node if present, empty otherwise
     */
    public static Optional<Node> getCastingType(ExpressionNode expressionNode) {
        if (expressionNode instanceof TypeCastExpressionNode typeCastExpressionNode) {
            TypeCastParamNode typeCastParamNode = typeCastExpressionNode.typeCastParam();
            return typeCastParamNode.type();
        }
        return Optional.empty();
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

    /**
     * Find a specific field by name within a mapping constructor.
     * <p>
     * Computed and spread fields cannot be resolved statically and are skipped.
     *
     * @param mapNode   the mapping constructor to search
     * @param fieldName the field name to look for
     * @return the matching field if present, empty otherwise
     */
    public static Optional<SpecificFieldNode> findSpecificField(MappingConstructorExpressionNode mapNode,
                                                                String fieldName) {
        return mapNode.fields().stream()
                .filter(field -> field.kind() == SyntaxKind.SPECIFIC_FIELD)
                .map(field -> (SpecificFieldNode) field)
                .filter(field -> matchesFieldName(field.fieldName(), fieldName, false))
                .findFirst();
    }

    /**
     * Check whether the given field name node matches the expected field name.
     * Handles both plain identifiers and quoted string field names.
     *
     * @param fieldNameNode     the field name node to check
     * @param expectedFieldName the expected field name
     * @param ignoreCase        whether to compare case-insensitively
     * @return true if the field name matches, false otherwise
     */
    public static boolean matchesFieldName(Node fieldNameNode, String expectedFieldName, boolean ignoreCase) {
        String fieldName;
        if (fieldNameNode instanceof IdentifierToken identifierToken) {
            fieldName = unescapeIdentifier(identifierToken.text());
        } else if (fieldNameNode instanceof BasicLiteralNode basicLiteralNode) {
            String literal = basicLiteralNode.literalToken().text();
            fieldName = literal.substring(1, literal.length() - 1);
        } else {
            return false;
        }
        return ignoreCase ? fieldName.equalsIgnoreCase(expectedFieldName) : fieldName.equals(expectedFieldName);
    }

    /**
     * Get the value expression of a named field within a mapping constructor.
     *
     * @param mapNode   the mapping constructor to search
     * @param fieldName the field name to look for
     * @return the field value if present, empty otherwise
     */
    public static Optional<ExpressionNode> getFieldValue(MappingConstructorExpressionNode mapNode, String fieldName) {
        return findSpecificField(mapNode, fieldName).flatMap(SpecificFieldNode::valueExpr);
    }

    /**
     * Get a named field whose value is itself a mapping constructor.
     *
     * @param mapNode   the mapping constructor to search
     * @param fieldName the field name to look for
     * @return the nested mapping constructor if present, empty otherwise
     */
    public static Optional<MappingConstructorExpressionNode> getNestedMapping(
            MappingConstructorExpressionNode mapNode, String fieldName) {
        return getFieldValue(mapNode, fieldName)
                .map(HttpStaticAnalysisUtils::getEffectiveExpression)
                .filter(MappingConstructorExpressionNode.class::isInstance)
                .map(MappingConstructorExpressionNode.class::cast);
    }

    /**
     * Get the value of a boolean literal expression.
     * <p>
     * Only a literal is actionable. A variable or a computed expression cannot be resolved without data-flow
     * analysis, and reporting on one would be a guess, so those yield an empty result.
     *
     * @param expression the expression to read
     * @return the literal value if the expression is a boolean literal, empty otherwise
     */
    public static Optional<Boolean> getBooleanLiteralValue(ExpressionNode expression) {
        String source = expression.toSourceCode().trim();
        if (Boolean.TRUE.toString().equals(source)) {
            return Optional.of(true);
        }
        if (Boolean.FALSE.toString().equals(source)) {
            return Optional.of(false);
        }
        return Optional.empty();
    }

    /**
     * Get the value of an integer literal expression, including a negated one such as {@code -1}.
     *
     * @param expression the expression to read
     * @return the literal value if the expression is an integer literal, empty otherwise
     */
    public static Optional<Long> getIntegerLiteralValue(ExpressionNode expression) {
        try {
            return Optional.of(Long.parseLong(expression.toSourceCode().trim()));
        } catch (NumberFormatException e) {
            return Optional.empty();
        }
    }

    /**
     * Get the value of a string literal expression, with the surrounding quotes removed.
     *
     * @param expression the expression to read
     * @return the literal value if the expression is a string literal, empty otherwise
     */
    public static Optional<String> getStringLiteralValue(ExpressionNode expression) {
        String source = expression.toSourceCode().trim();
        if (source.length() >= 2 && source.startsWith("\"") && source.endsWith("\"")) {
            return Optional.of(source.substring(1, source.length() - 1));
        }
        return Optional.empty();
    }

    /**
     * Get the element expressions of a list constructor.
     *
     * @param expression the expression to read
     * @return the list elements, or an empty list if the expression is not a list constructor
     */
    public static List<ExpressionNode> getListElements(ExpressionNode expression) {
        if (!(getEffectiveExpression(expression) instanceof ListConstructorExpressionNode listConstructor)) {
            return List.of();
        }
        return listConstructor.expressions().stream()
                .filter(ExpressionNode.class::isInstance)
                .map(ExpressionNode.class::cast)
                .toList();
    }

    /**
     * Resolve the type produced by a constructor expression.
     * <p>
     * A {@code new} expression on a type whose {@code init} can fail is typed as a union of the constructed type
     * and an error, and a {@code readonly &} construction is typed as an intersection. Both are unwrapped here so
     * callers see the constructed type itself.
     *
     * @param typeSymbol the type of the constructor expression
     * @return the constructed type
     */
    public static TypeSymbol resolveConstructedType(TypeSymbol typeSymbol) {
        TypeSymbol effective = typeSymbol;
        if (effective instanceof IntersectionTypeSymbol intersectionTypeSymbol) {
            effective = intersectionTypeSymbol.effectiveTypeDescriptor();
        }
        if (effective instanceof UnionTypeSymbol unionTypeSymbol) {
            List<TypeSymbol> constructedTypes = unionTypeSymbol.memberTypeDescriptors().stream()
                    .filter(member -> !isErrorType(member))
                    .toList();
            if (constructedTypes.size() == 1) {
                effective = constructedTypes.get(0);
            }
        }
        return effective;
    }

    private static boolean isErrorType(TypeSymbol typeSymbol) {
        TypeSymbol effective = typeSymbol instanceof TypeReferenceTypeSymbol typeReferenceTypeSymbol ?
                typeReferenceTypeSymbol.typeDescriptor() : typeSymbol;
        return effective.typeKind() == TypeDescKind.ERROR;
    }
}
