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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpResourceRuleContext;

import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getBooleanLiteralValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getEffectiveExpression;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getFieldValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.isHttpAnnotation;

/**
 * Shared lookups for the rules that examine response caching on a resource.
 *
 * @since 2.18.2
 */
final class CacheAnalysisSupport {
    static final String CACHE_ANNOTATION = "Cache";
    private static final String RESOURCE_CONFIG_ANNOTATION = "ResourceConfig";
    private static final String SERVICE_CONFIG_ANNOTATION = "ServiceConfig";
    private static final String AUTH_FIELD = "auth";

    private CacheAnalysisSupport() {
    }

    /**
     * Authentication is recognised only where it is declared on the resource or on its service, either a service
     * declaration or a service class. A service that enforces authentication imperatively inside a resource body is
     * out of scope, deliberately: establishing that from the syntax alone is guesswork.
     * <p>
     * {@code auth: []} declares no provider. On a resource it also switches off the service's authentication for that
     * resource, while the {@code Scopes} form only narrows the service's providers.
     */
    static boolean requiresAuthentication(HttpResourceRuleContext context) {
        Optional<FunctionDefinitionNode> definition = context.resourceFunction().getFunctionDefinitionNode();
        Optional<ExpressionNode> resourceAuth = getAuthField(context.semanticModel(),
                context.resourceFunction().metadata(), RESOURCE_CONFIG_ANNOTATION);
        if (resourceAuth.isPresent() && !(resourceAuth.get() instanceof MappingConstructorExpressionNode)) {
            return declaresProvider(resourceAuth.get());
        }
        if (definition.isEmpty()) {
            return false;
        }
        Optional<MetadataNode> serviceMetadata = switch (definition.get().parent()) {
            case ServiceDeclarationNode serviceDeclaration -> serviceDeclaration.metadata();
            case ClassDefinitionNode serviceClass -> serviceClass.metadata();
            default -> Optional.empty();
        };
        return getAuthField(context.semanticModel(), serviceMetadata, SERVICE_CONFIG_ANNOTATION)
                .map(CacheAnalysisSupport::declaresProvider)
                .orElse(false);
    }

    static Optional<AnnotationNode> getReturnTypeAnnotation(HttpResourceRuleContext context, String annotationName) {
        Optional<ReturnTypeDescriptorNode> returnType =
                context.resourceFunction().functionSignature().returnTypeDesc();
        if (returnType.isEmpty()) {
            return Optional.empty();
        }
        return returnType.get().annotations().stream()
                .filter(annotation -> isHttpAnnotation(context.semanticModel(), annotation, annotationName))
                .findFirst();
    }

    /**
     * Read a boolean flag of a cache configuration. An absent flag takes its default of {@code false}; a flag set to
     * something other than a literal cannot be read, and yields an empty result so that callers do not guess.
     */
    static Optional<Boolean> getFlag(MappingConstructorExpressionNode config, String fieldName) {
        Optional<ExpressionNode> value = getFieldValue(config, fieldName);
        return value.isEmpty() ? Optional.of(false) : getBooleanLiteralValue(value.get());
    }

    private static Optional<ExpressionNode> getAuthField(SemanticModel semanticModel, Optional<MetadataNode> metadata,
                                                         String annotationName) {
        return metadata.stream()
                .flatMap(meta -> meta.annotations().stream())
                .filter(annotation -> isHttpAnnotation(semanticModel, annotation, annotationName))
                .flatMap(annotation -> annotation.annotValue().stream())
                .flatMap(config -> getFieldValue(config, AUTH_FIELD).stream())
                .map(value -> getEffectiveExpression(value))
                .findFirst();
    }

    private static boolean declaresProvider(ExpressionNode auth) {
        return !(auth instanceof ListConstructorExpressionNode providers) || !providers.expressions().isEmpty();
    }
}
