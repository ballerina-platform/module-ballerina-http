/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.compiler.staticcodeanalyzer;

import org.testng.Assert;
import org.testng.annotations.BeforeSuite;
import org.testng.annotations.Test;
import org.testng.internal.ExitCode;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * This class includes tests for Ballerina Http static code analyzer.
 */
class StaticCodeAnalyzerTest {

    private static final Path RESOURCE_PACKAGES_DIRECTORY = Paths
            .get("src", "test", "resources", "static_code_analyzer", "ballerina_packages").toAbsolutePath();
    private static final Path EXPECTED_JSON_OUTPUT_DIRECTORY = Paths.
            get("src", "test", "resources", "static_code_analyzer", "expected_output").toAbsolutePath();
    private static final Path BALLERINA_PATH = Paths
            .get("../", "target", "ballerina-runtime", "bin", "bal").toAbsolutePath();
    private static final Path JSON_RULES_FILE_PATH = Paths
            .get("../", "compiler-plugin", "src", "main", "resources", "rules.json").toAbsolutePath();
    private static final String SCAN_COMMAND = "scan";

    @BeforeSuite
    public void pullScanTool() throws IOException, InterruptedException {
        ProcessBuilder processBuilder = new ProcessBuilder(BALLERINA_PATH.toString(), "tool", "pull", SCAN_COMMAND);
        Process process = processBuilder.start();
        int exitCode = process.waitFor();
        String output = convertInputStreamToString(process.getInputStream());
        if (Pattern.compile("tool 'scan:.+\\..+\\..+' successfully set as the active version\\.")
                .matcher(output).find() || Pattern.compile("tool 'scan:.+\\..+\\..+' is already active\\.")
                .matcher(output).find()) {
            return;
        }
        Assert.assertFalse(ExitCode.hasFailure(exitCode));
    }

    @Test
    public void validateRulesJson() throws IOException {
        String expectedRules = "[" + Arrays.stream(HttpRule.values())
                .map(HttpRule::toString).collect(Collectors.joining(",")) + "]";
        String actualRules = Files.readString(JSON_RULES_FILE_PATH);
        assertJsonEqual(normalizeJson(actualRules), normalizeJson(expectedRules));
    }

    @Test
    public void testStaticCodeRules() throws IOException, InterruptedException {
        for (HttpRule rule : HttpRule.values()) {
            String targetPackageName = "rule" + rule.getId();
            String actualJsonReport = StaticCodeAnalyzerTest.executeScanProcess(targetPackageName);
            String expectedJsonReport = Files
                    .readString(EXPECTED_JSON_OUTPUT_DIRECTORY.resolve(targetPackageName + ".json"));
            assertJsonEqual(actualJsonReport, expectedJsonReport);
        }
    }

    public static String executeScanProcess(String targetPackage) throws IOException, InterruptedException {
        ProcessBuilder processBuilder2 = new ProcessBuilder(BALLERINA_PATH.toString(), SCAN_COMMAND);
        processBuilder2.directory(RESOURCE_PACKAGES_DIRECTORY.resolve(targetPackage).toFile());
        Process process2 = processBuilder2.start();
        int exitCode = process2.waitFor();
        Assert.assertFalse(ExitCode.hasFailure(exitCode));
        return Files.readString(RESOURCE_PACKAGES_DIRECTORY.resolve(targetPackage)
                .resolve("target").resolve("report").resolve("scan_results.json"));
    }

    public static String convertInputStreamToString(InputStream inputStream) throws IOException {
        StringBuilder stringBuilder = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                stringBuilder.append(line).append(System.lineSeparator());
            }
        }
        return stringBuilder.toString();
    }

    private void assertJsonEqual(String actual, String expected) throws IOException {
        try {
            Assert.assertEquals(normalizeJson(actual), normalizeJson(expected));
        } catch (AssertionError e) {
            File temp = File.createTempFile("abc", "efg");
            PrintStream ps = new PrintStream(temp, StandardCharsets.UTF_8);
            e.printStackTrace(ps);
            var p = System.out;
            String fileContent = Files.readString(temp.toPath());
            p.println(fileContent);
            throw e;
        }
    }

    private static String normalizeJson(String json) {
        return json.replaceAll("\\s*\"\\s*", "\"")
                .replaceAll("\\s*:\\s*", ":")
                .replaceAll("\\s*,\\s*", ",")
                .replaceAll("\\s*\\{\\s*", "{")
                .replaceAll("\\s*}\\s*", "}")
                .replaceAll("\\s*\\[\\s*", "[")
                .replaceAll("\\s*]\\s*", "]")
                .replaceAll("\n", "");
    }
}
