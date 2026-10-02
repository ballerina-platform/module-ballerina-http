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

import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.ExplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.ImplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.NewExpressionNode;
import io.ballerina.compiler.syntax.tree.ParenthesizedArgList;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.scan.Reporter;
import io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil;

import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isHttpModule;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.resolveConstructedType;

/**
 * Analyzer to validate static rules on the construction of HTTP objects.
 * <p>
 * Client, listener and cookie configuration is supplied at construction, so none of it is reachable from the service
 * and annotation analyzers. This task provides the missing entry point.
 *
 * @since 2.15.0
 */
class HttpConstructionStaticAnalyzer implements AnalysisTask<SyntaxNodeAnalysisContext> {

    private final Reporter reporter;
    private final HttpConstructionRulesEngine rulesEngine;

    HttpConstructionStaticAnalyzer(Reporter reporter) {
        this.reporter = reporter;
        this.rulesEngine = new HttpConstructionRulesEngine();
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (!(context.node() instanceof NewExpressionNode newExpression)) {
            return;
        }

        Optional<String> typeName = getHttpTypeName(context, newExpression);
        if (typeName.isEmpty()) {
            return;
        }

        HttpConstructionArguments arguments = getArguments(newExpression)
                .map(argumentList -> new HttpConstructionArguments(context, argumentList))
                .orElseGet(HttpConstructionArguments::empty);
        rulesEngine.executeRules(new HttpConstructionRuleContext(reporter,
                HttpCompilerPluginUtil.getDocument(context), context.semanticModel(), newExpression.location(),
                typeName.get(), arguments));
    }

    /**
     * Resolve the simple name of the constructed type, if it belongs to {@code ballerina/http}.
     */
    private Optional<String> getHttpTypeName(SyntaxNodeAnalysisContext context, NewExpressionNode newExpression) {
        Optional<TypeSymbol> constructorType = context.semanticModel().typeOf(newExpression);
        if (constructorType.isEmpty()) {
            return Optional.empty();
        }
        TypeSymbol constructedType = resolveConstructedType(constructorType.get());
        Optional<ModuleSymbol> module = constructedType.getModule();
        if (module.isEmpty() || module.get().getName().isEmpty() || !isHttpModule(module.get())) {
            return Optional.empty();
        }
        return constructedType.getName();
    }

    /**
     * Get the constructor arguments. A bare {@code new} carries no argument list at all.
     */
    private Optional<SeparatedNodeList<FunctionArgumentNode>> getArguments(NewExpressionNode newExpression) {
        return switch (newExpression) {
            case ExplicitNewExpressionNode explicitNew ->
                    Optional.of(explicitNew.parenthesizedArgList().arguments());
            case ImplicitNewExpressionNode implicitNew ->
                    implicitNew.parenthesizedArgList().map(ParenthesizedArgList::arguments);
            default -> Optional.empty();
        };
    }
}
