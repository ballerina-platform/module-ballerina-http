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
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpResourceRuleContext;

import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_CACHING_AUTHENTICATED_RESPONSES;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules.CacheAnalysisSupport.CACHE_ANNOTATION;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules.CacheAnalysisSupport.getReturnTypeAnnotation;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules.CacheAnalysisSupport.isFieldTrue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.resourcerules.CacheAnalysisSupport.requiresAuthentication;

/**
 * Reports a resource that requires authentication but allows its response to be stored by shared caches.
 *
 * <p>The {@code Cache} annotation defaults to {@code must-revalidate, public, max-age=3600}, so a response that
 * is specific to one authenticated caller may be stored by a proxy or CDN and served to another. Marking the
 * response private, or declining to store it, resolves this.</p>
 *
 * @since 2.16.0
 */
public class AvoidCachingAuthenticatedResponsesRule implements HttpResourceRule {
    private static final String IS_PRIVATE_FIELD = "isPrivate";
    private static final String NO_STORE_FIELD = "noStore";
    private static final String NO_CACHE_FIELD = "noCache";

    @Override
    public void analyze(HttpResourceRuleContext context) {
        Optional<AnnotationNode> cacheAnnotation = getReturnTypeAnnotation(context, CACHE_ANNOTATION);
        if (cacheAnnotation.isEmpty() || !allowsSharedCaching(cacheAnnotation.get())) {
            return;
        }
        if (!requiresAuthentication(context)) {
            return;
        }
        context.reporter().reportIssue(context.document(), cacheAnnotation.get().location(), getRuleId());
    }

    /**
     * A response reaches a shared cache unless it is marked private, or excluded from storage altogether.
     * Every one of these fields defaults to {@code false}, so an annotation that sets none of them is
     * shared-cacheable and is reported.
     */
    private boolean allowsSharedCaching(AnnotationNode cacheAnnotation) {
        Optional<MappingConstructorExpressionNode> config = cacheAnnotation.annotValue();
        if (config.isEmpty()) {
            return true;
        }
        return !isFieldTrue(config.get(), IS_PRIVATE_FIELD)
                && !isFieldTrue(config.get(), NO_STORE_FIELD)
                && !isFieldTrue(config.get(), NO_CACHE_FIELD);
    }

    @Override
    public int getRuleId() {
        return AVOID_CACHING_AUTHENTICATED_RESPONSES.getId();
    }
}
