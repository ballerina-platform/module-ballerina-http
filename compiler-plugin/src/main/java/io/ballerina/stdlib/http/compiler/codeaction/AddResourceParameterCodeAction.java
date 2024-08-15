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

import io.ballerina.compiler.syntax.tree.FunctionSignatureNode;
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.codeaction.CodeAction;
import io.ballerina.projects.plugins.codeaction.CodeActionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.projects.plugins.codeaction.DocumentEdit;
import io.ballerina.stdlib.http.compiler.Constants;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.text.LinePosition;
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
 * Abstract implementation of code action to add a parameter to the resource signature.
 */
public abstract class AddResourceParameterCodeAction implements CodeAction {
    @Override
    public List<String> supportedDiagnosticCodes() {
        return List.of(diagnosticCode());
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext context) {
        Diagnostic diagnostic = context.diagnostic();
        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();
        NonTerminalNode node = CodeActionUtil.findNode(syntaxTree, diagnostic.location().lineRange());
        if (!node.kind().equals(SyntaxKind.FUNCTION_SIGNATURE)) {
            return Optional.empty();
        }
        Optional<LinePosition> cursorPosition = context.cursorPosition();
        if (cursorPosition.isEmpty()) {
            return Optional.empty();
        }
        Optional<ReturnTypeDescriptorNode> returnNode = ((FunctionSignatureNode) node).returnTypeDesc();
        if (returnNode.isPresent() && CodeActionUtil.isWithinRange(returnNode.get().lineRange(),
                cursorPosition.get())) {
            return Optional.empty();
        }
        return getCodeActionInfoWithLocation(node, String.format("Add %s parameter", paramKind()));
    }

    @Override
    public List<DocumentEdit> execute(CodeActionExecutionContext context) {
        Optional<LineRange> lineRange = getLineRangeFromLocationKey(context);

        if (lineRange.isEmpty()) {
            return Collections.emptyList();
        }

        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();
        NonTerminalNode node = CodeActionUtil.findNode(syntaxTree, lineRange.get());

        if (!node.kind().equals(SyntaxKind.FUNCTION_SIGNATURE)) {
            return Collections.emptyList();
        }

        String payloadParam = paramSignature();
        int start = ((FunctionSignatureNode) node).openParenToken().position() + 1;
        int end = ((FunctionSignatureNode) node).closeParenToken().position();
        if (end - start != 0) {
            payloadParam = Constants.COMMA_WITH_SPACE + payloadParam;
        }
        TextRange textRange = TextRange.from(end, 0);

        List<TextEdit> textEdits = new ArrayList<>();
        textEdits.add(TextEdit.from(textRange, payloadParam));
        TextDocumentChange change = TextDocumentChange.from(textEdits.toArray(new TextEdit[0]));
        TextDocument modifiedTextDocument = syntaxTree.textDocument().apply(change);
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(modifiedTextDocument)));
    }

    protected abstract String diagnosticCode();

    protected abstract String paramKind();

    protected abstract String paramSignature();
}
