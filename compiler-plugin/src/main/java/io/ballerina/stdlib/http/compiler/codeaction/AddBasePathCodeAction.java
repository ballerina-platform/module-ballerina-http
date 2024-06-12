/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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
package io.ballerina.stdlib.http.compiler.codeaction;

import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.codeaction.CodeAction;
import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.projects.plugins.codeaction.DocumentEdit;
import io.ballerina.stdlib.http.compiler.HttpDiagnosticCodes;
import io.ballerina.tools.text.LineRange;
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextDocumentChange;
import io.ballerina.tools.text.TextEdit;
import io.ballerina.tools.text.TextRange;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static io.ballerina.stdlib.http.compiler.codeaction.Constants.EXPECTED_BASE_PATH;
import static io.ballerina.stdlib.http.compiler.codeaction.Constants.NODE_LOCATION_KEY;

/**
 * Represents a code action to add the expected base path to the service declaration
 * from the service contract type.
 *
 * @since 2.12.0
 */
public class AddBasePathCodeAction implements CodeAction {
    @Override
    public List<String> supportedDiagnosticCodes() {
        return List.of(HttpDiagnosticCodes.HTTP_154.getCode());
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext context) {
        NonTerminalNode node = CodeActionUtil.findNode(context.currentDocument().syntaxTree(),
                context.diagnostic().location().lineRange());
        String diagnosticMsg = context.diagnostic().message();
        Pattern pattern = Pattern.compile("Expected base path is (.*)");
        Matcher matcher = pattern.matcher(diagnosticMsg);
        String basePath = "";
        if (matcher.find()) {
            basePath = matcher.group(1);
        }
        CodeActionArgument basePathArg = CodeActionArgument.from(EXPECTED_BASE_PATH, basePath);
        CodeActionArgument locationArg = CodeActionArgument.from(NODE_LOCATION_KEY, node.location().lineRange());
        return Optional.of(CodeActionInfo.from("Add base path from the service contract",
                List.of(locationArg, basePathArg)));
    }

    @Override
    public List<DocumentEdit> execute(CodeActionExecutionContext context) {
        LineRange lineRange = null;
        String basePath = "";
        for (CodeActionArgument argument : context.arguments()) {
            if (NODE_LOCATION_KEY.equals(argument.key())) {
                lineRange = argument.valueAs(LineRange.class);
            }
            if (EXPECTED_BASE_PATH.equals(argument.key())) {
                basePath = argument.valueAs(String.class);
            }
        }

        if (lineRange == null || basePath.isEmpty()) {
            return Collections.emptyList();
        }

        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();
        TextDocument textDocument = syntaxTree.textDocument();
        int end = textDocument.textPositionFrom(lineRange.endLine());

        List<TextEdit> textEdits = new ArrayList<>();
        textEdits.add(TextEdit.from(TextRange.from(end, 0), " \"" + basePath + "\""));
        TextDocumentChange change = TextDocumentChange.from(textEdits.toArray(new TextEdit[0]));
        TextDocument modifiedTextDocument = syntaxTree.textDocument().apply(change);
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(modifiedTextDocument)));
    }

    @Override
    public String name() {
        return "ADD_BASE_PATH";
    }
}
