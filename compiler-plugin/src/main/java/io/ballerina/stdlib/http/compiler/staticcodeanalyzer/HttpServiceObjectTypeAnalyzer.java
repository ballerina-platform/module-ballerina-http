/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.compiler.staticcodeanalyzer;

import io.ballerina.compiler.syntax.tree.ObjectTypeDescriptorNode;
import io.ballerina.projects.Document;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.scan.Reporter;
import io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil;

import static io.ballerina.stdlib.http.compiler.HttpCompilerPluginUtil.isHttpServiceType;

class HttpServiceObjectTypeAnalyzer extends HttpServiceAnalyzer {
    public HttpServiceObjectTypeAnalyzer(Reporter reporter) {
        super(reporter);
    }

    @Override
    public void perform(SyntaxNodeAnalysisContext context) {
        if (!isHttpServiceType(context.semanticModel(), context.node())) {
            return;
        }
        ObjectTypeDescriptorNode serviceObjectType = (ObjectTypeDescriptorNode) context.node();
        Document document = HttpCompilerPluginUtil.getDocument(context);
        validateServiceMembers(serviceObjectType.members(), document);
    }
}
