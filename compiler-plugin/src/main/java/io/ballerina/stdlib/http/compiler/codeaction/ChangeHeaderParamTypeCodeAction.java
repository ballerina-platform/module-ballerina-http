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

import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.syntax.tree.IncludedRecordParameterNode;
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.RequiredParameterNode;
import io.ballerina.compiler.syntax.tree.RestParameterNode;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.codeaction.CodeAction;
import io.ballerina.projects.plugins.codeaction.CodeActionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.projects.plugins.codeaction.DocumentEdit;
import io.ballerina.stdlib.http.compiler.HttpDiagnostic;
import io.ballerina.tools.diagnostics.DiagnosticProperty;
import io.ballerina.tools.text.LineRange;
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextDocumentChange;
import io.ballerina.tools.text.TextEdit;
import io.ballerina.tools.text.TextRange;
import org.wso2.ballerinalang.compiler.diagnostic.properties.BSymbolicProperty;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.codeaction.CodeActionUtil.getCodeActionInfoWithLocation;
import static io.ballerina.stdlib.http.compiler.codeaction.CodeActionUtil.getLineRangeFromLocationKey;

/**
 * Abstract implementation of code action to change a resource header param's type.
 */
public abstract class ChangeHeaderParamTypeCodeAction implements CodeAction {

    @Override
    public List<String> supportedDiagnosticCodes() {
        return List.of(HttpDiagnostic.HTTP_109.getCode());
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext context) {
        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();
        List<DiagnosticProperty<?>> properties = context.diagnostic().properties();
        if (properties.isEmpty()) {
            return Optional.empty();
        }

        DiagnosticProperty<?> diagnosticProperty = properties.get(0);
        if (!(diagnosticProperty instanceof BSymbolicProperty) || 
                !(diagnosticProperty.value() instanceof ParameterSymbol parameterSymbol)) {
            return Optional.empty();
        }

        Optional<NonTerminalNode> nonTerminalNode = parameterSymbol.getLocation()
                .flatMap(location -> Optional.ofNullable(CodeActionUtil.findNode(syntaxTree, parameterSymbol)));
        return nonTerminalNode.flatMap(terminalNode -> getCodeActionInfoWithLocation(terminalNode,
                String.format("Change header param to '%s'", headerParamType())));

    }

    @Override
    public List<DocumentEdit> execute(CodeActionExecutionContext context) {
        Optional<LineRange> lineRange = getLineRangeFromLocationKey(context);

        if (lineRange.isEmpty()) {
            return Collections.emptyList();
        }

        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();
        NonTerminalNode node = CodeActionUtil.findNode(syntaxTree, lineRange.get());

        TextRange typeNodeTextRange;
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
        TextDocument modifiedTextDocument = syntaxTree.textDocument().apply(change);
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(modifiedTextDocument)));
    }
    
    protected abstract String headerParamType();
}
