/*
 * Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com)
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

package io.ballerina.stdlib.http.compiler;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.openapi.service.mapper.ServiceToOpenAPIMapper;
import io.ballerina.openapi.service.mapper.diagnostic.DiagnosticMessages;
import io.ballerina.openapi.service.mapper.diagnostic.ExceptionDiagnostic;
import io.ballerina.openapi.service.mapper.diagnostic.OpenAPIMapperDiagnostic;
import io.ballerina.openapi.service.mapper.model.OASGenerationMetaInfo;
import io.ballerina.openapi.service.mapper.model.OASResult;
import io.ballerina.openapi.service.mapper.model.ServiceDeclaration;
import io.ballerina.openapi.service.mapper.model.ServiceNode;
import io.ballerina.projects.BuildOptions;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.ModuleId;
import io.ballerina.projects.Package;
import io.ballerina.projects.Project;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerina.tools.diagnostics.Location;
import io.ballerina.tools.text.LinePosition;
import io.ballerina.tools.text.LineRange;
import io.ballerina.tools.text.TextRange;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.servers.Server;
import io.swagger.v3.oas.models.servers.ServerVariables;

import java.io.IOException;
import java.io.PrintStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static io.ballerina.openapi.service.mapper.Constants.HYPHEN;
import static io.ballerina.openapi.service.mapper.Constants.OPENAPI_SUFFIX;
import static io.ballerina.openapi.service.mapper.Constants.SLASH;
import static io.ballerina.openapi.service.mapper.Constants.YAML_EXTENSION;
import static io.ballerina.openapi.service.mapper.utils.CodegenUtils.resolveContractFileName;
import static io.ballerina.openapi.service.mapper.utils.CodegenUtils.writeFile;
import static io.ballerina.openapi.service.mapper.utils.MapperCommonUtils.containErrors;
import static io.ballerina.openapi.service.mapper.utils.MapperCommonUtils.getNormalizedFileName;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.getServiceDeclarationNode;

public class OpenAPISpecGenerator implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private static boolean isErrorPrinted = false;
    private static final String OAS_PATH_SEPARATOR = "/";
    private static final String OPENAPI = "openapi";
    private static final String ENDPOINT = "endpoint";
    private static final String ENDPOINT_SUFFIX = "_endpoint";
    private static final String ARTIFACT = "artifact";

    private static final String UNDERSCORE = "_";

    static void setIsWarningPrinted() {
        OpenAPISpecGenerator.isErrorPrinted = true;
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode serviceNode = getServiceDeclarationNode(context);
        if (serviceNode == null) {
            return;
        }

        ModuleId moduleId = context.moduleId();
        DocumentId documentId = context.documentId();
        Module currentModule = context.currentPackage() != null ? context.currentPackage().module(moduleId) : null;

        if (moduleId != null && documentId != null && currentModule != null &&
                currentModule.testDocumentIds() != null &&
                currentModule.testDocumentIds().contains(documentId)) {
            return;
        }
        SemanticModel semanticModel = context.semanticModel();
        SyntaxTree syntaxTree = context.syntaxTree();
        Package currentPackage = context.currentPackage();
        Project project = currentPackage.project();
        BuildOptions buildOptions = project.buildOptions();
        if (!buildOptions.exportOpenAPI() && !buildOptions.exportEndpoints()) {
            return;
        }
        boolean hasErrors = context.compilation().diagnosticResult()
                .diagnostics().stream()
                .anyMatch(d -> DiagnosticSeverity.ERROR.equals(d.diagnosticInfo().severity()));

        if (hasErrors) {
            if (!isErrorPrinted) {
                setIsWarningPrinted();
                PrintStream outStream = System.out;
                outStream.println("openapi contract generation is skipped because of the following compilation " +
                        "error(s) in the ballerina package:");
            }
            return;
        }

        Path outPath = project.targetDir();
        Optional<Path> path = currentPackage.project().documentPath(context.documentId());
        Path inputPath = path.orElse(null);
        Map<Integer, String> services = new HashMap<>();
        List<Diagnostic> diagnostics = new ArrayList<>();

        if (containErrors(semanticModel.diagnostics())) {
            diagnostics.addAll(semanticModel.diagnostics());
        } else {
            Optional<Symbol> serviceSymbol = semanticModel.symbol(serviceNode);
            if (serviceSymbol.isPresent() && serviceSymbol.get() instanceof ServiceDeclarationSymbol) {
                extractServiceNodes(syntaxTree.rootNode(), services, semanticModel);
                OASGenerationMetaInfo.OASGenerationMetaInfoBuilder builder =
                        new OASGenerationMetaInfo.OASGenerationMetaInfoBuilder();
                ServiceNode service = new ServiceDeclaration(serviceNode, semanticModel);
                builder.setServiceNode(service).setSemanticModel(semanticModel)
                        .setOpenApiFileName(services.get(serviceSymbol.get().hashCode()))
                        .setBallerinaFilePath(inputPath).setProject(project);
                OASResult oasResult = ServiceToOpenAPIMapper.generateOAS(builder.build());

                if (buildOptions.exportEndpoints()) {
                    oasResult.setServiceName(constructFileName(
                            syntaxTree,
                            services,
                            true,
                            serviceSymbol.get()));

                    writeEndpointYaml(outPath, oasResult, diagnostics, service.absoluteResourcePath());
                }
                oasResult.setServiceName(constructFileName(
                        syntaxTree,
                        services,
                        false,
                        serviceSymbol.get()));

                writeOpenAPIYaml(outPath, oasResult, diagnostics);
            }
        }
        if (!diagnostics.isEmpty()) {
            for (Diagnostic diagnostic : diagnostics) {
                context.reportDiagnostic(diagnostic);
            }
        }
    }

    /**
     * This util function is to construct the generated file name.
     *
     * @param syntaxTree syntax tree for check the multiple services
     * @param services   service map for maintain the file name with updated name
     * @param serviceSymbol symbol for taking the hash code of services
     */
    private String constructFileName(SyntaxTree syntaxTree, Map<Integer, String> services,
                                     boolean isExportEndpoints, Symbol serviceSymbol) {
        String fileName = getNormalizedFileName(services.get(serviceSymbol.hashCode()));
        String balFileName = syntaxTree.filePath().replaceAll(SLASH, UNDERSCORE).split("\\.")[0];
        if (fileName.equals(SLASH) && isExportEndpoints) {
            return balFileName + ENDPOINT_SUFFIX + YAML_EXTENSION;
        } else if (fileName.equals(SLASH)) {
            return balFileName + OPENAPI_SUFFIX + YAML_EXTENSION;
        } else if (fileName.contains(HYPHEN) && fileName.split(HYPHEN)[0].equals(SLASH) || fileName.isBlank()) {
            return balFileName + UNDERSCORE + serviceSymbol.hashCode() + OPENAPI_SUFFIX + YAML_EXTENSION;
        } else if (isExportEndpoints) {
            return fileName + ENDPOINT_SUFFIX + YAML_EXTENSION;
        }
        return fileName + OPENAPI_SUFFIX + YAML_EXTENSION;
    }

    private void writeEndpointYaml(Path outPath, OASResult oasResult,
                                   List<Diagnostic> diagnostics, String serviceBasePath) {
        if (oasResult.getYaml().isPresent()) {
            try {
                Files.createDirectories(Paths.get(outPath + OAS_PATH_SEPARATOR + ARTIFACT));
                String serviceName = oasResult.getServiceName();
                String fileName = resolveContractFileName(outPath.resolve(ARTIFACT),
                        serviceName, false);
                List<Server> servers = oasResult.getOpenAPI().map(OpenAPI::getServers).orElse(new ArrayList<>());
                String endpointYaml = getEndpointYamlContent(servers, serviceBasePath);
                writeFile(outPath.resolve(ARTIFACT + OAS_PATH_SEPARATOR + fileName), endpointYaml);

            } catch (IOException e) {
                ExceptionDiagnostic diagnostic = new ExceptionDiagnostic(DiagnosticMessages.OAS_CONVERTOR_108,
                        e.toString());
                diagnostics.add(getDiagnostics(diagnostic));
            }
        }

    }

    private void writeOpenAPIYaml(Path outPath, OASResult oasResult, List<Diagnostic> diagnostics) {
        if (oasResult.getYaml().isPresent()) {
            try {
                Files.createDirectories(Paths.get(outPath + OAS_PATH_SEPARATOR + ARTIFACT));
                String serviceName = oasResult.getServiceName();
                String fileName = resolveContractFileName(outPath.resolve(ARTIFACT),
                        serviceName, false);
                writeFile(outPath.resolve(ARTIFACT + OAS_PATH_SEPARATOR + fileName), oasResult.getYaml().get());
            } catch (IOException e) {
                ExceptionDiagnostic diagnostic = new ExceptionDiagnostic(DiagnosticMessages.OAS_CONVERTOR_108,
                        e.toString());
                diagnostics.add(getDiagnostics(diagnostic));
            }
        }
        if (!oasResult.getDiagnostics().isEmpty()) {
            for (OpenAPIMapperDiagnostic diagnostic : oasResult.getDiagnostics()) {
                diagnostics.add(getDiagnostics(diagnostic));
            }
        }
    }

    /**
     * Filter all the end points and service nodes for avoiding the generated file name conflicts.
     */
    private static void extractServiceNodes(ModulePartNode modulePartNode, Map<Integer, String> services,
                                            SemanticModel semanticModel) {
        List<String> allServices = new ArrayList<>();
        for (Node node : modulePartNode.members()) {
            SyntaxKind syntaxKind = node.kind();
            if (syntaxKind.equals(SyntaxKind.SERVICE_DECLARATION)) {
                ServiceDeclarationNode serviceNode = (ServiceDeclarationNode) node;
                Optional<Symbol> serviceSymbol = semanticModel.symbol(serviceNode);
                if (serviceSymbol.isPresent() && serviceSymbol.get() instanceof ServiceDeclarationSymbol) {
                    String service = (new ServiceDeclaration(serviceNode, semanticModel)).absoluteResourcePath();
                    String updateServiceName = service;
                    if (allServices.contains(service)) {
                        updateServiceName = service + HYPHEN + serviceSymbol.get().hashCode();
                    } else {
                        allServices.add(service);
                    }
                    services.put(serviceSymbol.get().hashCode(), updateServiceName);
                }
            }
        }
    }

    public static Endpoint getEndpointYaml(Server server, String serviceBasePath) {
        ServerVariables vars = server != null ? server.getVariables() : null;

        String port = "";
        String type = "http";
        if (vars != null && vars.get("port") != null && vars.get("port").getDefault() != null) {
            port = vars.get("port").getDefault();
        }
        if (server != null && server.getUrl() != null && !server.getUrl().isBlank()) {
            try {
                URI serverUri = new URI(server.getUrl().replace("{port}", "80"));
                if (serverUri.getScheme() != null && !serverUri.getScheme().isBlank()) {
                    type = serverUri.getScheme();
                }
                if (port.isBlank() && serverUri.getPort() > 0) {
                    port = String.valueOf(serverUri.getPort());
                }
            } catch (URISyntaxException ignored) {
                // Ignore malformed URLs and keep defaults.
            }
        }
        String basePath = serviceBasePath;

        Endpoint ep = new Endpoint(port, basePath, type);
        return ep;
    }

    private static String getEndpointYamlContent(List<Server> servers, String serviceBasePath) {
        StringBuilder yamlBuilder = new StringBuilder();
        yamlBuilder.append("endpoints:\n");

        if (servers == null || servers.isEmpty()) {
            Endpoint endpoint = new Endpoint("", serviceBasePath, "http");
            appendEndpoint(yamlBuilder, endpoint);
            return yamlBuilder.toString();
        }

        for (Server server : servers) {
            Endpoint endpoint = getEndpointYaml(server, serviceBasePath);
            appendEndpoint(yamlBuilder, endpoint);
        }
        return yamlBuilder.toString();
    }

    private static void appendEndpoint(StringBuilder yamlBuilder, Endpoint endpoint) {
        yamlBuilder.append("  - type: ").append(escapeYaml(endpoint.getType())).append("\n");
        yamlBuilder.append("    port: ").append(escapeYaml(endpoint.getPort())).append("\n");
        yamlBuilder.append("    basePath: ").append(escapeYaml(endpoint.getBasePath())).append("\n");
    }

    private static String escapeYaml(String value) {
        String sanitized = value == null ? "" : value;
        return "\"" + sanitized.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }

    public static Diagnostic getDiagnostics(OpenAPIMapperDiagnostic diagnostic) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(diagnostic.getCode(), diagnostic.getMessage(),
                diagnostic.getDiagnosticSeverity());
        Location location = diagnostic.getLocation().orElse(new NullLocation());
        return DiagnosticFactory.createDiagnostic(diagnosticInfo, location);
    }

    private static class NullLocation implements Location {
        @Override
        public LineRange lineRange() {
            LinePosition from = LinePosition.from(0, 0);
            return LineRange.from("", from, from);
        }

        @Override
        public TextRange textRange() {
            return TextRange.from(0, 0);
        }
    }
}
