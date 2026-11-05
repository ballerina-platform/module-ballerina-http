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
package io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules;

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpResourceRuleContext;

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_STALE_AUTHENTICATED_RESPONSES;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getBooleanLiteralValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getFieldValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules.CacheAnalysisSupport.CACHE_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules.CacheAnalysisSupport.getFlag;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules.CacheAnalysisSupport.getReturnTypeAnnotation;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules.CacheAnalysisSupport.requiresAuthentication;

/**
 * Reports a resource that requires authentication but allows caches to serve its response stale.
 *
 * <p>{@code mustRevalidate} defaults to {@code true}. It governs only entries that are already stale: setting it to
 * {@code false} lets a cache keep serving a stored authenticated response after {@code maxAge} has expired, for
 * example while the service is unreachable or to a client that accepts stale content, without checking back with
 * the service. {@code noStore}, {@code noCache} and {@code proxyRevalidate} each remove or narrow that window, so a
 * literal {@code true} on any of them suppresses the issue.</p>
 *
 * @since 2.18.2
 */
public class AvoidStaleAuthenticatedResponsesRule implements HttpResourceRule {
    private static final String MUST_REVALIDATE_FIELD = "mustRevalidate";
    private static final List<String> STALE_REUSE_GUARDS = List.of("noStore", "noCache", "proxyRevalidate");

    @Override
    public void analyze(HttpResourceRuleContext context) {
        Optional<AnnotationNode> cacheAnnotation = getReturnTypeAnnotation(context, CACHE_ANNOTATION);
        if (cacheAnnotation.isEmpty()) {
            return;
        }
        Optional<MappingConstructorExpressionNode> config = cacheAnnotation.get().annotValue();
        if (config.isEmpty()) {
            return;
        }
        Optional<ExpressionNode> mustRevalidate = getFieldValue(config.get(), MUST_REVALIDATE_FIELD);
        if (mustRevalidate.isEmpty()) {
            return;
        }
        // Only an explicit `false` is reported. Leaving the field out keeps the secure default, and a
        // non-literal value cannot be resolved here without guessing.
        if (getBooleanLiteralValue(mustRevalidate.get()).filter(value -> !value).isEmpty()) {
            return;
        }
        boolean staleReuseGuarded = STALE_REUSE_GUARDS.stream()
                .map(field -> getFlag(config.get(), field))
                .anyMatch(flag -> flag.isEmpty() || flag.get());
        if (staleReuseGuarded || !requiresAuthentication(context)) {
            return;
        }
        context.reporter().reportIssue(context.document(), mustRevalidate.get().location(), getRuleId());
    }

    @Override
    public int getRuleId() {
        return AVOID_STALE_AUTHENTICATED_RESPONSES.getId();
    }
}
