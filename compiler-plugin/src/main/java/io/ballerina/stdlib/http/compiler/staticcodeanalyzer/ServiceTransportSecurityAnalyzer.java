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

import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.ExplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.ImplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.ListConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.NewExpressionNode;
import io.ballerina.compiler.syntax.tree.ParenthesizedArgList;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.projects.Document;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.scan.Reporter;

import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isHttpModule;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_AUTHENTICATION_OVER_CLEARTEXT;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getEffectiveExpression;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getFieldValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.resolveVariableInitializer;

/**
 * Check that a service accepting credentials is not exposed over a listener without TLS.
 * <p>
 * Flagging every listener without TLS would fire on nearly every service, most of them legitimately behind a
 * gateway that terminates TLS. A listener that <em>carries credentials</em> over cleartext is unambiguous: the
 * caller's token or password crosses the network in the clear, where anyone on the path can read and replay it.
 *
 * @since 2.15.0
 */
final class ServiceTransportSecurityAnalyzer {

    private static final String AUTH_FIELD_NAME = "auth";
    private static final String SECURE_SOCKET = "secureSocket";
    private static final String SERVICE_CONFIG_ANNOTATION = "ServiceConfig";

    private ServiceTransportSecurityAnalyzer() {
    }

    static void analyze(SyntaxNodeAnalysisContext context, ServiceDeclarationNode service, Document document,
                        Reporter reporter) {
        Optional<AnnotationNode> serviceConfig = getServiceConfigAnnotation(context, service);
        if (serviceConfig.isEmpty()) {
            return;
        }
        Optional<ExpressionNode> auth = serviceConfig.get().annotValue()
                .flatMap(config -> getFieldValue(config, AUTH_FIELD_NAME));
        if (auth.isEmpty() || declaresNoAuthProvider(auth.get())) {
            return;
        }
        for (ExpressionNode listener : service.expressions()) {
            reportIfListenerIsCleartext(context, listener, document, reporter);
        }
    }

    /**
     * Check for {@code auth: []}, which configures no provider at all. The service accepts no credentials, so
     * nothing crosses the network for a cleartext listener to expose.
     */
    private static boolean declaresNoAuthProvider(ExpressionNode auth) {
        return getEffectiveExpression(auth) instanceof ListConstructorExpressionNode providers
                && providers.expressions().isEmpty();
    }

    /**
     * Report a listener that is constructed without a secure socket.
     * <p>
     * A listener whose construction, or whose configuration record, cannot be resolved is left alone. Reporting one
     * would mean guessing that it has no TLS, and a listener built elsewhere is exactly the case where that guess is
     * most likely wrong.
     */
    private static void reportIfListenerIsCleartext(SyntaxNodeAnalysisContext context, ExpressionNode listener,
                                                    Document document, Reporter reporter) {
        Optional<NewExpressionNode> construction = resolveListenerConstruction(context, listener);
        if (construction.isEmpty()) {
            return;
        }
        HttpConstructionArguments arguments = getArguments(construction.get())
                .map(argumentList -> new HttpConstructionArguments(context, argumentList))
                .orElseGet(HttpConstructionArguments::empty);
        if (arguments.hasUnresolvedConfiguration()) {
            return;
        }
        if (arguments.getConfigurationField(SECURE_SOCKET).isEmpty()) {
            reporter.reportIssue(document, listener.location(), AVOID_AUTHENTICATION_OVER_CLEARTEXT.getId());
        }
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

    private static Optional<SeparatedNodeList<FunctionArgumentNode>> getArguments(NewExpressionNode newExpression) {
        return switch (newExpression) {
            case ExplicitNewExpressionNode explicitNew -> Optional.of(explicitNew.parenthesizedArgList().arguments());
            case ImplicitNewExpressionNode implicitNew ->
                    implicitNew.parenthesizedArgList().map(ParenthesizedArgList::arguments);
            default -> Optional.empty();
        };
    }

    private static Optional<AnnotationNode> getServiceConfigAnnotation(SyntaxNodeAnalysisContext context,
                                                                      ServiceDeclarationNode service) {
        return service.metadata()
                .map(metadata -> metadata.annotations().stream()
                        .filter(annotation -> isHttpServiceConfig(context, annotation))
                        .findFirst())
                .flatMap(annotation -> annotation);
    }

    /**
     * Confirm the annotation is {@code ballerina/http:ServiceConfig}. The name alone is not enough, since other
     * modules declare a {@code ServiceConfig} of their own with an {@code auth} field that means something else.
     */
    private static boolean isHttpServiceConfig(SyntaxNodeAnalysisContext context, AnnotationNode annotation) {
        if (!annotation.annotReference().toSourceCode().trim().endsWith(":" + SERVICE_CONFIG_ANNOTATION)) {
            return false;
        }
        return context.semanticModel().symbol(annotation.annotReference())
                .flatMap(Symbol::getModule)
                .filter(module -> module.getName().isPresent() && isHttpModule(module))
                .isPresent();
    }
}
