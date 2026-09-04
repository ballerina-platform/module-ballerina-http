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

import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.NamedArgumentNode;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getEffectiveExpression;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getNestedMapping;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.resolveVariableInitializer;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.unescapeIdentifier;

/**
 * The arguments of a constructor call, normalized so that configuration fields can be looked up by name regardless
 * of how the caller supplied them.
 * <p>
 * The HTTP constructors take their configuration through an included record parameter, for example
 * {@code Listener.init(int port, *ListenerConfiguration config)}. That means the same field arrives in either of two
 * shapes, and a rule that assumes one silently misses the other:
 * <pre>
 *     new http:Listener(9090, {secureSocket: {...}})   // a positional mapping constructor
 *     new http:Listener(9090, secureSocket = {...})    // a named argument
 * </pre>
 *
 * @since 2.15.0
 */
public final class HttpConstructionArguments {

    private final List<ExpressionNode> positionalArguments = new ArrayList<>();
    private final Map<String, ExpressionNode> namedArguments = new LinkedHashMap<>();
    private MappingConstructorExpressionNode inlineConfiguration;
    private boolean configurationUnresolved;

    private HttpConstructionArguments() {
    }

    /**
     * An empty argument set, for a bare {@code new} that carries no argument list.
     *
     * @return an argument set with no arguments
     */
    public static HttpConstructionArguments empty() {
        return new HttpConstructionArguments();
    }

    public HttpConstructionArguments(SyntaxNodeAnalysisContext context,
                                     SeparatedNodeList<FunctionArgumentNode> arguments) {
        for (FunctionArgumentNode argument : arguments) {
            switch (argument) {
                case PositionalArgumentNode positionalArgument -> {
                    ExpressionNode expression = getEffectiveExpression(positionalArgument.expression());
                    positionalArguments.add(expression);
                    acceptPositionalConfiguration(context, expression);
                }
                case NamedArgumentNode namedArgument -> namedArguments.put(
                        unescapeIdentifier(namedArgument.argumentName().name().text()),
                        getEffectiveExpression(namedArgument.expression()));
                default -> {
                    // A rest argument spreads a value that cannot be resolved without data-flow analysis
                }
            }
        }
    }

    /**
     * Record a positional argument that carries the configuration record.
     * <p>
     * The record is either written inline or held in a variable, and a variable is followed to the expression it was
     * declared with. One that cannot be followed leaves the configuration unresolved, so that a rule reporting on an
     * absent field does not mistake what it cannot see for what is not there.
     */
    private void acceptPositionalConfiguration(SyntaxNodeAnalysisContext context, ExpressionNode expression) {
        if (expression instanceof MappingConstructorExpressionNode mappingConstructor) {
            inlineConfiguration = mappingConstructor;
            return;
        }
        if (!isConfigurationRecord(context, expression)) {
            return;
        }
        Optional<MappingConstructorExpressionNode> declaredValue = resolveVariableInitializer(context, expression)
                .filter(MappingConstructorExpressionNode.class::isInstance)
                .map(MappingConstructorExpressionNode.class::cast);
        if (declaredValue.isPresent()) {
            inlineConfiguration = declaredValue.get();
        } else {
            configurationUnresolved = true;
        }
    }

    /**
     * Tell the configuration argument from the other positional arguments, such as a listener port or a client URL,
     * by its type rather than its position, since each constructor places it differently.
     */
    private static boolean isConfigurationRecord(SyntaxNodeAnalysisContext context, ExpressionNode expression) {
        return context.semanticModel().typeOf(expression)
                .map(HttpStaticAnalysisUtils::resolveEffectiveType)
                .filter(type -> type.typeKind() == TypeDescKind.RECORD)
                .isPresent();
    }

    /**
     * Get a configuration field, whether it was supplied inside a positional configuration record or as a named
     * argument.
     *
     * @param fieldName the configuration field name
     * @return the field value if supplied, empty otherwise
     */
    public Optional<ExpressionNode> getConfigurationField(String fieldName) {
        Optional<ExpressionNode> namedArgument = Optional.ofNullable(namedArguments.get(fieldName));
        if (namedArgument.isPresent()) {
            return namedArgument;
        }
        return Optional.ofNullable(inlineConfiguration)
                .flatMap(config -> HttpStaticAnalysisUtils.getFieldValue(config, fieldName));
    }

    /**
     * Get a configuration field whose value is itself a record.
     *
     * @param fieldName the configuration field name
     * @return the nested record if supplied as a mapping constructor, empty otherwise
     */
    public Optional<MappingConstructorExpressionNode> getConfigurationRecord(String fieldName) {
        Optional<ExpressionNode> namedArgument = Optional.ofNullable(namedArguments.get(fieldName));
        if (namedArgument.isPresent()) {
            return namedArgument
                    .filter(MappingConstructorExpressionNode.class::isInstance)
                    .map(MappingConstructorExpressionNode.class::cast);
        }
        return Optional.ofNullable(inlineConfiguration).flatMap(config -> getNestedMapping(config, fieldName));
    }

    /**
     * Get a positional argument by its index.
     *
     * @param index the zero-based argument position
     * @return the argument expression if present, empty otherwise
     */
    public Optional<ExpressionNode> getPositionalArgument(int index) {
        return index >= 0 && index < positionalArguments.size() ?
                Optional.of(positionalArguments.get(index)) : Optional.empty();
    }

    /**
     * Check whether the caller supplied any configuration at all, in either shape.
     *
     * @return true if a configuration record or at least one named argument was supplied
     */
    public boolean hasConfiguration() {
        return inlineConfiguration != null || !namedArguments.isEmpty() || configurationUnresolved;
    }

    /**
     * Check whether a configuration record was supplied in a form this analysis cannot read.
     * <p>
     * A rule that reports on an absent field must consult this first: an unreadable record may well set the field,
     * and reporting it would be a guess.
     *
     * @return true if configuration was supplied but could not be resolved
     */
    public boolean hasUnresolvedConfiguration() {
        return configurationUnresolved;
    }
}
