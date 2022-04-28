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

import io.ballerina.compiler.syntax.tree.ClassDefinitionNode;
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.codeaction.CodeAction;
import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.projects.plugins.codeaction.DocumentEdit;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.text.LineRange;
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextDocumentChange;
import io.ballerina.tools.text.TextEdit;
import io.ballerina.tools.text.TextRange;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.codeaction.Constants.ERROR;
import static io.ballerina.stdlib.http.compiler.codeaction.Constants.IS_ERROR_INTERCEPTOR_TYPE;
import static io.ballerina.stdlib.http.compiler.codeaction.Constants.NODE_LOCATION_KEY;

/**
 * Abstract implementation of code action to add interceptor method template.
 */
public abstract class AddInterceptorMethodCodeAction implements CodeAction {
    @Override
    public List<String> supportedDiagnosticCodes() {
        return List.of(diagnosticCode());
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext context) {
        Diagnostic diagnostic = context.diagnostic();
        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();
        NonTerminalNode node = CodeActionUtil.findNode(syntaxTree, diagnostic.location().lineRange());
        CodeActionArgument location = CodeActionArgument.from(NODE_LOCATION_KEY, node.lineRange());
        CodeActionArgument isError = CodeActionArgument.from(IS_ERROR_INTERCEPTOR_TYPE,
                                                             diagnostic.message().contains(ERROR));
        CodeActionInfo info = CodeActionInfo.from(String.format("Add interceptor %s method", methodKind()),
                                                  List.of(location, isError));
        return Optional.of(info);
    }

    @Override
    public List<DocumentEdit> execute(CodeActionExecutionContext context) {
        LineRange lineRange = null;
        boolean isErrorInterceptor = false;
        for (CodeActionArgument arg : context.arguments()) {
            if (NODE_LOCATION_KEY.equals(arg.key())) {
                lineRange = arg.valueAs(LineRange.class);
            }
            if (IS_ERROR_INTERCEPTOR_TYPE.equals(arg.key())) {
                isErrorInterceptor = arg.valueAs(boolean.class);
            }
        }
        if (lineRange == null) {
            return Collections.emptyList();
        }

        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();
        NonTerminalNode node = CodeActionUtil.findNode(syntaxTree, lineRange);
        if (!node.kind().equals(SyntaxKind.CLASS_DEFINITION)) {
            return Collections.emptyList();
        }

        TextRange textRange = TextRange.from(((ClassDefinitionNode) node).closeBrace().textRange().startOffset(), 0);
        String method = methodSignature(isErrorInterceptor);
        List<TextEdit> textEdits = new ArrayList<>();
        textEdits.add(TextEdit.from(textRange, method));
        TextDocumentChange change = TextDocumentChange.from(textEdits.toArray(new TextEdit[0]));
        TextDocument modifiedTextDocument = syntaxTree.textDocument().apply(change);
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(modifiedTextDocument)));
    }

    protected abstract String diagnosticCode();

    protected abstract String methodKind();

    protected abstract String methodSignature(boolean isErrorInterceptor);
}
