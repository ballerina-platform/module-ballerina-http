/*
 * Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org)
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

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import io.ballerina.projects.Project;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.BuildProject;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.scan.Issue;
import io.ballerina.scan.Rule;
import io.ballerina.scan.Source;
import io.ballerina.scan.test.Assertions;
import io.ballerina.scan.test.TestOptions;
import io.ballerina.scan.test.TestRunner;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.regex.PatternSyntaxException;
import java.util.stream.Collectors;

import static io.ballerina.scan.RuleKind.VULNERABILITY;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_AUTHENTICATION_OVER_CLEARTEXT;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_CREDENTIALED_WILDCARD_CORS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_DEFAULT_RESOURCE_ACCESSOR;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_DISABLED_AUTH_PROVIDER_TLS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_DISABLED_TLS_VALIDATION;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_FORWARDING_CREDENTIALS_ON_REDIRECT;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_PERMISSIVE_CORS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_TRAVERSING_ATTACKS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_UNLIMITED_REQUEST_BODY_SIZE;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_UNSECURE_CALLER_REDIRECTIONS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_UNSECURE_REDIRECTIONS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.AVOID_WEAK_TLS_PROTOCOLS;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.ENSURE_AUTHORIZATION_SCOPES;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.ENSURE_JWT_VERIFICATION;
import static io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpRule.ENSURE_SECURE_COOKIE_CONFIGURATION;
import static java.nio.charset.StandardCharsets.UTF_8;

public class StaticCodeAnalyzerTest {
    private static final Path RESOURCE_PACKAGES_DIRECTORY = Paths
            .get("src", "test", "resources", "static_code_analyzer", "ballerina_packages").toAbsolutePath();
    private static final Path EXPECTED_OUTPUT_DIRECTORY = Paths
            .get("src", "test", "resources", "static_code_analyzer", "expected_output").toAbsolutePath();
    private static final Path JSON_RULES_FILE_PATH = Paths
            .get("../", "compiler-plugin", "src", "main", "resources", "rules.json").toAbsolutePath();
    private static final Path DISTRIBUTION_PATH = Paths.get("../", "target", "ballerina-runtime");
    private static final String MODULE_BALLERINA_HTTP = "module-ballerina-http";

    @Test
    public void validateRulesJson() throws IOException {
        String expectedRules = "[" + Arrays.stream(HttpRule.values())
                .map(HttpRule::toString).collect(Collectors.joining(",")) + "]";
        String actualRules = Files.readString(JSON_RULES_FILE_PATH);
        assertJsonEqual(actualRules, expectedRules);
    }

    @Test
    public void testStaticCodeRulesWithAPI() throws IOException {
        ByteArrayOutputStream console = new ByteArrayOutputStream();
        PrintStream printStream = new PrintStream(console, true, UTF_8);

        for (HttpRule rule : HttpRule.values()) {
            testIndividualRule(rule, console, printStream);
        }
    }

    private void testIndividualRule(HttpRule rule, ByteArrayOutputStream console, PrintStream printStream)
            throws IOException {
        String targetPackageName = "rule" + rule.getId();
        Path targetPackagePath = RESOURCE_PACKAGES_DIRECTORY.resolve(targetPackageName);

        TestRunner testRunner = setupTestRunner(targetPackagePath, printStream);
        testRunner.performScan();

        validateRules(testRunner.getRules());
        if (System.getProperty("dumpOnly") == null) {
            validateIssues(rule, testRunner.getIssues());
        }
        validateOutput(console, targetPackageName);

        console.reset();
    }

    private TestRunner setupTestRunner(Path targetPackagePath, PrintStream printStream) {
        Project project = BuildProject.load(getEnvironmentBuilder(), targetPackagePath);
        TestOptions options = TestOptions.builder(project).setOutputStream(printStream).build();
        return new TestRunner(options);
    }

    private void validateRules(List<Rule> rules) {
        for (HttpRule rule : HttpRule.values()) {
            Assertions.assertRule(rules, "ballerina/http:" + rule.getId(), rule.getDescription(), VULNERABILITY);
        }
    }

    private void validateIssues(HttpRule rule, List<Issue> issues) {
        switch (rule) {
            case AVOID_DEFAULT_RESOURCE_ACCESSOR:
                int index = 0;
                Assert.assertEquals(issues.size(), 8);
                Assertions.assertIssue(issues, index++, "ballerina/http:1", "service.bal",
                        20, 20, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:1", "service.bal",
                        24, 24, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:1", "service_class.bal",
                        21, 21, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:1", "service_class.bal",
                        25, 25, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:1", "service_object.bal",
                        20, 20, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:1", "service_object.bal",
                        21, 21, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:1", "service_object.bal",
                        26, 26, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:1", "service_object.bal",
                        27, 27, Source.BUILT_IN);
                break;
            case AVOID_PERMISSIVE_CORS:
                index = 0;
                Assert.assertEquals(issues.size(), 7);
                Assertions.assertIssue(issues, index++, "ballerina/http:2", "service.bal",
                        20, 20, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:2", "service.bal",
                        27, 27, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:2", "service_class.bal",
                        23, 23, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:2", "service_object.bal",
                        20, 20, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:2", "service_object.bal",
                        28, 28, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:2", "service_object.bal",
                        36, 36, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:2", "service_object.bal",
                        44, 44, Source.BUILT_IN);
                break;
            case AVOID_TRAVERSING_ATTACKS:
                index = 0;
                Assert.assertEquals(issues.size(), 12);
                Assertions.assertIssue(issues, index++, "ballerina/http:3", "service.bal",
                        24, 24, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:3", "service.bal",
                        30, 30, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:3", "service.bal",
                        39, 39, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:3", "service.bal",
                        44, 44, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:3", "service.bal",
                        48, 48, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:3", "service.bal",
                        52, 52, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:3", "service.bal",
                        54, 54, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:3", "service.bal",
                        58, 58, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:3", "service.bal",
                        58, 58, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:3", "service.bal",
                        61, 61, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:3", "service_class.bal",
                        22, 22, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:3", "service_class.bal",
                        28, 28, Source.BUILT_IN);
                break;
            case AVOID_UNSECURE_REDIRECTIONS:
                index = 0;
                Assert.assertEquals(issues.size(), 9);
                Assertions.assertIssue(issues, index++, "ballerina/http:4", "custom_prefix.bal",
                        22, 22, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:4", "service.bal",
                        33, 33, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:4", "service.bal",
                        42, 42, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:4", "service.bal",
                        50, 50, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:4", "service.bal",
                        58, 58, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:4", "service.bal",
                        66, 66, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:4", "service.bal",
                        76, 76, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:4", "service.bal",
                        83, 83, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:4", "service.bal",
                        95, 95, Source.BUILT_IN);
                break;
            case AVOID_CREDENTIALED_WILDCARD_CORS:
                index = 0;
                Assert.assertEquals(issues.size(), 5);
                Assertions.assertIssue(issues, index++, "ballerina/http:2", "service.bal",
                        21, 21, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:5", "service.bal",
                        22, 22, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:2", "service.bal",
                        28, 28, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:5", "service.bal",
                        29, 29, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:2", "service.bal",
                        40, 40, Source.BUILT_IN);
                break;
            case AVOID_DISABLED_TLS_VALIDATION:
                index = 0;
                Assert.assertEquals(issues.size(), 4);
                Assertions.assertIssue(issues, index++, "ballerina/http:6", "client.bal",
                        22, 22, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:6", "client.bal",
                        30, 30, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:6", "client.bal",
                        38, 38, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:6", "client.bal",
                        39, 39, Source.BUILT_IN);
                break;
            case AVOID_WEAK_TLS_PROTOCOLS:
                index = 0;
                Assert.assertEquals(issues.size(), 4);
                Assertions.assertIssue(issues, index++, "ballerina/http:7", "protocol.bal",
                        24, 24, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:7", "protocol.bal",
                        36, 36, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:7", "protocol.bal",
                        36, 36, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:7", "protocol.bal",
                        50, 50, Source.BUILT_IN);
                break;
            case AVOID_FORWARDING_CREDENTIALS_ON_REDIRECT:
                index = 0;
                Assert.assertEquals(issues.size(), 2);
                Assertions.assertIssue(issues, index++, "ballerina/http:8", "redirect.bal",
                        23, 23, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:8", "redirect.bal",
                        32, 32, Source.BUILT_IN);
                break;
            case ENSURE_SECURE_COOKIE_CONFIGURATION:
                index = 0;
                Assert.assertEquals(issues.size(), 4);
                Assertions.assertIssue(issues, index++, "ballerina/http:9", "cookie.bal",
                        21, 21, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:9", "cookie.bal",
                        26, 26, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:9", "cookie.bal",
                        33, 33, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:9", "cookie.bal",
                        39, 39, Source.BUILT_IN);
                break;
            case AVOID_DISABLED_AUTH_PROVIDER_TLS:
                index = 0;
                Assert.assertEquals(issues.size(), 2);
                Assertions.assertIssue(issues, index++, "ballerina/http:10", "auth_client.bal",
                        26, 26, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:10", "auth_client.bal",
                        39, 39, Source.BUILT_IN);
                break;
            case ENSURE_JWT_VERIFICATION:
                index = 0;
                Assert.assertEquals(issues.size(), 3);
                Assertions.assertIssue(issues, index++, "ballerina/http:11", "service.bal",
                        29, 33, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:11", "service.bal",
                        45, 51, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:11", "service.bal",
                        63, 69, Source.BUILT_IN);
                break;
            case ENSURE_AUTHORIZATION_SCOPES:
                index = 0;
                Assert.assertEquals(issues.size(), 2);
                Assertions.assertIssue(issues, index++, "ballerina/http:12", "service.bal",
                        29, 35, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:12", "service.bal",
                        47, 50, Source.BUILT_IN);
                break;
            case AVOID_AUTHENTICATION_OVER_CLEARTEXT:
                index = 0;
                Assert.assertEquals(issues.size(), 2);
                Assertions.assertIssue(issues, index++, "ballerina/http:13", "service.bal",
                        41, 41, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:13", "service.bal",
                        60, 60, Source.BUILT_IN);
                break;
            case AVOID_UNSECURE_CALLER_REDIRECTIONS:
                index = 0;
                Assert.assertEquals(issues.size(), 4);
                Assertions.assertIssue(issues, index++, "ballerina/http:14", "service.bal",
                        24, 24, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:14", "service.bal",
                        30, 30, Source.BUILT_IN);
                Assertions.assertIssue(issues, index++, "ballerina/http:14", "service.bal",
                        36, 36, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:14", "service.bal",
                        42, 42, Source.BUILT_IN);
                break;
            case AVOID_UNLIMITED_REQUEST_BODY_SIZE:
                index = 0;
                Assert.assertEquals(issues.size(), 2);
                Assertions.assertIssue(issues, index++, "ballerina/http:15", "listener.bal",
                        22, 22, Source.BUILT_IN);
                Assertions.assertIssue(issues, index, "ballerina/http:15", "listener.bal",
                        31, 31, Source.BUILT_IN);
                break;
            default:
                Assert.fail("Unhandled rule in validateIssues: " + rule);
                break;
        }
    }

    private void validateOutput(ByteArrayOutputStream console, String targetPackageName) throws IOException {
        String output = console.toString(UTF_8);
        String jsonOutput = extractJson(output);
        Files.writeString(Paths.get("/private/tmp/claude-501/-Users-tharmigan-Downloads-module-ballerina-http/"
                        + "3a1ec2a3-ed06-460b-aad1-6a6e754bd99d/scratchpad/actual", targetPackageName + ".json"),
                jsonOutput.replaceAll(":\\s*\"[^\"]*" + MODULE_BALLERINA_HTTP, ": \"" + MODULE_BALLERINA_HTTP));
        if (System.getProperty("dumpOnly") != null) {
            return;
        }
        String expectedOutput = Files.readString(EXPECTED_OUTPUT_DIRECTORY.resolve(targetPackageName + ".json"));
        assertJsonEqual(jsonOutput, expectedOutput);
    }

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    private String extractJson(String consoleOutput) {
        int startIndex = consoleOutput.indexOf("[");
        int endIndex = consoleOutput.lastIndexOf("]");
        if (startIndex == -1 || endIndex == -1) {
            return "";
        }
        return consoleOutput.substring(startIndex, endIndex + 1);
    }

    private void assertJsonEqual(String actual, String expected) {
        Assert.assertEquals(normalizeString(actual), normalizeString(expected));
    }

    private static String normalizeString(String json) {
        try {
            ObjectMapper mapper = new ObjectMapper().configure(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS, true);
            JsonNode node = mapper.readTree(json);
            // Trim the machine specific prefix of a file path, matching within one JSON string value: a greedy
            // match would run past the closing quote and swallow every diagnostic up to the last path in the report
            String normalizedJson = mapper.writeValueAsString(node)
                    .replaceAll(":\"[^\"]*" + MODULE_BALLERINA_HTTP, ":\"" + MODULE_BALLERINA_HTTP);
            return isWindows() ? normalizedJson.replace("/", "\\\\") : normalizedJson;
        } catch (JsonProcessingException | PatternSyntaxException ignore) {
            return json;
        }
    }

    private static boolean isWindows() {
        return System.getProperty("os.name").toLowerCase(Locale.ENGLISH).startsWith("windows");
    }
}
