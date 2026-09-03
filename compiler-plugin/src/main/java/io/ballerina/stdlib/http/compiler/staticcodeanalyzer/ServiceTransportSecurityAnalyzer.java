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
import io.ballerina.compiler.syntax.tree.ListenerDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.NewExpressionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.ParenthesizedArgList;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.scan.Reporter;
import io.ballerina.tools.diagnostics.Location;

import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_AUTHENTICATION_OVER_CLEARTEXT;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getEffectiveExpression;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getFieldValue;

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
        Optional<AnnotationNode> serviceConfig = getServiceConfigAnnotation(service);
        if (serviceConfig.isEmpty()) {
            return;
        }
        Optional<ExpressionNode> auth = serviceConfig.get().annotValue()
                .flatMap(config -> getFieldValue(config, AUTH_FIELD_NAME));
        if (auth.isEmpty()) {
            return;
        }
        for (ExpressionNode listener : service.expressions()) {
            reportIfListenerIsCleartext(context, listener, document, reporter);
        }
    }

    /**
     * Report a listener that is constructed without a secure socket.
     * <p>
     * A listener whose construction cannot be resolved is left alone. Reporting one would mean guessing that it has
     * no TLS, and a listener built elsewhere is exactly the case where that guess is most likely wrong.
     */
    private static void reportIfListenerIsCleartext(SyntaxNodeAnalysisContext context, ExpressionNode listener,
                                                    Document document, Reporter reporter) {
        Optional<NewExpressionNode> construction = resolveListenerConstruction(context, listener);
        if (construction.isEmpty()) {
            return;
        }
        HttpConstructionArguments arguments = getArguments(construction.get())
                .map(HttpConstructionArguments::new)
                .orElseGet(HttpConstructionArguments::empty);
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
        return context.semanticModel().symbol(expression)
                .flatMap(Symbol::getLocation)
                .flatMap(location -> findDeclarationNode(context, location))
                .flatMap(ServiceTransportSecurityAnalyzer::getDeclarationInitializer);
    }

    /**
     * Find the syntax node a symbol was declared at. The declaration may live in any document of the module, so it
     * is located by the file name the symbol reports.
     */
    private static Optional<Node> findDeclarationNode(SyntaxNodeAnalysisContext context, Location location) {
        Module module = context.currentPackage().module(context.moduleId());
        for (DocumentId documentId : module.documentIds()) {
            Document document = module.document(documentId);
            if (!document.name().equals(location.lineRange().fileName())) {
                continue;
            }
            if (document.syntaxTree().rootNode() instanceof ModulePartNode modulePart) {
                return Optional.ofNullable(modulePart.findNode(location.textRange()));
            }
        }
        return Optional.empty();
    }

    private static Optional<NewExpressionNode> getDeclarationInitializer(Node declaration) {
        Node current = declaration;
        while (current != null) {
            Optional<Node> initializer = switch (current) {
                case ListenerDeclarationNode listenerDeclaration ->
                        Optional.of(listenerDeclaration.initializer());
                case ModuleVariableDeclarationNode variableDeclaration ->
                        variableDeclaration.initializer().map(Node.class::cast);
                default -> Optional.empty();
            };
            if (initializer.isPresent()) {
                return initializer
                        .filter(ExpressionNode.class::isInstance)
                        .map(node -> getEffectiveExpression((ExpressionNode) node))
                        .filter(NewExpressionNode.class::isInstance)
                        .map(NewExpressionNode.class::cast);
            }
            current = current.parent();
        }
        return Optional.empty();
    }

    private static Optional<SeparatedNodeList<FunctionArgumentNode>> getArguments(NewExpressionNode newExpression) {
        return switch (newExpression) {
            case ExplicitNewExpressionNode explicitNew -> Optional.of(explicitNew.parenthesizedArgList().arguments());
            case ImplicitNewExpressionNode implicitNew ->
                    implicitNew.parenthesizedArgList().map(ParenthesizedArgList::arguments);
            default -> Optional.empty();
        };
    }

    private static Optional<AnnotationNode> getServiceConfigAnnotation(ServiceDeclarationNode service) {
        return service.metadata()
                .map(metadata -> metadata.annotations().stream()
                        .filter(ServiceTransportSecurityAnalyzer::isServiceConfig)
                        .findFirst())
                .flatMap(annotation -> annotation);
    }

    private static boolean isServiceConfig(AnnotationNode annotation) {
        return annotation.annotReference().toSourceCode().trim().endsWith(":" + SERVICE_CONFIG_ANNOTATION);
    }
}
