/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.codeaction.CodeAction;
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

import static io.ballerina.stdlib.http.compiler.codeaction.CodeActionUtil.getCodeActionInfoWithLocation;
import static io.ballerina.stdlib.http.compiler.codeaction.CodeActionUtil.getLineRangeFromLocationKey;

/**
 * CodeAction to add response cache configuration.
 */
public class AddResponseCacheConfigCodeAction implements CodeAction {
    @Override
    public List<String> supportedDiagnosticCodes() {
        return List.of(HttpDiagnosticCodes.HTTP_HINT_104.getCode());
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext context) {
        NonTerminalNode node = CodeActionUtil.findNode(context.currentDocument().syntaxTree(),
                context.diagnostic().location().lineRange());
        if (node == null || node.parent().kind() != SyntaxKind.RETURN_TYPE_DESCRIPTOR) {
            return Optional.empty();
        }

        return getCodeActionInfoWithLocation(node, "Add response cache configuration");
    }

    @Override
    public List<DocumentEdit> execute(CodeActionExecutionContext context) {
        Optional<LineRange> lineRange = getLineRangeFromLocationKey(context);

        if (lineRange.isEmpty()) {
            return Collections.emptyList();
        }

        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();
        NonTerminalNode node = CodeActionUtil.findNode(syntaxTree, lineRange.get());

        String cacheConfig = "@http:Cache ";
        int start = node.position();
        TextRange textRange = TextRange.from(start, 0);

        List<TextEdit> textEdits = new ArrayList<>();
        textEdits.add(TextEdit.from(textRange, cacheConfig));
        TextDocumentChange change = TextDocumentChange.from(textEdits.toArray(new TextEdit[0]));
        TextDocument modifiedTextDocument = syntaxTree.textDocument().apply(change);
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(modifiedTextDocument)));
    }

    @Override
    public String name() {
        return "ADD_RESPONSE_CACHE_CONFIG";
    }
}
