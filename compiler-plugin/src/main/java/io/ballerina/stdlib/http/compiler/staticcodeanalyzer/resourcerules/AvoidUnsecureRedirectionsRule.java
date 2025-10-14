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

package io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.BasicLiteralNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.ExpressionNodeInfo;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpResourceRuleContext;

import java.util.Map;
import java.util.Optional;

import static io.ballerina.compiler.syntax.tree.SyntaxKind.SPECIFIC_FIELD;
import static io.ballerina.stdlib.http.compiler.Constants.BALLERINA;
import static io.ballerina.stdlib.http.compiler.Constants.EMPTY;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getUsedParamName;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.unescapeIdentifier;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_UNSECURE_REDIRECTIONS;

/**
 * Rule to avoid unsecure redirections in HTTP services where the resource level raw parameters are used in the
 * "Location" header of redirection responses. Here, we only consider status code responses.
 *
 * @since 2.15.0
 */
public class AvoidUnsecureRedirectionsRule implements HttpResourceRule {

    public static final String REDIRECT_STATUS_CODE_RESPONSE_TYPE = "RedirectStatusCodeResponses";
    public static final String HEADERS = "headers";
    public static final String LOCATION = "location";

    private TypeSymbol redirectResponseType = null;

    @Override
    public void analyze(HttpResourceRuleContext context) {
        // Only considering the return statements which can send a redirect status code response type
        context.functionBodyExpressions().stream()
                .filter(expressionNodeInfo -> expressionNodeInfo.returnExpr() &&
                        isRedirectResponseValue(context.semanticModel(), expressionNodeInfo))
                .forEach(exprNodeInfo -> {
                    if (!(exprNodeInfo.expression() instanceof MappingConstructorExpressionNode mappingExpression)) {
                        return;
                    }
                    analyzeRedirectResponse(mappingExpression, context);
                });
    }

    @Override
    public int getRuleId() {
        return AVOID_UNSECURE_REDIRECTIONS.getId();
    }

    @Override
    public boolean isApplicable(HttpResourceRuleContext context) {
        if (this.redirectResponseType == null) {
            // This is more like caching for each service level analysis
            // Once initialized the redirectResponseType should not be null
            initializeRedirectResponseType(context.semanticModel());
        }

        // This rule is only applicable if there are parameters that could be used maliciously,
        // there's a function body to analyze, and the return type is or includes atleast one redirect response type
        return !context.resourceParamNames().isEmpty() && context.functionReturnType().isPresent() &&
                !context.functionBodyExpressions().isEmpty() && this.redirectResponseType != null &&
                hasRedirectResponseType(context.functionReturnType().get(), this.redirectResponseType);
    }

    private void initializeRedirectResponseType(SemanticModel semanticModel) {
        Optional<Map<String, Symbol>> httpTypes = semanticModel.types().typesInModule(BALLERINA, HTTP, EMPTY);
        if (httpTypes.isEmpty() || !httpTypes.get().containsKey(REDIRECT_STATUS_CODE_RESPONSE_TYPE)) {
            return;
        }

        Symbol symbol = httpTypes.get().get(REDIRECT_STATUS_CODE_RESPONSE_TYPE);
        if (symbol instanceof TypeDefinitionSymbol typeDefinitionSymbol) {
            this.redirectResponseType = typeDefinitionSymbol.typeDescriptor();
        } else if (symbol instanceof TypeSymbol typeSymbol) {
            this.redirectResponseType = typeSymbol;
        }
    }

    /**
     * Check if the given field name node matches the expected field name.
     * Currently, supports,
     * - IdentifierToken
     * - BasicLiteralNode (string literals)
     *
     * @param fieldNameNode      The field name node to check.
     * @param expectedFieldName  The expected field name.
     * @param ignoreCase         Whether to ignore case when comparing.
     * @return true if the field name matches, false otherwise.
     */
    private boolean matchesFieldName(Node fieldNameNode, String expectedFieldName, boolean ignoreCase) {
        if (fieldNameNode instanceof IdentifierToken identifierToken) {
            String fieldName = unescapeIdentifier(identifierToken.text());
            return ignoreCase ? fieldName.equalsIgnoreCase(expectedFieldName) : fieldName.equals(expectedFieldName);
        }

        if (fieldNameNode instanceof BasicLiteralNode basicLiteralNode) {
            String fieldName = basicLiteralNode.literalToken().text();
            // Removing the additional quotes from the string literal
            fieldName = fieldName.substring(1, fieldName.length() - 1);
            return ignoreCase ? fieldName.equalsIgnoreCase(expectedFieldName) : fieldName.equals(expectedFieldName);
        }

        return false;
    }

    private boolean isRedirectResponseValue(SemanticModel semanticModel, ExpressionNodeInfo expressionNodeInfo) {
        if (expressionNodeInfo.castingType().isEmpty()) {
            // If there is no casting, then it should be a redirect response since compiler resolves this as a
            // valid type when the return type contains a redirect response type.
            return true;
        }
        Node node = expressionNodeInfo.castingType().get();
        Optional<Symbol> symbol = semanticModel.symbol(node);
        if (symbol.isEmpty() || !(symbol.get() instanceof TypeSymbol returnTypeSymbol)) {
            // Unable to resolve the symbol, so we cannot confirm if it's a redirect response type.
            return false;
        }
        return returnTypeSymbol.subtypeOf(this.redirectResponseType);
    }

    private boolean hasRedirectResponseType(TypeSymbol returnTypeSymbol, TypeSymbol redirectResponseType) {
        if (redirectResponseType == null) {
            return false;
        }

        if (returnTypeSymbol.subtypeOf(redirectResponseType)) {
            return true;
        }

        if (returnTypeSymbol instanceof TypeReferenceTypeSymbol referenceTypeSymbol) {
            return hasRedirectResponseType(referenceTypeSymbol.typeDescriptor(), redirectResponseType);
        }

        // If the type is a union type which contains types other than redirect response types, we need to check
        // each member type of the union type.
        if (returnTypeSymbol instanceof UnionTypeSymbol unionTypeSymbol) {
            return unionTypeSymbol.memberTypeDescriptors().stream()
                    .anyMatch(memberType -> hasRedirectResponseType(memberType, this.redirectResponseType));
        }

        return false;
    }

    private void analyzeRedirectResponse(MappingConstructorExpressionNode mappingExpression,
                                         HttpResourceRuleContext context) {
        for (MappingFieldNode field : mappingExpression.fields()) {
            if (!field.kind().equals(SPECIFIC_FIELD)) {
                continue;
            }

            Node fieldNameNode = ((SpecificFieldNode) field).fieldName();
            if (!matchesFieldName(fieldNameNode, HEADERS, false)) {
                continue;
            }

            Optional<ExpressionNode> valueExpr = ((SpecificFieldNode) field).valueExpr();
            if (valueExpr.isEmpty() || !(valueExpr.get() instanceof MappingConstructorExpressionNode headersMap)) {
                return;
            }

            analyzeLocationHeaders(headersMap, context);
        }
    }

    private void analyzeLocationHeaders(MappingConstructorExpressionNode headersMap,
                                        HttpResourceRuleContext context) {
        SeparatedNodeList<MappingFieldNode> headers = headersMap.fields();

        for (MappingFieldNode header : headers) {
            if (!header.kind().equals(SPECIFIC_FIELD)) {
                continue;
            }

            Node headerFieldNameNode = ((SpecificFieldNode) header).fieldName();
            if (matchesFieldName(headerFieldNameNode, LOCATION, true)) {
                analyzeLocationHeaderValue(header, context);
            }
        }
    }

    private void analyzeLocationHeaderValue(MappingFieldNode header, HttpResourceRuleContext context) {
        Optional<ExpressionNode> locationValue = ((SpecificFieldNode) header).valueExpr();

        if (locationValue.isPresent()) {
            ExpressionNode expression = locationValue.get();
            Optional<String> usedParamName = getUsedParamName(expression);
            if (usedParamName.isPresent() && context.resourceParamNames().contains(usedParamName.get())) {
                context.reporter().reportIssue(
                        context.document(),
                        header.location(),
                        getRuleId()
                );
            }
        }
    }
}
