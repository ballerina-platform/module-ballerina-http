/*
 *  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.http.uri.parser;

import io.ballerina.runtime.api.values.BError;

/**
 * This class is used to set and return data in the template tree.
 * @param <DataType> Type of data which should be set and returned.
 */
public class DataReturnAgent<DataType> {

    private DataType data;
    private BError error;

    /**
     * Set data.
     * @param data data which should get returned.
     */
    public void setData(DataType data) {
        this.data = data;
    }

    /**
     * Get data.
     * @return data stored in the Agent.
     */
    public DataType getData() {
        return data;
    }

    /**
     * Set Error.
     * @param error the error to be set.
     */
    public void setError(BError error) {
        this.error = error;
    }

    /**
     * Get Error.
     * @return the Throwable which caused the error.
     */
    public BError getError() {
        return error;
    }
}
