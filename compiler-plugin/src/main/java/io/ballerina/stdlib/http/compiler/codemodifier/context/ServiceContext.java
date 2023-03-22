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

package io.ballerina.stdlib.http.compiler.codemodifier.context;

import java.util.HashMap;
import java.util.Map;

/**
 * {@code ServiceContext} contains details of the service where the unannotated payload parameter is located.
 *
 *  @since 2201.5.0
 */
public class ServiceContext {
    private final int serviceId;
    private final Map<Integer, ResourceContext> resourceContextMap;

    public ServiceContext(int serviceId) {
        this.serviceId = serviceId;
        this.resourceContextMap = new HashMap<>();
    }

    public void setResourceContext(int resourceId, ResourceContext payloadParamInfo) {
        this.resourceContextMap.put(resourceId, payloadParamInfo);
    }

    public void removeResourceContext(int resourceId) {
        this.resourceContextMap.remove(resourceId);
    }

    public int getServiceId() {
        return serviceId;
    }

    public boolean containsResource(int resourceId) {
        return resourceContextMap.containsKey(resourceId);
    }

    public ResourceContext getResourceContext(int resourceId) {
        return resourceContextMap.get(resourceId);
    }
}
