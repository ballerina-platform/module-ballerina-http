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

public record HttpResourceRuleContext(Reporter reporter, Document document, SemanticModel semanticModel,
                                      ResourceFunction resourceFunction, ResourceMethodSymbol resourceMethodSymbol,
                                      List<String> resourceParamNames,
                                      List<HttpAnalysisUtils.ExpressionNodeInfo> functionBodyExpressions,
                                      Optional<TypeSymbol> functionReturnType) {
}

