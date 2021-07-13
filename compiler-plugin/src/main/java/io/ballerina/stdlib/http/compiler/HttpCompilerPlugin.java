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

import io.ballerina.projects.plugins.CompilerPlugin;
import io.ballerina.projects.plugins.CompilerPluginContext;
import io.ballerina.projects.plugins.codeaction.CodeAction;
import io.ballerina.stdlib.http.compiler.codeaction.AddResourceConfigAnnotation;
import io.ballerina.stdlib.http.compiler.codeaction.ChangeHeaderParamTypeToString;
import io.ballerina.stdlib.http.compiler.codeaction.ChangeHeaderParamTypeToStringArray;

import java.util.List;

/**
 * The compiler plugin implementation for Ballerina Http package.
 */
public class HttpCompilerPlugin extends CompilerPlugin {

    @Override
    public void init(CompilerPluginContext context) {
        context.addCodeAnalyzer(new HttpServiceAnalyzer());

        getCodeActions().forEach(context::addCodeAction);
    }

    private List<CodeAction> getCodeActions() {
        return List.of(
                new ChangeHeaderParamTypeToString(),
                new ChangeHeaderParamTypeToStringArray(),
                new AddResourceConfigAnnotation()
        );
    }
}
