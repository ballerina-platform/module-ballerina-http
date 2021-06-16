package io.ballerina.stdlib.http.compiler.codeaction;

import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.codeaction.CodeAction;
import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.projects.plugins.codeaction.DocumentEdit;
import io.ballerina.stdlib.http.compiler.HttpDiagnosticCodes;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticProperty;
import io.ballerina.tools.text.LineRange;
import io.ballerina.tools.text.TextDocumentChange;
import io.ballerina.tools.text.TextEdit;
import io.ballerina.tools.text.TextRange;
import org.wso2.ballerinalang.compiler.diagnostic.properties.NonCatProperty;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

/**
 * Code action to add resource config to a resource method.
 */
public class AddResourceConfigAnnotation implements CodeAction {

    @Override
    public List<String> supportedDiagnosticCodes() {
        return List.of(HttpDiagnosticCodes.HTTP_HINT_101.getCode());
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext context) {
        Diagnostic diagnostic = context.diagnostic();
        List<DiagnosticProperty<?>> properties = diagnostic.properties();
        if (properties.isEmpty()) {
            return Optional.empty();
        }

        DiagnosticProperty<?> diagnosticProperty = properties.get(0);
        if (!(diagnosticProperty instanceof NonCatProperty) ||
                !(diagnosticProperty.value() instanceof FunctionDefinitionNode)) {
            return Optional.empty();
        }

        FunctionDefinitionNode functionDefinitionNode = (FunctionDefinitionNode) diagnosticProperty.value();

        CodeActionArgument locationArg = CodeActionArgument.from(CodeActionUtil.NODE_LOCATION_KEY,
                functionDefinitionNode.location().lineRange());
        return Optional.of(CodeActionInfo.from("Add `http:ResourceConfig` annotation", List.of(locationArg)));
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
        NonTerminalNode node = CodeActionUtil.findNode(syntaxTree, lineRange);
        if (!(node instanceof FunctionDefinitionNode)) {
            return Collections.emptyList();
        }

        FunctionDefinitionNode functionDefinitionNode = (FunctionDefinitionNode) node;
        if (functionDefinitionNode.metadata().isPresent() &&
                !functionDefinitionNode.metadata().get().annotations().isEmpty()) {
            return Collections.emptyList();
        }

        List<TextEdit> textEdits = new ArrayList<>();

        String insertText = "@http:ResourceConfig {}" +
                System.lineSeparator() +
                " ".repeat(Math.max(0, functionDefinitionNode.lineRange().startLine().offset()));
        TextRange textRange = TextRange.from(functionDefinitionNode.textRange().startOffset(), 0);
        textEdits.add(TextEdit.from(textRange, insertText));
        TextDocumentChange change = TextDocumentChange.from(textEdits.toArray(new TextEdit[0]));
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(syntaxTree, change)));
    }

    @Override
    public String name() {
        return "ADD_RESOURCE_CONFIG_ANNOTATION";
    }
}
