/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.http;

import io.ballerina.runtime.api.Module;
import org.ballerinalang.net.http.nativeimpl.ModuleUtils;

import static io.ballerina.runtime.api.constants.RuntimeConstants.ORG_NAME_SEPARATOR;

/**
 * Utility class providing package related utility methods.
 */
public class HttpPackageUtil {

    /**
     * Gets ballerina http package.
     *
     * @return http package.
     */
    public static Module getHttpPackage() {
        return ModuleUtils.getModule();
    }

    /**
     * Gets ballerina http package version.
     *
     * @return http package version.
     */
    public static String getHttpPackageVersion() {
        return ModuleUtils.getModule().getVersion();
    }

    /**
     * Gets ballerina http package identifier.
     *
     * @return http package identifier.
     */
    public static String getHttpPackageIdentifier() {
        return HttpConstants.PACKAGE + ORG_NAME_SEPARATOR + HttpConstants.PROTOCOL_HTTP + HttpConstants.COLON +
                getHttpPackageVersion();
    }

    private HttpPackageUtil() {
    }
}
