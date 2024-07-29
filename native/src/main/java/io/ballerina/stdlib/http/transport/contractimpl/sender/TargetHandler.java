/*
 * Copyright (c) 2015, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and limitations under the License.
 */
package io.ballerina.stdlib.http.transport.contractimpl.sender;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.config.KeepAliveConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.SenderReqRespStateManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.TargetChannel;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ClientChannel;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ClientTimeoutHandler;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2TargetHandler;
import io.ballerina.stdlib.http.transport.internal.HandlerExecutor;
import io.ballerina.stdlib.http.transport.internal.HttpTransportContextHolder;
import io.ballerina.stdlib.http.transport.message.ClientRemoteFlowControlListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.socket.ChannelInputShutdownReadComplete;
import io.netty.handler.codec.http.HttpClientUpgradeHandler;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http2.Http2CodecUtil;
import io.netty.handler.codec.http2.Http2ConnectionPrefaceAndSettingsFrameWrittenEvent;
import io.netty.handler.ssl.SslCloseCompletionEvent;
import io.netty.handler.ssl.SslHandshakeCompletionEvent;
import io.netty.handler.timeout.IdleStateEvent;
import io.netty.util.ReferenceCountUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Objects;

import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.createInboundRespCarbonMsg;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.safelyRemoveHandlers;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.Http2StateUtil.initHttp2MessageContext;

/**
 * A class responsible for handling responses coming from BE.
 */
public class TargetHandler extends ChannelInboundHandlerAdapter {

    private static final Logger LOG = LoggerFactory.getLogger(TargetHandler.class);

    private HttpResponseFuture httpResponseFuture;
    private HttpCarbonMessage inboundResponseMsg;
    private ConnectionManager connectionManager;
    private TargetChannel targetChannel;
    private Http2TargetHandler http2TargetHandler;
    private HttpCarbonMessage outboundRequestMsg;
    private HandlerExecutor handlerExecutor;
    private KeepAliveConfig keepAliveConfig;
    private boolean idleTimeoutTriggered;
    private ChannelHandlerContext context;
    private Throwable cause;
    private HttpClientChannelInitializer httpClientChannelInitializer;

    @Override
    public void handlerAdded(ChannelHandlerContext ctx) {
        context = ctx;
    }

    @SuppressWarnings("unchecked")
    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        SenderReqRespStateManager senderReqRespStateManager = targetChannel.senderReqRespStateManager;

        if (handlerExecutor != null) {
            handlerExecutor.executeAtTargetResponseReceiving(inboundResponseMsg);
        }
        if (targetChannel.isRequestHeaderWritten()) {
            if (msg instanceof HttpResponse) {
                if (isAbnormal100Response((HttpResponse) msg)) {
                    LOG.warn("Received an unexpected 100-continue response");
                } else {
                    inboundResponseMsg = createInboundRespCarbonMsg(ctx, (HttpResponse) msg, outboundRequestMsg);
                    senderReqRespStateManager.readInboundResponseHeaders(this, (HttpResponse) msg);
                }
            } else {
                if (inboundResponseMsg != null) {
                    senderReqRespStateManager.readInboundResponseEntityBody(ctx, (HttpContent) msg,
                                                                                       getInboundResponseMsg());
                }
            }
        } else {
            if (msg instanceof HttpResponse) {
                LOG.warn("Received a response for an obsolete request {}", msg);
            }
            ReferenceCountUtil.release(msg);
        }
    }

    private boolean isAbnormal100Response(HttpResponse msg) {
        return msg.status().code() == 100 && !outboundRequestMsg.is100ContinueExpected();
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        handlerExecutor = HttpTransportContextHolder.getInstance().getHandlerExecutor();
        if (handlerExecutor != null) {
            handlerExecutor.executeAtTargetConnectionInitiation(Integer.toString(ctx.hashCode()));
        }
        super.channelActive(ctx);
    }

    @Override
    public void channelInactive(ChannelHandlerContext ctx) throws Exception {
        if (!idleTimeoutTriggered) {
            targetChannel.senderReqRespStateManager.handleAbruptChannelClosure(this, httpResponseFuture);
        }
        releasePerRoutePoolLatchOnFailure();
        connectionManager.invalidateTargetChannel(targetChannel);

        if (handlerExecutor != null) {
            handlerExecutor.executeAtTargetConnectionTermination(Integer.toString(ctx.hashCode()));
            handlerExecutor = null;
        }
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        this.cause = cause;
        closeChannel(ctx);
        LOG.warn("Exception occurred in TargetHandler : {}", cause.getMessage());
    }

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        if (evt instanceof IdleStateEvent) {
            this.idleTimeoutTriggered = true;
            targetChannel.senderReqRespStateManager.handleIdleTimeoutConnectionClosure(this,
                    httpResponseFuture, ctx.channel().id().asLongText());
        } else if (evt instanceof HttpClientUpgradeHandler.UpgradeEvent) {
            HttpClientUpgradeHandler.UpgradeEvent upgradeEvent = (HttpClientUpgradeHandler.UpgradeEvent) evt;
            if (HttpClientUpgradeHandler.UpgradeEvent.UPGRADE_SUCCESSFUL.name().equals(upgradeEvent.name())) {
                executePostUpgradeActions(ctx);
            } else if (HttpClientUpgradeHandler.UpgradeEvent.UPGRADE_REJECTED.name().equals(upgradeEvent.name())) {
                releasePerRoutePoolLatchOnFailure();
            }
            ctx.fireUserEventTriggered(evt);
        } else {
            logTheErrorMsg(evt);
        }
    }

    private void logTheErrorMsg(Object evt) {
        if (evt instanceof Http2ConnectionPrefaceAndSettingsFrameWrittenEvent) {
            LOG.debug("Connection Preface and Settings frame written");
        } else if (evt instanceof SslCloseCompletionEvent) {
            LOG.debug("SSL close completion event received");
        }  else if (evt instanceof SslHandshakeCompletionEvent) {
            LOG.debug("SSL handshake completion event received");
        } else if (evt instanceof ChannelInputShutdownReadComplete) {
            // When you try to read from a channel which has already been closed by the peer,
            // 'java.io.IOException: Connection reset by peer' is thrown and it is a harmless exception.
            // We can ignore this most of the time. see 'https://github.com/netty/netty/issues/2332'.
            // As per the code, when an IOException is thrown when reading from a channel, it closes the channel.
            // When closing the channel, if it is already closed it will trigger this event. So we can ignore this.
            LOG.debug("Input side of the connection is already shutdown");
        } else {
            releasePerRoutePoolLatchOnFailure();
            LOG.warn("Unexpected user event {} triggered", evt);
        }
    }

    private void executePostUpgradeActions(ChannelHandlerContext ctx) {
        ctx.pipeline().remove(this);
        ctx.pipeline().addLast(Constants.HTTP2_TARGET_HANDLER, http2TargetHandler);
        Http2ClientChannel http2ClientChannel = http2TargetHandler.getHttp2ClientChannel();

        // Remove Http specific handlers
        safelyRemoveHandlers(targetChannel.getChannel().pipeline(), Constants.IDLE_STATE_HANDLER,
                             Constants.HTTP_TRACE_LOG_HANDLER);
        initHttp2MessageContext(outboundRequestMsg, http2TargetHandler);
        http2ClientChannel.addDataEventListener(
                Constants.IDLE_STATE_HANDLER,
                new Http2ClientTimeoutHandler(http2ClientChannel.getSocketIdleTimeout(), http2ClientChannel));

        http2ClientChannel.getInFlightMessage(Http2CodecUtil.HTTP_UPGRADE_STREAM_ID).setRequestWritten(true);
        http2ClientChannel.getDataEventListeners().
                forEach(dataEventListener ->
                                dataEventListener.onStreamInit(ctx, Http2CodecUtil.HTTP_UPGRADE_STREAM_ID));
        handoverChannelToHttp2ConnectionManager();
    }

    private void handoverChannelToHttp2ConnectionManager() {
        Http2ClientChannel upgradedHttp2ClientChannel = targetChannel.getHttp2ClientChannel();
        connectionManager.getHttp2ConnectionManager().addHttp2ClientChannel(targetChannel.getHttpRoute(),
                                                                            upgradedHttp2ClientChannel);
        upgradedHttp2ClientChannel.getConnection().remote().flowController().listener(
            new ClientRemoteFlowControlListener(upgradedHttp2ClientChannel));
    }

    public void closeChannel(ChannelHandlerContext ctx) {
        // The if condition here checks if the connection has already been closed by either the client or the backend.
        // If it was the backend which closed the connection, the channel inactive event will be triggered and
        // subsequently, this method will be called.
        if (ctx != null && ctx.channel().isActive()) {
            ctx.close();
        }
    }

    private void releasePerRoutePoolLatchOnFailure() {
        // When SSL completion event is received via UserEventTriggered method, this method can be called before
        // assigning value to connectionManager. Hence the null check
        if (Objects.nonNull(connectionManager)) {
            connectionManager.getHttp2ConnectionManager().releasePerRoutePoolLatch(targetChannel.getHttpRoute());
        }
    }

    public void setHttpResponseFuture(HttpResponseFuture httpResponseFuture) {
        this.httpResponseFuture = httpResponseFuture;
    }

    public void setConnectionManager(ConnectionManager connectionManager) {
        this.connectionManager = connectionManager;
    }

    public void setOutboundRequestMsg(HttpCarbonMessage outboundRequestMsg) {
        this.outboundRequestMsg = outboundRequestMsg;
    }

    public void setTargetChannel(TargetChannel targetChannel) {
        this.targetChannel = targetChannel;
    }

    public void setKeepAliveConfig(KeepAliveConfig keepAliveConfig) {
        this.keepAliveConfig = keepAliveConfig;
    }

    public HttpResponseFuture getHttpResponseFuture() {
        return httpResponseFuture;
    }

    void setHttp2TargetHandler(Http2TargetHandler http2TargetHandler) {
        this.http2TargetHandler = http2TargetHandler;
    }

    public HttpCarbonMessage getInboundResponseMsg() {
        return inboundResponseMsg;
    }

    public Http2TargetHandler getHttp2TargetHandler() {
        return http2TargetHandler;
    }

    public void resetInboundMsg() {
        this.inboundResponseMsg = null;
    }

    public TargetChannel getTargetChannel() {
        return targetChannel;
    }

    public KeepAliveConfig getKeepAliveConfig() {
        return keepAliveConfig;
    }

    public HttpCarbonMessage getOutboundRequestMsg() {
        return outboundRequestMsg;
    }

    public ConnectionManager getConnectionManager() {
        return connectionManager;
    }

    /**
     * Gets the {@link ChannelHandlerContext} of the {@link TargetHandler}.
     *
     * @return the {@link ChannelHandlerContext} of this handler.
     */
    public ChannelHandlerContext getContext() {
        return context;
    }

    public Throwable getCause() {
        return cause;
    }

    public HttpClientChannelInitializer getHttpClientChannelInitializer() {
        return httpClientChannelInitializer;
    }

    public void setHttpClientChannelInitializer(HttpClientChannelInitializer httpClientChannelInitializer) {
        this.httpClientChannelInitializer = httpClientChannelInitializer;
    }
}
