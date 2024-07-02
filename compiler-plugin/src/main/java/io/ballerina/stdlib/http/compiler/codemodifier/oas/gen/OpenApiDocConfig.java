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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.openapi.service.mapper.model.ServiceNode;
import io.ballerina.projects.Package;
import io.ballerina.projects.ProjectKind;

/**
 * {@code OpenApiDocConfig} contains the configurations related to generate OpenAPI doc.
 *
 * @param currentPackage current package
 * @param semanticModel  semantic model
 * @param syntaxTree     syntax tree
 * @param serviceNode    service node
 * @param projectType    project type
 */
public record OpenApiDocConfig(Package currentPackage, SemanticModel semanticModel, SyntaxTree syntaxTree,
                               ServiceNode serviceNode, ProjectKind projectType) {

    public int getServiceId() {
        return serviceNode.getServiceId();
    }
}
