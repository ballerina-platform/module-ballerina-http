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
import com.google.gson.JsonObject;
import io.ballerina.projects.CodeActionManager;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Package;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.Project;
import io.ballerina.projects.directory.ProjectLoader;
import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionContextImpl;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContextImpl;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.projects.plugins.codeaction.DocumentEdit;
import io.ballerina.stdlib.http.compiler.AbstractLSCompilerPluginTest;
import io.ballerina.tools.text.LinePosition;
import org.testng.Assert;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Abstract implementation of codeaction tests.
 */
public abstract class AbstractCodeActionTest extends AbstractLSCompilerPluginTest {

    private static final Gson GSON = new Gson();
    
    /**
     * Performs the actual test. This will verify both the code action title/args and the edits made once executed.
     *
     * @param filePath    Source file path
     * @param cursorPos   Cursor position
     * @param expected    Expected code action
     * @param expectedSrc File with expected content once the expected codeaction is executed
     * @throws IOException File not found, etc
     */
    protected void performTest(Path filePath, LinePosition cursorPos, CodeActionInfo expected, Path expectedSrc)
            throws IOException {
        Project project = ProjectLoader.loadProject(filePath, getEnvironmentBuilder());
        List<CodeActionInfo> codeActions = getCodeActions(filePath, cursorPos, project);
        Assert.assertFalse(codeActions.isEmpty(), "Expect atleast 1 code action");

        JsonObject expectedCodeAction = GSON.toJsonTree(expected).getAsJsonObject();
        Optional<CodeActionInfo> found = codeActions.stream()
                .filter(codeActionInfo -> {
                    JsonObject actualCodeAction = GSON.toJsonTree(codeActionInfo).getAsJsonObject();
                    return actualCodeAction.equals(expectedCodeAction);
                })
                .findFirst();
        Assert.assertTrue(found.isPresent(), "Codeaction not found:" + expectedCodeAction.toString());

        List<DocumentEdit> actualEdits = executeCodeAction(project, filePath, found.get());
        // Changes to 1 file expected
        Assert.assertEquals(actualEdits.size(), 1, "Expected changes to 1 file");

        String expectedFileUri = filePath.toUri().toString();
        Optional<DocumentEdit> actualEdit = actualEdits.stream()
                .filter(docEdit -> docEdit.getFileUri().equals(expectedFileUri))
                .findFirst();

        Assert.assertTrue(actualEdit.isPresent(), "Edits not found for fileUri: " + expectedFileUri);

        String modifiedSourceCode = actualEdit.get().getModifiedSyntaxTree().toSourceCode();
        String expectedSourceCode = Files.readString(expectedSrc);
        Assert.assertEquals(modifiedSourceCode, expectedSourceCode,
                "Actual source code didn't match expected source code");
    }

    /**
     * Get codeactions for the provided cursor position in the provided source file.
     *
     * @param filePath  Source file path
     * @param cursorPos Cursor position
     * @param project   Project
     * @return List of codeactions for the cursor position
     */
    private List<CodeActionInfo> getCodeActions(Path filePath, LinePosition cursorPos, Project project) {
        Package currentPackage = project.currentPackage();
        PackageCompilation compilation = currentPackage.getCompilation();
        CodeActionManager codeActionManager = compilation.getCodeActionManager();

        DocumentId documentId = project.documentId(filePath);
        Document document = currentPackage.getDefaultModule().document(documentId);

        return compilation.diagnosticResult().diagnostics().stream()
                .filter(diagnostic -> CodeActionUtil.isWithinRange(diagnostic.location().lineRange(), cursorPos) &&
                        filePath.endsWith(diagnostic.location().lineRange().fileName()))
                .flatMap(diagnostic -> {
                    CodeActionContextImpl context = CodeActionContextImpl.from(
                            filePath.toUri().toString(),
                            filePath,
                            cursorPos,
                            document,
                            compilation.getSemanticModel(documentId.moduleId()),
                            diagnostic);
                    return codeActionManager.codeActions(context).getCodeActions().stream();
                })
                .collect(Collectors.toList());
    }

    /**
     * Get the document edits returned when the provided codeaction is executed.
     *
     * @param project    Project
     * @param filePath   Source file path
     * @param codeAction Codeaction to be executed
     * @return List of edits returned by the codeaction execution
     */
    private List<DocumentEdit> executeCodeAction(Project project, Path filePath, CodeActionInfo codeAction) {
        Package currentPackage = project.currentPackage();
        PackageCompilation compilation = currentPackage.getCompilation();

        DocumentId documentId = project.documentId(filePath);
        Document document = currentPackage.getDefaultModule().document(documentId);

        List<CodeActionArgument> codeActionArguments = codeAction.getArguments().stream()
                .map(arg -> CodeActionArgument.from(GSON.toJsonTree(arg)))
                .collect(Collectors.toList());

        CodeActionExecutionContext executionContext = CodeActionExecutionContextImpl.from(
                filePath.toUri().toString(),
                filePath,
                null,
                document,
                compilation.getSemanticModel(document.documentId().moduleId()),
                codeActionArguments);

        return compilation.getCodeActionManager()
                .executeCodeAction(codeAction.getProviderName(), executionContext);
    }
}
