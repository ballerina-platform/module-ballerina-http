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

package io.ballerina.stdlib.http.compiler.staticcodeanalyzer.constructionrules;

import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpConstructionRuleContext;

import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_FORWARDING_CREDENTIALS_ON_REDIRECT;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.findSpecificField;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getBooleanLiteralValue;

/**
 * Rule to detect a client that forwards authorization headers across redirects.
 * <p>
 * The client strips {@code Authorization} and {@code Proxy-Authorization} from a redirected request by default.
 * Setting {@code allowAuthHeaders: true} sends them on to whatever host the redirect names, which is chosen by the
 * server being called rather than by the caller. A compromised or merely misconfigured upstream can then collect the
 * caller's credentials by answering with a redirect to a host it controls. Redirects are followed only when
 * {@code enabled} is {@code true}, which is not the default, so the rule requires a literal {@code enabled: true}.
 *
 * @since 2.18.2
 */
public class AvoidForwardingCredentialsOnRedirectRule implements HttpConstructionRule {

    private static final String FOLLOW_REDIRECTS = "followRedirects";
    private static final String ENABLED = "enabled";
    private static final String ALLOW_AUTH_HEADERS = "allowAuthHeaders";

    @Override
    public void analyze(HttpConstructionRuleContext context) {
        Optional<MappingConstructorExpressionNode> followRedirects =
                context.arguments().getConfigurationRecord(FOLLOW_REDIRECTS);
        if (followRedirects.isEmpty() || !isLiteralTrue(followRedirects.get(), ENABLED)) {
            return;
        }
        Optional<SpecificFieldNode> allowAuthHeaders = findSpecificField(followRedirects.get(), ALLOW_AUTH_HEADERS);
        if (allowAuthHeaders.isPresent() && isLiteralTrue(followRedirects.get(), ALLOW_AUTH_HEADERS)) {
            context.reporter().reportIssue(context.document(),
                    context.arguments().issueLocation(allowAuthHeaders.get()), getRuleId());
        }
    }

    private static boolean isLiteralTrue(MappingConstructorExpressionNode config, String fieldName) {
        return findSpecificField(config, fieldName)
                .flatMap(SpecificFieldNode::valueExpr)
                .flatMap(value -> getBooleanLiteralValue(value))
                .orElse(false);
    }

    @Override
    public int getRuleId() {
        return AVOID_FORWARDING_CREDENTIALS_ON_REDIRECT.getId();
    }

    @Override
    public boolean isApplicable(HttpConstructionRuleContext context) {
        return context.arguments().hasConfiguration();
    }
}
