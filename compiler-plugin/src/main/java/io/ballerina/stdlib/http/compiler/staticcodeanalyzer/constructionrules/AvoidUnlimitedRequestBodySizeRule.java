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

import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpConstructionRuleContext;

import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_UNLIMITED_REQUEST_BODY_SIZE;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.findSpecificField;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getIntegerLiteralValue;

/**
 * Rule to detect a listener that accepts request bodies of unlimited size.
 * <p>
 * {@code maxEntityBodySize: -1} removes the ceiling on an incoming body, so a single request can exhaust the
 * service's memory. The rule reports only an explicit {@code -1}: the field also defaults to {@code -1}, and
 * reporting every listener that leaves it alone would fire on essentially all of them. That default is worth
 * raising with the HTTP team, since it means the unsafe value is what a listener gets by saying nothing.
 *
 * @since 2.15.0
 */
public class AvoidUnlimitedRequestBodySizeRule implements HttpConstructionRule {

    private static final String REQUEST_LIMITS = "requestLimits";
    private static final String MAX_ENTITY_BODY_SIZE = "maxEntityBodySize";
    private static final long UNLIMITED = -1L;

    @Override
    public void analyze(HttpConstructionRuleContext context) {
        Optional<SpecificFieldNode> maxEntityBodySize = context.arguments()
                .getConfigurationRecord(REQUEST_LIMITS)
                .flatMap(requestLimits -> findSpecificField(requestLimits, MAX_ENTITY_BODY_SIZE));
        if (maxEntityBodySize.isEmpty() || maxEntityBodySize.get().valueExpr().isEmpty()) {
            return;
        }
        if (getIntegerLiteralValue(maxEntityBodySize.get().valueExpr().get())
                .filter(size -> size == UNLIMITED).isPresent()) {
            context.reporter().reportIssue(context.document(), maxEntityBodySize.get().location(), getRuleId());
        }
    }

    @Override
    public int getRuleId() {
        return AVOID_UNLIMITED_REQUEST_BODY_SIZE.getId();
    }

    @Override
    public boolean isApplicable(HttpConstructionRuleContext context) {
        return context.arguments().hasConfiguration();
    }
}
