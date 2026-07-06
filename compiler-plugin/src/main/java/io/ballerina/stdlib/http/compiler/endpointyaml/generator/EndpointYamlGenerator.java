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

import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.projects.plugins.EndpointArtifact;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.swagger.v3.oas.models.servers.Server;
import io.swagger.v3.oas.models.servers.ServerVariables;

import java.io.PrintStream;

public class EndpointYamlGenerator {
    private final ServiceDeclarationNode node;
    private final SyntaxNodeAnalysisContext context;
    private String schemaFileName;

    private static final PrintStream outStream = System.out;

    private static final String REST = "REST";
    private static final String OPENAPI_SUFFIX = "_openapi";
    private static final String PORT = "port";

    private int portVal = 0;

    private final Server server;

    /**
     * Adds endpoint details of HTTP service to the build context.
     */
    public EndpointYamlGenerator(ServiceDeclarationNode node, SyntaxNodeAnalysisContext context, Server server) {
        this.node = node;
        this.context = context;
        this.server = server != null ? new Server()
                .url(server.getUrl())
                .description(server.getDescription())
                .variables(server.getVariables())
                .extensions(server.getExtensions()) : null;

        FileNameGeneratorUtil fileNameGeneratorUtil = new FileNameGeneratorUtil(context);
        this.schemaFileName = fileNameGeneratorUtil.getFileName();
    }

    public Endpoint getEndpoint() {
        if (server == null) {
            reportMissingPortConfigDiagnostic(context);
            return new Endpoint(this.portVal, getBasePath(), REST, this.schemaFileName);
        }
        ServerVariables vars = server.getVariables();
        String basePath = getBasePath();
        var portVar = vars != null ? vars.get(PORT) : null;
        String defaultPort = portVar != null ? portVar.getDefault() : null;

       if (defaultPort != null && !defaultPort.isEmpty()) {
           try {
               this.portVal = Integer.parseInt(defaultPort);
           } catch (NumberFormatException ex) {
               outStream.println("Assign a integer value for port.");
           }
       } else {
            reportMissingPortConfigDiagnostic(context);
       }
        return new Endpoint(this.portVal, basePath, REST, this.schemaFileName);
    }

    public void addEndpointArtifact() {
        Endpoint ep = getEndpoint();
        context.addEndpointArtifact(new EndpointArtifact(getEndpointName(), ep.getPort(), ep.getBasePath(),
                ep.getType(), ep.getSchemaPath()));
    }

    private String getBasePath() {
        StringBuilder serviceBasePath = new StringBuilder();
        NodeList<Node> resourcePathNode = node.absoluteResourcePath();
        for (Node identifierNode : resourcePathNode) {
            serviceBasePath.append(identifierNode.toString().replace("\"", "").trim());
        }
        return serviceBasePath.toString();
    }

    private String getEndpointName() {
        return schemaFileName.split("\\.")[0].replace(OPENAPI_SUFFIX, "");
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

}
