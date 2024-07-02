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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDefinitionSymbol;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ObjectTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.TypeDefinitionNode;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.Constants.BALLERINA;
import static io.ballerina.stdlib.http.compiler.Constants.EMPTY;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP;
import static io.ballerina.stdlib.http.compiler.Constants.HTTP_SERVICE_TYPE;
import static io.ballerina.stdlib.http.compiler.Constants.SERVICE_CONTRACT_TYPE;

/**
 * Validates the HTTP service object type.
 *
 * @since 2.12.0
 */
public class HttpServiceObjTypeAnalyzer extends HttpServiceValidator {

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        List<Diagnostic> diagnostics = context.semanticModel().diagnostics();
        if (diagnostics.stream().anyMatch(d -> DiagnosticSeverity.ERROR.equals(d.diagnosticInfo().severity()))) {
            return;
        }

        Node typeNode = context.node();
        if (!isHttpServiceType(context.semanticModel(), typeNode)) {
            return;
        }

        ObjectTypeDescriptorNode serviceObjectType = (ObjectTypeDescriptorNode) typeNode;
        Optional<MetadataNode> metadataNodeOptional = ((TypeDefinitionNode) serviceObjectType.parent()).metadata();
        metadataNodeOptional.ifPresent(metadataNode -> validateServiceAnnotation(context, metadataNode, null,
                isServiceContractType(context.semanticModel(), serviceObjectType)));

        NodeList<Node> members = serviceObjectType.members();
        validateResources(context, members);
    }

    public static boolean isServiceObjectType(ObjectTypeDescriptorNode typeNode) {
        return typeNode.objectTypeQualifiers().stream().anyMatch(
                qualifier -> qualifier.kind().equals(SyntaxKind.SERVICE_KEYWORD));
    }

    public static boolean isHttpServiceType(SemanticModel semanticModel, Node typeNode) {
        if (!(typeNode instanceof ObjectTypeDescriptorNode serviceObjType) || !isServiceObjectType(serviceObjType)) {
            return false;
        }

        Optional<Symbol> serviceObjSymbol = semanticModel.symbol(serviceObjType.parent());
        if (serviceObjSymbol.isEmpty() ||
                (!(serviceObjSymbol.get() instanceof TypeDefinitionSymbol serviceObjTypeDef))) {
            return false;
        }

        Optional<Symbol> serviceContractType = semanticModel.types().getTypeByName(BALLERINA, HTTP, EMPTY,
                HTTP_SERVICE_TYPE);
        if (serviceContractType.isEmpty() ||
                !(serviceContractType.get() instanceof TypeDefinitionSymbol serviceContractTypeDef)) {
            return false;
        }

        return serviceObjTypeDef.typeDescriptor().subtypeOf(serviceContractTypeDef.typeDescriptor());
    }

    private static boolean isServiceContractType(SemanticModel semanticModel,
                                                 ObjectTypeDescriptorNode serviceObjType) {
        Optional<Symbol> serviceObjSymbol = semanticModel.symbol(serviceObjType.parent());
        if (serviceObjSymbol.isEmpty() ||
                (!(serviceObjSymbol.get() instanceof TypeDefinitionSymbol serviceObjTypeDef))) {
            return false;
        }

        Optional<Symbol> serviceContractType = semanticModel.types().getTypeByName(BALLERINA, HTTP, EMPTY,
                SERVICE_CONTRACT_TYPE);
        if (serviceContractType.isEmpty() ||
                !(serviceContractType.get() instanceof TypeDefinitionSymbol serviceContractTypeDef)) {
            return false;
        }

        return serviceObjTypeDef.typeDescriptor().subtypeOf(serviceContractTypeDef.typeDescriptor());
    }
}
