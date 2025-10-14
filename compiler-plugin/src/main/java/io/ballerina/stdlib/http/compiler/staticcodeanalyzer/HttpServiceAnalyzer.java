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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.PathParameterSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.resourcepath.PathSegmentList;
import io.ballerina.compiler.api.symbols.resourcepath.ResourcePath;
import io.ballerina.compiler.syntax.tree.FunctionBodyNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.MethodDeclarationNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.projects.Document;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.scan.Reporter;
import io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil;
import io.ballerina.stdlib.http.compiler.ResourceFunction;
import io.ballerina.stdlib.http.compiler.ResourceFunctionDeclaration;
import io.ballerina.stdlib.http.compiler.ResourceFunctionDefinition;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.models.HttpService;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static io.ballerina.compiler.syntax.tree.SyntaxKind.RESOURCE_ACCESSOR_DECLARATION;
import static io.ballerina.compiler.syntax.tree.SyntaxKind.RESOURCE_ACCESSOR_DEFINITION;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpAnalysisUtils.getHttpService;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpAnalysisUtils.unescapeIdentifier;

class HttpServiceAnalyzer implements AnalysisTask<SyntaxNodeAnalysisContext> {

    private final Reporter reporter;
    private final HttpResourceRulesEngine rulesEngine;

    public HttpServiceAnalyzer(Reporter reporter) {
        this.reporter = reporter;
        this.rulesEngine = new HttpResourceRulesEngine();
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        HttpService service = getHttpService(context);
        if (service == null) {
            return;
        }

        Document document = HttpCompilerPluginUtil.getDocument(context);
        SemanticModel semanticModel = context.semanticModel();

        analyzeServiceMembers(service.members(), document, semanticModel);
    }

    private void analyzeServiceMembers(NodeList<Node> members, Document document, SemanticModel semanticModel) {
        for (Node member : members) {
            if (member.kind() != RESOURCE_ACCESSOR_DEFINITION &&
                    member.kind() != RESOURCE_ACCESSOR_DECLARATION) {
                continue;
            }

            ResourceFunction resourceFunction = member.kind() == RESOURCE_ACCESSOR_DEFINITION
                    ? new ResourceFunctionDefinition((FunctionDefinitionNode) member)
                    : new ResourceFunctionDeclaration((MethodDeclarationNode) member);

            analyzeResource(resourceFunction, document, semanticModel);
        }
    }

    private void analyzeResource(ResourceFunction resourceFunction, Document document, SemanticModel semanticModel) {
        Optional<Symbol> functionSymbol = resourceFunction.getSymbol(semanticModel);
        if (functionSymbol.isEmpty() || !(functionSymbol.get() instanceof ResourceMethodSymbol resourceMethodSymbol)) {
            return;
        }

        HttpResourceRuleContext context = createRuleContext(
            resourceFunction, resourceMethodSymbol, document, semanticModel
        );

        rulesEngine.executeRules(context);
    }

    private HttpResourceRuleContext createRuleContext(ResourceFunction resourceFunction,
                                                      ResourceMethodSymbol resourceMethodSymbol,
                                                      Document document,
                                                      SemanticModel semanticModel) {
        List<PathParameterSymbol> pathParameterSymbols = extractPathParameters(resourceMethodSymbol);
        Optional<List<ParameterSymbol>> parametersOptional = resourceMethodSymbol.typeDescriptor().params();
        Optional<FunctionBodyNode> functionBody = resourceFunction.getFunctionBody();
        Optional<TypeSymbol> functionReturnType = resourceMethodSymbol.typeDescriptor().returnTypeDescriptor();

        List<String> resourceParamNames = new ArrayList<>();
        for (PathParameterSymbol pathParam : pathParameterSymbols) {
            TypeSymbol pathParamType = pathParam.typeDescriptor();
            Optional<String> paramName = pathParam.getName();
            if (pathParamType.subtypeOf(semanticModel.types().ANYDATA) && paramName.isPresent()) {
                resourceParamNames.add(unescapeIdentifier(paramName.get()));
            }
        }
        if (parametersOptional.isPresent()) {
            for (ParameterSymbol parameterSymbol : parametersOptional.get()) {
                TypeSymbol paramType = parameterSymbol.typeDescriptor();
                Optional<String> paramName = parameterSymbol.getName();
                if (paramType.subtypeOf(semanticModel.types().ANYDATA) && paramName.isPresent()) {
                    resourceParamNames.add(unescapeIdentifier(paramName.get()));
                }
            }
        }

        return new HttpResourceRuleContext(
            reporter,
            document,
            semanticModel,
            resourceFunction,
            resourceMethodSymbol,
            resourceParamNames,
            functionBody.map(HttpAnalysisUtils::extractExpressions).orElseGet(List::of),
            functionReturnType
        );
    }

    private List<PathParameterSymbol> extractPathParameters(ResourceMethodSymbol resourceMethodSymbol) {
        ResourcePath resourcePath = resourceMethodSymbol.resourcePath();
        if (resourcePath instanceof PathSegmentList resourcePathList) {
            return resourcePathList.pathParameters();
        }
        return List.of();
    }
}
