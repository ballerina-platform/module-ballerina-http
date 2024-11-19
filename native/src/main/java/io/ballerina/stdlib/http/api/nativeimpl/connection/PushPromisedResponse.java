/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.api.nativeimpl.connection;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.DataContext;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;

import java.io.OutputStream;
import java.util.concurrent.CompletableFuture;

import static io.ballerina.stdlib.http.api.HttpUtil.extractEntity;
import static io.ballerina.stdlib.http.api.nativeimpl.ExternUtils.getResult;

/**
 * {@code PushPromisedResponse} is the extern function to respond back the client with Server Push response.
 */
public class PushPromisedResponse extends ConnectionAction {

    public static Object pushPromisedResponse(Environment env, BObject connectionObj, BObject pushPromiseObj,
                                              BObject outboundResponseObj) {
        HttpCarbonMessage inboundRequestMsg = HttpUtil.getCarbonMsg(connectionObj, null);
        return env.yieldAndRun(() -> {
            CompletableFuture<Object> balFuture = new CompletableFuture<>();
            DataContext dataContext = new DataContext(env, balFuture, inboundRequestMsg);
            HttpUtil.serverConnectionStructCheck(inboundRequestMsg);
            Http2PushPromise http2PushPromise = HttpUtil.getPushPromise(pushPromiseObj, null);
            if (http2PushPromise == null) {
                throw ErrorCreator.createError(StringUtils.fromString("invalid push promise"));
            }
            HttpCarbonMessage outboundResponseMsg = HttpUtil
                    .getCarbonMsg(outboundResponseObj, HttpUtil.createHttpCarbonMessage(false));
            HttpUtil.prepareOutboundResponse(connectionObj, inboundRequestMsg, outboundResponseMsg,
                    outboundResponseObj);
            pushResponseRobust(dataContext, inboundRequestMsg, outboundResponseObj, outboundResponseMsg,
                    http2PushPromise);
            return getResult(balFuture);
        });
    }

    private static void pushResponseRobust(DataContext dataContext, HttpCarbonMessage requestMessage,
                                    BObject outboundResponseObj, HttpCarbonMessage responseMessage,
                                    Http2PushPromise http2PushPromise) {
        HttpResponseFuture outboundRespStatusFuture =
                HttpUtil.pushResponse(requestMessage, responseMessage, http2PushPromise);
        HttpMessageDataStreamer outboundMsgDataStreamer = getMessageDataStreamer(responseMessage);
        HttpConnectorListener outboundResStatusConnectorListener =
                new ResponseWriter.HttpResponseConnectorListener(dataContext, outboundMsgDataStreamer);
        outboundRespStatusFuture.setHttpConnectorListener(outboundResStatusConnectorListener);
        OutputStream messageOutputStream = outboundMsgDataStreamer.getOutputStream();

        BObject entityObj = extractEntity(outboundResponseObj);
        if (entityObj != null) {
            Object outboundMessageSource = EntityBodyHandler.getMessageDataSource(entityObj);
            serializeMsgDataSource(dataContext, outboundMessageSource, entityObj, messageOutputStream);
        }
    }

    private PushPromisedResponse() {}
}
