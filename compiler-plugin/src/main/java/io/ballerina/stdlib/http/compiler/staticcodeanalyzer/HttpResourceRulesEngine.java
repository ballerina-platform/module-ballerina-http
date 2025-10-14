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

import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules.AvoidDefaultResourceAccessorRule;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules.AvoidTraversingAttacksRule;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules.AvoidUnsecureRedirectionsRule;

import java.util.ArrayList;
import java.util.List;

/**
 * Engine to manage and execute HTTP resource related static code analysis rules.
 *
 * @since 2.15.0
 */
public class HttpResourceRulesEngine {

    private final List<HttpResourceRule> rules;

    public HttpResourceRulesEngine() {
        this.rules = new ArrayList<>();
        initializeDefaultRules();
    }

    public void executeRules(HttpResourceRuleContext context) {
        for (HttpResourceRule rule : rules) {
            if (rule.isApplicable(context)) {
                rule.analyze(context);
            }
        }
    }

    public void addRule(HttpResourceRule rule) {
        if (rule != null && !rules.contains(rule)) {
            rules.add(rule);
        }
    }

    private void initializeDefaultRules() {
        addRule(new AvoidDefaultResourceAccessorRule());
        addRule(new AvoidTraversingAttacksRule());
        addRule(new AvoidUnsecureRedirectionsRule());
        // Add more default rules here as needed
    }
}
