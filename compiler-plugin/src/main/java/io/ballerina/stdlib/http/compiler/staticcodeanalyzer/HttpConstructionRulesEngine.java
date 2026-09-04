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

import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.constructionrules.AvoidDisabledAuthProviderTlsRule;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.constructionrules.AvoidDisabledTlsValidationRule;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.constructionrules.AvoidForwardingCredentialsOnRedirectRule;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.constructionrules.AvoidUnlimitedRequestBodySizeRule;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.constructionrules.AvoidWeakTlsProtocolsRule;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.constructionrules.EnsureSecureCookieConfigurationRule;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.constructionrules.HttpConstructionRule;

import java.util.ArrayList;
import java.util.List;

/**
 * Engine to manage and execute static code analysis rules on HTTP object construction.
 *
 * @since 2.15.0
 */
public class HttpConstructionRulesEngine {

    private final List<HttpConstructionRule> rules;

    public HttpConstructionRulesEngine() {
        this.rules = new ArrayList<>();
        initializeDefaultRules();
    }

    public void executeRules(HttpConstructionRuleContext context) {
        for (HttpConstructionRule rule : rules) {
            if (rule.isApplicable(context)) {
                rule.analyze(context);
            }
        }
    }

    public void addRule(HttpConstructionRule rule) {
        if (rule != null && !rules.contains(rule)) {
            rules.add(rule);
        }
    }

    private void initializeDefaultRules() {
        addRule(new AvoidDisabledTlsValidationRule());
        addRule(new AvoidWeakTlsProtocolsRule());
        addRule(new AvoidForwardingCredentialsOnRedirectRule());
        addRule(new EnsureSecureCookieConfigurationRule());
        addRule(new AvoidDisabledAuthProviderTlsRule());
        addRule(new AvoidUnlimitedRequestBodySizeRule());
        // Add more default rules here as needed
    }
}
