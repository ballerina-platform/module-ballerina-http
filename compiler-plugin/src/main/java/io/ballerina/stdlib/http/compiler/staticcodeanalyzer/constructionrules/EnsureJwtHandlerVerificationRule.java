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

import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.AuthConfigAnalyzer;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpConstructionRuleContext;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.ENSURE_JWT_VERIFICATION;

/**
 * Rule to detect a {@code ListenerJwtAuthHandler} constructed with a JWT validator configuration that omits a
 * verification step. The declarative form in {@code @http:ServiceConfig} is checked by the annotation analyzer; this
 * covers the imperative form, where the validator configuration is the handler's argument.
 *
 * @since 2.18.2
 */
public class EnsureJwtHandlerVerificationRule implements HttpConstructionRule {

    private static final String JWT_AUTH_HANDLER = "ListenerJwtAuthHandler";

    @Override
    public void analyze(HttpConstructionRuleContext context) {
        context.arguments().getConfiguration().ifPresent(validatorConfig ->
                AuthConfigAnalyzer.reportUnverifiedJwtValidator(validatorConfig, context.reporter(),
                        context.document(), context.arguments()::issueLocation));
    }

    @Override
    public int getRuleId() {
        return ENSURE_JWT_VERIFICATION.getId();
    }

    @Override
    public boolean isApplicable(HttpConstructionRuleContext context) {
        return JWT_AUTH_HANDLER.equals(context.constructedTypeName());
    }
}
