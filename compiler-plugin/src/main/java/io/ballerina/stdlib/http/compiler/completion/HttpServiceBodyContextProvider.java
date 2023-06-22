/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
package io.ballerina.stdlib.http.compiler.completion;

import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.projects.plugins.completion.CompletionContext;
import io.ballerina.projects.plugins.completion.CompletionException;
import io.ballerina.projects.plugins.completion.CompletionItem;
import io.ballerina.projects.plugins.completion.CompletionProvider;
import io.ballerina.projects.plugins.completion.CompletionUtil;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Completion provider for Http services.
 */
public class HttpServiceBodyContextProvider implements CompletionProvider<ServiceDeclarationNode> {

    private static final String NAME = "HttpServiceBodyProvider";


    @Override
    public String name() {
        return NAME;
    }

    @Override
    public List<CompletionItem> getCompletions(CompletionContext completionContext,
                                               ServiceDeclarationNode serviceDeclarationNode)
            throws CompletionException {

        //Add resource function snippets for get,post,delete,put,head,and options http methods.
        return Constants.METHODS.stream().map(method -> {
            String insertText = "resource function " + method + " "
                    + CompletionUtil.getPlaceHolderText(1, "path")
                    + "(" + CompletionUtil.getPlaceHolderText(2) + ") " + CompletionUtil.getPlaceHolderText(3)
                    + "{" + CompletionUtil.LINE_BREAK + CompletionUtil.PADDING + CompletionUtil.getPlaceHolderText(4)
                    + CompletionUtil.LINE_BREAK + "}";
            String label = "resource function " + method + " path()";
            return new CompletionItem(label, insertText, CompletionItem.Priority.HIGH);
        }).collect(Collectors.toList());
    }

    @Override
    public List<Class<ServiceDeclarationNode>> getSupportedNodes() {
        return List.of(ServiceDeclarationNode.class);
    }
}
