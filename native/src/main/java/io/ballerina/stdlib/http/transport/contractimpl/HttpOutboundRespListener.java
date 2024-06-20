/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 *
 */

package io.ballerina.stdlib.http.transport.contractimpl;

import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.config.ChunkConfig;
import io.ballerina.stdlib.http.transport.contract.config.KeepAliveConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.BackPressureHandler;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.contractimpl.listener.RequestDataHolder;
import io.ballerina.stdlib.http.transport.contractimpl.listener.SourceHandler;
import io.ballerina.stdlib.http.transport.contractimpl.listener.states.ListenerReqRespStateManager;
import io.ballerina.stdlib.http.transport.internal.HandlerExecutor;
import io.ballerina.stdlib.http.transport.internal.HttpTransportContextHolder;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Calendar;
import java.util.Locale;

/**
 * Get executed when the response is available.
 */
public class HttpOutboundRespListener implements HttpConnectorListener {

    private static final Logger LOG = LoggerFactory.getLogger(HttpOutboundRespListener.class);
    private final SourceHandler sourceHandler;
    private final ListenerReqRespStateManager listenerReqRespStateManager;

    private ChannelHandlerContext sourceContext;
    private RequestDataHolder requestDataHolder;
    private HandlerExecutor handlerExecutor;
    private HttpCarbonMessage inboundRequestMsg;
    private ChunkConfig chunkConfig;
    private KeepAliveConfig keepAliveConfig;
    private String serverName;
    private Calendar inboundRequestArrivalTime;
    private String remoteAddress = "-";

    public HttpOutboundRespListener(HttpCarbonMessage requestMsg, SourceHandler sourceHandler) {
        this.requestDataHolder = new RequestDataHolder(requestMsg);
        this.inboundRequestMsg = requestMsg;
        this.sourceHandler = sourceHandler;
        this.sourceContext = sourceHandler.getInboundChannelContext();
        this.chunkConfig = sourceHandler.getChunkConfig();
        this.keepAliveConfig = sourceHandler.getKeepAliveConfig();
        this.handlerExecutor = HttpTransportContextHolder.getInstance().getHandlerExecutor();
        this.serverName = sourceHandler.getServerName();
        this.listenerReqRespStateManager = requestMsg.listenerReqRespStateManager;
        this.remoteAddress = sourceHandler.getRemoteHost();
        this.inboundRequestArrivalTime = Calendar.getInstance();
        setBackPressureObservableToHttpResponseFuture();
    }

    private void setBackPressureObservableToHttpResponseFuture() {
        inboundRequestMsg.getHttpOutboundRespStatusFuture().
                setBackPressureObservable(Util.getBackPressureHandler(sourceContext).getBackPressureObservable());
    }

    @Override
    public void onMessage(HttpCarbonMessage outboundResponseMsg) {
        if (handlerExecutor != null) {
            handlerExecutor.executeAtSourceResponseReceiving(outboundResponseMsg);
        }

        BackPressureHandler backpressureHandler = Util.getBackPressureHandler(sourceContext);
        Util.setBackPressureListener(outboundResponseMsg, backpressureHandler, outboundResponseMsg.getTargetContext());

        outboundResponseMsg.getHttpContentAsync().setMessageListener(httpContent -> {
            Util.checkUnWritabilityAndNotify(sourceContext, backpressureHandler);
            this.sourceContext.channel().eventLoop().execute(() -> {
                try {
                    listenerReqRespStateManager.writeOutboundResponseBody(this, outboundResponseMsg, httpContent);
                } catch (Exception exception) {
                    String errorMsg = "Failed to send the outbound response : "
                            + exception.getMessage().toLowerCase(Locale.ENGLISH);
                    LOG.error(errorMsg, exception);
                    inboundRequestMsg.getHttpOutboundRespStatusFuture().notifyHttpListener(exception);
                }
            });
        });
    }

    @Override
    public void onPushPromise(Http2PushPromise pushPromise) {
        inboundRequestMsg.getHttpOutboundRespStatusFuture().notifyHttpListener(new UnsupportedOperationException(
                "Sending a PUSH_PROMISE is not supported for HTTP/1.x connections"));
    }

    @Override
    public void onPushResponse(int promiseId, HttpCarbonMessage httpMessage) {
        inboundRequestMsg.getHttpOutboundRespStatusFuture().notifyHttpListener(new UnsupportedOperationException(
                "Sending Server Push messages is not supported for HTTP/1.x connections"));
    }

    // Decides whether to close the connection after sending the response
    public boolean isKeepAlive() {
        return Util.isKeepAliveConnection(keepAliveConfig, requestDataHolder.getConnectionHeaderValue(),
                                          requestDataHolder.getHttpVersion());
    }

    @Override
    public void onError(Throwable throwable) {
        LOG.error("Couldn't send the outbound response", throwable);
    }

    public ChunkConfig getChunkConfig() {
        return chunkConfig;
    }

    public HttpCarbonMessage getInboundRequestMsg() {
        return inboundRequestMsg;
    }

    public RequestDataHolder getRequestDataHolder() {
        return requestDataHolder;
    }

    public ChannelHandlerContext getSourceContext() {
        return sourceContext;
    }

    public String getServerName() {
        return serverName;
    }

    public void setKeepAliveConfig(KeepAliveConfig config) {
        this.keepAliveConfig = config;
    }

    public SourceHandler getSourceHandler() {
        return sourceHandler;
    }

    public Calendar getInboundRequestArrivalTime() {
        return inboundRequestArrivalTime;
    }

    public String getRemoteAddress() {
        return remoteAddress;
    }
}
