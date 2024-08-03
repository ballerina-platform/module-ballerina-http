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

package io.ballerina.stdlib.http.compiler.codemodifier.payload.context;

import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;

import java.util.HashMap;
import java.util.Map;

/**
 * {@code PayloadParamContext} contains details of unannotated payload parameter.
 *
 *  @since 2201.5.0
 */
public class PayloadParamContext {
    private final SyntaxNodeAnalysisContext context;
    private final Map<Integer, ServicePayloadParamContext> serviceContextMap;

    public PayloadParamContext(SyntaxNodeAnalysisContext context) {
        this.context = context;
        this.serviceContextMap = new HashMap<>();
    }

    public SyntaxNodeAnalysisContext getContext() {
        return context;
    }

    public void setServiceContext(ServicePayloadParamContext serviceContext) {
        serviceContextMap.put(serviceContext.getServiceId(), serviceContext);
    }

    public boolean containsService(int serviceId) {
        return serviceContextMap.containsKey(serviceId);
    }

    public ServicePayloadParamContext getServiceContext(int serviceId) {
        return serviceContextMap.get(serviceId);
    }
}
