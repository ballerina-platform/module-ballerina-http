/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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

package io.ballerina.stdlib.http.compiler.endpointyaml.generator;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static io.ballerina.openapi.service.mapper.Constants.OPENAPI_SUFFIX;
import static io.ballerina.openapi.service.mapper.Constants.YAML_EXTENSION;
import static io.ballerina.openapi.service.mapper.utils.MapperCommonUtils.getNormalizedFileName;

/*
 * Contains the util functions of file name generation for ServiceArtifactGenerator
 */
public class FileNameGeneratorUtil {

    private static final String SLASH = "/";
    private static final String UNDERSCORE = "_";
    private static final String HYPHEN = "-";
    private static final String EXTENSION = OPENAPI_SUFFIX + YAML_EXTENSION;
    private final Map<Integer, String> services = new HashMap<>();

    private final SyntaxNodeAnalysisContext context;

    public FileNameGeneratorUtil(SyntaxNodeAnalysisContext context) {
        this.context = context;
    }

    public String getFileName() {
        SyntaxTree syntaxTree = this.context.syntaxTree();
        SemanticModel semanticModel = this.context.semanticModel();
        extractServiceNodes(syntaxTree.rootNode(), this.services, semanticModel);
        String filePath = syntaxTree.filePath().replace(SLASH, UNDERSCORE);
        String balFileName = filePath.endsWith(".bal")
                ? filePath.substring(0, filePath.length() - ".bal".length()) : filePath;
        if (!(this.context.node() instanceof ServiceDeclarationNode node)) {
            return balFileName + EXTENSION;
        }

        Optional<Symbol> serviceSymbol = semanticModel.symbol(node);
        if (serviceSymbol.isEmpty()) {
            String basePathName = getServiceBasePath(node);
            return constructEndpointFileName(balFileName, basePathName, EXTENSION, "");
        }

        return constructEndpointFileName(syntaxTree, services, serviceSymbol.get());
    }

    public static void extractServiceNodes(ModulePartNode modulePartNode, Map<Integer, String> services,
                                           SemanticModel semanticModel) {
        List<String> allServices = new ArrayList<>();
        for (Node node : modulePartNode.members()) {
            if (!SyntaxKind.SERVICE_DECLARATION.equals(node.kind())) {
                continue;
            }
            ServiceDeclarationNode serviceNode = (ServiceDeclarationNode) node;
            Optional<Symbol> serviceSymbol = semanticModel.symbol(serviceNode);
            if (semanticModel.symbol(serviceNode).isEmpty() ||
                    !(serviceSymbol.get() instanceof ServiceDeclarationSymbol)) {
                continue;
            }
            String service = getServiceBasePath(serviceNode);
            String updateServiceName = service;
            if (allServices.contains(service)) {
                updateServiceName = service + HYPHEN + serviceSymbol.get().hashCode();
            } else {
                allServices.add(service);
            }
            services.put(serviceSymbol.get().hashCode(), updateServiceName);
        }
    }

    private String constructEndpointFileName(SyntaxTree syntaxTree, Map<Integer, String> services,
                                     Symbol serviceSymbol) {
        String serviceName = services.get(serviceSymbol.hashCode());
        String filePath = syntaxTree.filePath().replace(SLASH, UNDERSCORE);
        String balFileName = filePath.endsWith(".bal")
                ? filePath.substring(0, filePath.length() - ".bal".length()) : filePath;
        return constructEndpointFileName(balFileName, serviceName, EXTENSION, String.valueOf(serviceSymbol.hashCode()));
    }

    private String constructEndpointFileName(String balFileName, String basePathName, String extension,
                                             String fallbackSuffix) {
        String fileName = basePathName == null ? "" : getNormalizedFileName(basePathName);
        if (fileName.equals(SLASH)) {
            return balFileName + extension;
        } else if ((fileName.contains(HYPHEN) && fileName.split(HYPHEN)[0].equals(SLASH)) || fileName.isBlank()) {
            if (fallbackSuffix == null || fallbackSuffix.isBlank()) {
                return balFileName + extension;
            }
            return balFileName + UNDERSCORE + fallbackSuffix + extension;
        }
        return balFileName + UNDERSCORE + fileName + extension;
    }


    private static String getServiceBasePath(ServiceDeclarationNode serviceNode) {
        StringBuilder basePath = new StringBuilder();
        NodeList<Node> resourcePathNode = serviceNode.absoluteResourcePath();
        for (Node identifierNode : resourcePathNode) {
            basePath.append(identifierNode.toString().replace("\"", "").trim());
        }
        return basePath.toString();
    }

}
