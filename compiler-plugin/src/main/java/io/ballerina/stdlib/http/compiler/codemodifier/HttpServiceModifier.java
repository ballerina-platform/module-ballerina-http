/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.compiler.codemodifier;

import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.plugins.CodeModifier;
import io.ballerina.projects.plugins.CodeModifierContext;
import io.ballerina.stdlib.http.compiler.codemodifier.context.PayloadParamContext;

import java.util.HashMap;
import java.util.Map;

/**
 * {@code HttpServiceModifier} handles required code-modification related to http-service.
 *
 * @since 2201.5.0
 */
public class HttpServiceModifier extends CodeModifier {
    private final Map<DocumentId, PayloadParamContext> payloadParamContextMap;

    public HttpServiceModifier() {
        this.payloadParamContextMap = new HashMap<>();
    }

    @Override
    public void init(CodeModifierContext codeModifierContext) {
        codeModifierContext.addSyntaxNodeAnalysisTask(new HttpPayloadParamIdentifier(this.payloadParamContextMap),
                                                      SyntaxKind.SERVICE_DECLARATION);
        codeModifierContext.addSourceModifierTask(new PayloadAnnotationModifierTask(this.payloadParamContextMap));
    }
}
