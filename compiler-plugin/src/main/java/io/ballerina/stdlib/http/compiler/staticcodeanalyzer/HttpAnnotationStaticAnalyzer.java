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

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_CREDENTIALED_WILDCARD_CORS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_PERMISSIVE_CORS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.findSpecificField;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getEffectiveExpression;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getFieldValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getListElements;

/**
 * Analyzer to validate static rules related to HTTP annotations.
 *
 * @since 2.15.0
 */
class HttpAnnotationStaticAnalyzer implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private final Reporter reporter;
    private static final String CORS_FIELD_NAME = "cors";
    private static final String ALLOW_ORIGINS_FIELD_NAME = "allowOrigins";
    private static final String ALLOW_CREDENTIALS_FIELD_NAME = "allowCredentials";
    private static final String AUTH_FIELD_NAME = "auth";
    public static final Pattern WILDCARD_ORIGIN = Pattern.compile("\"(\s*)\\*(\s*)\"");

    public HttpAnnotationStaticAnalyzer(Reporter reporter) {
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
        validateCorsConfig(annotationValue.get(), document);
        validateAuthConfig(annotationValue.get(), document);
    }

    /**
     * Validate every listener authentication configuration declared on the annotation.
     * <p>
     * {@code auth} is a list of provider configurations. A resource may instead give a bare {@code Scopes} record,
     * which carries a required {@code scopes} field and so has nothing to check.
     *
     * @param annotationValueMap the annotation's configuration record
     * @param document           the document being analyzed
     */
    private void validateAuthConfig(MappingConstructorExpressionNode annotationValueMap, Document document) {
        Optional<ExpressionNode> authField = getFieldValue(annotationValueMap, AUTH_FIELD_NAME);
        if (authField.isEmpty()) {
            return;
        }
        for (ExpressionNode authConfig : getListElements(authField.get())) {
            if (getEffectiveExpression(authConfig) instanceof MappingConstructorExpressionNode authConfigMap) {
                AuthConfigAnalyzer.reportDisabledTlsValidation(authConfigMap, this.reporter, document);
                AuthConfigAnalyzer.reportUnverifiedJwt(authConfigMap, this.reporter, document);
                AuthConfigAnalyzer.reportMissingScopes(authConfigMap, this.reporter, document);
            }
        }
    }

    private void validateCorsConfig(MappingConstructorExpressionNode annotationValueMap, Document document) {
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
        ListConstructorExpressionNode origins = (ListConstructorExpressionNode) allowOriginsValue;
        checkForPermissiveCors(origins, document);
        checkForCredentialedWildcardCors(corsMap, origins, document);
    }

    /**
     * Report a wildcard origin that is combined with {@code allowCredentials: true}.
     * <p>
     * A wildcard origin on its own exposes only unauthenticated responses. Combined with credentials it allows any
     * site to issue authenticated cross-origin requests and read the responses, so the two together are materially
     * more dangerous than either alone. Browsers reject this combination, which means the service is either
     * relying on a non-browser client or the configuration does not work as its author intended.
     *
     * @param corsMap  the {@code cors} configuration record
     * @param origins  the {@code allowOrigins} list
     * @param document the document being analyzed
     */
    private void checkForCredentialedWildcardCors(MappingConstructorExpressionNode corsMap,
                                                  ListConstructorExpressionNode origins, Document document) {
        Optional<SpecificFieldNode> allowCredentials = findSpecificField(corsMap, ALLOW_CREDENTIALS_FIELD_NAME);
        if (allowCredentials.isEmpty() || allowCredentials.get().valueExpr().isEmpty()) {
            return;
        }
        // Only a literal `true` is actionable. A variable or expression cannot be resolved here, and reporting on
        // one would be a guess, so those are left alone.
        if (!Boolean.parseBoolean(allowCredentials.get().valueExpr().get().toSourceCode().trim())) {
            return;
        }
        boolean hasWildcardOrigin = origins.expressions().stream()
                .anyMatch(exp -> WILDCARD_ORIGIN.matcher(exp.toSourceCode().trim()).find());
        if (hasWildcardOrigin) {
            this.reporter.reportIssue(document, allowCredentials.get().location(),
                    AVOID_CREDENTIALED_WILDCARD_CORS.getId());
        }
    }

    private void checkForPermissiveCors(ListConstructorExpressionNode allowedOrigins, Document document) {
        for (Node exp : allowedOrigins.expressions()) {
            if (WILDCARD_ORIGIN.matcher(exp.toSourceCode().trim()).find()) {
                this.reporter.reportIssue(document, exp.location(), AVOID_PERMISSIVE_CORS.getId());
            }
        }
    }
}
