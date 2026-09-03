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

import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.NamedArgumentNode;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.RemoteMethodCallActionNode;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpResourceRuleContext;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isHttpModuleType;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_UNSECURE_CALLER_REDIRECTIONS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getEffectiveExpression;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getListElements;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getUsedParamNames;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.resolveConstructedType;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.unescapeIdentifier;

/**
 * Rule to detect a resource parameter reaching the target of a {@code Caller.redirect} call.
 * <p>
 * A caller-controlled redirect target lets an attacker send a user to a site of their choosing from a URL that
 * begins on the trusted origin, which is what makes the resulting phishing page credible. This is the second
 * redirect sink in the module: {@code AvoidUnsecureRedirectionsRule} covers the {@code location} header of a status
 * code response, and this one covers the explicit caller API.
 *
 * @since 2.15.0
 */
public class AvoidUnsecureCallerRedirectionsRule implements HttpResourceRule {

    private static final String CALLER_TYPE = "Caller";
    private static final String REDIRECT_METHOD = "redirect";
    private static final String LOCATIONS_PARAM = "locations";
    private static final int LOCATIONS_POSITION = 2;

    @Override
    public void analyze(HttpResourceRuleContext context) {
        context.functionBodyExpressions().stream()
                .map(exprNodeInfo -> exprNodeInfo.expression())
                .filter(RemoteMethodCallActionNode.class::isInstance)
                .map(RemoteMethodCallActionNode.class::cast)
                .filter(remoteCall -> isCallerRedirect(remoteCall, context))
                .forEach(remoteCall -> analyzeRedirectLocations(remoteCall, context));
    }

    @Override
    public int getRuleId() {
        return AVOID_UNSECURE_CALLER_REDIRECTIONS.getId();
    }

    @Override
    public boolean isApplicable(HttpResourceRuleContext context) {
        return !context.resourceParamNames().isEmpty() && !context.functionBodyExpressions().isEmpty();
    }

    /**
     * Confirm the call is {@code redirect} on an {@code http:Caller}. The method name alone is not enough, since
     * any client can define a remote method by that name.
     */
    private boolean isCallerRedirect(RemoteMethodCallActionNode remoteCall, HttpResourceRuleContext context) {
        if (!REDIRECT_METHOD.equals(unescapeIdentifier(remoteCall.methodName().name().text()))) {
            return false;
        }
        Optional<TypeSymbol> targetType = context.semanticModel().typeOf(remoteCall.expression());
        return targetType.isPresent() && isHttpModuleType(CALLER_TYPE, resolveConstructedType(targetType.get()));
    }

    private void analyzeRedirectLocations(RemoteMethodCallActionNode remoteCall, HttpResourceRuleContext context) {
        Optional<ExpressionNode> locations = getLocationsArgument(remoteCall);
        if (locations.isEmpty()) {
            return;
        }
        // The argument is a `string[]`, so it is either a list of targets or the array itself
        List<ExpressionNode> targets = new ArrayList<>(getListElements(locations.get()));
        if (targets.isEmpty()) {
            targets.add(locations.get());
        }
        for (ExpressionNode target : targets) {
            if (getUsedParamNames(target).stream().anyMatch(context.resourceParamNames()::contains)) {
                context.reporter().reportIssue(context.document(), target.location(), getRuleId());
            }
        }
    }

    private Optional<ExpressionNode> getLocationsArgument(RemoteMethodCallActionNode remoteCall) {
        int position = 0;
        for (FunctionArgumentNode argument : remoteCall.arguments()) {
            switch (argument) {
                case NamedArgumentNode namedArgument -> {
                    if (LOCATIONS_PARAM.equals(unescapeIdentifier(namedArgument.argumentName().name().text()))) {
                        return Optional.of(getEffectiveExpression(namedArgument.expression()));
                    }
                }
                case PositionalArgumentNode positionalArgument -> {
                    if (position++ == LOCATIONS_POSITION) {
                        return Optional.of(getEffectiveExpression(positionalArgument.expression()));
                    }
                }
                default -> {
                    // A rest argument spreads a value that cannot be resolved without data-flow analysis
                }
            }
        }
        return Optional.empty();
    }
}
