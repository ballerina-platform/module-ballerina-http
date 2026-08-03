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
import io.ballerina.tools.diagnostics.Diagnostic;
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
import java.util.List;

/*
 * Computes endpoint details of an HTTP service and writes the consolidated endpoints.yaml
 */
public class EndpointYamlGenerator {
    private final ServiceDeclarationNode node;
    private String schemaFileName;

    private static final PrintStream outStream = System.out;

    private static final String ARTIFACT = "artifact";
    private static final String REST = "REST";
    private static final String ENDPOINTS_FILE_NAME = "endpoints.yaml";
    private static final String PORT = "port";

    private int portVal = 0;

    private final Server server;

    /*
     * Computes the endpoint details of an HTTP service
     */
    public EndpointYamlGenerator(ServiceDeclarationNode node, Server server, String schemaFileName) {
        this.node = node;
        this.server = server != null ? new Server()
                .url(server.getUrl())
                .description(server.getDescription())
                .variables(server.getVariables())
                .extensions(server.getExtensions()) : null;
        this.schemaFileName = schemaFileName;
    }

    public Endpoint getEndpoint(List<Diagnostic> diagnostics) {
        String basePath = getBasePath();
        if (server == null) {
            diagnostics.add(missingPortConfigDiagnostic());
            return new Endpoint(basePath, this.portVal, basePath, REST, this.schemaFileName);
        }
        ServerVariables vars = server.getVariables();
        var portVar = vars != null ? vars.get(PORT) : null;
        String defaultPort = portVar != null ? portVar.getDefault() : null;

       if (defaultPort != null && !defaultPort.isEmpty()) {
           try {
               this.portVal = Integer.parseInt(defaultPort);
           } catch (NumberFormatException ex) {
               outStream.println("Assign a integer value for port.");
           }
       } else {
            diagnostics.add(missingPortConfigDiagnostic());
       }
        return new Endpoint(basePath, this.portVal, basePath, REST, this.schemaFileName);
    }

    public static void writeEndpointsYaml(Path outPath, List<Endpoint> endpoints) throws IOException {
        Files.createDirectories(outPath.resolve(ARTIFACT));
        Path path = outPath.resolve(ARTIFACT).resolve(ENDPOINTS_FILE_NAME);
        writeYaml(path, new EndpointsWrapper(endpoints));
    }

    private String getBasePath() {
        StringBuilder serviceBasePath = new StringBuilder();
        NodeList<Node> resourcePathNode = node.absoluteResourcePath();
        for (Node identifierNode : resourcePathNode) {
            serviceBasePath.append(identifierNode.toString().replace("\"", "").trim());
        }
        return serviceBasePath.toString();
    }

    private static void writeYaml(Path path, EndpointsWrapper wrapper) throws IOException {
        YAMLFactory yamlFactory = YAMLFactory.builder()
                .disable(YAMLGenerator.Feature.WRITE_DOC_START_MARKER)
                .build();
        ObjectMapper mapper = new ObjectMapper(yamlFactory);
        mapper.findAndRegisterModules();

        try (Writer writer = Files.newBufferedWriter(path)) {
            mapper.writeValue(writer, wrapper);
        } catch (IOException e) {
            throw new IOException("Failed to write endpoints yaml to " + path, e);
        }
    }

    private Diagnostic missingPortConfigDiagnostic() {
        DiagnosticInfo diagnosticInfo = new DiagnosticInfo(
                "PORT_CONFIGURATION_BEING_NULL",
                "The configurable value provided for the port should have a " +
                        "default value to generate the server details",
                DiagnosticSeverity.ERROR
        );
        return DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location());
    }

}
