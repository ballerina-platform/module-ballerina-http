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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.projects.Document;
import io.ballerina.scan.Reporter;
import io.ballerina.stdlib.http.compiler.ResourceFunction;

import java.util.List;
import java.util.Optional;

/**
 * Context information required to analyze HTTP resource related static code analysis rules.
 * @param reporter - Static code analysis reporter
 * @param document - Ballerina document
 * @param semanticModel - Semantic model of the document
 * @param resourceFunction - HTTP resource function
 * @param resourceMethodSymbol - Resource method symbol of the resource function
 * @param resourceParamNames - List of resource anydata typed parameter names including path parameters
 * @param functionReturnType - Return type of the resource function
 * @param functionBodyExpressions - List of expression nodes in the function body with additional info
 *
 * @since 2.15.0
 */
public record HttpResourceRuleContext(Reporter reporter, Document document, SemanticModel semanticModel,
                                      ResourceFunction resourceFunction, ResourceMethodSymbol resourceMethodSymbol,
                                      List<String> resourceParamNames, Optional<TypeSymbol> functionReturnType,
                                      List<HttpStaticAnalysisUtils.ExpressionNodeInfo> functionBodyExpressions) {
}

