/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com)
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

package io.ballerina.stdlib.http.compiler.endpointyaml.generator;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.openapi.service.mapper.ServiceToOpenAPIMapper;
import io.ballerina.openapi.service.mapper.diagnostic.DiagnosticMessages;
import io.ballerina.openapi.service.mapper.diagnostic.ExceptionDiagnostic;
import io.ballerina.openapi.service.mapper.diagnostic.OpenAPIMapperDiagnostic;
import io.ballerina.openapi.service.mapper.model.OASGenerationMetaInfo;
import io.ballerina.openapi.service.mapper.model.OASResult;
import io.ballerina.openapi.service.mapper.model.ServiceDeclaration;
import io.ballerina.openapi.service.mapper.model.ServiceNode;
import io.ballerina.openapi.service.mapper.utils.MapperCommonUtils;
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
import io.swagger.v3.oas.models.servers.Server;

import java.io.IOException;
import java.io.PrintStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static io.ballerina.openapi.service.mapper.utils.CodegenUtils.writeFile;
import static io.ballerina.openapi.service.mapper.utils.MapperCommonUtils.containErrors;
import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.getServiceDeclarationNode;
import static io.ballerina.stdlib.http.compiler.OpenAPISpecGenerator.constructFileName;
import static io.ballerina.stdlib.http.compiler.endpointyaml.generator.FileNameGeneratorUtil.extractServiceNodes;

/*
 * Generates the .yaml file with endpoint details and OpenAPI specification of HTTP service.
 */
public class ServiceArtifactsExtractor implements AnalysisTask<SyntaxNodeAnalysisContext> {
    private static boolean isErrorPrinted = false;
    private static final String OAS_PATH_SEPARATOR = "/";
    private static final String ARTIFACT = "artifact";
    private static final PrintStream outStream = System.out;

    static void setIsWarningPrinted() {
        ServiceArtifactsExtractor.isErrorPrinted = true;
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
        List<Diagnostic> diagnostics = new ArrayList<>();
        SemanticModel semanticModel = context.semanticModel();
        Package currentPackage = context.currentPackage();
        Project project = currentPackage.project();
        BuildOptions buildOptions = project.buildOptions();

        if (!isExportEndpoints(buildOptions)) {
            return;
        }

        checkCompilationErrors(context);
        if (containErrors(semanticModel.diagnostics())) {
            diagnostics.addAll(semanticModel.diagnostics());
        } else {
            exportServiceArtifact(context, semanticModel, serviceNode, project, diagnostics);
        }

        printDiagnostics(context, diagnostics);
    }

    private void exportServiceArtifact(SyntaxNodeAnalysisContext context, SemanticModel semanticModel,
                                       ServiceDeclarationNode serviceNode, Project project,
                                       List<Diagnostic> diagnostics) {
        SyntaxTree syntaxTree = context.syntaxTree();
        Path outPath = project.targetDir();
        Map<Integer, String> services = new HashMap<>();
        Optional<Symbol> serviceSymbol = semanticModel.symbol(serviceNode);
        if (serviceSymbol.isEmpty() || !(serviceSymbol.get() instanceof ServiceDeclarationSymbol)) {
            return;
        }
        OASResult oasResult = getOASResult(context, services, semanticModel, serviceNode, serviceSymbol);
        oasResult.setServiceName(constructFileName(
                syntaxTree,
                services,
                serviceSymbol.get()));

        writeOpenAPIYaml(outPath, context, oasResult, diagnostics);
        exportEndpointYaml(serviceNode, context, oasResult, diagnostics);
    }

    private void checkCompilationErrors(SyntaxNodeAnalysisContext context) {
        boolean hasErrors = context.compilation().diagnosticResult()
                .diagnostics().stream()
                .anyMatch(d -> DiagnosticSeverity.ERROR.equals(d.diagnosticInfo().severity()));

        if (hasErrors && !isErrorPrinted) {
            setIsWarningPrinted();
            outStream.println("openapi contract generation is skipped because of the following compilation " +
                    "error(s) in the ballerina package:");

        }
    }

    private void printDiagnostics(SyntaxNodeAnalysisContext context, List<Diagnostic> diagnostics) {
        if (!diagnostics.isEmpty()) {
            for (Diagnostic diagnostic : diagnostics) {
                context.reportDiagnostic(diagnostic);
            }
        }
    }

    private boolean isExportEndpoints(BuildOptions buildOptions) {
        boolean isExportEndpoints = false;
        // Ensure backward compatibility with older ballerina-lang versions
        try {
            isExportEndpoints = buildOptions.exportEndpoints();
        } catch (NoSuchMethodError e) {
            outStream.println("The ballerina version is not supported for --export-endpoints" +
                    " build option. Try using ballerina 2201.13.3 or above.");
        }
        return isExportEndpoints;
    }

    private void exportEndpointYaml(ServiceDeclarationNode serviceNode, SyntaxNodeAnalysisContext context,
                                    OASResult oasResult, List<Diagnostic> diagnostics) {
        if (oasResult.getOpenAPI().isEmpty()) {
            return;
        }
        List<Server> servers = oasResult.getOpenAPI().get().getServers();
        if (servers == null || servers.isEmpty()) {
            return;
        }

        for (Server server: servers) {
            EndpointYamlGenerator endpointYamlGeneratorHttp =
                    new EndpointYamlGenerator(serviceNode, context, server);
            try {
                endpointYamlGeneratorHttp.writeEndpointYaml();
            } catch (IOException e) {
                diagnostics.add(getDiagnostics(
                     new ExceptionDiagnostic(DiagnosticMessages.OAS_CONVERTOR_108, e.toString())));
            }
        }

    }

    private OASResult getOASResult(SyntaxNodeAnalysisContext context, Map<Integer, String> services,
                                   SemanticModel semanticModel, ServiceDeclarationNode serviceNode,
                                   Optional<Symbol> serviceSymbol) {
        Package currentPackage = context.currentPackage();
        Optional<Path> path = currentPackage.project().documentPath(context.documentId());
        Path inputPath = path.orElse(null);

        extractServiceNodes(context.syntaxTree().rootNode(), services, semanticModel);
        OASGenerationMetaInfo.OASGenerationMetaInfoBuilder builder =
                new OASGenerationMetaInfo.OASGenerationMetaInfoBuilder();
        ServiceNode service = new ServiceDeclaration(serviceNode, semanticModel);
        builder.setServiceNode(service).setSemanticModel(semanticModel)
                .setOpenApiFileName(services.get(serviceSymbol.get().hashCode()))
                .setBallerinaFilePath(inputPath).setProject(currentPackage.project());

        return ServiceToOpenAPIMapper.generateOAS(builder.build());
    }

    private void writeOpenAPIYaml(Path outPath, SyntaxNodeAnalysisContext context, OASResult oasResult,
                                  List<Diagnostic> diagnostics) {
        if (oasResult.getYaml().isPresent()) {
            try {
                Files.createDirectories(Paths.get(outPath + OAS_PATH_SEPARATOR + ARTIFACT));
                FileNameGeneratorUtil fileNameGen = new FileNameGeneratorUtil(context);
                String fileName = fileNameGen.getFileName();
                writeFile(outPath.resolve(ARTIFACT + OAS_PATH_SEPARATOR + fileName), oasResult.getYaml().get());
            } catch (IOException e) {
                ExceptionDiagnostic diagnostic = new ExceptionDiagnostic(DiagnosticMessages.OAS_CONVERTOR_108,
                        e.toString());
                diagnostics.add(getDiagnostics(diagnostic));
                outStream.println(e);
            }
        }
        if (!oasResult.getDiagnostics().isEmpty()) {
            for (OpenAPIMapperDiagnostic diagnostic : oasResult.getDiagnostics()) {
                diagnostics.add(getDiagnostics(diagnostic));
            }
        }
    }

    public static Diagnostic getDiagnostics(OpenAPIMapperDiagnostic diagnostic) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(diagnostic.getCode(), diagnostic.getMessage(),
                diagnostic.getDiagnosticSeverity());
        Location location = diagnostic.getLocation().orElse(new MapperCommonUtils.NullLocation());
        return DiagnosticFactory.createDiagnostic(diagnosticInfo, location);
    }

}
