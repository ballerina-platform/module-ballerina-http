/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.compiler;

import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.CodeAnalysisContext;
import io.ballerina.projects.plugins.CodeAnalyzer;
import io.ballerina.stdlib.http.compiler.oas.ServiceContractOasGenerator;
import io.ballerina.stdlib.http.compiler.oas.ServiceOasGenerator;

import java.util.Map;

/**
 * The {@code CodeAnalyzer} for Ballerina Http services.
 */
public class HttpServiceAnalyzer extends CodeAnalyzer {
    private final Map<String, Object> ctxData;

    public HttpServiceAnalyzer(Map<String, Object> ctxData) {
        this.ctxData = ctxData;
    }

    @Override
    public void init(CodeAnalysisContext codeAnalysisContext) {
        codeAnalysisContext.addSyntaxNodeAnalysisTask(new HttpServiceObjTypeAnalyzer(), SyntaxKind.OBJECT_TYPE_DESC);
        codeAnalysisContext.addSyntaxNodeAnalysisTask(new HttpServiceValidator(), SyntaxKind.SERVICE_DECLARATION);
        codeAnalysisContext.addSyntaxNodeAnalysisTask(new OpenAPISpecGenerator(), SyntaxKind.SERVICE_DECLARATION);

        boolean httpCodeModifierExecuted = (boolean) ctxData.getOrDefault("HTTP_CODE_MODIFIER_EXECUTED", false);
        if (httpCodeModifierExecuted) {
            codeAnalysisContext.addSyntaxNodeAnalysisTask(new ServiceContractOasGenerator(),
                    SyntaxKind.OBJECT_TYPE_DESC);
            codeAnalysisContext.addSyntaxNodeAnalysisTask(new ServiceOasGenerator(),
                    SyntaxKind.SERVICE_DECLARATION);
        }

        codeAnalysisContext.addSyntaxNodeAnalysisTask(new HttpInterceptorServiceValidator(),
                SyntaxKind.CLASS_DEFINITION);
    }
}
