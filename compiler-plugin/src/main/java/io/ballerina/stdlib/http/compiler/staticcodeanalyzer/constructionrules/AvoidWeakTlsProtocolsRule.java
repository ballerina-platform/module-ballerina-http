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

import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpConstructionRuleContext;

import java.util.Locale;
import java.util.Optional;
import java.util.Set;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_WEAK_TLS_PROTOCOLS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getFieldValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getListElements;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getNestedMapping;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getStringLiteralValue;

/**
 * Rule to detect weak TLS protocol versions on a client or listener secure socket.
 * <p>
 * The {@code SSL} protocol family is broken outright, and TLS 1.0 and TLS 1.1 are withdrawn: both rely on MD5 and
 * SHA-1 in the handshake and lack the modern cipher suites, which leaves them open to downgrade and padding-oracle
 * attacks. Naming any of them pins the endpoint to a protocol version that a current peer should refuse.
 *
 * @since 2.15.0
 */
public class AvoidWeakTlsProtocolsRule implements HttpConstructionRule {

    private static final String SECURE_SOCKET = "secureSocket";
    private static final String PROTOCOL = "protocol";
    private static final String NAME = "name";
    private static final String VERSIONS = "versions";
    private static final String SSL_PROTOCOL = "SSL";
    private static final Set<String> WEAK_VERSIONS = Set.of("SSLV3", "TLSV1.0", "TLSV1.1", "TLSV1", "SSL");

    @Override
    public void analyze(HttpConstructionRuleContext context) {
        Optional<MappingConstructorExpressionNode> protocol =
                context.arguments().getConfigurationRecord(SECURE_SOCKET)
                        .flatMap(secureSocket -> getNestedMapping(secureSocket, PROTOCOL));
        if (protocol.isEmpty()) {
            return;
        }
        checkProtocolName(context, protocol.get());
        checkProtocolVersions(context, protocol.get());
    }

    /**
     * Report {@code name: SSL}, which selects the SSL protocol family rather than TLS. The name is an enum member
     * reference, so it is matched on source text rather than as a string literal.
     */
    private void checkProtocolName(HttpConstructionRuleContext context,
                                   MappingConstructorExpressionNode protocol) {
        Optional<ExpressionNode> name = getFieldValue(protocol, NAME);
        if (name.isEmpty()) {
            return;
        }
        String protocolName = name.get().toSourceCode().trim();
        if (protocolName.equals(SSL_PROTOCOL) || protocolName.endsWith(":" + SSL_PROTOCOL)) {
            context.reporter().reportIssue(context.document(), name.get().location(), getRuleId());
        }
    }

    private void checkProtocolVersions(HttpConstructionRuleContext context,
                                       MappingConstructorExpressionNode protocol) {
        Optional<ExpressionNode> versions = getFieldValue(protocol, VERSIONS);
        if (versions.isEmpty()) {
            return;
        }
        for (ExpressionNode version : getListElements(versions.get())) {
            boolean isWeak = getStringLiteralValue(version)
                    .map(value -> WEAK_VERSIONS.contains(value.trim().toUpperCase(Locale.ROOT)))
                    .orElse(false);
            if (isWeak) {
                context.reporter().reportIssue(context.document(), version.location(), getRuleId());
            }
        }
    }

    @Override
    public int getRuleId() {
        return AVOID_WEAK_TLS_PROTOCOLS.getId();
    }

    @Override
    public boolean isApplicable(HttpConstructionRuleContext context) {
        return context.arguments().hasConfiguration();
    }
}
