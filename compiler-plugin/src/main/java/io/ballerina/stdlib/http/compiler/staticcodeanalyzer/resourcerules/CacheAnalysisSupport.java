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
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpResourceRuleContext;

import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getBooleanLiteralValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getFieldValue;

/**
 * Shared lookups for the rules that examine response caching on a resource.
 *
 * @since 2.16.0
 */
final class CacheAnalysisSupport {
    static final String CACHE_ANNOTATION = "Cache";
    private static final String RESOURCE_CONFIG_ANNOTATION = "ResourceConfig";
    private static final String SERVICE_CONFIG_ANNOTATION = "ServiceConfig";
    private static final String AUTH_FIELD = "auth";

    private CacheAnalysisSupport() {
    }

    /**
     * Authentication is recognised only where it is declared on the resource or on its service. A service that
     * enforces authentication imperatively inside a resource body is out of scope, deliberately: establishing
     * that from the syntax alone is guesswork.
     */
    static boolean requiresAuthentication(HttpResourceRuleContext context) {
        boolean resourceAuth = context.resourceFunction().metadata()
                .map(metadata -> hasAuthField(metadata.annotations(), RESOURCE_CONFIG_ANNOTATION))
                .orElse(false);
        return resourceAuth || hasServiceLevelAuth(context);
    }

    static Optional<AnnotationNode> getReturnTypeAnnotation(HttpResourceRuleContext context, String annotationName) {
        Optional<ReturnTypeDescriptorNode> returnType =
                context.resourceFunction().functionSignature().returnTypeDesc();
        if (returnType.isEmpty()) {
            return Optional.empty();
        }
        return returnType.get().annotations().stream()
                .filter(annotation -> annotation.annotReference().toSourceCode().trim()
                        .endsWith(":" + annotationName))
                .findFirst();
    }

    static boolean isFieldTrue(MappingConstructorExpressionNode config, String fieldName) {
        return getFieldValue(config, fieldName)
                .flatMap(value -> getBooleanLiteralValue(value))
                .orElse(false);
    }

    private static boolean hasServiceLevelAuth(HttpResourceRuleContext context) {
        Optional<FunctionDefinitionNode> definition = context.resourceFunction().getFunctionDefinitionNode();
        if (definition.isEmpty()) {
            return false;
        }
        Node parent = definition.get().parent();
        if (!(parent instanceof ServiceDeclarationNode serviceDeclaration)) {
            return false;
        }
        return serviceDeclaration.metadata()
                .map(metadata -> hasAuthField(metadata.annotations(), SERVICE_CONFIG_ANNOTATION))
                .orElse(false);
    }

    private static boolean hasAuthField(NodeList<AnnotationNode> annotations, String annotationName) {
        for (AnnotationNode annotation : annotations) {
            if (!annotation.annotReference().toSourceCode().trim().endsWith(":" + annotationName)) {
                continue;
            }
            Optional<MappingConstructorExpressionNode> value = annotation.annotValue();
            if (value.isPresent() && getFieldValue(value.get(), AUTH_FIELD).isPresent()) {
                return true;
            }
        }
        return false;
    }
}
