/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.http;

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;

import static org.ballerinalang.net.http.HttpConstants.NOTIFY_SUCCESS_METADATA;

/**
 * {@code HttpCallableUnitCallback} is the responsible for acting on notifications received from Ballerina side.
 *
 * @since 0.94
 */
public class HttpCallableUnitCallback implements Callback {
    private final BObject caller;
    private final Runtime runtime;
    private HttpCarbonMessage requestMessage;
    private static final String ILLEGAL_FUNCTION_INVOKED = "illegal return: request has already been responded";

    HttpCallableUnitCallback(HttpCarbonMessage requestMessage, Runtime runtime) {
        this.requestMessage = requestMessage;
        this.caller = (BObject) requestMessage.getProperty(HttpConstants.CALLER);
        this.runtime = runtime;
    }

    @Override
    public void notifySuccess(Object result) {
        if (result == null) { // handles nil return and end of resource exec
            requestMessage.waitAndReleaseAllEntities();
            return;
        }
        HttpUtil.methodInvocationCheck(requestMessage, HttpConstants.INVALID_STATUS_CODE, ILLEGAL_FUNCTION_INVOKED);
        if (result instanceof BError) { // handles error check and return
            sendFailureResponse((BError) result);
            return;
        }
        Object[] paramFeed = new Object[2];
        paramFeed[0] = result;
        paramFeed[1] = true;

        runtime.invokeMethodAsync(caller, "returnResponse", null, NOTIFY_SUCCESS_METADATA, new Callback() {
            @Override
            public void notifySuccess(Object result) {
                System.out.println("oooooooookkkkkkkkkkkkkkkkkkkkkkkkk");
                requestMessage.waitAndReleaseAllEntities();
            }

            @Override
            public void notifyFailure(BError result) {
                System.out.println("panicccccccccccccccccccc");
                sendFailureResponse(result);
            }
        }, paramFeed);
    }

    @Override
    public void notifyFailure(BError error) { // handles panic and check_panic
        sendFailureResponse(error);
    }

    private void sendFailureResponse(BError error) {
        HttpUtil.handleFailure(requestMessage, error);
        requestMessage.waitAndReleaseAllEntities();
    }
}
