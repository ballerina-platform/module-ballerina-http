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

package io.ballerina.stdlib.http.compiler;

import io.ballerina.compiler.syntax.tree.Node;

import java.util.Locale;
import java.util.Objects;

/**
 * Represents HTTP resource linked to a specific resource.
 */
public class LinkedToResource {
    private final String name;
    private final String method;
    private Node node;
    boolean nameRefMethodAvailable;

    public LinkedToResource(String name, String method, Node node, boolean nameRefMethodAvailable) {
        this.name = name;
        this.method = method;
        this.node = node;
        this.nameRefMethodAvailable = nameRefMethodAvailable;
    }

    public String getName() {
        return name;
    }

    public String getMethod() {
        return Objects.nonNull(method) ? method.toUpperCase(Locale.getDefault()) : null;
    }

    public Node getNode() {
        return node;
    }

    public boolean hasNameRefMethodAvailable() {
        return this.nameRefMethodAvailable;
    }
}
