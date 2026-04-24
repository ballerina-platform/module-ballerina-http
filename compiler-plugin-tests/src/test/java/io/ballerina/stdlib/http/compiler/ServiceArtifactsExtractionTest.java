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

package io.ballerina.stdlib.http.compiler;

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.BuildOptions;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.Package;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.stdlib.http.compiler.endpointyaml.generator.Endpoint;
import io.ballerina.stdlib.http.compiler.endpointyaml.generator.EndpointYamlGenerator;
import io.ballerina.stdlib.http.compiler.endpointyaml.generator.FileNameGeneratorUtil;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.swagger.v3.oas.models.servers.Server;
import io.swagger.v3.oas.models.servers.ServerVariable;
import io.swagger.v3.oas.models.servers.ServerVariables;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.io.IOException;
import java.lang.reflect.Proxy;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.TimeUnit;
import java.util.stream.Stream;

public class ServiceArtifactsExtractionTest {

    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources")
            .toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime")
            .toAbsolutePath();
    private static final String ARTIFACT_DIR = "artifact";

    @Test
    public void testServiceArtifactGenerationWithSimpleService() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_20");
        try {
            executeBallerinaCommand(projectDirPath, true);

            Path artifactDir = projectDirPath.resolve("target").resolve(ARTIFACT_DIR);
            Assert.assertTrue(Files.exists(artifactDir), "Artifact directory should exist");
            Assert.assertTrue(Files.exists(artifactDir.resolve("service_openapi.yaml")),
                    "OpenAPI artifact file should be generated");
            Assert.assertTrue(Files.exists(artifactDir.resolve("service_endpoint.yaml")),
                    "Endpoint artifact file should be generated");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testServiceArtifactGenerationWithoutFlag() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_20");
        executeBallerinaCommand(projectDirPath, false);

        Path artifactDir = projectDirPath.resolve("target").resolve(ARTIFACT_DIR);
        Assert.assertTrue(Files.notExists(artifactDir),
                "Artifact directory should not be generated without flag");
        deleteDirectories(projectDirPath);
    }

    @Test
    public void testServiceArtifactGenerationWithCompilationErrors() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_43");
        executeBallerinaCommand(projectDirPath, true);

        Path artifactDir = projectDirPath.resolve("target").resolve(ARTIFACT_DIR);
        Assert.assertTrue(Files.notExists(artifactDir),
                "Artifact directory should not be generated when compilation has errors");
        deleteDirectories(projectDirPath);
    }

    @Test
    public void testServiceArtifactGenerationForMultipleServices() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_44");
        executeBallerinaCommand(projectDirPath, true);

        Path artifactDir = projectDirPath.resolve("target").resolve(ARTIFACT_DIR);
        Assert.assertTrue(Files.exists(artifactDir), "Artifact directory should exist");

        List<Path> yamlFiles;
        try (Stream<Path> paths = Files.walk(artifactDir)) {
            yamlFiles = paths.filter(path -> path.toString().endsWith(".yaml")).sorted().toList();
        }

        Assert.assertEquals(yamlFiles.size(), 10,
                "Expected openapi and endpoint artifacts for all services");
        Assert.assertEquals(yamlFiles.stream()
                .map(this::safeFileName)
                .filter(fileName -> fileName.contains("_openapi"))
                .count(), 5L, "Expected 5 OpenAPI artifact files");
        Assert.assertEquals(yamlFiles.stream()
                .map(this::safeFileName)
                .filter(fileName -> fileName.contains("_endpoint"))
                .count(), 5L, "Expected 5 endpoint artifact files");

        deleteDirectories(projectDirPath);
    }

    @Test
    public void testEndpointYamlContentForSimpleService() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_20");
        executeBallerinaCommand(projectDirPath, true);

        Path endpointYaml = projectDirPath.resolve("target")
                .resolve(ARTIFACT_DIR)
                .resolve("service_endpoint.yaml");
        Path openAPIYaml = projectDirPath.resolve("target")
                .resolve(ARTIFACT_DIR)
                .resolve("service_openapi.yaml");
        Assert.assertTrue(Files.exists(endpointYaml), "Endpoint YAML should be generated");
        Assert.assertTrue(Files.exists(openAPIYaml), "OpenAPI YAML should be generated");

        Path expectedEndpointFile = RESOURCE_DIRECTORY.resolve("../yaml_files").resolve("service_endpoint.yaml");
        Path expectedOpenAPIFile = RESOURCE_DIRECTORY.resolve("../yaml_files").resolve("service_openapi_1.yaml");

        verifyYamlContent(endpointYaml, expectedEndpointFile);
        verifyYamlContent(openAPIYaml, expectedOpenAPIFile);
        deleteDirectories(projectDirPath);
    }

    @Test
    public void testEndpointYamlGenerationWithRegularServicePath() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_48");
        executeBallerinaCommand(projectDirPath, true);

        Path endpointYaml = projectDirPath.resolve("target")
                .resolve(ARTIFACT_DIR)
                .resolve("service_userservice_endpoint.yaml");
        Path openAPIYaml = projectDirPath.resolve("target")
                .resolve(ARTIFACT_DIR)
                .resolve("service_userservice_openapi.yaml");
        Assert.assertTrue(Files.exists(endpointYaml),
                "Endpoint YAML for regular base path should be generated");
        Assert.assertTrue(Files.exists(openAPIYaml),
                "OpenAPI YAML for regular base path should be generated");

        Path expectedEndpointFile = RESOURCE_DIRECTORY.resolve("../yaml_files")
                .resolve("service_userservice_endpoint.yaml");
        Path expectedOpenAPIFile = RESOURCE_DIRECTORY.resolve("../yaml_files")
                .resolve("service_userservice_openapi.yaml");

        verifyYamlContent(endpointYaml, expectedEndpointFile);
        verifyYamlContent(openAPIYaml, expectedOpenAPIFile);
        deleteDirectories(projectDirPath);
    }

    @Test
    public void testConfigurablePortWithRequiredValue() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_51");
        executeBallerinaCommand(projectDirPath, true);
        try {
            Path artifactDir = projectDirPath.resolve("target").resolve(ARTIFACT_DIR);
            Path endpointYaml = artifactDir.resolve("service_endpoint.yaml");
            Assert.assertFalse(Files.exists(endpointYaml));
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testConfigurablePortWithDefaultValue() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_50");
        executeBallerinaCommand(projectDirPath, true);
        try {
            Path artifactDir = projectDirPath.resolve("target").resolve(ARTIFACT_DIR);
            Path endpointYaml = artifactDir.resolve("service_endpoint.yaml");
            assertEndpointPort(endpointYaml, 8080);
        } finally {
            deleteDirectories(projectDirPath);
        }
    }


    @Test
    public void testEndpointYamlGenerationWithEmptyServicePath() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_47");
        executeBallerinaCommand(projectDirPath, true);

        Path artifactDir = projectDirPath.resolve("target").resolve(ARTIFACT_DIR);
        Assert.assertTrue(Files.exists(artifactDir), "Artifact directory should exist");

        List<String> endpointFiles;
        try (Stream<Path> paths = Files.walk(artifactDir)) {
            endpointFiles = paths
                    .map(this::safeFileName)
                    .filter(fileName -> fileName.endsWith("_endpoint.yaml")).toList();
        }

        Assert.assertEquals(endpointFiles.size(), 1, "Expected exactly one endpoint YAML file");
        Assert.assertTrue(endpointFiles.getFirst().matches("service_[0-9]+_endpoint\\.yaml"),
                "Endpoint YAML file should use fallback hash-based naming for empty service path");

        deleteDirectories(projectDirPath);
    }

    @Test
    public void testExtractServiceNodesWithDuplicateBasePaths() {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_44");
        BuildProject project = BuildProject.load(getEnvironmentBuilder(), projectDirPath);
        Package currentPackage = project.currentPackage();
        Module module = currentPackage.getDefaultModule();
        DocumentId documentId = module.documentIds().iterator().next();
        Document document = module.document(documentId);
        SyntaxTree syntaxTree = document.syntaxTree();
        SemanticModel semanticModel = currentPackage.getCompilation().getSemanticModel(documentId.moduleId());
        Map<Integer, String> services = new HashMap<>();

        FileNameGeneratorUtil.extractServiceNodes(syntaxTree.rootNode(), services, semanticModel);

        Assert.assertEquals(services.size(), 5);
        Assert.assertTrue(services.containsValue("/api/v1"));
        Assert.assertTrue(services.values().stream().anyMatch(value -> value.startsWith("/api/v1-")));
        Assert.assertEquals(services.values().stream().filter("/"::equals).count(), 1);
        Assert.assertTrue(services.values().stream().anyMatch(value -> value.startsWith("/-")));
    }

    @Test
    public void testInProcessServiceArtifactGenerationWithExportEndpoints() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_20");
        executeBallerinaCommand(projectDirPath, true);
        try {
            Path artifactDir = projectDirPath.resolve("target").resolve(ARTIFACT_DIR);
            Assert.assertTrue(Files.exists(artifactDir), "Artifact directory should exist");
            Assert.assertTrue(Files.exists(artifactDir.resolve("service_openapi.yaml")),
                    "OpenAPI artifact file should be generated");
            Assert.assertTrue(Files.exists(artifactDir.resolve("service_endpoint.yaml")),
                    "Endpoint artifact file should be generated");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
    public void testInProcessServiceArtifactGenerationWithoutExportEndpoints() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_20");
        executeBallerinaCommand(projectDirPath, false);
        try {
            Path artifactDir = projectDirPath.resolve("target").resolve(ARTIFACT_DIR);
            Assert.assertTrue(Files.notExists(artifactDir),
                    "Artifact directory should not be generated without export-endpoints option");
        } finally {
            deleteDirectories(projectDirPath);
        }
    }

    @Test
        public void testEndpointYamlGeneratorWithMissingPortVariableReportsDiagnostic() {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_48");
        BuildProject project = loadProject(projectDirPath, false);
        TestContextData contextData = getTestContextData(project);
        List<Diagnostic> reportedDiagnostics = new ArrayList<>();
        SyntaxNodeAnalysisContext context = createSyntaxNodeAnalysisContext(contextData, reportedDiagnostics);

        Server server = new Server();
        server.setUrl("http://localhost:{port}");
        server.setVariables(new ServerVariables());

        EndpointYamlGenerator generator = new EndpointYamlGenerator(contextData.serviceNode, context, server);
        Endpoint endpoint = generator.getEndpoint();

        Assert.assertEquals(endpoint.getPort(), 0,
            "Endpoint port should fallback to 0 when no port variable default is provided");
        Assert.assertEquals(endpoint.getBasePath(), "/userservice");
        Assert.assertTrue(reportedDiagnostics.stream().anyMatch(d -> "PORT_CONFIGURATION_BEING_NULL"
            .equals(d.diagnosticInfo().code())), "Expected missing port diagnostic");
        }

        @Test
        public void testEndpointYamlGeneratorWithInvalidPortValue() {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_48");
        BuildProject project = loadProject(projectDirPath, false);
        TestContextData contextData = getTestContextData(project);
        List<Diagnostic> reportedDiagnostics = new ArrayList<>();
        SyntaxNodeAnalysisContext context = createSyntaxNodeAnalysisContext(contextData, reportedDiagnostics);

        ServerVariables variables = new ServerVariables();
        ServerVariable port = new ServerVariable();
        port.setDefault("invalid-port");
        variables.put("port", port);
        Server server = new Server();
        server.setUrl("http://localhost:{port}");
        server.setVariables(variables);

        EndpointYamlGenerator generator = new EndpointYamlGenerator(contextData.serviceNode, context, server);
        Endpoint endpoint = generator.getEndpoint();

        Assert.assertEquals(endpoint.getPort(), 0,
            "Endpoint port should remain default when server variable is non-numeric");
        Assert.assertEquals(endpoint.getBasePath(), "/userservice");
        Assert.assertTrue(endpoint.getSchemaPath().endsWith("_openapi.yaml"));
        Assert.assertTrue(reportedDiagnostics.isEmpty(),
            "Invalid port format should not report a missing-port diagnostic");
    }

    private String safeFileName(Path path) {
        Path fileName = path == null ? null : path.getFileName();
        return Objects.toString(fileName, "");
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private BuildProject loadProject(Path projectDirPath, boolean exportEndpoints) {
        BuildOptions options = BuildOptions.builder().setExportEndpoints(exportEndpoints).build();
        return BuildProject.load(getEnvironmentBuilder(), projectDirPath, options);
    }

    private TestContextData getTestContextData(BuildProject project) {
        Package currentPackage = project.currentPackage();
        Module module = currentPackage.getDefaultModule();
        DocumentId documentId = module.documentIds().iterator().next();
        Document document = module.document(documentId);
        SyntaxTree syntaxTree = document.syntaxTree();
        SemanticModel semanticModel = currentPackage.getCompilation().getSemanticModel(documentId.moduleId());
        io.ballerina.compiler.syntax.tree.ModulePartNode modulePartNode = syntaxTree.rootNode();
        io.ballerina.compiler.syntax.tree.ServiceDeclarationNode serviceNode = null;

        for (io.ballerina.compiler.syntax.tree.Node member : modulePartNode.members()) {
            if (member.kind() == io.ballerina.compiler.syntax.tree.SyntaxKind.SERVICE_DECLARATION) {
                serviceNode = (io.ballerina.compiler.syntax.tree.ServiceDeclarationNode) member;
                break;
            }
        }

        if (serviceNode == null) {
            throw new IllegalStateException("No service declaration node found in source file");
        }

        return new TestContextData(currentPackage, syntaxTree, semanticModel, serviceNode,
                documentId, currentPackage.getCompilation());
    }

    private SyntaxNodeAnalysisContext createSyntaxNodeAnalysisContext(TestContextData data,
                                                                      List<Diagnostic> reportedDiagnostics) {
        return (SyntaxNodeAnalysisContext) Proxy.newProxyInstance(
                SyntaxNodeAnalysisContext.class.getClassLoader(),
                new Class[]{SyntaxNodeAnalysisContext.class},
                (proxy, method, args) -> switch (method.getName()) {
                    case "node" -> data.serviceNode;
                    case "syntaxTree" -> data.syntaxTree;
                    case "semanticModel" -> data.semanticModel;
                    case "currentPackage" -> data.currentPackage;
                    case "documentId" -> data.documentId;
                    case "moduleId" -> data.documentId.moduleId();
                    case "compilation" -> data.compilation;
                    case "reportDiagnostic" -> {
                        if (args != null && args.length == 1 && args[0] instanceof Diagnostic) {
                            reportedDiagnostics.add((Diagnostic) args[0]);
                        }
                        yield null;
                    }
                    default -> throw new UnsupportedOperationException("Unsupported context method: " +
                            method.getName());
                });
    }

    private static class TestContextData {
        private final Package currentPackage;
        private final SyntaxTree syntaxTree;
        private final SemanticModel semanticModel;
        private final io.ballerina.compiler.syntax.tree.ServiceDeclarationNode serviceNode;
        private final DocumentId documentId;
        private final PackageCompilation compilation;

        private TestContextData(Package currentPackage, SyntaxTree syntaxTree, SemanticModel semanticModel,
                                io.ballerina.compiler.syntax.tree.ServiceDeclarationNode serviceNode,
                                DocumentId documentId, PackageCompilation compilation) {
            this.currentPackage = currentPackage;
            this.syntaxTree = syntaxTree;
            this.semanticModel = semanticModel;
            this.serviceNode = serviceNode;
            this.documentId = documentId;
            this.compilation = compilation;
        }
    }

    public static void executeBallerinaCommand(Path projectDirPath, boolean exportEndpoints) throws Exception {
        List<String> buildArgs = new ArrayList<>();
        String balFile = "bal";
        if (System.getProperty("os.name").startsWith("Windows")) {
            balFile = "bal.bat";
        }
        buildArgs.add(0, DISTRIBUTION_PATH.resolve("bin").resolve(balFile).toString());
        buildArgs.add(1, "build");
        if (exportEndpoints) {
            buildArgs.add(2, "--export-endpoints");
        }

        ProcessBuilder pb = new ProcessBuilder(buildArgs)
                .redirectErrorStream(true)
                .redirectOutput(ProcessBuilder.Redirect.INHERIT);
        pb.directory(projectDirPath.toFile());
        Process process = pb.start();
        boolean completed = process.waitFor(2, TimeUnit.MINUTES);
        Assert.assertTrue(completed, "bal build timed out after 2 minutes");
    }

    public static void assertEndpointPort(Path endpointYaml, int expectedPort) throws IOException {
        try (Stream<String> lines = Files.lines(endpointYaml)) {
            String portLine = lines.map(String::trim)
                    .filter(line -> line.startsWith("port:"))
                    .findFirst()
                    .orElseThrow(() -> new AssertionError("No port field found in: " + endpointYaml));
            int actualPort = Integer.parseInt(portLine.substring("port:".length()).trim());
            Assert.assertEquals(actualPort, expectedPort, "Unexpected endpoint port in " + endpointYaml);
        }
    }

    private static void verifyYamlContent(Path actualYaml, Path expectedYaml) throws IOException {
        String endpointContent = Files.readString(actualYaml);
        String expectedEndpointContent = Files.readString(expectedYaml);
        Assert.assertEquals(endpointContent.replaceAll("\\s+", ""),
                expectedEndpointContent.replaceAll("\\s+", ""),
                "Spec content does not match expected content");
    }

    private void deleteDirectories(Path projectDirPath) throws IOException {
        Path targetDir = projectDirPath.resolve("target");
        if (Files.exists(targetDir)) {
            try (Stream<Path> paths = Files.walk(targetDir)) {
                paths.sorted(Comparator.reverseOrder())
                        .forEach(path -> {
                            try {
                                Files.delete(path);
                            } catch (IOException e) {
                                Assert.fail("Failed to delete file: " + path, e);
                            }
                        });
            }
        }
        Path dependenciesFile = projectDirPath.resolve("Dependencies.toml");
        if (Files.exists(dependenciesFile)) {
            Files.delete(dependenciesFile);
        }
    }

}
