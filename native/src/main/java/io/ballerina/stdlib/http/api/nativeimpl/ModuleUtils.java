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

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.async.StrandMetadata;
import io.ballerina.stdlib.http.api.HttpConstants;

import static io.ballerina.runtime.api.constants.RuntimeConstants.BALLERINA_BUILTIN_PKG_PREFIX;
import static io.ballerina.runtime.api.constants.RuntimeConstants.ORG_NAME_SEPARATOR;
import static io.ballerina.stdlib.http.api.HttpConstants.PROTOCOL_HTTP;

/**
 * This class will hold module related utility functions.
 *
 * @since 2.0.0
 */
public class ModuleUtils {

    private static Module httpModule;
    private static Module httpStatusModule;
    private static StrandMetadata onMessageMetaData;
    private static StrandMetadata notifySuccessMetaData;
    private static String packageIdentifier;

    private ModuleUtils() {}

    public static void setModule(Environment env) {
        httpModule = env.getCurrentModule();
        onMessageMetaData = new StrandMetadata(BALLERINA_BUILTIN_PKG_PREFIX, PROTOCOL_HTTP, httpModule.getVersion(),
                                               "onMessage");
        notifySuccessMetaData = new StrandMetadata(BALLERINA_BUILTIN_PKG_PREFIX, PROTOCOL_HTTP, httpModule.getVersion(),
                                                   "notifySuccess");
        packageIdentifier = HttpConstants.PACKAGE + ORG_NAME_SEPARATOR + HttpConstants.PROTOCOL_HTTP +
                HttpConstants.COLON + httpModule.getVersion();
    }

    public static void setHttpStatusModule(Environment env) {
        httpStatusModule = env.getCurrentModule();
    }

    /**
     * Gets ballerina http package.
     *
     * @return http package.
     */
    public static Module getHttpPackage() {
        return httpModule;
    }

    /**
     * Returns ballerina http status package.
     *
     * @return http status package.
     */
    public static Module getHttpStatusPackage() {
        return httpStatusModule;
    }

    /**
     * Gets the metadata of onMessage() method to invoke resource method.
     *
     * @return metadata of onMessage() method
     */
    public static StrandMetadata getOnMessageMetaData() {
        return onMessageMetaData;
    }

    /**
     * Gets the metadata of notifySuccess() method to invoke Caller.returnResponse() method.
     *
     * @return metadata of notifySuccess() method
     */
    public static StrandMetadata getNotifySuccessMetaData() {
        return notifySuccessMetaData;
    }

    /**
     * Gets ballerina http package identifier.
     *
     * @return http package identifier.
     */
    public static String getHttpPackageIdentifier() {
        return packageIdentifier;
    }
}
