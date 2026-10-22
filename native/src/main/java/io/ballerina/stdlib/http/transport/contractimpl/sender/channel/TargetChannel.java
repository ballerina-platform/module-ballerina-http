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

package io.ballerina.stdlib.http.transport.contractimpl.sender.channel;

import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ClientConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.common.BackPressureHandler;
import io.ballerina.stdlib.http.transport.contractimpl.common.HttpRoute;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.SenderReqRespStateManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.ConnectionAvailabilityFuture;
import io.ballerina.stdlib.http.transport.contractimpl.sender.HttpClientChannelInitializer;
import io.ballerina.stdlib.http.transport.contractimpl.sender.TargetHandler;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ClientChannel;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ConnectionManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.NewConnectionAttempt;
import io.ballerina.stdlib.http.transport.internal.HandlerExecutor;
import io.ballerina.stdlib.http.transport.internal.HttpTransportContextHolder;
import io.ballerina.stdlib.http.transport.message.BackPressureObservable;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.Channel;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInboundHandlerAdapter;
import org.apache.commons.pool.impl.GenericObjectPool;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Locale;

/**
 * A class that encapsulate channel and state.
 */
public class TargetChannel {

    private static final Logger LOG = LoggerFactory.getLogger(TargetChannel.class);

    public SenderReqRespStateManager senderReqRespStateManager;
    public String trgHlrConnPoolId;

    private volatile boolean requestHeaderWritten = false;
    private Channel channel;
    private HttpClientChannelInitializer httpClientChannelInitializer;
    private ChannelInboundHandlerAdapter correlatedSource;
    private ConnectionManager connectionManager;
    private TargetHandler targetHandler;

    private Http2ClientChannel http2ClientChannel;
    private final HttpRoute httpRoute;
    private final ChannelFuture channelFuture;
    private final HandlerExecutor handlerExecutor;
    private final ConnectionAvailabilityFuture connectionAvailabilityFuture;
    private GenericObjectPool pool;
    // The route's new HTTP/2 connection this channel is opening, if any, and whether it can no longer become one.
    // Each side writes its own field before reading the other's, so whichever runs second releases the waiters.
    private volatile Http2ConnectionManager http2ConnectionManager;
    private volatile NewConnectionAttempt newConnectionAttempt;
    private volatile boolean connectionAttemptEnded;
    private volatile boolean http2Unavailable;
    private volatile ClientConnectorException connectionAttemptFailure;

    public TargetChannel(HttpClientChannelInitializer httpClientChannelInitializer, ChannelFuture channelFuture,
                         HttpRoute httpRoute, ConnectionAvailabilityFuture connectionAvailabilityFuture) {
        this.httpClientChannelInitializer = httpClientChannelInitializer;
        this.channelFuture = channelFuture;
        this.handlerExecutor = HttpTransportContextHolder.getInstance().getHandlerExecutor();
        this.httpRoute = httpRoute;
        if (httpClientChannelInitializer != null) {
            http2ClientChannel =
                    new Http2ClientChannel(httpClientChannelInitializer.getHttp2ConnectionManager(),
                                           httpClientChannelInitializer.getConnection(),
                                           httpRoute, channelFuture.channel(), this);
        }
        this.connectionAvailabilityFuture = connectionAvailabilityFuture;
    }

    public void configTargetHandler(HttpCarbonMessage httpCarbonMessage, HttpResponseFuture httpInboundResponseFuture) {
        targetHandler = httpClientChannelInitializer.getTargetHandler();
        targetHandler.setHttpResponseFuture(httpInboundResponseFuture);
        targetHandler.setOutboundRequestMsg(httpCarbonMessage);
        targetHandler.setConnectionManager(connectionManager);
        targetHandler.setTargetChannel(this);
    }

    public BackPressureObservable getBackPressureObservable() {
        if (Util.getBackPressureHandler(targetHandler.getContext()) != null) {
            return Util.getBackPressureHandler(targetHandler.getContext()).getBackPressureObservable();
        }
        return null;
    }

    public void writeContent(HttpCarbonMessage httpOutboundRequest) {
        if (handlerExecutor != null) {
            handlerExecutor.executeAtTargetRequestReceiving(httpOutboundRequest);
        }

        BackPressureHandler backpressureHandler = Util.getBackPressureHandler(targetHandler.getContext());
        Util.setBackPressureListener(httpOutboundRequest, backpressureHandler, httpOutboundRequest.getSourceContext());

        resetTargetChannelState();

        httpOutboundRequest.getHttpContentAsync().setMessageListener((httpContent -> {
            //TODO:Until the listener is set, content writing happens in I/O thread. If writability changed
            //while in I/O thread and DefaultBackPressureListener is engaged, there's a chance of I/O thread
            //getting blocked. Cannot recreate, only a possibility.
            Util.checkUnWritabilityAndNotify(targetHandler.getContext(), backpressureHandler);
            this.channel.eventLoop().execute(() -> {
                try {
                    senderReqRespStateManager.writeOutboundRequestEntity(httpOutboundRequest, httpContent);
                } catch (Exception exception) {
                    String errorMsg = "Failed to send the request : "
                            + exception.getMessage().toLowerCase(Locale.ENGLISH);
                    LOG.error(errorMsg, exception);
                    this.targetHandler.getHttpResponseFuture().notifyHttpListener(exception);
                }
            });
        }));
    }

    public void setConnectionManager(ConnectionManager connectionManager) {
        this.connectionManager = connectionManager;
    }

    public ChannelFuture getChannelFuture() {
        return channelFuture;
    }

    private void resetTargetChannelState() {
        this.requestHeaderWritten = false;
    }

    public void setCorrelatedSource(ChannelInboundHandlerAdapter correlatedSource) {
        this.correlatedSource = correlatedSource;
    }

    public ChannelInboundHandlerAdapter getCorrelatedSource() {
        return correlatedSource;
    }

    public void setChannel(Channel channel) {
        this.channel = channel;
    }

    public Channel getChannel() {
        return channel;
    }

    public Http2ClientChannel getHttp2ClientChannel() {
        return http2ClientChannel;
    }

    /**
     * Records the route's new HTTP/2 connection attempt this channel is serving, or {@code null} if the requests
     * waiting for a new connection are not waiting for this channel. If the channel already failed to become an HTTP/2
     * connection, the outcome is reported to the waiting requests at once.
     *
     * @param attempt                the attempt, or {@code null}
     * @param http2ConnectionManager the manager holding the route's pool
     */
    public void setNewConnectionAttempt(NewConnectionAttempt attempt, Http2ConnectionManager http2ConnectionManager) {
        this.http2ConnectionManager = http2ConnectionManager;
        this.newConnectionAttempt = attempt;
        if (connectionAttemptEnded) {
            endConnectionAttempt();
        }
    }

    public NewConnectionAttempt getNewConnectionAttempt() {
        return newConnectionAttempt;
    }

    /**
     * Reports that this channel is connected but did not negotiate HTTP/2. If it was opened as the route's new HTTP/2
     * connection, each request waiting for that connection opens its own.
     */
    public void reportHttp2Unavailable() {
        http2Unavailable = true;
        endConnectionAttempt();
    }

    /**
     * Reports that this channel failed before it became an HTTP/2 connection. If it was opened as the route's new
     * HTTP/2 connection, the requests waiting for that connection fail with the given error.
     *
     * @param failure the error of the failed connection attempt
     */
    public void reportConnectionAttemptFailed(ClientConnectorException failure) {
        connectionAttemptFailure = failure;
        endConnectionAttempt();
    }

    private void endConnectionAttempt() {
        connectionAttemptEnded = true;
        NewConnectionAttempt attempt = newConnectionAttempt;
        if (attempt == null) {
            return;
        }
        if (http2Unavailable) {
            http2ConnectionManager.releaseWaitingRequests(httpRoute, attempt);
        } else {
            http2ConnectionManager.failWaitingRequests(httpRoute, attempt, connectionAttemptFailure);
        }
    }

    public ConnectionAvailabilityFuture getConnectionReadyFuture() {
        return connectionAvailabilityFuture;
    }

    public void setRequestHeaderWritten(boolean isRequestWritten) {
        this.requestHeaderWritten = isRequestWritten;
    }

    public boolean isRequestHeaderWritten() {
        return requestHeaderWritten;
    }

    public HttpRoute getHttpRoute() {
        return httpRoute;
    }

    public void setPool(GenericObjectPool pool) {
        this.pool = pool;
    }

    public void invalidate() {
        if (pool == null) {
            LOG.warn("Pool is not set for the channel: {}. Cannot invalidate.", this);
            return;
        }
        try {
            pool.invalidateObject(this);
        } catch (Exception e) {
            LOG.error("Error while invalidating the channel: {}", this, e);
        }
    }
}
