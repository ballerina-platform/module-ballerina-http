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

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.fasterxml.jackson.dataformat.yaml.YAMLGenerator;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.projects.Package;
import io.ballerina.projects.Project;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.swagger.v3.oas.models.servers.Server;
import io.swagger.v3.oas.models.servers.ServerVariables;

import java.io.IOException;
import java.io.PrintStream;
import java.io.Writer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import static io.ballerina.openapi.service.mapper.utils.CodegenUtils.resolveContractFileName;

public class EndpointYamlGenerator {
    private final ServiceDeclarationNode node;
    private final SyntaxNodeAnalysisContext context;
    private String schemaFileName;

    private static final PrintStream outStream = System.out;

    private static final String ARTIFACT = "artifact";
    private static final String REST = "REST";
    private static final String YAML_EXTENSION = ".yaml";
    private static final String OPENAPI_SUFFIX = "_openapi";
    private static final String ENDPOINT_SUFFIX = "_endpoint";
    private static final String PORT = "port";

    private String schemaExtension = "";
    private int portVal = 0;

    private final Server server;

    /*
     * Generates the .yaml file with endpoint details of HTTP service
     */
    public EndpointYamlGenerator(ServiceDeclarationNode node, SyntaxNodeAnalysisContext context, Server server) {
        this.node = node;
        this.context = context;
        this.server = server != null ? new Server()
                .url(server.getUrl())
                .description(server.getDescription())
                .variables(server.getVariables())
                .extensions(server.getExtensions()) : null;

        FileNameGeneratorUtil fileNameGeneratorUtil = new FileNameGeneratorUtil(context, this.schemaExtension);
        this.schemaFileName = fileNameGeneratorUtil.getFileName();
    }

    public Endpoint getEndpoint() {
        if (server == null) {
            reportMissingPortConfigDiagnostic(context);
            return new Endpoint(this.portVal, getBasePath(), REST, this.schemaFileName + schemaExtension);
        }
        ServerVariables vars = server.getVariables();
        String basePath = getBasePath();
        var portVar = vars != null ? vars.get(PORT) : null;
        String defaultPort = portVar != null ? portVar.getDefault() : null;

       if (defaultPort != null && !defaultPort.isEmpty()) {
           this.portVal = Integer.parseInt(defaultPort);
       } else {
            reportMissingPortConfigDiagnostic(context);
       }
        this.schemaFileName = this.schemaFileName + schemaExtension;
        return new Endpoint(this.portVal, basePath, REST, this.schemaFileName);
    }

    public void writeEndpointYaml() throws IOException {
        Endpoint ep = getEndpoint();
        Path outPath = resolveOutputPath();
        String fileName = buildEndpointFileName(outPath);
        Path path = outPath.resolve(ARTIFACT).resolve(fileName + YAML_EXTENSION);
        writeYaml(path, new EndpointWrapper(ep));
    }

    private String getBasePath() {
        StringBuilder serviceBasePath = new StringBuilder();
        NodeList<Node> resourcePathNode = node.absoluteResourcePath();
        for (Node identifierNode : resourcePathNode) {
            serviceBasePath.append(identifierNode.toString().replace("\"", "").trim());
        }
        return serviceBasePath.toString();
    }

    private Path resolveOutputPath() throws IOException {
        Package currentPackage = this.context.currentPackage();
        Project project = currentPackage.project();
        Path outPath = project.targetDir();
        Files.createDirectories(Paths.get(String.valueOf(outPath), ARTIFACT));
        return outPath;
    }

    private String buildEndpointFileName(Path outPath) {
        String base = schemaFileName.split("\\.")[0].replace(OPENAPI_SUFFIX, ENDPOINT_SUFFIX);
        return resolveContractFileName(outPath.resolve(ARTIFACT), base, false);
    }

    private void writeYaml(Path path, EndpointWrapper wrapper) {
        YAMLFactory yamlFactory = YAMLFactory.builder()
                .disable(YAMLGenerator.Feature.WRITE_DOC_START_MARKER)
                .build();
        ObjectMapper mapper = new ObjectMapper(yamlFactory);
        mapper.findAndRegisterModules();

        try (Writer writer = Files.newBufferedWriter(path)) {
            mapper.writeValue(writer, wrapper);
        } catch (IOException e) {
            outStream.println("Failed to write to " + path + "\n");
            e.printStackTrace(outStream);
        }
    }

    private static void reportMissingPortConfigDiagnostic(SyntaxNodeAnalysisContext context) {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                "PORT_CONFIGURATION_BEING_NULL",
                "The configurable value provided for the port should have a " +
                        "default value to generate the server details",
                DiagnosticSeverity.ERROR
        );
        context.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, context.node().location()));
    }

    public void setSchemaExtension(String schemaExtension) {
        this.schemaExtension = schemaExtension;
    }

}
