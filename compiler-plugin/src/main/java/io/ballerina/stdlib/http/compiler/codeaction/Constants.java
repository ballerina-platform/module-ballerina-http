/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.compiler.codeaction;

/**
 * Constants related to compiler plugin code-action implementation.
 */
public final class Constants {
    private Constants () {}

    public static final String NODE_LOCATION_KEY = "node.location";
    public static final String IS_ERROR_INTERCEPTOR_TYPE = "node.errorInterceptor";
    public static final String EXPECTED_BASE_PATH = "expectedBasePath";

    public static final String REMOTE = "remote";
    public static final String RESOURCE = "resource";
    public static final String ERROR = "Error";
    public static final String LS = System.lineSeparator();
}
