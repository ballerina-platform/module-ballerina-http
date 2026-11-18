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

import io.ballerina.compiler.api.symbols.ClassSymbol;
import io.ballerina.compiler.api.symbols.ParameterKind;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.ExplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.ExpressionNode;
import io.ballerina.compiler.syntax.tree.FunctionArgumentNode;
import io.ballerina.compiler.syntax.tree.ImplicitNewExpressionNode;
import io.ballerina.compiler.syntax.tree.MappingConstructorExpressionNode;
import io.ballerina.compiler.syntax.tree.NamedArgumentNode;
import io.ballerina.compiler.syntax.tree.NewExpressionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.ParenthesizedArgList;
import io.ballerina.compiler.syntax.tree.PositionalArgumentNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Location;

import java.util.ArrayList;
import java.util.IdentityHashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getEffectiveExpression;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getFieldValue;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.getListElements;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.hasUnresolvableFields;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.resolveVariableInitializer;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticAnalysisUtils.unescapeIdentifier;

/**
 * The arguments of a constructor call, normalized so that configuration fields can be looked up by name regardless
 * of how the caller supplied them.
 * <p>
 * The HTTP constructors take their configuration through an included record parameter, for example
 * {@code Listener.init(int port, *ListenerConfiguration config)}. That means the same field arrives in any of three
 * shapes, and a rule that assumes one silently misses the others:
 * <pre>
 *     new http:Listener(9090, {secureSocket: {...}})            // a positional mapping constructor
 *     new http:Listener(9090, config = {secureSocket: {...}})   // the included record passed by name
 *     new http:Listener(9090, secureSocket = {...})             // a named argument per field
 * </pre>
 * A record held in an immutable variable is followed to its initializer. An issue found inside such an initializer
 * is reported at the call site, see {@link #issueLocation(Node)}.
 *
 * @since 2.18.2
 */
public final class HttpConstructionArguments {

    private static final String SECURE_SOCKET = "secureSocket";
    private static final String TARGETS = "targets";

    private final SyntaxNodeAnalysisContext context;
    private final String includedRecordParamName;
    private final List<ExpressionNode> positionalArguments = new ArrayList<>();
    private final Map<String, ExpressionNode> namedArguments = new LinkedHashMap<>();
    private final Map<Node, Location> followedValueCallSites = new IdentityHashMap<>();
    private MappingConstructorExpressionNode inlineConfiguration;
    private boolean configurationUnresolved;

    private HttpConstructionArguments(SyntaxNodeAnalysisContext context, String includedRecordParamName) {
        this.context = context;
        this.includedRecordParamName = includedRecordParamName;
    }

    /**
     * Collect the arguments of a constructor call. A bare {@code new} carries no argument list and yields an empty
     * argument set.
     *
     * @param context       the analysis context, for the semantic model and the module's documents
     * @param newExpression the constructor call
     * @return the normalized arguments
     */
    public static HttpConstructionArguments of(SyntaxNodeAnalysisContext context, NewExpressionNode newExpression) {
        HttpConstructionArguments arguments = new HttpConstructionArguments(context,
                getIncludedRecordParamName(context, newExpression).orElse(null));
        getArgumentList(newExpression).ifPresent(arguments::accept);
        return arguments;
    }

    private void accept(SeparatedNodeList<FunctionArgumentNode> arguments) {
        for (FunctionArgumentNode argument : arguments) {
            switch (argument) {
                case PositionalArgumentNode positionalArgument -> {
                    ExpressionNode expression = getEffectiveExpression(positionalArgument.expression());
                    positionalArguments.add(expression);
                    acceptConfigurationRecord(expression);
                }
                case NamedArgumentNode namedArgument -> {
                    String name = unescapeIdentifier(namedArgument.argumentName().name().text());
                    ExpressionNode expression = getEffectiveExpression(namedArgument.expression());
                    if (name.equals(includedRecordParamName)) {
                        acceptConfigurationRecord(expression);
                    } else {
                        namedArguments.put(name, expression);
                    }
                }
                // A rest argument spreads a value that cannot be resolved without data-flow analysis
                default -> configurationUnresolved = true;
            }
        }
    }

    /**
     * Record an argument that may carry the whole configuration record.
     * <p>
     * The record is either written inline or held in a variable, and an immutable variable is followed to the
     * expression it was declared with. One that cannot be followed, or a record built with spread or computed
     * fields, leaves the configuration unresolved, so that a rule reporting on an absent field does not mistake what
     * it cannot see for what is not there.
     */
    private void acceptConfigurationRecord(ExpressionNode expression) {
        if (expression instanceof MappingConstructorExpressionNode mappingConstructor) {
            setInlineConfiguration(mappingConstructor);
            return;
        }
        if (!isConfigurationRecord(expression)) {
            return;
        }
        Optional<MappingConstructorExpressionNode> declaredValue = followVariable(expression);
        if (declaredValue.isPresent()) {
            setInlineConfiguration(declaredValue.get());
        } else {
            configurationUnresolved = true;
        }
    }

    private void setInlineConfiguration(MappingConstructorExpressionNode configuration) {
        inlineConfiguration = configuration;
        if (hasUnresolvableFields(configuration)) {
            configurationUnresolved = true;
        }
    }

    /**
     * Tell the configuration argument from the other positional arguments, such as a listener port or a client URL,
     * by its type rather than its position, since each constructor places it differently. A fallible producer under
     * {@code check} is typed as a union with {@code error}, so the error members are dropped first.
     */
    private boolean isConfigurationRecord(ExpressionNode expression) {
        return context.semanticModel().typeOf(expression)
                .map(HttpStaticAnalysisUtils::resolveConstructedType)
                .map(HttpStaticAnalysisUtils::resolveEffectiveType)
                .filter(type -> type.typeKind() == TypeDescKind.RECORD)
                .isPresent();
    }

    private Optional<MappingConstructorExpressionNode> followVariable(ExpressionNode expression) {
        Optional<MappingConstructorExpressionNode> declaredValue = resolveVariableInitializer(context, expression)
                .filter(MappingConstructorExpressionNode.class::isInstance)
                .map(MappingConstructorExpressionNode.class::cast);
        declaredValue.ifPresent(value -> followedValueCallSites.put(value, expression.location()));
        return declaredValue;
    }

    /**
     * Resolve a value to the mapping constructor it denotes, written inline or held in an immutable variable.
     *
     * @param value the value expression
     * @return the mapping constructor if the value could be resolved to one, empty otherwise
     */
    public Optional<MappingConstructorExpressionNode> resolveRecord(ExpressionNode value) {
        ExpressionNode effective = getEffectiveExpression(value);
        if (effective instanceof MappingConstructorExpressionNode mappingConstructor) {
            return Optional.of(mappingConstructor);
        }
        return followVariable(effective);
    }

    /**
     * Get the configuration record itself, when it was supplied as one record rather than field by field.
     *
     * @return the configuration record if it could be resolved to a mapping constructor, empty otherwise
     */
    public Optional<MappingConstructorExpressionNode> getConfiguration() {
        return Optional.ofNullable(inlineConfiguration);
    }

    /**
     * Get a configuration field, whether it was supplied inside the configuration record or as a named argument.
     *
     * @param fieldName the configuration field name
     * @return the field value if supplied, empty otherwise
     */
    public Optional<ExpressionNode> getConfigurationField(String fieldName) {
        Optional<ExpressionNode> namedArgument = Optional.ofNullable(namedArguments.get(fieldName));
        if (namedArgument.isPresent()) {
            return namedArgument;
        }
        return Optional.ofNullable(inlineConfiguration).flatMap(config -> getFieldValue(config, fieldName));
    }

    /**
     * Get a configuration field whose value is itself a record, written inline or held in an immutable variable.
     *
     * @param fieldName the configuration field name
     * @return the nested record if it could be resolved to a mapping constructor, empty otherwise
     */
    public Optional<MappingConstructorExpressionNode> getConfigurationRecord(String fieldName) {
        return getConfigurationField(fieldName).flatMap(this::resolveRecord);
    }

    /**
     * Get a field of a record reached through this argument set whose value is itself a record.
     *
     * @param record    the enclosing record
     * @param fieldName the field name
     * @return the nested record if it could be resolved to a mapping constructor, empty otherwise
     */
    public Optional<MappingConstructorExpressionNode> getNestedRecord(MappingConstructorExpressionNode record,
                                                                      String fieldName) {
        return getFieldValue(record, fieldName).flatMap(this::resolveRecord);
    }

    /**
     * Get every client or listener secure socket configured by this argument set: the top-level
     * {@code secureSocket}, and the one on each {@code targets} entry of a failover or load-balancing client.
     *
     * @return the secure socket records that could be resolved
     */
    public List<MappingConstructorExpressionNode> getSecureSocketRecords() {
        List<MappingConstructorExpressionNode> secureSockets = new ArrayList<>();
        getConfigurationRecord(SECURE_SOCKET).ifPresent(secureSockets::add);
        getConfigurationField(TARGETS).ifPresent(targets -> getListElements(targets).stream()
                .map(this::resolveRecord)
                .flatMap(Optional::stream)
                .forEach(target -> getNestedRecord(target, SECURE_SOCKET).ifPresent(secureSockets::add)));
        return secureSockets;
    }

    /**
     * Get the location an issue on the given node should be reported at.
     * <p>
     * A node inside a variable's initializer belongs to the declaration, which may be in another document and shared
     * by several constructions. The issue is reported at the argument that referenced the variable instead, so that
     * it lands in the document being analyzed and once per construction.
     *
     * @param node the node the issue concerns
     * @return the location to report at
     */
    public Location issueLocation(Node node) {
        for (Node current = node; current != null; current = current.parent()) {
            Location callSite = followedValueCallSites.get(current);
            if (callSite != null) {
                return callSite;
            }
        }
        return node.location();
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
     * Check whether the caller supplied any configuration at all, in any shape.
     *
     * @return true if a configuration record or at least one named argument was supplied
     */
    public boolean hasConfiguration() {
        return inlineConfiguration != null || !namedArguments.isEmpty() || configurationUnresolved;
    }

    /**
     * Check whether configuration was supplied in a form this analysis cannot read.
     * <p>
     * A rule that reports on an absent field must consult this first: an unreadable record may well set the field,
     * and reporting it would be a guess.
     *
     * @return true if configuration was supplied but could not be resolved
     */
    public boolean hasUnresolvedConfiguration() {
        return configurationUnresolved;
    }

    private static Optional<SeparatedNodeList<FunctionArgumentNode>> getArgumentList(NewExpressionNode newExpression) {
        return switch (newExpression) {
            case ExplicitNewExpressionNode explicitNew -> Optional.of(explicitNew.parenthesizedArgList().arguments());
            case ImplicitNewExpressionNode implicitNew ->
                    implicitNew.parenthesizedArgList().map(ParenthesizedArgList::arguments);
            default -> Optional.empty();
        };
    }

    /**
     * Find the name of the constructor's included record parameter, such as {@code config} or {@code options}, which
     * a caller may pass by name to supply the whole configuration record.
     */
    private static Optional<String> getIncludedRecordParamName(SyntaxNodeAnalysisContext context,
                                                               NewExpressionNode newExpression) {
        Optional<TypeSymbol> constructedType = context.semanticModel().typeOf(newExpression)
                .map(HttpStaticAnalysisUtils::resolveConstructedType);
        if (constructedType.isEmpty()
                || !(constructedType.get() instanceof TypeReferenceTypeSymbol typeReference)
                || !(typeReference.definition() instanceof ClassSymbol classSymbol)) {
            return Optional.empty();
        }
        return classSymbol.initMethod()
                .flatMap(init -> init.typeDescriptor().params())
                .flatMap(params -> params.stream()
                        .filter(param -> param.paramKind() == ParameterKind.INCLUDED_RECORD)
                        .findFirst())
                .flatMap(ParameterSymbol::getName);
    }
}
