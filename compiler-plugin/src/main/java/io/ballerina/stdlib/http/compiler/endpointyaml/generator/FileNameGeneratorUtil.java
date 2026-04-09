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

import static io.ballerina.openapi.service.mapper.utils.MapperCommonUtils.getNormalizedFileName;

/*
 * Contains the util functions of file name generation for ServiceArtifactGenerator
 */
public class FileNameGeneratorUtil {

    private static final String SLASH = "/";
    private static final String UNDERSCORE = "_";
    private static final String HYPHEN = "-";
    private final String extension;
    private final Map<Integer, String> services = new HashMap<>();

    private final SyntaxNodeAnalysisContext context;

    public FileNameGeneratorUtil(SyntaxNodeAnalysisContext context, String schemaExtension) {
        this.context = context;
        this.extension = schemaExtension;
    }

    public String getFileName() {
        SyntaxTree syntaxTree = context.syntaxTree();
        SemanticModel semanticModel = context.semanticModel();
        extractServiceNodes(syntaxTree.rootNode(), this.services, semanticModel);
        if (!(context.node() instanceof ServiceDeclarationNode node)) {
            String balFileName = syntaxTree.filePath().replaceAll(SLASH, UNDERSCORE).split("\\.")[0];
            return balFileName + extension;
        }

        Optional<Symbol> serviceSymbol = semanticModel.symbol(node);
        if (serviceSymbol.isEmpty()) {
            String basePathName = getServiceBasePath(node);
            if (!basePathName.isBlank()) {
                return getNormalizedFileName(basePathName) + extension;
            }
            String balFileName = syntaxTree.filePath().replaceAll(SLASH, UNDERSCORE).split("\\.")[0];
            return balFileName + extension;
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
            StringBuilder basePath = new StringBuilder();
            NodeList<Node> resourcePathNode = ((ServiceDeclarationNode) node).absoluteResourcePath();
            for (Node identifierNode : resourcePathNode) {
                basePath.append(identifierNode.toString().replace("\"", "").trim());
            }
            String service = basePath.toString();
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
        String fileName = serviceName == null ? "" : getNormalizedFileName(serviceName);
        String balFileName = syntaxTree.filePath().replaceAll(SLASH, UNDERSCORE).split("\\.")[0];
        if (fileName.equals(SLASH)) {
            return balFileName + extension;
        } else if ((fileName.contains(HYPHEN) && fileName.split(HYPHEN)[0].equals(SLASH)) || fileName.isBlank()) {
            return balFileName + UNDERSCORE + serviceSymbol.hashCode() + extension;
        }
        return fileName + extension;
    }


    private String getServiceBasePath(ServiceDeclarationNode serviceNode) {
        StringBuilder basePath = new StringBuilder();
        NodeList<Node> resourcePathNode = serviceNode.absoluteResourcePath();
        for (Node identifierNode : resourcePathNode) {
            basePath.append(identifierNode.toString().replace("\"", "").trim());
        }
        return basePath.toString();
    }

//    public static String getNormalizedFileName(String fileName) {
//        String[] splitNames = fileName.split("[^a-zA-Z0-9]");
//        if (splitNames.length > 0) {
//            return Arrays.stream(splitNames)
//                    .filter(namePart -> !namePart.isBlank())
//                    .collect(Collectors.joining(UNDERSCORE));
//        }
//        return fileName;
//    }

}
