/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
package io.ballerina.stdlib.http.compiler.completion;

import com.google.gson.Gson;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.projects.CompletionManager;
import io.ballerina.projects.CompletionResult;
import io.ballerina.projects.Document;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;
import io.ballerina.projects.Package;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.Project;
import io.ballerina.projects.directory.ProjectLoader;
import io.ballerina.projects.plugins.completion.CompletionContext;
import io.ballerina.projects.plugins.completion.CompletionContextImpl;
import io.ballerina.projects.plugins.completion.CompletionException;
import io.ballerina.projects.plugins.completion.CompletionItem;
import io.ballerina.stdlib.http.compiler.AbstractLSCompilerPluginTest;
import io.ballerina.tools.text.LinePosition;
import io.ballerina.tools.text.TextRange;
import org.testng.Assert;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Abstract implementation of completion tests.
 */
public abstract class AbstractCompletionTest extends AbstractLSCompilerPluginTest {

    private static final Gson GSON = new Gson();


    @Test(dataProvider = "completion-data-provider")
    protected void test(String filePath, int line, int offset, String configFile)
            throws IOException {

        Path sourceFilePath = Path.of(filePath);
        Path configfilePath = Path.of(configFile);
        TestConfig expectedList =
                GSON.fromJson(Files.newBufferedReader(configfilePath), TestConfig.class);
        List<CompletionItem> expectedItems = expectedList.getItems();
        LinePosition cursorPos = LinePosition.from(line, offset);

        Project project = ProjectLoader.loadProject(sourceFilePath, getEnvironmentBuilder());
        CompletionResult completionResult = getCompletions(sourceFilePath, cursorPos, project);
        List<CompletionItem> actualItems = completionResult.getCompletionItems();
        List<CompletionException> errors = completionResult.getErrors();
        Assert.assertTrue(errors.isEmpty());
        Assert.assertTrue(compareCompletionItems(actualItems, expectedItems));
    }

    private static boolean compareCompletionItems(List<CompletionItem> actualItems,
                                                  List<CompletionItem> expectedItems) {
        List<String> actualList = actualItems.stream()
                .map(AbstractCompletionTest::getCompletionItemPropertyString)
                .collect(Collectors.toList());
        List<String> expectedList = expectedItems.stream()
                .map(AbstractCompletionTest::getCompletionItemPropertyString)
                .collect(Collectors.toList());
        return actualList.containsAll(expectedList) && actualItems.size() == expectedItems.size();
    }

    private static String getCompletionItemPropertyString(CompletionItem completionItem) {
        // Here we replace the Windows specific \r\n to \n for evaluation only
        String additionalTextEdits = "";
        if (completionItem.getAdditionalTextEdits() != null && !completionItem.getAdditionalTextEdits().isEmpty()) {
            additionalTextEdits = "," + GSON.toJson(completionItem.getAdditionalTextEdits());
        }
        return ("{" +
                completionItem.getInsertText() + "," +
                completionItem.getLabel() + "," +
                completionItem.getPriority() +
                additionalTextEdits +
                "}").replace("\r\n", "\n").replace("\\r\\n", "\\n");
    }

    private CompletionResult getCompletions(Path filePath, LinePosition cursorPos, Project project) {

        Package currentPackage = project.currentPackage();
        PackageCompilation compilation = currentPackage.getCompilation();
        CompletionManager completionManager = compilation.getCompletionManager();

        DocumentId documentId = project.documentId(filePath);
        Document document = currentPackage.getDefaultModule().document(documentId);
        Module module = project.currentPackage().module(documentId.moduleId());

        int cursorPositionInTree = document.textDocument().textPositionFrom(cursorPos);
        TextRange range = TextRange.from(cursorPositionInTree, 0);
        NonTerminalNode nodeAtCursor = ((ModulePartNode) document.syntaxTree().rootNode()).findNode(range);

        CompletionContext completionContext = CompletionContextImpl.from(filePath.toUri().toString(),
                filePath, cursorPos, cursorPositionInTree, nodeAtCursor, document,
                module.getCompilation().getSemanticModel());

        return completionManager.completions(completionContext);
    }

    @DataProvider(name = "completion-data-provider")
    public abstract Object[][] dataProvider();

    /**
     * Represents the completion test config.
     */
    public static class TestConfig {
        private List<CompletionItem> items;

        public void setItems(List<CompletionItem> items) {
            this.items = items;
        }

        public List<CompletionItem> getItems() {
            return items;
        }
    }

}
