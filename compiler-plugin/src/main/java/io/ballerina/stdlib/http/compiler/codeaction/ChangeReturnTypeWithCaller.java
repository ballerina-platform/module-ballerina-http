package io.ballerina.stdlib.http.compiler.codeaction;

import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.ReturnTypeDescriptorNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
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

public class ChangeReturnTypeWithCaller implements CodeAction {

    @Override
    public List<String> supportedDiagnosticCodes() {
        return List.of(HttpDiagnosticCodes.HTTP_118.getCode());
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext context) {
        NonTerminalNode node = CodeActionUtil.findNode(context.currentDocument().syntaxTree(),
                context.diagnostic().location().lineRange());
        if (node == null || node.parent().kind() != SyntaxKind.RETURN_TYPE_DESCRIPTOR) {
            return Optional.empty();
        }

        CodeActionArgument locationArg = CodeActionArgument.from(CodeActionUtil.NODE_LOCATION_KEY,
                node.location().lineRange());
        return Optional.of(CodeActionInfo.from("Change return type to 'error?'", List.of(locationArg)));
    }

    @Override
    public List<DocumentEdit> execute(CodeActionExecutionContext context) {
        LineRange lineRange = null;
        for (CodeActionArgument argument : context.arguments()) {
            if (CodeActionUtil.NODE_LOCATION_KEY.equals(argument.key())) {
                lineRange = argument.valueAs(LineRange.class);
            }
        }

        if (lineRange == null) {
            return Collections.emptyList();
        }

        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();
        TextDocument textDocument = syntaxTree.textDocument();

        int start = textDocument.textPositionFrom(lineRange.startLine());
        int end = textDocument.textPositionFrom(lineRange.endLine());

        List<TextEdit> textEdits = new ArrayList<>();
        textEdits.add(TextEdit.from(TextRange.from(start, end - start), "error?"));
        TextDocumentChange change = TextDocumentChange.from(textEdits.toArray(new TextEdit[0]));
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(syntaxTree, change)));
    }

    @Override
    public String name() {
        return "CHANGE_RETURN_TYPE_WITH_CALLER";
    }
}
