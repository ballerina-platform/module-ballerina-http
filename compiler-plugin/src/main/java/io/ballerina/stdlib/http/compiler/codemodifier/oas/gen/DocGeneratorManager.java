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
package io.ballerina.stdlib.http.compiler.codemodifier.oas.gen;

import io.ballerina.compiler.syntax.tree.NodeLocation;
import io.ballerina.stdlib.http.compiler.codemodifier.oas.context.ServiceNodeAnalysisContext;

import java.util.List;

/**
 * {@code DocGeneratorManager} manages OpenAPI doc generation for HTTP services depending on whether the current project
 * is a ballerina-project or a single ballerina file.
 */
public final class DocGeneratorManager {
    private final List<OpenApiDocGenerator> docGenerators;

    public DocGeneratorManager() {
        this.docGenerators = List.of(new SingleFileOpenApiDocGenerator(), new BalProjectOpenApiDocGenerator());
    }

    public void generate(OpenApiDocConfig config, ServiceNodeAnalysisContext context, NodeLocation location) {
        docGenerators.stream()
                .filter(dg -> dg.isSupported(config.projectType()))
                .findFirst()
                .ifPresent(dg -> dg.generate(config, context, location));
    }
}
