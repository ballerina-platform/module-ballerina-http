/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
package io.ballerina.stdlib.http.compiler.completion;


import java.util.List;

/**
 * Constants related to compiler plugin completion implementation.
 */
public class Constants {
    public static final String GET = "get";
    public static final String POST = "post";

    public static final String PUT = "put";
    public static final String DELETE = "delete";

    public static final String HEAD = "head";

    public static final String OPTIONS = "options";

    public static final List<String> METHODS = List.of(GET, POST, PUT, DELETE, HEAD, OPTIONS);

}
