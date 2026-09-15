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

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_DISABLED_TLS_VALIDATION;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.findSpecificField;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getBooleanLiteralValue;

/**
 * Rule to detect a client whose TLS validation has been switched off.
 * <p>
 * {@code enable: false} turns off SSL for the client entirely, and {@code verifyHostName: false} keeps the encrypted
 * channel but stops checking that the certificate belongs to the host being contacted. Either one leaves the
 * connection open to interception by any party able to present a certificate, so the transport looks secure while
 * providing no authentication of the peer.
 *
 * @since 2.15.0
 */
public class AvoidDisabledTlsValidationRule implements HttpConstructionRule {

    private static final String SECURE_SOCKET = "secureSocket";
    private static final String ENABLE = "enable";
    private static final String VERIFY_HOST_NAME = "verifyHostName";

    @Override
    public void analyze(HttpConstructionRuleContext context) {
        Optional<MappingConstructorExpressionNode> secureSocket =
                context.arguments().getConfigurationRecord(SECURE_SOCKET);
        if (secureSocket.isEmpty()) {
            return;
        }
        for (String field : List.of(ENABLE, VERIFY_HOST_NAME)) {
            reportIfDisabled(context, secureSocket.get(), field);
        }
    }

    /**
     * Report a field that is explicitly set to {@code false}. Both fields default to {@code true}, so only an
     * explicit assignment weakens the connection and an absent field is correct usage.
     */
    private void reportIfDisabled(HttpConstructionRuleContext context, MappingConstructorExpressionNode secureSocket,
                                  String fieldName) {
        Optional<SpecificFieldNode> field = findSpecificField(secureSocket, fieldName);
        if (field.isEmpty() || field.get().valueExpr().isEmpty()) {
            return;
        }
        if (getBooleanLiteralValue(field.get().valueExpr().get()).filter(value -> !value).isPresent()) {
            context.reporter().reportIssue(context.document(), field.get().location(), getRuleId());
        }
    }

    @Override
    public int getRuleId() {
        return AVOID_DISABLED_TLS_VALIDATION.getId();
    }

    @Override
    public boolean isApplicable(HttpConstructionRuleContext context) {
        return context.arguments().hasConfiguration();
    }
}
