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
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.UnionTypeSymbol;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.Project;
import io.ballerina.stdlib.http.compiler.codemodifier.oas.context.ServiceNodeAnalysisContext;
import io.ballerina.stdlib.http.compiler.codemodifier.oas.gen.DocGeneratorManager;
import io.ballerina.stdlib.http.compiler.codemodifier.oas.gen.OpenApiDocConfig;

import java.util.Optional;

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
        ServiceDeclarationNode serviceNode = context.node();
        SemanticModel semanticModel = context.semanticModel();
        Optional<Symbol> serviceDeclarationOpt = semanticModel.symbol(serviceNode);
        if (serviceDeclarationOpt.isPresent()) {
            ServiceDeclarationSymbol serviceSymbol = (ServiceDeclarationSymbol) serviceDeclarationOpt.get();
            if (!isHttpService(serviceSymbol)) {
                return;
            }
            SyntaxTree syntaxTree = context.syntaxTree();
            OpenApiDocConfig docConfig = new OpenApiDocConfig(context.currentPackage(),
                    semanticModel, syntaxTree, serviceNode, currentProject.kind());
            this.docGenerator.generate(docConfig, context, serviceNode.location());
        }
    }

    private boolean isHttpService(ServiceDeclarationSymbol serviceSymbol) {
        return serviceSymbol.listenerTypes().stream().anyMatch(this::isHttpListener);
    }

    private boolean isHttpListener(TypeSymbol listenerType) {
        if (listenerType.typeKind() == TypeDescKind.UNION) {
            return ((UnionTypeSymbol) listenerType).memberTypeDescriptors().stream()
                    .filter(typeDescriptor -> typeDescriptor instanceof TypeReferenceTypeSymbol)
                    .map(typeReferenceTypeSymbol -> (TypeReferenceTypeSymbol) typeReferenceTypeSymbol)
                    .anyMatch(typeReferenceTypeSymbol ->
                            typeReferenceTypeSymbol.getModule().isPresent()
                                    && isHttp(typeReferenceTypeSymbol.getModule().get()
                            ));
        }

        if (listenerType.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            Optional<ModuleSymbol> moduleOpt = ((TypeReferenceTypeSymbol) listenerType).typeDescriptor().getModule();
            return moduleOpt.isPresent() && isHttp(moduleOpt.get());
        }

        if (listenerType.typeKind() == TypeDescKind.OBJECT) {
            Optional<ModuleSymbol> moduleOpt = listenerType.getModule();
            return moduleOpt.isPresent() && isHttp(moduleOpt.get());
        }

        return false;
    }

    private boolean isHttp(ModuleSymbol moduleSymbol) {
        Optional<String> moduleNameOpt = moduleSymbol.getName();
        return moduleNameOpt.isPresent() && Constants.HTTP_PACKAGE_NAME.equals(moduleNameOpt.get())
                && Constants.PACKAGE_ORG.equals(moduleSymbol.id().orgName());
    }
}
