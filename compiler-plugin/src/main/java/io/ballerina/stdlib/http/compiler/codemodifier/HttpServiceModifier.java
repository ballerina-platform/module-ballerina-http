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
import io.ballerina.stdlib.http.compiler.codemodifier.contract.ContractInfoModifierTask;
import io.ballerina.stdlib.http.compiler.codemodifier.payload.HttpPayloadParamIdentifier;
import io.ballerina.stdlib.http.compiler.codemodifier.payload.PayloadAnnotationModifierTask;
import io.ballerina.stdlib.http.compiler.codemodifier.payload.context.PayloadParamContext;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * {@code HttpServiceModifier} handles required code-modification related to http-service.
 *
 * @since 2201.5.0
 */
public class HttpServiceModifier extends CodeModifier {
    private final Map<DocumentId, PayloadParamContext> payloadParamContextMap;
    private final Map<String, Object> ctxData;

    public HttpServiceModifier(Map<String, Object> ctxData) {
        this.payloadParamContextMap = new HashMap<>();
        this.ctxData = ctxData;
    }

    @Override
    public void init(CodeModifierContext codeModifierContext) {
        ctxData.put("HTTP_CODE_MODIFIER_EXECUTED", true);
        codeModifierContext.addSyntaxNodeAnalysisTask(
                new HttpPayloadParamIdentifier(this.payloadParamContextMap),
                List.of(SyntaxKind.SERVICE_DECLARATION, SyntaxKind.CLASS_DEFINITION, SyntaxKind.OBJECT_TYPE_DESC));
        codeModifierContext.addSourceModifierTask(new PayloadAnnotationModifierTask(this.payloadParamContextMap));

        codeModifierContext.addSourceModifierTask(new ContractInfoModifierTask());
    }
}
