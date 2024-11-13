/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.compiler.staticcodeanalyzer;

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.Document;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.scan.Reporter;
import io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil;

import java.util.Optional;
import java.util.regex.Pattern;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_PERMISSIVE_CORS;

class HttpAnnotationAnalyzer implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final Reporter reporter;
    private static final String CORS_FIELD_NAME = "cors";
    private static final String ALLOW_ORIGINS_FIELD_NAME = "allowOrigins";
    public static final Pattern WILDCARD_ORIGIN = Pattern.compile("\"(\s*)\\*(\s*)\"");

    public HttpAnnotationAnalyzer(Reporter reporter) {
        this.reporter = reporter;
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        AnnotationNode annotationNode = HttpCompilerPluginUtil.getAnnotationNode(context);
        if (annotationNode == null) {
            return;
        }
        Optional<MappingConstructorExpressionNode> annotationValue = annotationNode.annotValue();
        if (annotationValue.isEmpty()) {
            return;
        }
        Document document = HttpCompilerPluginUtil.getDocument(context);
        validateAnnotationValue(annotationValue.get(), document);
    }

    private void validateAnnotationValue(MappingConstructorExpressionNode annotationValueMap, Document document) {
        Optional<SpecificFieldNode> corsField = findSpecificField(annotationValueMap, CORS_FIELD_NAME);
        if (corsField.isEmpty() || corsField.get().valueExpr().isEmpty()) {
            return;
        }
        ExpressionNode corsVal = corsField.get().valueExpr().get();
        if (corsVal.kind() != SyntaxKind.MAPPING_CONSTRUCTOR) {
            return;
        }
        MappingConstructorExpressionNode corsMap = (MappingConstructorExpressionNode) corsVal;
        Optional<SpecificFieldNode> allowOrigins = findSpecificField(corsMap, ALLOW_ORIGINS_FIELD_NAME);
        if (allowOrigins.isEmpty() || allowOrigins.get().valueExpr().isEmpty()) {
            return;
        }
        ExpressionNode allowOriginsValue = allowOrigins.get().valueExpr().get();
        if (allowOriginsValue.kind() != SyntaxKind.LIST_CONSTRUCTOR) {
            return;
        }
        checkForPermissiveCors((ListConstructorExpressionNode) allowOriginsValue, document);
    }

    private Optional<SpecificFieldNode> findSpecificField(MappingConstructorExpressionNode mapNode, String fieldName) {
        return mapNode.fields().stream()
                .filter(field -> field.kind() == SyntaxKind.SPECIFIC_FIELD).map(field -> (SpecificFieldNode) field)
                .filter(field -> fieldName.equals(field.fieldName().toSourceCode().trim())).findFirst();
    }

    private void checkForPermissiveCors(ListConstructorExpressionNode allowedOrigins, Document document) {
        for (Node exp : allowedOrigins.expressions()) {
            if (WILDCARD_ORIGIN.matcher(exp.toSourceCode().trim()).find()) {
                this.reporter.reportIssue(document, exp.location(), AVOID_PERMISSIVE_CORS.getId());
            }
        }
    }
}
