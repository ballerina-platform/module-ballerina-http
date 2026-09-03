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

import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingFieldNode;
import io.ballerina.compiler.syntax.tree.SpecificFieldNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.Document;
import io.ballerina.scan.Reporter;

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_DISABLED_AUTH_PROVIDER_TLS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.ENSURE_AUTHORIZATION_SCOPES;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.ENSURE_JWT_VERIFICATION;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.findSpecificField;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getBooleanLiteralValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getEffectiveExpression;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getNestedMapping;

/**
 * Checks that apply to an authentication configuration record, wherever it appears.
 * <p>
 * The same configuration shapes are reachable from two unrelated places: a client passes them to its constructor,
 * and a service declares them in {@code @http:ServiceConfig}. The checks live here so both entry points share one
 * implementation rather than diverging.
 *
 * @since 2.15.0
 */
public final class AuthConfigAnalyzer {

    private static final String SECURE_SOCKET = "secureSocket";
    private static final String DISABLE = "disable";
    private static final String SCOPES = "scopes";
    private static final String SIGNATURE_CONFIG = "signatureConfig";
    private static final String ISSUER = "issuer";
    private static final String AUDIENCE = "audience";
    private static final String JWT_VALIDATOR_CONFIG = "jwtValidatorConfig";

    /**
     * The deepest nesting at which a secure socket appears inside an authentication configuration. A JWT validator
     * reaches its own at {@code signatureConfig.jwksConfig.clientConfig.secureSocket}.
     */
    private static final int MAX_SECURE_SOCKET_DEPTH = 4;

    private AuthConfigAnalyzer() {
    }

    /**
     * Report a secure socket, at any nesting depth within the authentication configuration, whose validation has been
     * disabled.
     * <p>
     * The clients that fetch tokens and JWKS documents carry their own secure socket, separate from the one on the
     * client or listener that uses them. Disabling validation there means the identity provider's response is
     * accepted from any host able to answer, which undermines every authentication decision made from it.
     *
     * @param authConfig the authentication configuration record
     * @param reporter   static code analysis reporter
     * @param document   the document being analyzed
     */
    public static void reportDisabledTlsValidation(MappingConstructorExpressionNode authConfig, Reporter reporter,
                                                   Document document) {
        reportDisabledTlsValidation(authConfig, reporter, document, 0);
    }

    private static void reportDisabledTlsValidation(MappingConstructorExpressionNode config, Reporter reporter,
                                                    Document document, int depth) {
        if (depth > MAX_SECURE_SOCKET_DEPTH) {
            return;
        }
        for (MappingFieldNode field : config.fields()) {
            if (field.kind() != SyntaxKind.SPECIFIC_FIELD) {
                continue;
            }
            SpecificFieldNode specificField = (SpecificFieldNode) field;
            Optional<ExpressionNode> value = specificField.valueExpr();
            if (value.isEmpty()
                    || !(getEffectiveExpression(value.get()) instanceof MappingConstructorExpressionNode nested)) {
                continue;
            }
            if (HttpStaticAnalysisUtils.matchesFieldName(specificField.fieldName(), SECURE_SOCKET, false)) {
                reportIfValidationDisabled(nested, reporter, document);
            }
            reportDisabledTlsValidation(nested, reporter, document, depth + 1);
        }
    }

    private static void reportIfValidationDisabled(MappingConstructorExpressionNode secureSocket, Reporter reporter,
                                                   Document document) {
        Optional<SpecificFieldNode> disable = findSpecificField(secureSocket, DISABLE);
        if (disable.isEmpty() || disable.get().valueExpr().isEmpty()) {
            return;
        }
        if (getBooleanLiteralValue(disable.get().valueExpr().get()).orElse(false)) {
            reporter.reportIssue(document, disable.get().location(), AVOID_DISABLED_AUTH_PROVIDER_TLS.getId());
        }
    }

    /**
     * Report a listener authentication configuration that carries no {@code scopes}.
     * <p>
     * Without scopes the service authenticates the caller and then authorizes every caller it managed to
     * authenticate, so any valid credential issued by the provider grants full access. That is authentication
     * standing in for authorization, which it cannot do.
     *
     * @param authConfig the listener authentication configuration record
     * @param reporter   static code analysis reporter
     * @param document   the document being analyzed
     */
    public static void reportMissingScopes(MappingConstructorExpressionNode authConfig, Reporter reporter,
                                           Document document) {
        if (findSpecificField(authConfig, SCOPES).isEmpty()) {
            reporter.reportIssue(document, authConfig.location(), ENSURE_AUTHORIZATION_SCOPES.getId());
        }
    }

    /**
     * Report a JWT validator configuration that omits a verification step.
     * <p>
     * {@code signatureConfig}, {@code issuer} and {@code audience} are all optional, and each one that is left out
     * removes a check rather than defaulting to a safe value. With no {@code signatureConfig} the signature is never
     * verified at all, so any self-signed token is accepted; with no {@code issuer} or {@code audience} a token
     * genuinely issued for a different service is accepted here.
     * <p>
     * A listener authentication configuration nests its provider under a named field, so the checks apply to the
     * {@code jwtValidatorConfig} record rather than to the entry that carries it. That field also identifies the
     * provider outright, since no other listener authentication configuration declares it.
     *
     * @param authConfig the listener authentication configuration record
     * @param reporter   static code analysis reporter
     * @param document   the document being analyzed
     */
    public static void reportUnverifiedJwt(MappingConstructorExpressionNode authConfig, Reporter reporter,
                                           Document document) {
        Optional<MappingConstructorExpressionNode> validatorConfig = getNestedMapping(authConfig,
                JWT_VALIDATOR_CONFIG);
        if (validatorConfig.isEmpty()) {
            return;
        }
        for (String field : List.of(SIGNATURE_CONFIG, ISSUER, AUDIENCE)) {
            if (findSpecificField(validatorConfig.get(), field).isEmpty()) {
                reporter.reportIssue(document, validatorConfig.get().location(), ENSURE_JWT_VERIFICATION.getId());
                return;
            }
        }
    }
}
