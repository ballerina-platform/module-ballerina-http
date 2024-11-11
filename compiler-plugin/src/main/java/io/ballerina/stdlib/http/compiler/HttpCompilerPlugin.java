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

package io.ballerina.stdlib.http.compiler;

import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.projects.plugins.CompilerPlugin;
import io.ballerina.projects.plugins.CompilerPluginContext;
import io.ballerina.projects.plugins.codeaction.CodeAction;
import io.ballerina.projects.plugins.completion.CompletionProvider;
import io.ballerina.scan.ScannerContext;
import io.ballerina.stdlib.http.compiler.codeaction.AddHeaderParameterCodeAction;
import io.ballerina.stdlib.http.compiler.codeaction.AddInterceptorRemoteMethodCodeAction;
import io.ballerina.stdlib.http.compiler.codeaction.AddInterceptorResourceMethodCodeAction;
import io.ballerina.stdlib.http.compiler.codeaction.AddPayloadParameterCodeAction;
import io.ballerina.stdlib.http.compiler.codeaction.AddResponseCacheConfigCodeAction;
import io.ballerina.stdlib.http.compiler.codeaction.AddResponseContentTypeCodeAction;
import io.ballerina.stdlib.http.compiler.codeaction.ChangeHeaderParamTypeToStringArrayCodeAction;
import io.ballerina.stdlib.http.compiler.codeaction.ChangeHeaderParamTypeToStringCodeAction;
import io.ballerina.stdlib.http.compiler.codeaction.ChangeReturnTypeWithCallerCodeAction;
import io.ballerina.stdlib.http.compiler.codeaction.ImplementServiceContract;
import io.ballerina.stdlib.http.compiler.codemodifier.HttpServiceModifier;
import io.ballerina.stdlib.http.compiler.completion.HttpServiceBodyContextProvider;
import io.ballerina.stdlib.http.compiler.staticcodeanalyzer.HttpStaticCodeAnalyzer;

import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.http.compiler.Constants.SCANNER_CONTEXT;

/**
 * The compiler plugin implementation for Ballerina Http package.
 */
public class HttpCompilerPlugin extends CompilerPlugin {

    @Override
    public void init(CompilerPluginContext context) {
        Map<String, Object> ctxData = context.userData();
        ctxData.put("HTTP_CODE_MODIFIER_EXECUTED", false);
        context.addCodeModifier(new HttpServiceModifier(ctxData));
        context.addCodeAnalyzer(new HttpServiceAnalyzer(ctxData));
        getCodeActions().forEach(context::addCodeAction);
        getCompletionProviders().forEach(context::addCompletionProvider);
        Object object = context.userData().get(SCANNER_CONTEXT);
        if (object instanceof ScannerContext scannerContext) {
            context.addCodeAnalyzer(new HttpStaticCodeAnalyzer(scannerContext.getReporter()));
        }
    }

    private List<CodeAction> getCodeActions() {
        return List.of(
                new ChangeHeaderParamTypeToStringCodeAction(),
                new ChangeHeaderParamTypeToStringArrayCodeAction(),
                new ChangeReturnTypeWithCallerCodeAction(),
                new AddPayloadParameterCodeAction(),
                new AddHeaderParameterCodeAction(),
                new AddResponseContentTypeCodeAction(),
                new AddResponseCacheConfigCodeAction(),
                new AddInterceptorResourceMethodCodeAction(),
                new AddInterceptorRemoteMethodCodeAction(),
                new ImplementServiceContract()
        );
    }

    private List<CompletionProvider<? extends Node>> getCompletionProviders() {
        return List.of(new HttpServiceBodyContextProvider());
    }
}
