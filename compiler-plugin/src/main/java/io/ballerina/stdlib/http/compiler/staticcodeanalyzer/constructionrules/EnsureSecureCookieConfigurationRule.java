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

import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MethodCallExpressionNode;
import io.ballerina.compiler.syntax.tree.NamedArgumentNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpConstructionRuleContext;

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isHttpModuleType;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.ENSURE_SECURE_COOKIE_CONFIGURATION;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getBooleanLiteralValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.resolveConstructedType;

/**
 * Rule to detect a cookie created without the {@code secure} and {@code httpOnly} flags.
 * <p>
 * Without {@code secure} the cookie is sent over plaintext HTTP, where anyone on the path can read it. Without
 * {@code httpOnly} it is readable from JavaScript, which turns any cross-site scripting flaw on the origin into
 * session theft. Both flags default to {@code false}, so a cookie carrying a session or any other credential is
 * insecure unless the author sets them, and omitting them is as much a defect as disabling them.
 * <p>
 * The flags only matter on a cookie sent in a response. A cookie constructed directly as the argument of
 * {@code Request.addCookies}, which serializes only its name and value, is not reported. At most one issue is
 * reported per construction.
 *
 * @since 2.18.2
 */
public class EnsureSecureCookieConfigurationRule implements HttpConstructionRule {

    private static final String COOKIE_TYPE = "Cookie";
    private static final String REQUEST_TYPE = "Request";
    private static final String ADD_COOKIES_METHOD = "addCookies";
    private static final String SECURE = "secure";
    private static final String HTTP_ONLY = "httpOnly";

    @Override
    public void analyze(HttpConstructionRuleContext context) {
        boolean anyFlagUnset = false;
        for (String flag : List.of(SECURE, HTTP_ONLY)) {
            Optional<ExpressionNode> value = context.arguments().getConfigurationField(flag);
            if (value.isEmpty()) {
                anyFlagUnset = true;
                continue;
            }
            // A non-literal value cannot be resolved here. Treat it as deliberate rather than guessing.
            if (getBooleanLiteralValue(value.get()).filter(enabled -> !enabled).isPresent()) {
                context.reporter().reportIssue(context.document(), context.arguments().issueLocation(value.get()),
                        getRuleId());
                return;
            }
        }
        // An options record this analysis cannot read may well set the flags, so an absent flag is only a defect
        // when the whole record is in view
        if (anyFlagUnset && !context.arguments().hasUnresolvedConfiguration()) {
            context.reporter().reportIssue(context.document(), context.construction().location(), getRuleId());
        }
    }

    /**
     * Check whether the cookie is constructed as an argument of {@code Request.addCookies}, on its own or as a member
     * of the list literal passed to it.
     */
    private static boolean isOutboundRequestCookie(HttpConstructionRuleContext context) {
        Node parent = context.construction().parent();
        if (parent instanceof ListConstructorExpressionNode) {
            parent = parent.parent();
        }
        if (!(parent instanceof PositionalArgumentNode || parent instanceof NamedArgumentNode)
                || !(parent.parent() instanceof MethodCallExpressionNode methodCall)
                || !ADD_COOKIES_METHOD.equals(methodCall.methodName().toSourceCode().trim())) {
            return false;
        }
        return context.semanticModel().typeOf(methodCall.expression())
                .map(type -> isHttpModuleType(REQUEST_TYPE, resolveConstructedType(type)))
                .orElse(false);
    }

    @Override
    public int getRuleId() {
        return ENSURE_SECURE_COOKIE_CONFIGURATION.getId();
    }

    @Override
    public boolean isApplicable(HttpConstructionRuleContext context) {
        return COOKIE_TYPE.equals(context.constructedTypeName()) && !isOutboundRequestCookie(context);
    }
}
