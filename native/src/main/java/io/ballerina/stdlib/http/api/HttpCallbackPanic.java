/*
 *  Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.values.BError;
import io.ballerina.stdlib.http.transport.contract.ImmediateStopFuture;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.Objects;

public class HttpCallbackPanic extends HttpCallbackReturn {
    private final ImmediateStopFuture immediateStopFuture;

    public HttpCallbackPanic(HttpCarbonMessage requestMessage, ImmediateStopFuture immediateStopFuture) {
        super(requestMessage);
        this.immediateStopFuture = immediateStopFuture;
    }

    @Override
    public void notifySuccess(Object result) {
        super.notifySuccess(result);
        if (Objects.nonNull(this.immediateStopFuture)) {
            this.immediateStopFuture.Stop();
            System.exit(0);
        }
    }

    @Override
    public void notifyFailure(BError result) {
        HttpCallbackUtils.sendFailureResponse(result, requestMessage);
    }
}
