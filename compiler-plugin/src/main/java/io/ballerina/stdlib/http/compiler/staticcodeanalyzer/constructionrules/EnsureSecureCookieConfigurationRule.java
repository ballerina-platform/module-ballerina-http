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
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpConstructionRuleContext;

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.ENSURE_SECURE_COOKIE_CONFIGURATION;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getBooleanLiteralValue;

/**
 * Rule to detect a cookie created without the {@code secure} and {@code httpOnly} flags.
 * <p>
 * Without {@code secure} the cookie is sent over plaintext HTTP, where anyone on the path can read it. Without
 * {@code httpOnly} it is readable from JavaScript, which turns any cross-site scripting flaw on the origin into
 * session theft. Both flags default to {@code false}, so a cookie carrying a session or any other credential is
 * insecure unless the author sets them, and omitting them is as much a defect as disabling them.
 *
 * @since 2.15.0
 */
public class EnsureSecureCookieConfigurationRule implements HttpConstructionRule {

    private static final String COOKIE_TYPE = "Cookie";
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
                context.reporter().reportIssue(context.document(), value.get().location(), getRuleId());
            }
        }
        // An options record this analysis cannot read may well set the flags, so an absent flag is only a defect
        // when the whole record is in view
        if (anyFlagUnset && !context.arguments().hasUnresolvedConfiguration()) {
            context.reporter().reportIssue(context.document(), context.constructionLocation(), getRuleId());
        }
    }

    @Override
    public int getRuleId() {
        return ENSURE_SECURE_COOKIE_CONFIGURATION.getId();
    }

    @Override
    public boolean isApplicable(HttpConstructionRuleContext context) {
        return COOKIE_TYPE.equals(context.constructedTypeName());
    }
}
