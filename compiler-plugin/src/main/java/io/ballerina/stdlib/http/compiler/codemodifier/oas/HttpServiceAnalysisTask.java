/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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
package io.ballerina.stdlib.http.compiler.codemodifier.oas;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.openapi.service.mapper.model.ServiceNode;
import io.ballerina.projects.Project;
import io.ballerina.stdlib.http.compiler.codemodifier.oas.context.ServiceNodeAnalysisContext;
import io.ballerina.stdlib.http.compiler.codemodifier.oas.gen.DocGeneratorManager;
import io.ballerina.stdlib.http.compiler.codemodifier.oas.gen.OpenApiDocConfig;

/**
 * {@code HttpServiceAnalysisTask} analyses the HTTP service for which the OpenApi doc is generated.
 */
public class HttpServiceAnalysisTask {
    private final DocGeneratorManager docGenerator;

    public HttpServiceAnalysisTask() {
        this.docGenerator = new DocGeneratorManager();
    }

    public void perform(ServiceNodeAnalysisContext context) {
        Project currentProject = context.currentPackage().project();
        ServiceNode serviceNode = context.node();
        SemanticModel semanticModel = context.semanticModel();
        SyntaxTree syntaxTree = context.syntaxTree();
        OpenApiDocConfig docConfig = new OpenApiDocConfig(context.currentPackage(),
                semanticModel, syntaxTree, serviceNode, currentProject.kind());
        this.docGenerator.generate(docConfig, context, serviceNode.location());
    }
}
