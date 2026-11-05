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
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.NewExpressionNode;
import io.ballerina.compiler.syntax.tree.NilLiteralNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.Document;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.scan.Reporter;

import java.util.Locale;
import java.util.Optional;
import java.util.Set;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_AUTHENTICATION_OVER_CLEARTEXT;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getEffectiveExpression;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getFieldValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getStringLiteralValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.isHttpAnnotation;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.resolveVariableInitializer;

/**
 * Check that a service accepting credentials is not exposed over a listener without TLS.
 * <p>
 * Flagging every listener without TLS would fire on nearly every service, most of them legitimately behind a
 * gateway that terminates TLS. A listener that <em>carries credentials</em> over cleartext is unambiguous: the
 * caller's token or password crosses the network in the clear, where anyone on the path can read and replay it.
 * A listener bound to a loopback address is exempt, since credentials sent to it never leave the host.
 *
 * @since 2.18.2
 */
final class ServiceTransportSecurityAnalyzer {

    private static final String AUTH_FIELD_NAME = "auth";
    private static final String SECURE_SOCKET = "secureSocket";
    private static final String HOST = "host";
    private static final String SERVICE_CONFIG_ANNOTATION = "ServiceConfig";
    private static final String RESOURCE_CONFIG_ANNOTATION = "ResourceConfig";
    private static final Set<String> LOOPBACK_HOSTS = Set.of("localhost", "::1", "[::1]", "0:0:0:0:0:0:0:1");
    private static final String IPV4_LOOPBACK_PREFIX = "127.";

    private ServiceTransportSecurityAnalyzer() {
    }

    static void analyze(SyntaxNodeAnalysisContext context, ServiceDeclarationNode service, Document document,
                        Reporter reporter) {
        if (!acceptsCredentials(context, service)) {
            return;
        }
        for (ExpressionNode listener : service.expressions()) {
            reportIfListenerIsCleartext(context, listener, document, reporter);
        }
    }

    /**
     * A service accepts credentials when its {@code @http:ServiceConfig} or any resource's
     * {@code @http:ResourceConfig} declares at least one authentication provider.
     */
    private static boolean acceptsCredentials(SyntaxNodeAnalysisContext context, ServiceDeclarationNode service) {
        if (declaresAuthProvider(context, service.metadata(), SERVICE_CONFIG_ANNOTATION)) {
            return true;
        }
        return service.members().stream()
                .filter(member -> member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION)
                .map(FunctionDefinitionNode.class::cast)
                .anyMatch(resource -> declaresAuthProvider(context, resource.metadata(), RESOURCE_CONFIG_ANNOTATION));
    }

    /**
     * Check for a non-empty provider list in the {@code auth} field of the named HTTP annotation. {@code auth: []}
     * configures no provider at all, and the {@code Scopes} form of a resource's {@code auth} only narrows the
     * service's providers, so neither accepts credentials on its own.
     */
    private static boolean declaresAuthProvider(SyntaxNodeAnalysisContext context, Optional<MetadataNode> metadata,
                                                String annotationName) {
        return metadata.stream()
                .flatMap(meta -> meta.annotations().stream())
                .filter(annotation -> isHttpAnnotation(context.semanticModel(), annotation, annotationName))
                .flatMap(annotation -> annotation.annotValue().stream())
                .flatMap(config -> getFieldValue(config, AUTH_FIELD_NAME).stream())
                .map(HttpStaticAnalysisUtils::getEffectiveExpression)
                .anyMatch(auth -> auth instanceof ListConstructorExpressionNode providers ?
                        !providers.expressions().isEmpty() : !(auth instanceof MappingConstructorExpressionNode));
    }

    /**
     * Report a listener that is constructed without a secure socket, or with {@code secureSocket = ()}.
     * <p>
     * A listener whose construction, configuration record or host cannot be resolved is left alone. Reporting one
     * would mean guessing that it has no TLS, and a listener built elsewhere is exactly the case where that guess is
     * most likely wrong.
     */
    private static void reportIfListenerIsCleartext(SyntaxNodeAnalysisContext context, ExpressionNode listener,
                                                    Document document, Reporter reporter) {
        Optional<NewExpressionNode> construction = resolveListenerConstruction(context, listener);
        if (construction.isEmpty()) {
            return;
        }
        HttpConstructionArguments arguments = HttpConstructionArguments.of(context, construction.get());
        if (arguments.hasUnresolvedConfiguration() || !isExposedBeyondHost(arguments)) {
            return;
        }
        Optional<ExpressionNode> secureSocket = arguments.getConfigurationField(SECURE_SOCKET);
        if (secureSocket.isEmpty() || getEffectiveExpression(secureSocket.get()) instanceof NilLiteralNode) {
            reporter.reportIssue(document, listener.location(), AVOID_AUTHENTICATION_OVER_CLEARTEXT.getId());
        }
    }

    /**
     * A listener with no {@code host} binds to every interface. One bound to a loopback address is reachable only
     * from the same host, and one whose host is not a literal cannot be judged.
     */
    private static boolean isExposedBeyondHost(HttpConstructionArguments arguments) {
        Optional<ExpressionNode> host = arguments.getConfigurationField(HOST);
        if (host.isEmpty()) {
            return true;
        }
        return getStringLiteralValue(host.get())
                .map(value -> value.trim().toLowerCase(Locale.ROOT))
                .map(value -> !LOOPBACK_HOSTS.contains(value) && !value.startsWith(IPV4_LOOPBACK_PREFIX))
                .orElse(false);
    }

    /**
     * Resolve the constructor expression of the given listener, whether it is written inline on the service or
     * declared elsewhere in the module and referenced by name.
     */
    private static Optional<NewExpressionNode> resolveListenerConstruction(SyntaxNodeAnalysisContext context,
                                                                          ExpressionNode listener) {
        ExpressionNode expression = getEffectiveExpression(listener);
        if (expression instanceof NewExpressionNode newExpression) {
            return Optional.of(newExpression);
        }
        return resolveVariableInitializer(context, expression)
                .filter(NewExpressionNode.class::isInstance)
                .map(NewExpressionNode.class::cast);
    }
}
