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

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_DISABLED_AUTH_PROVIDER_TLS;

/**
 * Rule to detect a client whose authentication provider has had its TLS validation disabled.
 * <p>
 * A client's {@code auth} configuration carries its own secure socket for reaching the token endpoint, separate from
 * the {@code secureSocket} that governs the client's own requests. Securing one and disabling the other is easy to
 * do by accident and leaves the credential exchange itself unprotected.
 *
 * @since 2.15.0
 */
public class AvoidDisabledAuthProviderTlsRule implements HttpConstructionRule {

    private static final String AUTH = "auth";

    @Override
    public void analyze(HttpConstructionRuleContext context) {
        context.arguments().getConfigurationRecord(AUTH).ifPresent(authConfig ->
                AuthConfigAnalyzer.reportDisabledTlsValidation(authConfig, context.reporter(), context.document()));
    }

    @Override
    public int getRuleId() {
        return AVOID_DISABLED_AUTH_PROVIDER_TLS.getId();
    }

    @Override
    public boolean isApplicable(HttpConstructionRuleContext context) {
        return context.arguments().hasConfiguration();
    }
}
