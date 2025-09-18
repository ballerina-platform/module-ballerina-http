/*
 * Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionBodyBlockNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.FunctionSignatureNode;
import io.ballerina.compiler.syntax.tree.ImportOrgNameNode;
import io.ballerina.compiler.syntax.tree.ImportPrefixNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.QualifiedNameReferenceNode;
import io.ballerina.compiler.syntax.tree.ReturnStatementNode;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SimpleNameReferenceNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.StatementNode;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.scan.Reporter;

import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_UNSECURE_REDIRECTIONS;

class HttpRedirectAnalyzer implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final Reporter reporter;
    private SemanticModel semanticModel = null;
    private static final String BALLERINA_ORG = "ballerina";
    private static final String HTTP = "http";
    private static final String TEMPORARY_REDIRECT = "TemporaryRedirect";
    private static final String HEADERS = "headers";
    private static final String LOCATION = "Location";

    private final Set<String> httpPrefixes = new HashSet<>();

    public HttpRedirectAnalyzer(Reporter reporter) {
        this.reporter = reporter;
        this.httpPrefixes.add(HTTP);
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        analyzeImports(context);
        FunctionSignatureNode functionSignature = (FunctionSignatureNode) context.node();
        semanticModel = context.semanticModel();
        if (functionSignature.returnTypeDesc().isEmpty()) {
            return;
        }
        ReturnTypeDescriptorNode returnTypeDescriptor = functionSignature.returnTypeDesc().get();
        if (!(returnTypeDescriptor.type() instanceof QualifiedNameReferenceNode qualifiedNameReference)
                || !httpPrefixes.contains(qualifiedNameReference.modulePrefix().text().trim())
                || !qualifiedNameReference.identifier().text().equals(TEMPORARY_REDIRECT)) {
            return;
        }
        if (!isUnsecureRedirect(functionSignature)) {
            return;
        }
        report(context, AVOID_UNSECURE_REDIRECTIONS.getId());
    }

    /**
     * Checks if the function signature is a redirect function that returns an unsecure redirect.
     *
     * @param functionSignature the function signature node
     * @return true if it is an unsecure redirect, false otherwise
     */
    private boolean isUnsecureRedirect(FunctionSignatureNode functionSignature) {
        FunctionDefinitionNode functionDefinition = (FunctionDefinitionNode) functionSignature.parent();
        FunctionBodyBlockNode functionBodyBlock = (FunctionBodyBlockNode) functionDefinition.functionBody();
        return isUnsecureRedirectMappingConstructor(functionBodyBlock);
    }

    /**
     * Checks if the function body block contains a return statement with an unsecure redirect mapping constructor.
     *
     * @param functionBodyBlock the function body block node
     * @return true if it contains an unsecure redirect mapping constructor, false otherwise
     */
    private boolean isUnsecureRedirectMappingConstructor(FunctionBodyBlockNode functionBodyBlock) {
        for (StatementNode statement : functionBodyBlock.statements()) {
            if (statement instanceof ReturnStatementNode returnStatement
                    && returnStatement.expression().isPresent()
                    && returnStatement.expression().get()
                    instanceof MappingConstructorExpressionNode mappingConstructorExpression) {
                return isUnsecureHeaderField(mappingConstructorExpression);
            }
        }
        return false;
    }

    /**
     * Checks if the mapping constructor expression contains a headers field with a user-controlled location.
     *
     * @param mappingConstructorExpression the mapping constructor expression node
     * @return true if it contains an unsecure header field, false otherwise
     */
    private boolean isUnsecureHeaderField(MappingConstructorExpressionNode mappingConstructorExpression) {
        for (MappingFieldNode mappingField : mappingConstructorExpression.fields()) {
            if (mappingField instanceof SpecificFieldNode specificField
                    && specificField.fieldName().toString().trim().equals(HEADERS)) {
                return isUserControlledLocation(specificField.valueExpr());
            }
        }
        return false;
    }

    /**
     * Checks if the headers field contains a user-controlled location.
     *
     * @param expression the expression node of the headers field
     * @return true if it contains a user-controlled location, false otherwise
     */
    private boolean isUserControlledLocation(Optional<ExpressionNode> expression) {
        if (expression.isEmpty()) {
            return false;
        }
        ExpressionNode valueExpr = expression.get();
        if (valueExpr instanceof MappingConstructorExpressionNode mappingConstructorExpression) {
            for (MappingFieldNode mappingField : mappingConstructorExpression.fields()) {
                if (mappingField instanceof SpecificFieldNode specificField
                        && specificField.fieldName().toString().trim().equals("\"" + LOCATION + "\"")) {
                    return isFunctionArgument(specificField.valueExpr());
                }
            }
        }
        return false;
    }

    /**
     * Checks if the expression is a function argument, indicating that it may be user-controlled.
     *
     * @param expression the expression node to check
     * @return true if it is a function argument, false otherwise
     */
    private boolean isFunctionArgument(Optional<ExpressionNode> expression) {
        if (expression.isEmpty()) {
            return false;
        }
        ExpressionNode valueExpr = expression.get();
        if (valueExpr instanceof SimpleNameReferenceNode simpleNameReference) {
            semanticModel.symbol(simpleNameReference);
            Optional<Symbol> symbol = semanticModel.symbol(simpleNameReference);
            return symbol.isPresent() && symbol.get() instanceof ParameterSymbol;
        }
        return false;
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

    /**
     * Analyzes imports to identify all prefixes used for the http module.
     *
     * @param context the syntax node analysis context
     */
    private void analyzeImports(SyntaxNodeAnalysisContext context) {
        Document document = getDocument(context.currentPackage().module(context.moduleId()), context.documentId());

        if (document.syntaxTree().rootNode() instanceof ModulePartNode modulePartNode) {
            modulePartNode.imports().forEach(importDeclarationNode -> {
                ImportOrgNameNode importOrgNameNode = importDeclarationNode.orgName().orElse(null);

                if (importOrgNameNode != null && BALLERINA_ORG.equals(importOrgNameNode.orgName().text())
                        && importDeclarationNode.moduleName().stream()
                        .anyMatch(moduleNameNode -> HTTP.equals(moduleNameNode.text()))) {

                    ImportPrefixNode importPrefixNode = importDeclarationNode.prefix().orElse(null);
                    String prefix = importPrefixNode != null ? importPrefixNode.prefix().text() : HTTP;

                    httpPrefixes.add(prefix);
                }
            });
        }
    }
}
