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

import io.ballerina.projects.plugins.CodeAnalysisContext;
import io.ballerina.projects.plugins.CodeAnalyzer;
import io.ballerina.scan.Reporter;

import java.util.List;

import static io.ballerina.compiler.syntax.tree.SyntaxKind.ANNOTATION;
import static io.ballerina.compiler.syntax.tree.SyntaxKind.CLIENT_RESOURCE_ACCESS_ACTION;
import static io.ballerina.compiler.syntax.tree.SyntaxKind.CLASS_DEFINITION;
import static io.ballerina.compiler.syntax.tree.SyntaxKind.OBJECT_TYPE_DESC;
import static io.ballerina.compiler.syntax.tree.SyntaxKind.RETURN_STATEMENT;
import static io.ballerina.compiler.syntax.tree.SyntaxKind.SERVICE_DECLARATION;

/**
 * The static code analyzer implementation for Ballerina Http package.
 */
public class HttpStaticCodeAnalyzer extends CodeAnalyzer {
    private final Reporter reporter;

    public HttpStaticCodeAnalyzer(Reporter reporter) {
        this.reporter = reporter;
    }

    @Override
    public void init(CodeAnalysisContext analysisContext) {
        analysisContext.addSyntaxNodeAnalysisTask(new HttpServiceAnalyzer(reporter),
                List.of(SERVICE_DECLARATION, OBJECT_TYPE_DESC, CLASS_DEFINITION));
        analysisContext.addSyntaxNodeAnalysisTask(new HttpAnnotationAnalyzer(reporter), ANNOTATION);
        analysisContext.addSyntaxNodeAnalysisTask(new HttpClientAnalyzer(reporter), CLIENT_RESOURCE_ACCESS_ACTION);
        analysisContext.addSyntaxNodeAnalysisTask(new HttpReturnResponseAnalyzer(reporter), RETURN_STATEMENT);
    }
}
