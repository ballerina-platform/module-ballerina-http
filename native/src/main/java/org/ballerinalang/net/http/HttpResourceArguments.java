/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.http;

import java.util.HashMap;
import java.util.Map;

/**
 * This class holds the resource signature path parameters. Each path template has an associated map which keeps
 * URI segment value against the expression position index(initialized during the load time).
 * Eg :
 * resource function get [string aaa]/go/[string bbb]() {}
 * resource function get [string bbb]/go/[string aaa]/[string ccc]() {}
 *
 * URL - bal/go/java/c
 * aaa:
 *   0: bal
 *   1: java
 * bbb:
 *   0: bal
 *   1: java
 * ccc:
 *   2: c
 *
 * @since 0.995.0
 */
public class HttpResourceArguments {

    private Map<String, Map<Integer, String>> resourceArgumentValues = new HashMap<>();

    public HttpResourceArguments() {
        resourceArgumentValues = new HashMap<>();
    }

    public Map<String, Map<Integer, String>> getMap() {
        return resourceArgumentValues;
    }
}
