/*
 * Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org)
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

package io.ballerina.stdlib.http.compiler.staticcodeanalyzer;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.VariableSymbol;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.ExpressionStatementNode;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.FunctionBodyBlockNode;
import io.ballerina.compiler.syntax.tree.MethodCallExpressionNode;
import io.ballerina.compiler.syntax.tree.NamedArgumentNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.ReturnStatementNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.StatementNode;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.scan.Reporter;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_VULNERABLE_XSS_ENDPOINTS;

class HttpReturnResponseAnalyzer implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final Reporter reporter;
    private SemanticModel semanticModel = null;
    private static final String RESPONSE = "Response";
    private static final String SET_PAYLOAD = "setPayload";
    private static final String SET_HEADER = "setHeader";
    private static final String CONTENT_TYPE = "content-type";
    private static final String TEXT_PLAIN = "text/plain";

    public HttpReturnResponseAnalyzer(Reporter reporter) {
        this.reporter = reporter;
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        ReturnStatementNode returnStatement = (ReturnStatementNode) context.node();
        semanticModel = context.semanticModel();
        if (returnStatement.expression().isEmpty()) {
            return;
        }
        ExpressionNode expression = returnStatement.expression().get();
        if (!(expression instanceof SimpleNameReferenceNode simpleNameReference)
                || !isResponseObject(simpleNameReference)) {
            return;
        }
        if (!hasUserInputInPayload(simpleNameReference.name().toString().trim(), returnStatement)) {
            return;
        }
        if (!hasVulnerableHeader(simpleNameReference.name().toString().trim(), returnStatement)) {
            return;
        }
        report(context, AVOID_VULNERABLE_XSS_ENDPOINTS.getId());
    }

    /**
     * Checks if the given SimpleNameReferenceNode refers to a Response object.
     *
     * @param simpleNameReference the SimpleNameReferenceNode to check
     * @return true if it refers to a Response object, false otherwise
     */
    private boolean isResponseObject(SimpleNameReferenceNode simpleNameReference) {
        if (semanticModel.symbol(simpleNameReference).isEmpty()) {
            return false;
        }
        Symbol symbol = semanticModel.symbol(simpleNameReference).get();
        if (symbol instanceof VariableSymbol variableSymbol) {
            TypeReferenceTypeSymbol typeReferenceType = (TypeReferenceTypeSymbol) variableSymbol.typeDescriptor();
            return typeReferenceType.typeDescriptor() instanceof ClassSymbol classSymbol
                    && classSymbol.getName().isPresent()
                    && RESPONSE.equals(classSymbol.getName().get());
        }
        return false;
    }

    /**
     * Checks if the payload of the Response object is set with user input.
     *
     * @param varName         the name of the variable holding the Response object
     * @param returnStatement the ReturnStatementNode containing the Response object
     * @return true if user input is found in the payload, false otherwise
     */
    private boolean hasUserInputInPayload(String varName, ReturnStatementNode returnStatement) {
        Node parent = returnStatement;
        while (parent != null) {
            if (parent instanceof FunctionBodyBlockNode) {
                break;
            }
            parent = parent.parent();
        }

        if (parent == null) {
            return false;
        }

        FunctionBodyBlockNode functionBodyBlockNode = (FunctionBodyBlockNode) parent;
        for (StatementNode statement : functionBodyBlockNode.statements()) {
            if (statement instanceof ExpressionStatementNode expressionStatement) {
                ExpressionNode expression = expressionStatement.expression();
                if (expression instanceof MethodCallExpressionNode methodCallExpression
                        && methodCallExpression.expression().toString().trim().equals(varName)
                        && methodCallExpression.methodName().toString().trim().equals(SET_PAYLOAD)) {
                    return isUserInput(methodCallExpression.arguments());
                }
            }
        }
        return false;
    }

    /**
     * Checks if any of the arguments in the method call are user inputs.
     *
     * @param arguments the list of function arguments
     * @return true if any argument is a user input, false otherwise
     */
    private boolean isUserInput(SeparatedNodeList<FunctionArgumentNode> arguments) {
        for (FunctionArgumentNode argument : arguments) {
            if (semanticModel.symbol(argument).isEmpty()) {
                return false;
            }
            Symbol symbol = semanticModel.symbol(argument).get();
            if (symbol instanceof ParameterSymbol) {
                return true;
            }
        }
        return false;
    }

    /**
     * Checks if the Response object has a vulnerable header set.
     *
     * @param varName         the name of the variable holding the Response object
     * @param returnStatement the ReturnStatementNode containing the Response object
     * @return true if a vulnerable header is found, false otherwise
     */
    private boolean hasVulnerableHeader(String varName, ReturnStatementNode returnStatement) {
        Node parent = returnStatement;
        while (parent != null) {
            if (parent instanceof FunctionBodyBlockNode) {
                break;
            }
            parent = parent.parent();
        }

        if (parent == null) {
            return false;
        }

        FunctionBodyBlockNode functionBodyBlockNode = (FunctionBodyBlockNode) parent;
        for (StatementNode statement : functionBodyBlockNode.statements()) {
            if (statement instanceof ExpressionStatementNode expressionStatement) {
                ExpressionNode expression = expressionStatement.expression();
                if (expression instanceof MethodCallExpressionNode methodCallExpression
                        && methodCallExpression.expression().toString().trim().equals(varName)) {
                    if (methodCallExpression.methodName().toString().trim().equals(SET_HEADER)) {
                        return isContentTypeNotTextOrPlain(methodCallExpression.arguments());
                    }
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Checks if the content type is not set to "text/plain" in the Response header.
     *
     * @param arguments the list of function arguments
     * @return true if content type is not set to "text/plain", false otherwise
     */
    private boolean isContentTypeNotTextOrPlain(SeparatedNodeList<FunctionArgumentNode> arguments) {
        if (arguments.size() < 2) {
            return true;
        }

        String headerName = null;
        String headerValue = null;

        int argIndex = 0;
        for (FunctionArgumentNode argument : arguments) {
            if (argIndex >= 2) {
                break;
            }

            String argValue = null;
            if (argument instanceof PositionalArgumentNode positionalArgument) {
                argValue = positionalArgument.expression().toString().trim();
            } else if (argument instanceof NamedArgumentNode namedArgument) {
                argValue = namedArgument.expression().toString().trim();
            }

            if (argIndex == 0) {
                headerName = argValue;
            } else if (argIndex == 1) {
                headerValue = argValue;
            }
            argIndex++;
        }

        if (headerName == null || headerValue == null) {
            return true;
        }

        headerName = headerName.replaceAll("(^\")|(\"$)", "");
        headerValue = headerValue.replaceAll("(^\")|(\"$)", "");

        if (!CONTENT_TYPE.equals(headerName)) {
            return true;
        }

        return !TEXT_PLAIN.equals(headerValue);
    }

    /**
     * Reports an issue for the given context and rule ID.
     *
     * @param context the syntax node analysis context
     * @param ruleId  the ID of the rule to report
     */
    private void report(SyntaxNodeAnalysisContext context, int ruleId) {
        reporter.reportIssue(
                getDocument(context.currentPackage().module(context.moduleId()), context.documentId()),
                context.node().location(),
                ruleId
        );
    }

    /**
     * Retrieves the Document corresponding to the given module and document ID.
     *
     * @param module     the module
     * @param documentId the document ID
     * @return the Document for the given module and document ID
     */
    private static Document getDocument(Module module, DocumentId documentId) {
        return module.document(documentId);
    }
}
