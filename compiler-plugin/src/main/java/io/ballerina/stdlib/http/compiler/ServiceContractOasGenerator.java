/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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
package io.ballerina.stdlib.http.compiler;

import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.ObjectTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.openapi.service.mapper.model.ServiceContractType;
import io.ballerina.openapi.service.mapper.model.ServiceNode;
import io.ballerina.projects.ProjectKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.diagnosticContainsErrors;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isHttpServiceType;

/**
 * This class generates the OpenAPI definition resource for the service contract type node.
 *
 * @since 2.12.0
 */
public class ServiceContractOasGenerator extends ServiceOasGenerator {

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (diagnosticContainsErrors(context) ||
                !context.currentPackage().project().kind().equals(ProjectKind.BUILD_PROJECT)) {
            return;
        }

        Node typeNode = context.node();
        if (!isHttpServiceType(context.semanticModel(), typeNode)) {
            return;
        }

        ObjectTypeDescriptorNode serviceObjectType = (ObjectTypeDescriptorNode) typeNode;
        TypeDefinitionNode serviceTypeNode = (TypeDefinitionNode) serviceObjectType.parent();

        if (!serviceTypeNode.visibilityQualifier()
                .map(qualifier -> qualifier.text().equals("public"))
                .orElse(false)) {
            return;
        }

        String fileName = String.format("%s.json", serviceTypeNode.typeName().text());
        ServiceNode serviceNode = new ServiceContractType(serviceTypeNode);
        Optional<String> openApi = generateOpenApi(fileName, context.currentPackage().project(),
                context.semanticModel(), serviceNode);
        if (openApi.isEmpty()) {
            return;
        }

        writeOpenApiAsTargetResource(context.currentPackage().project(), fileName, openApi.get());
    }
}
