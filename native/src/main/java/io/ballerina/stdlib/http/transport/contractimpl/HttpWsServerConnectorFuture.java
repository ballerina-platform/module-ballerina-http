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
import io.ballerina.stdlib.http.transport.contract.PortBindingEventListener;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.websocket.DefaultWebSocketConnectorFuture;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelFuture;
import io.netty.channel.group.ChannelGroup;
import io.netty.util.concurrent.EventExecutor;
import io.netty.util.concurrent.Future;
import io.netty.util.concurrent.GenericFutureListener;
import io.netty.util.internal.PlatformDependent;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Server connector future implementation.
 */
public class HttpWsServerConnectorFuture extends DefaultWebSocketConnectorFuture implements ServerConnectorFuture {

    private static final String HTTP_CONNECTOR_LISTENER_IS_NOT_SET = "HTTP connector listener is not set";
    private HttpConnectorListener httpConnectorListener;
    private PortBindingEventListener portBindingEventListener;

    private ChannelFuture nettyBindFuture;
    private ChannelGroup allChannels;

    private volatile String openingServerConnectorId;
    private volatile boolean isOpeningSCHttps;
    private volatile String closingServerConnectorId;
    private volatile boolean isClosingSCHttps;
    private volatile Throwable connectorInitException;
    private volatile CountDownLatch handoverLatch;
    private final AtomicBoolean handoverClaimed = new AtomicBoolean();
    private volatile Throwable handoverFailure;
    private EventExecutor terminatingExecutor;
    private GenericFutureListener<Future<Object>> terminationListener;
    private boolean published;
    private boolean cancelRequested;

    /**
     * The state a start was in when its cancellation was requested.
     */
    public enum CancelResult {
        // The bind is still pending, and the port is closed as soon as it is bound
        CANCELLED,
        // The port is already bound and serving, hence the connector has to be stopped
        PUBLISHED
    }

    public HttpWsServerConnectorFuture() {
    }

    public HttpWsServerConnectorFuture(ChannelFuture nettyBindFuture) {
        this.nettyBindFuture = nettyBindFuture;
    }

    public HttpWsServerConnectorFuture(ChannelFuture nettyBindFuture, ChannelGroup allChannels) {
        this.nettyBindFuture = nettyBindFuture;
        this.allChannels = allChannels;
    }

    @Override
    public void setHttpConnectorListener(HttpConnectorListener httpConnectorListener) {
        this.httpConnectorListener = httpConnectorListener;
    }

    @Override
    public void notifyHttpListener(HttpCarbonMessage httpMessage) throws ServerConnectorException {
        if (httpConnectorListener == null) {
            throw new ServerConnectorException(HTTP_CONNECTOR_LISTENER_IS_NOT_SET);
        }
        httpConnectorListener.onMessage(httpMessage);
    }

    @Override
    public void notifyHttpListener(HttpCarbonMessage httpMessage, Http2PushPromise pushPromise)
            throws ServerConnectorException {
        if (httpConnectorListener == null) {
            throw new ServerConnectorException(HTTP_CONNECTOR_LISTENER_IS_NOT_SET);
        }
        httpConnectorListener.onPushResponse(pushPromise.getPromisedStreamId(), httpMessage);
    }

    @Override
    public void notifyHttpListener(Http2PushPromise pushPromise) throws ServerConnectorException {
        if (httpConnectorListener == null) {
            throw new ServerConnectorException(HTTP_CONNECTOR_LISTENER_IS_NOT_SET);
        }
        httpConnectorListener.onPushPromise(pushPromise);
    }

    /**
     * Makes {@link #sync()} wait until the bind callback has handed over the request dispatching.
     *
     * @param handoverLatch counted down by the bind callback
     */
    public void setHandoverLatch(CountDownLatch handoverLatch) {
        this.handoverLatch = handoverLatch;
    }

    /**
     * Claims the right to run the bind callback. Either the bind callback or the termination of the event loop gets
     * it, never both, so the handover latch is counted down exactly once.
     *
     * @return true if the caller owns the handover
     */
    public boolean claimHandover() {
        return handoverClaimed.compareAndSet(false, true);
    }

    /**
     * Fails the start if the event loop terminates before the bind callback has run. Netty does not run a callback
     * that is rejected by a shut down event loop, so without this {@link #sync()} would wait for it forever.
     * This has to be called before the bind callback is added, which releases the registration with
     * {@link #releaseTerminationListener()}.
     *
     * @param executor the event loop that runs the bind callback
     */
    @SuppressWarnings("unchecked")
    public void failHandoverOnTermination(EventExecutor executor) {
        GenericFutureListener<Future<Object>> listener = terminated -> {
            if (claimHandover()) {
                try {
                    handoverFailure = new ServerConnectorException("The event loop was shut down before the " +
                            "listener finished starting");
                    notifyPortBindingError(handoverFailure);
                } finally {
                    CountDownLatch latch = this.handoverLatch;
                    if (latch != null) {
                        latch.countDown();
                    }
                }
            }
        };
        synchronized (this) {
            terminatingExecutor = executor;
            terminationListener = listener;
        }
        ((Future<Object>) executor.terminationFuture()).addListener(listener);
    }

    /**
     * Removes the listener added by {@link #failHandoverOnTermination(EventExecutor)}. The event loop outlives the
     * listeners started on it, so the registration would keep this future reachable.
     */
    @SuppressWarnings("unchecked")
    public void releaseTerminationListener() {
        EventExecutor executor;
        GenericFutureListener<Future<Object>> listener;
        synchronized (this) {
            executor = terminatingExecutor;
            listener = terminationListener;
            terminatingExecutor = null;
            terminationListener = null;
        }
        if (executor != null) {
            ((Future<Object>) executor.terminationFuture()).removeListener(listener);
        }
    }

    /**
     * Runs the given action, which starts serving the bound port, unless the start has been cancelled.
     *
     * @param publisher the action that starts serving the port
     * @return false if the start was cancelled, in which case the action is not run
     */
    public synchronized boolean publish(Runnable publisher) {
        if (cancelRequested) {
            return false;
        }
        publisher.run();
        published = true;
        return true;
    }

    /**
     * Requests the cancellation of a start, for a stop that arrives while the port is being bound.
     *
     * @return whether the start was cancelled, or the port is already being served
     */
    public synchronized CancelResult cancelStart() {
        if (published) {
            return CancelResult.PUBLISHED;
        }
        cancelRequested = true;
        return CancelResult.CANCELLED;
    }

    /**
     * Fails the start, so that {@link #sync()} throws the given failure.
     *
     * @param failure the reason for the failure
     */
    public void failStart(Throwable failure) {
        handoverFailure = failure;
        notifyPortBindingError(failure);
    }

    @Override
    public void sync() throws InterruptedException {
        ChannelFuture bindFuture = nettyBindFuture.sync();
        CountDownLatch latch = this.handoverLatch;
        if (latch != null) {
            latch.await();
        }
        Throwable failure = this.handoverFailure;
        if (failure != null) {
            PlatformDependent.throwException(failure);
        }
        if (this.allChannels != null && bindFuture.channel() != null) {
            this.allChannels.add(bindFuture.channel());
        }
    }

    @Override
    public void notifyErrorListener(Throwable cause) throws ServerConnectorException {
        if (httpConnectorListener == null) {
            throw new ServerConnectorException(HTTP_CONNECTOR_LISTENER_IS_NOT_SET, new Exception(cause));
        }
        httpConnectorListener.onError(cause);
    }

    @Override
    public synchronized void setPortBindingEventListener(PortBindingEventListener portBindingEventListener) {
        this.portBindingEventListener = portBindingEventListener;
        if (openingServerConnectorId != null) {
            notifyPortBindingEvent(openingServerConnectorId, isOpeningSCHttps);
            openingServerConnectorId = null;
            isOpeningSCHttps = false;
        }
        if (closingServerConnectorId != null) {
            notifyPortUnbindingEvent(closingServerConnectorId, isClosingSCHttps);
            closingServerConnectorId = null;
            isClosingSCHttps = false;
        }
        if (connectorInitException != null) {
            notifyPortBindingError(connectorInitException);
            connectorInitException = null;
        }
    }

    @Override
    public synchronized void notifyPortBindingEvent(String serverConnectorId, boolean isHttps) {
        if (portBindingEventListener == null) {
            this.openingServerConnectorId = serverConnectorId;
            this.isOpeningSCHttps = isHttps;
        } else {
            portBindingEventListener.onOpen(serverConnectorId, isHttps);
        }
    }

    @Override
    public synchronized void notifyPortUnbindingEvent(String serverConnectorId, boolean isHttps) {
        if (portBindingEventListener == null) {
            this.closingServerConnectorId = serverConnectorId;
            this.isClosingSCHttps = isHttps;
        } else {
            portBindingEventListener.onClose(serverConnectorId, isHttps);
        }
    }

    @Override
    public synchronized void notifyPortBindingError(Throwable throwable) {
        if (portBindingEventListener == null) {
            this.connectorInitException = throwable;
        } else {
            portBindingEventListener.onError(throwable);
        }
    }
}
