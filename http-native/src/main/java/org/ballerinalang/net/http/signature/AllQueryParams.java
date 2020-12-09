/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.http.signature;

import org.ballerinalang.net.http.HttpConstants;

import java.util.ArrayList;
import java.util.List;

/**
 * {@code {@link AllQueryParams }} holds all the query parameters in the resource signature.
 *
 * @since slp8
 */
public class AllQueryParams implements Parameter {

    private List<QueryParam> allQueryParams = new ArrayList<>();

    @Override
    public String getTypeName() {
        return HttpConstants.QUERY_PARAM;
    }

    public void add(QueryParam queryParam) {
        allQueryParams.add(queryParam);
    }

    boolean isNotEmpty() {
        return !allQueryParams.isEmpty();
    }

    public List<QueryParam> getAllQueryParams() {
        return allQueryParams;
    }
}
