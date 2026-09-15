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

import java.util.Optional;
import java.util.regex.Pattern;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_SERVER_VERSION_DISCLOSURE;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getStringLiteralValue;

/**
 * Reports a listener that advertises a product version through the {@code server} response header.
 *
 * @since 2.16.0
 */
public class AvoidServerVersionDisclosureRule implements HttpConstructionRule {
    private static final String LISTENER = "Listener";
    private static final String SERVER_FIELD = "server";

    // A version token such as "1.2", "2201.13.5" or "v3.0" is what turns a product name into an
    // invitation to look up known vulnerabilities. A bare name discloses far less and is not reported.
    private static final Pattern VERSION_TOKEN = Pattern.compile("\\d+\\.\\d+");

    @Override
    public void analyze(HttpConstructionRuleContext context) {
        Optional<ExpressionNode> serverField = context.arguments().getConfigurationField(SERVER_FIELD);
        if (serverField.isEmpty()) {
            return;
        }
        Optional<String> serverValue = getStringLiteralValue(serverField.get());
        if (serverValue.isEmpty()) {
            return;
        }
        if (VERSION_TOKEN.matcher(serverValue.get()).find()) {
            context.reporter().reportIssue(context.document(), serverField.get().location(), getRuleId());
        }
    }

    @Override
    public int getRuleId() {
        return AVOID_SERVER_VERSION_DISCLOSURE.getId();
    }

    @Override
    public boolean isApplicable(HttpConstructionRuleContext context) {
        return LISTENER.equals(context.constructedTypeName()) && context.arguments().hasConfiguration();
    }
}
