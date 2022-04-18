/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.api.service.signature.builder;

import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;

import java.io.IOException;

/**
 * The blob type payload builder.
 *
 * @since SwanLake update 1
 */
public class BinaryPayloadBuilder extends AbstractPayloadBuilder {

    @Override
    public int build(BObject inRequestEntity, boolean readonly, Object[] paramFeed, int index) {
        BArray blobDataSource;
        try {
            blobDataSource = EntityBodyHandler.constructBlobDataSource(inRequestEntity);
        } catch (IOException e) {
            throw HttpUtil.createHttpError(e.getMessage(), HttpErrorType.CLIENT_ERROR);
        }
        EntityBodyHandler.addMessageDataSource(inRequestEntity, blobDataSource);
        if (readonly) {
            blobDataSource.freezeDirect();
        }
        paramFeed[index++] = blobDataSource;
        return index;
    }
}
