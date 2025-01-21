/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.contractimpl.sender.http2;

import io.ballerina.stdlib.http.transport.contractimpl.common.HttpRoute;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http2MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.PoolConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.locks.ReentrantLock;

/**
 * {@code Http2ConnectionManager} Manages HTTP/2 connections.
 */
public class Http2ConnectionManager {

    Logger logger = LoggerFactory.getLogger(this.getClass());

    private final Http2ChannelPool http2ChannelPool = new Http2ChannelPool();
    private final BlockingQueue<Http2ClientChannel> http2StaleClientChannels = new LinkedBlockingQueue<>();
    private final PoolConfiguration poolConfiguration;
    private final ReentrantLock lock = new ReentrantLock();

    public Http2ConnectionManager(PoolConfiguration poolConfiguration) {
        this.poolConfiguration = poolConfiguration;
        initiateConnectionEvictionTask();
    }

    /**
     * Add a given {@link Http2ClientChannel} to the PerRoutePool. Based on the HttpRoute, each channel will be located
     * in the Http2ChannelPool.
     *
     * @param httpRoute          http route
     * @param http2ClientChannel newly created http/2 client channel
     */
    public void addHttp2ClientChannel(HttpRoute httpRoute, Http2ClientChannel http2ClientChannel) {
        String key = generateKey(httpRoute);
        final Http2ChannelPool.PerRouteConnectionPool perRouteConnectionPool =
                getOrCreatePerRoutePool(this.http2ChannelPool, key);
        perRouteConnectionPool.addChannel(http2ClientChannel);

        // Configure a listener to remove connection from pool when it is closed
        http2ClientChannel.getChannel().closeFuture().
                addListener(future -> {
                                Http2ChannelPool.PerRouteConnectionPool pool =
                                        this.http2ChannelPool.fetchPerRoutePool(key);
                                if (pool != null) {
                                    pool.removeChannel(http2ClientChannel);
                                    http2ClientChannel.getDataEventListeners().
                                            forEach(Http2DataEventListener::destroy);
                                }
                            }
                );
    }

    /**
     * Release the count down latch. If the connection upgrade is rejected, the H2Pool count down latch will not be
     * release as the channel is not added. In such instances, forcefully reduces the count down to allow subsequent
     * requests to proceed.
     *
     * @param httpRoute  the route key
     */
    public void releasePerRoutePoolLatch(HttpRoute httpRoute) {
        String key = generateKey(httpRoute);
        Http2ChannelPool.PerRouteConnectionPool perRouteConnectionPool = this.http2ChannelPool.fetchPerRoutePool(key);
        if (perRouteConnectionPool != null) {
            perRouteConnectionPool.releaseCountdown();
        }
    }

    /**
     * Get or create the per route pool.
     *
     * @param pool the HTTP2 channel pool
     * @param key  the route key
     * @return PerRouteConnectionPool
     */
    private Http2ChannelPool.PerRouteConnectionPool getOrCreatePerRoutePool(Http2ChannelPool pool, String key) {
        final Http2ChannelPool.PerRouteConnectionPool perRouteConnectionPool = pool.fetchPerRoutePool(key);
        if (perRouteConnectionPool != null) {
            return perRouteConnectionPool;
        }
        return createPerRouteConnectionPool(pool, key);
    }

    /**
     * Create the per route pool synchronized manner to avoid multiple pool creating for the same route.
     *
     * @param pool the HTTP2 channel pool
     * @param key  the route key
     * @return PerRouteConnectionPool
     */
    private Http2ChannelPool.PerRouteConnectionPool createPerRouteConnectionPool(
            Http2ChannelPool pool, String key) {
        lock.lock();
        try {
            Http2ChannelPool.PerRouteConnectionPool perRouteConnectionPool = pool.getPerRouteConnectionPools().get(key);
            if (perRouteConnectionPool == null) {
                perRouteConnectionPool = new Http2ChannelPool.PerRouteConnectionPool(Integer.MAX_VALUE);
                pool.getPerRouteConnectionPools().put(key, perRouteConnectionPool);
            }
            return perRouteConnectionPool;
        } finally {
            lock.unlock();
        }
    }

    /**
     * Borrow an HTTP/2 client channel.
     *
     * @param httpRoute the http route
     * @return Http2ClientChannel
     */
    public Http2ClientChannel fetchChannel(HttpRoute httpRoute) {
        Http2ChannelPool.PerRouteConnectionPool perRouteConnectionPool;
        perRouteConnectionPool = getOrCreatePerRoutePool(this.http2ChannelPool, generateKey(httpRoute));
        return perRouteConnectionPool != null ? perRouteConnectionPool.fetchTargetChannel() : null;
    }

    /**
     * Return the http/2 client channel to per route pool.
     *
     * @param httpRoute          the http route
     * @param http2ClientChannel represents the http/2 client channel
     */
    void returnClientChannel(HttpRoute httpRoute, Http2ClientChannel http2ClientChannel) {
        Http2ChannelPool.PerRouteConnectionPool perRouteConnectionPool = fetchPerRoutePool(httpRoute);
        if (perRouteConnectionPool != null) {
            perRouteConnectionPool.addChannel(http2ClientChannel);
        }
    }

    /**
     * Remove http/2 client channel from per route pool.
     *
     * @param httpRoute          the http route
     * @param http2ClientChannel represents the http/2 client channel to be removed
     */
    void removeClientChannel(HttpRoute httpRoute, Http2ClientChannel http2ClientChannel) {
        Http2ChannelPool.PerRouteConnectionPool perRouteConnectionPool = fetchPerRoutePool(httpRoute);
        if (perRouteConnectionPool != null) {
            perRouteConnectionPool.removeChannel(http2ClientChannel);
        }
    }

    void markClientChannelAsStale(HttpRoute httpRoute, Http2ClientChannel http2ClientChannel) {
        Http2ChannelPool.PerRouteConnectionPool perRouteConnectionPool = fetchPerRoutePool(httpRoute);
        if (perRouteConnectionPool != null) {
            perRouteConnectionPool.removeChannel(http2ClientChannel);
        }
        http2ClientChannel.setTimeSinceMarkedAsStale(System.currentTimeMillis());
        http2StaleClientChannels.add(http2ClientChannel);
    }

    void removeClosedChannelFromStalePool(Http2ClientChannel http2ClientChannel) {
        if (!http2StaleClientChannels.remove(http2ClientChannel)) {
            logger.warn("Specified channel does not exist in the stale list.");
        }
    }

    private void initiateConnectionEvictionTask() {
        Timer timer = new Timer(true);
        TimerTask timerTask = new TimerTask() {
            @Override
            public void run() {
                http2StaleClientChannels.forEach(http2ClientChannel -> {
                    if (poolConfiguration.getMinIdleTimeInStaleState() == -1) {
                        if (!http2ClientChannel.hasInFlightMessages()) {
                            closeChannelAndEvict(http2ClientChannel);
                        }
                    } else if ((System.currentTimeMillis() - http2ClientChannel.getTimeSinceMarkedAsStale()) >
                            poolConfiguration.getMinIdleTimeInStaleState()) {
                        http2ClientChannel.getInFlightMessages().forEach((streamId, outboundMsgHolder) -> {
                            Http2MessageStateContext messageStateContext =
                                    outboundMsgHolder.getRequest().getHttp2MessageStateContext();
                            if (messageStateContext != null) {
                                messageStateContext.getSenderState().handleConnectionClose(outboundMsgHolder);
                            }
                        });
                        closeChannelAndEvict(http2ClientChannel);
                    }
                });
            }

            public void closeChannelAndEvict(Http2ClientChannel http2ClientChannel) {
                removeClosedChannelFromStalePool(http2ClientChannel);
                http2ClientChannel.getConnection().close(http2ClientChannel.getChannel().newPromise());
            }
        };
        timer.schedule(timerTask, poolConfiguration.getTimeBetweenStaleEviction(),
                poolConfiguration.getTimeBetweenStaleEviction());
    }

    private Http2ChannelPool.PerRouteConnectionPool fetchPerRoutePool(HttpRoute httpRoute) {
        String key = generateKey(httpRoute);
        return this.http2ChannelPool.fetchPerRoutePool(key);
    }

    private String generateKey(HttpRoute httpRoute) {
        return httpRoute.getScheme() + ":" + httpRoute.getHost() + ":" + httpRoute.getPort() + ":" +
                httpRoute.getConfigHash();
    }
}
