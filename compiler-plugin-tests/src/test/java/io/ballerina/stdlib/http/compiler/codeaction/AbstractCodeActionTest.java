/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.compiler.codeaction;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import io.ballerina.projects.CodeActionManager;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Package;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.Project;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.directory.ProjectLoader;
import io.ballerina.projects.environment.Environment;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionContextImpl;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContextImpl;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.projects.plugins.codeaction.DocumentEdit;
import io.ballerina.tools.text.LinePosition;
import org.testng.Assert;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Abstract implementation of codeaction tests.
 */
public abstract class AbstractCodeActionTest {

    private static final Path RESOURCE_PATH = Paths.get("src", "test", "resources");
    private static final Path CONFIG_ROOT = RESOURCE_PATH.resolve("codeaction");
    private static final Path SOURCE_PATH = RESOURCE_PATH.resolve("ballerina_sources");
    private static final Path DISTRIBUTION_PATH = Paths.get("build", "target", "ballerina-distribution");

    private static final Gson GSON = new Gson();

    private static ProjectEnvironmentBuilder getEnvironmentBuilder() {
        Environment environment = EnvironmentBuilder.getBuilder().setBallerinaHome(DISTRIBUTION_PATH).build();
        return ProjectEnvironmentBuilder.getBuilder(environment);
    }

    /**
     * Performs the actual test. This will verify both the code action title/args and the edits made once executed.
     *
     * @param configName Config file name with expected results.
     * @throws IOException File not found, etc.
     */
    protected void performTest(String configName) throws IOException {
        Path configPath = CONFIG_ROOT.resolve(getConfigDir()).resolve(configName);
        JsonObject configJson = new JsonParser().parse(Files.readString(configPath)).getAsJsonObject();

        Path filePath = SOURCE_PATH.resolve(configJson.get("source").getAsString());
        Project project = ProjectLoader.loadProject(filePath, getEnvironmentBuilder());

        Package currentPackage = project.currentPackage();
        PackageCompilation compilation = currentPackage.getCompilation();
        CodeActionManager codeActionManager = compilation.getCodeActionManager();

        DocumentId documentId = project.documentId(filePath);
        Document document = currentPackage.getDefaultModule().document(documentId);

        LinePosition cursorPos = GSON.fromJson(configJson.get("position").getAsJsonObject(), LinePosition.class);
        List<CodeActionInfo> codeActions = compilation.diagnosticResult().diagnostics().stream()
                .filter(diagnostic -> CodeActionUtil.isWithinRange(diagnostic.location().lineRange(), cursorPos) &&
                        filePath.endsWith(diagnostic.location().lineRange().filePath()))
                .flatMap(diagnostic -> {
                    CodeActionContextImpl context = CodeActionContextImpl.from(
                            filePath.toUri().toString(),
                            filePath,
                            cursorPos,
                            document,
                            compilation.getSemanticModel(documentId.moduleId()),
                            diagnostic);
                    return codeActionManager.codeActions(context).stream();
                })
                .collect(Collectors.toList());

        Assert.assertTrue(codeActions.size() > 0, "Expect atleast 1 code action");
        JsonArray expected = configJson.get("expected").getAsJsonArray();
        compareResults(expected, codeActions, filePath, compilation, document);
    }

    protected void compareResults(JsonArray expected, List<CodeActionInfo> codeActions, Path filePath,
                                  PackageCompilation compilation, Document document) {
        expected.forEach(item -> {
            JsonObject expectedCodeAction = item.getAsJsonObject().get("codeaction").getAsJsonObject();

            Optional<CodeActionInfo> found = codeActions.stream()
                    .filter(codeActionInfo -> {
                        JsonObject actualCodeAction = GSON.toJsonTree(codeActionInfo).getAsJsonObject();
                        return actualCodeAction.equals(expectedCodeAction);
                    })
                    .findFirst();
            Assert.assertTrue(found.isPresent(), "Codeaction not found:" + expectedCodeAction.toString());

            List<CodeActionArgument> codeActionArguments = found.get().getArguments().stream()
                    .map(arg -> CodeActionArgument.from(GSON.toJsonTree(arg)))
                    .collect(Collectors.toList());

            CodeActionExecutionContext executionContext = CodeActionExecutionContextImpl.from(
                    filePath.toUri().toString(),
                    filePath,
                    null,
                    document,
                    compilation.getSemanticModel(document.documentId().moduleId()),
                    codeActionArguments);

            List<DocumentEdit> actualEdits = compilation.getCodeActionManager()
                    .executeCodeAction(found.get().getProviderName(), executionContext);

            JsonArray expectedEdits = item.getAsJsonObject().get("edits").getAsJsonArray();
            Assert.assertEquals(actualEdits.size(), expectedEdits.size());

            expectedEdits.forEach(edit -> {
                String expectedFileUri = SOURCE_PATH.resolve(
                        edit.getAsJsonObject().get("fileUri").getAsString()).toUri().toString();
                Optional<DocumentEdit> actualEdit = actualEdits.stream()
                        .filter(docEdit -> docEdit.getFileUri().equals(expectedFileUri))
                        .findFirst();

                Assert.assertTrue(actualEdit.isPresent(), "Edits not found for fileUri: " + expectedFileUri);

                JsonArray validations = edit.getAsJsonObject().get("validations").getAsJsonArray();
                validations.forEach(validation -> {
                    int line = validation.getAsJsonObject().get("line").getAsInt();
                    String text = validation.getAsJsonObject().get("text").getAsString();

                    String actualText = actualEdit.get().getModifiedSyntaxTree().textDocument().line(line).text();
                    Assert.assertEquals(text, actualText,
                            String.format("Text for line %s of file: %s didn't match. (expected: %s, actual: %s)",
                                    line, expectedFileUri, text, actualText));
                });
            });
        });
    }

    protected abstract String getConfigDir();
}
