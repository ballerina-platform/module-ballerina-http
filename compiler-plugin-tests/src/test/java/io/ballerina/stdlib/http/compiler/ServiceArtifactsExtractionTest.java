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
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.Package;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.stdlib.http.compiler.endpointyaml.generator.FileNameGeneratorUtil;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
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
        executeBallerinaCommand(projectDirPath, true);

        Path artifactDir = projectDirPath.resolve("target").resolve(ARTIFACT_DIR);
        Assert.assertTrue(Files.exists(artifactDir), "Artifact directory should exist");
        Assert.assertTrue(Files.exists(artifactDir.resolve("service_openapi.yaml")),
                "OpenAPI artifact file should be generated");
        Assert.assertTrue(Files.exists(artifactDir.resolve("service_endpoint.yaml")),
                "Endpoint artifact file should be generated");
        deleteDirectories(projectDirPath);
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
            yamlFiles = paths.filter(path -> path.toString().endsWith(".yaml"))
                    .sorted()
                    .collect(Collectors.toList());
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
    public void testEndpointYamlGenerationWithEmptyServicePath() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_47");
        executeBallerinaCommand(projectDirPath, true);

        Path artifactDir = projectDirPath.resolve("target").resolve(ARTIFACT_DIR);
        Assert.assertTrue(Files.exists(artifactDir), "Artifact directory should exist");

        List<String> endpointFiles;
        try (Stream<Path> paths = Files.walk(artifactDir)) {
            endpointFiles = paths
                    .map(this::safeFileName)
                    .filter(fileName -> fileName.endsWith("_endpoint.yaml"))
                    .collect(Collectors.toList());
        }

        Assert.assertEquals(endpointFiles.size(), 1, "Expected exactly one endpoint YAML file");
        Assert.assertTrue(endpointFiles.get(0).matches("service_[0-9]+_endpoint\\.yaml"),
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

    private String safeFileName(Path path) {
        Path fileName = path == null ? null : path.getFileName();
        return Objects.toString(fileName, "");
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private void executeBallerinaCommand(Path projectDirPath, boolean exportEndpoints) throws Exception {
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

        ProcessBuilder pb = new ProcessBuilder(buildArgs);
        pb.directory(projectDirPath.toFile());
        Process process = pb.start();
        process.waitFor();
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
