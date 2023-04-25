/*
 * Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.ServiceType;
import io.ballerina.runtime.api.utils.IdentifierUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

/**
 * Utilities related to HTTP resource.
 *
 * @since 2.0.0
 */
public class ExternResource {

    /**
     * Returns resource annotation value of provided resource attached to provided service.
     *
     * @param service      service name
     * @param resourceName resource name
     * @return annotation value object
     */
    public static Object getResourceAnnotation(BObject service, BString resourceName) {
        ServiceType serviceType = (ServiceType) TypeUtils.getType(service);
        ResourceMethodType[] functions = serviceType.getResourceMethods();
        for (ResourceMethodType function : functions) {
            if (IdentifierUtils.decodeIdentifier(function.getName()).equals(
                    resourceName.getValue().strip().replace("\\", ""))) {
                BString identifier = StringUtils.fromString(ModuleUtils.getHttpPackage().toString() +
                                                                    ":ResourceConfig");
                return function.getAnnotation(identifier);
            }
        }
        return null;
    }

    private ExternResource() {}
}
