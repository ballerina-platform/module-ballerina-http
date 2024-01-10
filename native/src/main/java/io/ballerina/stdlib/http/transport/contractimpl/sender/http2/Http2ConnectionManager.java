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
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.PoolConfiguration;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 * {@code Http2ConnectionManager} Manages HTTP/2 connections.
 */
public class Http2ConnectionManager {

    private final Http2ChannelPool http2ChannelPool = new Http2ChannelPool();
    private final PoolConfiguration poolConfiguration;
    private Lock lock = new ReentrantLock();

    public Http2ConnectionManager(PoolConfiguration poolConfiguration) {
        this.poolConfiguration = poolConfiguration;
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
    private synchronized Http2ChannelPool.PerRouteConnectionPool createPerRouteConnectionPool(
            Http2ChannelPool pool, String key) {
        return pool.getPerRouteConnectionPools()
                .computeIfAbsent(key, p -> new Http2ChannelPool.PerRouteConnectionPool(
                        this.poolConfiguration.getHttp2MaxActiveStreamsPerConnection()));
    }

    /**
     * Borrow an HTTP/2 client channel.
     *
     * @param httpRoute the http route
     * @return Http2ClientChannel
     */
    public Http2ClientChannel borrowChannel(HttpRoute httpRoute) {
        Http2ChannelPool.PerRouteConnectionPool perRouteConnectionPool;
        try {
            getLock().lock();
            perRouteConnectionPool = getOrCreatePerRoutePool(this.http2ChannelPool, generateKey(httpRoute));

            Http2ClientChannel http2ClientChannel = null;
            if (perRouteConnectionPool != null) {
                http2ClientChannel = perRouteConnectionPool.fetchTargetChannel();
            }
            return http2ClientChannel;
        } finally {
            getLock().unlock();
        }
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

    private Http2ChannelPool.PerRouteConnectionPool fetchPerRoutePool(HttpRoute httpRoute) {
        String key = generateKey(httpRoute);
        return this.http2ChannelPool.fetchPerRoutePool(key);
    }

    private String generateKey(HttpRoute httpRoute) {
        return httpRoute.getScheme() + ":" + httpRoute.getHost() + ":" + httpRoute.getPort() + ":" +
                httpRoute.getConfigHash();
    }

    public Lock getLock() {
        return lock;
    }
}
