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

import io.ballerina.compiler.api.SemanticModel;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ObjectTypeSymbol;
import io.ballerina.compiler.api.symbols.ResourceMethodSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.resourcepath.ResourcePath;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.compiler.syntax.tree.TypeDescriptorNode;
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
import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static io.ballerina.stdlib.http.compiler.HttpServiceContractResourceValidator.constructResourcePathName;
import static io.ballerina.stdlib.http.compiler.HttpServiceValidator.getServiceContractTypeDesc;
import static io.ballerina.stdlib.http.compiler.codeaction.Constants.LS;
import static io.ballerina.stdlib.http.compiler.codeaction.Constants.NODE_LOCATION_KEY;

public class ImplementServiceContract implements CodeAction {
    @Override
    public List<String> supportedDiagnosticCodes() {
        return List.of(HttpDiagnosticCodes.HTTP_HINT_105.getCode());
    }

    @Override
    public Optional<CodeActionInfo> codeActionInfo(CodeActionContext context) {
        NonTerminalNode node = CodeActionUtil.findNode(context.currentDocument().syntaxTree(),
                context.diagnostic().location().lineRange());
        if (!node.kind().equals(SyntaxKind.SERVICE_DECLARATION)) {
            return Optional.empty();
        }

        CodeActionArgument locationArg = CodeActionArgument.from(NODE_LOCATION_KEY, node.location().lineRange());
        return Optional.of(CodeActionInfo.from("Implement all the resource methods from service contract",
                List.of(locationArg)));
    }

    @Override
    public List<DocumentEdit> execute(CodeActionExecutionContext context) {
        LineRange lineRange = null;
        for (CodeActionArgument argument : context.arguments()) {
            if (NODE_LOCATION_KEY.equals(argument.key())) {
                lineRange = argument.valueAs(LineRange.class);
            }
        }

        if (lineRange == null) {
            return Collections.emptyList();
        }

        SyntaxTree syntaxTree = context.currentDocument().syntaxTree();
        SemanticModel semanticModel = context.currentSemanticModel();
        NonTerminalNode node = CodeActionUtil.findNode(syntaxTree, lineRange);
        if (!node.kind().equals(SyntaxKind.SERVICE_DECLARATION)) {
            return Collections.emptyList();
        }

        Optional<TypeDescriptorNode> serviceTypeDesc = getServiceContractTypeDesc(semanticModel,
                (ServiceDeclarationNode) node);
        if (serviceTypeDesc.isEmpty()) {
            return Collections.emptyList();
        }

        Optional<Symbol> serviceTypeSymbol = semanticModel.symbol(serviceTypeDesc.get());
        if (serviceTypeSymbol.isEmpty() ||
                !(serviceTypeSymbol.get() instanceof TypeReferenceTypeSymbol serviceTypeRef)) {
            return Collections.emptyList();
        }

        TypeSymbol serviceTypeRefSymbol = serviceTypeRef.typeDescriptor();
        if (!(serviceTypeRefSymbol instanceof ObjectTypeSymbol serviceObjTypeSymbol)) {
            return Collections.emptyList();
        }

        NodeList<Node> members = ((ServiceDeclarationNode) node).members();
        List<String> existingMethods = new ArrayList<>();
        for (Node member : members) {
            if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                Optional<Symbol> functionDefinitionSymbol = semanticModel.symbol(member);
                if (functionDefinitionSymbol.isEmpty() ||
                        !(functionDefinitionSymbol.get() instanceof ResourceMethodSymbol resourceMethodSymbol)) {
                    continue;
                }
                ResourcePath resourcePath = resourceMethodSymbol.resourcePath();
                existingMethods.add(resourceMethodSymbol.getName().orElse("") + " " +
                        constructResourcePathName(resourcePath));
            }
        }

        Map<String, MethodSymbol> methodSymbolMap = serviceObjTypeSymbol.methods();
        StringBuilder methods = new StringBuilder();
        for (Map.Entry<String, MethodSymbol> entry : methodSymbolMap.entrySet()) {
            if (existingMethods.contains(entry.getKey())) {
                continue;
            }
            MethodSymbol methodSymbol = entry.getValue();
            if (methodSymbol instanceof ResourceMethodSymbol resourceMethodSymbol) {
                methods.append(getMethodSignature(resourceMethodSymbol));
            }
        }

        TextRange textRange = TextRange.from(((ServiceDeclarationNode) node).closeBraceToken().
                textRange().startOffset(), 0);
        List<TextEdit> textEdits = new ArrayList<>();
        textEdits.add(TextEdit.from(textRange, methods.toString()));
        TextDocumentChange change = TextDocumentChange.from(textEdits.toArray(new TextEdit[0]));
        TextDocument modifiedTextDocument = syntaxTree.textDocument().apply(change);
        return Collections.singletonList(new DocumentEdit(context.fileUri(), SyntaxTree.from(modifiedTextDocument)));
    }

    private String getMethodSignature(ResourceMethodSymbol resourceMethodSymbol) {
        return LS + "\t" + sanitizePackageNames(resourceMethodSymbol.signature()) + " {" + LS + LS + "\t}" + LS;
    }

    private String sanitizePackageNames(String input) {
        Pattern pattern = Pattern.compile("(\\w+)/(\\w+:)(\\d+.\\d+.\\d+):");
        Matcher matcher = pattern.matcher(input);
        return matcher.replaceAll("$2");
    }

    @Override
    public String name() {
        return "IMPLEMENT_SERVICE_CONTRACT";
    }
}
