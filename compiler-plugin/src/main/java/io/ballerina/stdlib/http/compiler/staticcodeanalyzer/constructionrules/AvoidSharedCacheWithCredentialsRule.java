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

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_SHARED_CACHE_WITH_CREDENTIALS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.findSpecificField;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getBooleanLiteralValue;

/**
 * Reports a client that treats its response cache as shared while it is configured to send credentials.
 *
 * <p>A shared cache stores responses on behalf of more than one caller. A client that sends credentials
 * receives responses belonging to the identity those credentials represent, so marking its cache shared
 * allows one caller's data to be returned to another.</p>
 *
 * @since 2.16.0
 */
public class AvoidSharedCacheWithCredentialsRule implements HttpConstructionRule {
    private static final String CLIENT = "Client";
    private static final String CACHE_FIELD = "cache";
    private static final String IS_SHARED_FIELD = "isShared";
    private static final String AUTH_FIELD = "auth";

    @Override
    public void analyze(HttpConstructionRuleContext context) {
        Optional<MappingConstructorExpressionNode> cacheConfig =
                context.arguments().getConfigurationRecord(CACHE_FIELD);
        if (cacheConfig.isEmpty()) {
            return;
        }
        Optional<SpecificFieldNode> isShared = findSpecificField(cacheConfig.get(), IS_SHARED_FIELD);
        if (isShared.isEmpty() || isShared.get().valueExpr().isEmpty()) {
            return;
        }
        if (getBooleanLiteralValue(isShared.get().valueExpr().get()).filter(shared -> shared).isEmpty()) {
            return;
        }
        if (context.arguments().getConfigurationField(AUTH_FIELD).isEmpty()) {
            return;
        }
        context.reporter().reportIssue(context.document(), isShared.get().location(), getRuleId());
    }

    @Override
    public int getRuleId() {
        return AVOID_SHARED_CACHE_WITH_CREDENTIALS.getId();
    }

    @Override
    public boolean isApplicable(HttpConstructionRuleContext context) {
        return CLIENT.equals(context.constructedTypeName()) && context.arguments().hasConfiguration();
    }
}
