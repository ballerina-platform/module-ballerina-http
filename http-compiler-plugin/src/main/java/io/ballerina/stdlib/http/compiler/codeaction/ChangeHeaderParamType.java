package io.ballerina.stdlib.http.compiler.codeaction;

import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.syntax.tree.IncludedRecordParameterNode;
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.RequiredParameterNode;
import io.ballerina.compiler.syntax.tree.RestParameterNode;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.codeaction.CodeAction;
import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.projects.plugins.codeaction.DocumentEdit;
import io.ballerina.stdlib.http.compiler.HttpDiagnosticCodes;
import io.ballerina.tools.diagnostics.DiagnosticProperty;
import io.ballerina.tools.text.LineRange;
import io.ballerina.tools.text.TextDocumentChange;
import io.ballerina.tools.text.TextEdit;
import io.ballerina.tools.text.TextRange;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BSymbolicProperty;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

/**
 * Abstract implementation of code action to change a resource header param's type.
 */
public abstract class ChangeHeaderParamType implements CodeAction {

    @Override
    public List<String> supportedDiagnosticCodes() {
        return List.of(HttpDiagnosticCodes.HTTP_109.getCode());
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext context) {
        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();
        List<DiagnosticProperty<?>> properties = context.diagnostic().properties();
        if (properties.isEmpty()) {
            return Optional.empty();
        }

        DiagnosticProperty<?> diagnosticProperty = properties.get(0);
        if (!(diagnosticProperty instanceof BSymbolicProperty) || !(diagnosticProperty.value() instanceof ParameterSymbol)) {
            return Optional.empty();
        }

        ParameterSymbol parameterSymbol = (ParameterSymbol) diagnosticProperty.value();
        Optional<NonTerminalNode> nonTerminalNode = parameterSymbol.getLocation()
                .flatMap(location -> Optional.ofNullable(CodeActionUtil.findNode(syntaxTree, parameterSymbol)));
        if (nonTerminalNode.isEmpty()) {
            return Optional.empty();
        }

        CodeActionArgument locationArg = CodeActionArgument.from(CodeActionUtil.NODE_LOCATION_KEY, nonTerminalNode.get().location().lineRange());
        return Optional.of(CodeActionInfo.from(String.format("Change header param to '%s'", headerParamType()),
                List.of(locationArg)));
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

        TextRange typeNodeTextRange = null;
        switch (node.kind()) {
            case REQUIRED_PARAM:
                typeNodeTextRange = ((RequiredParameterNode) node).typeName().textRange();
                break;
            case REST_PARAM:
                typeNodeTextRange = ((RestParameterNode) node).typeName().textRange();
                break;
            case INCLUDED_RECORD_PARAM:
                typeNodeTextRange = ((IncludedRecordParameterNode) node).typeName().textRange();
                break;
            default:
                return Collections.emptyList();
        }

        List<TextEdit> textEdits = new ArrayList<>();
        textEdits.add(TextEdit.from(typeNodeTextRange, headerParamType()));
        TextDocumentChange change = TextDocumentChange.from(textEdits.toArray(new TextEdit[0]));
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(syntaxTree, change)));
    }

    private void checkInvalidHeaderParameterNode(NonTerminalNode node) {

    }

    protected abstract String headerParamType();
}
