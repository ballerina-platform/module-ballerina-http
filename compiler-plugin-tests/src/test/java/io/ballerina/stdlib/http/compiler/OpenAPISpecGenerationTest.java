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

import org.testng.Assert;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Stream;

public class OpenAPISpecGenerationTest {
    private static final Path RESOURCE_DIRECTORY = Paths.get("src", "test", "resources", "ballerina_sources")
            .toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime")
            .toAbsolutePath();

    @Test
    public void testSpecGeneration() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_20");
        executeBallerinaCommand(projectDirPath, true);
        Path actualFile = projectDirPath.resolve("target/openapi").resolve("service_openapi.yaml");
        Path expectedFile = RESOURCE_DIRECTORY.resolve("../yaml_files").resolve("service_openapi.yaml");
        verifySpecContent(actualFile, expectedFile);
        deleteDirectories(projectDirPath);
    }

    @Test
    public void testSpecGenerationInComplexServices() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_42");
        executeBallerinaCommand(projectDirPath, true);
        Path actualFile = projectDirPath.resolve("target/openapi")
                .resolve("api_v1_openapi.yaml");
        Path expectedFile = RESOURCE_DIRECTORY.resolve("../yaml_files").resolve("complex_openapi.yaml");
        verifySpecContent(actualFile, expectedFile);
        deleteDirectories(projectDirPath);
    }

    @Test
    public void testSpecGenerationWithoutFlag() throws Exception {
        Path projectDirPath = RESOURCE_DIRECTORY.resolve("sample_package_20");
        executeBallerinaCommand(projectDirPath, false);
        Path yamlFile = projectDirPath.resolve("target/openapi").resolve("service_openapi.yaml");
        Assert.assertTrue(Files.notExists(yamlFile), "OpenAPI spec file should not be generated: " + yamlFile);
        deleteDirectories(projectDirPath);
    }

    private void executeBallerinaCommand(Path projectDirPath, boolean exportOpenApi) throws Exception {
        List<String> buildArgs = new ArrayList<>();
        String balFile = "bal";
        if (System.getProperty("os.name").startsWith("Windows")) {
            balFile = "bal.bat";
        }
        buildArgs.add(0, DISTRIBUTION_PATH.resolve("bin").resolve(balFile).toString());
        buildArgs.add(1, "build");
        if (exportOpenApi) {
            buildArgs.add(2, "--export-openapi");
        }
        ProcessBuilder pb = new ProcessBuilder(buildArgs);
        pb.directory(projectDirPath.toFile());
        Process process = pb.start();
        process.waitFor();
    }

    private void verifySpecContent(Path actualFilePath, Path expectedFilePath) throws IOException {
        Assert.assertTrue(Files.exists(actualFilePath), "OpenAPI spec file does not exist: " + actualFilePath);
        String content = Files.readString(actualFilePath);
        String expectedContent = Files.readString(expectedFilePath);
        Assert.assertEquals(content.replaceAll("\\s+", ""), expectedContent.replaceAll("\\s+", ""),
            "OpenAPI Spec content does not match expected content");
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
                            Assert.fail("Failed to delete file: " + path.toString(), e);
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
