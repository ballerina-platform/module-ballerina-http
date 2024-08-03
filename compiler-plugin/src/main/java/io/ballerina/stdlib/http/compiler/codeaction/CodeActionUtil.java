/*
 * Copyright (c) 2021, WSO2 Inc. (http://wso2.com) All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.ballerina.stdlib.http.compiler.codeaction;

import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.NonTerminalNode;
import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.plugins.codeaction.CodeActionArgument;
import io.ballerina.projects.plugins.codeaction.CodeActionExecutionContext;
import io.ballerina.projects.plugins.codeaction.CodeActionInfo;
import io.ballerina.tools.text.LinePosition;
import io.ballerina.tools.text.LineRange;
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextRange;

import java.util.List;
import java.util.Optional;

import static io.ballerina.stdlib.http.compiler.codeaction.Constants.NODE_LOCATION_KEY;

/**
 * Utilities for code actions.
 */
public class CodeActionUtil {

    private CodeActionUtil() {
    }

    /**
     * Find the node from syntax tree given a symbol.
     *
     * @param syntaxTree Syntax tree
     * @param symbol     Symbol for which node is to be found
     * @return Node for the symbol
     */
    public static NonTerminalNode findNode(SyntaxTree syntaxTree, Symbol symbol) {
        if (symbol.getLocation().isEmpty()) {
            return null;
        }

        TextDocument textDocument = syntaxTree.textDocument();
        LineRange symbolRange = symbol.getLocation().get().lineRange();
        int start = textDocument.textPositionFrom(symbolRange.startLine());
        int end = textDocument.textPositionFrom(symbolRange.endLine());
        return ((ModulePartNode) syntaxTree.rootNode()).findNode(TextRange.from(start, end - start), true);
    }

    /**
     * Find a node in syntax tree by line range.
     *
     * @param syntaxTree Syntax tree
     * @param lineRange  line range
     * @return Node
     */
    public static NonTerminalNode findNode(SyntaxTree syntaxTree, LineRange lineRange) {
        if (lineRange == null) {
            return null;
        }

        TextDocument textDocument = syntaxTree.textDocument();
        int start = textDocument.textPositionFrom(lineRange.startLine());
        int end = textDocument.textPositionFrom(lineRange.endLine());
        return ((ModulePartNode) syntaxTree.rootNode()).findNode(TextRange.from(start, end - start), true);
    }

    /**
     * Check if provided position is within the provided line range.
     *
     * @param lineRange Line range
     * @param pos       Position
     * @return True if position is within the provided line range
     */
    public static boolean isWithinRange(LineRange lineRange, LinePosition pos) {
        int sLine = lineRange.startLine().line();
        int sCol = lineRange.startLine().offset();
        int eLine = lineRange.endLine().line();
        int eCol = lineRange.endLine().offset();

        return ((sLine == eLine && pos.line() == sLine) &&
                (pos.offset() >= sCol && pos.offset() <= eCol)
        ) || ((sLine != eLine) && (pos.line() > sLine && pos.line() < eLine ||
                pos.line() == eLine && pos.offset() <= eCol ||
                pos.line() == sLine && pos.offset() >= sCol
        ));
    }

    /**
     * Get code action info with location.
     *
     * @param node  Node
     * @param title Title
     * @return Code action info with location
     */
    public static Optional<CodeActionInfo> getCodeActionInfoWithLocation(NonTerminalNode node, String title) {
        CodeActionArgument locationArg = CodeActionArgument.from(NODE_LOCATION_KEY, node.location().lineRange());
        return Optional.of(CodeActionInfo.from(title, List.of(locationArg)));
    }

    /**
     * Get line range from location key.
     *
     * @param context Code action execution context
     * @return Line range
     */
    public static Optional<LineRange> getLineRangeFromLocationKey(CodeActionExecutionContext context) {
        for (CodeActionArgument argument : context.arguments()) {
            if (NODE_LOCATION_KEY.equals(argument.key())) {
                return Optional.of(argument.valueAs(LineRange.class));
            }
        }
        return Optional.empty();
    }
}
