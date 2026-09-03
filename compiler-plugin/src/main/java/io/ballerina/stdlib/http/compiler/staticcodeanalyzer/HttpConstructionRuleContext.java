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
import io.ballerina.projects.Document;
import io.ballerina.scan.Reporter;
import io.ballerina.tools.diagnostics.Location;

/**
 * Context information required to analyze static code analysis rules on HTTP object construction.
 *
 * @param reporter            static code analysis reporter
 * @param document            Ballerina document
 * @param semanticModel       semantic model of the document
 * @param constructionLocation location of the constructor expression, for reporting on the
 *                            construction itself rather than on one of its fields
 * @param constructedTypeName simple name of the constructed {@code ballerina/http} type, for example {@code Listener}
 * @param arguments           constructor arguments, normalized across positional and named forms
 *
 * @since 2.15.0
 */
public record HttpConstructionRuleContext(Reporter reporter, Document document, SemanticModel semanticModel,
                                          Location constructionLocation, String constructedTypeName,
                                          HttpConstructionArguments arguments) {
}
