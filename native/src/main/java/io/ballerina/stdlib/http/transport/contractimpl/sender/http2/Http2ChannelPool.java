/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.netty.channel.Channel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;

/**
 * The ChannelPool maintained for HTTP2 requests. Each channel is grouped per route.
 *
 * @since 6.0.273
 */
class Http2ChannelPool {

    private static final Logger LOG = LoggerFactory.getLogger(Http2ChannelPool.class);
    private final Map<String, PerRouteConnectionPool> perRouteConnectionPools = new HashMap<>();

    PerRouteConnectionPool fetchPerRoutePool(String key) {
        return perRouteConnectionPools.get(key);
    }

    Map<String, PerRouteConnectionPool> getPerRouteConnectionPools() {
        return perRouteConnectionPools;
    }

    /**
     * Entity which holds the pool of connections for a given http route.
     */
    static class PerRouteConnectionPool {

        // Guarded by lock, as are newChannelInitializer and newChannelInitialized
        private final Deque<Http2ClientChannel> http2ClientChannels = new ArrayDeque<>();
        // Maximum number of allowed active streams
        private final int maxActiveStreams;
        private final long maxWaitTimeNanos;
        // Whether the next caller that finds no usable channel should open the new connection
        private boolean newChannelInitializer = true;
        // Whether callers that find no usable channel can open a connection instead of waiting for one
        private boolean newChannelInitialized = false;
        private final ReentrantLock lock = new ReentrantLock();
        private final Condition channelAvailable = lock.newCondition();

        PerRouteConnectionPool(int maxActiveStreams, long maxWaitTimeMillis) {
            this.maxActiveStreams = maxActiveStreams;
            this.maxWaitTimeNanos = TimeUnit.MILLISECONDS.toNanos(maxWaitTimeMillis);
        }

        /**
         * Fetches an active {@code TargetChannel} from the pool and reserves a stream on it. When no channel can take
         * another stream, a single caller gets {@code null} and opens the new connection, while the rest wait until
         * it is added to the pool. A caller that waits longer than a positive pool wait time gets {@code null} and
         * opens its own connection, so a connection attempt that never reports back cannot stall the route.
         *
         * @return active TargetChannel, or {@code null} if the caller should open a new connection
         */
        Http2ClientChannel fetchTargetChannel() {
            lock.lock();
            try {
                long remainingNanos = maxWaitTimeNanos;
                while (true) {
                    Http2ClientChannel http2ClientChannel = reserveStream();
                    if (http2ClientChannel != null) {
                        return http2ClientChannel;
                    }
                    if (newChannelInitializer) {
                        newChannelInitializer = false;
                        return null;
                    }
                    if (newChannelInitialized) {
                        return null;
                    }
                    if (maxWaitTimeNanos <= 0) {  // a non-positive wait time means wait without a limit
                        channelAvailable.await();
                        continue;
                    }
                    if (remainingNanos <= 0) {
                        LOG.warn("Timed out waiting for a new HTTP/2 connection, opening another connection");
                        return null;
                    }
                    remainingNanos = channelAvailable.awaitNanos(remainingNanos);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                LOG.warn("Interrupted before adding the target channel");
                return null;
            } finally {
                lock.unlock();
            }
        }

        private Http2ClientChannel reserveStream() {
            Http2ClientChannel http2ClientChannel;
            while ((http2ClientChannel = http2ClientChannels.peek()) != null) {
                Channel channel = http2ClientChannel.getChannel();
                if (channel == null || !channel.isActive()) {  // if channel is not active, forget it
                    removeHead();
                    continue;
                }
                int activeStreamCount = http2ClientChannel.incrementActiveStreamCount();
                if (activeStreamCount < maxActiveStreams) {
                    return http2ClientChannel;
                }
                if (activeStreamCount == maxActiveStreams) {  // no more streams except this one can be opened
                    http2ClientChannel.markAsExhausted();
                    removeHead();
                    return http2ClientChannel;
                }
                http2ClientChannel.decrementActiveStreamCount();
                http2ClientChannel.markAsExhausted();
                removeHead();
            }
            return null;
        }

        private void removeHead() {
            http2ClientChannels.poll();
            awaitNewChannelIfEmpty();
        }

        // With no channel left, the next caller opens a connection and the rest wait for it
        private void awaitNewChannelIfEmpty() {
            if (http2ClientChannels.isEmpty()) {
                newChannelInitializer = true;
                newChannelInitialized = false;
            }
        }

        void addChannel(Http2ClientChannel http2ClientChannel) {
            lock.lock();
            try {
                http2ClientChannels.add(http2ClientChannel);
                signalChannelAvailable();
            } finally {
                lock.unlock();
            }
        }

        /**
         * Releases a stream reserved on the given channel, and returns the channel to the pool if it was taken out
         * for being exhausted. Done under the pool lock so that it cannot interleave with a caller exhausting it.
         *
         * @param http2ClientChannel the channel the stream belonged to
         */
        void releaseStream(Http2ClientChannel http2ClientChannel) {
            lock.lock();
            try {
                http2ClientChannel.decrementActiveStreamCount();
                Channel channel = http2ClientChannel.getChannel();
                if (!http2ClientChannel.isStale() && http2ClientChannel.resetExhausted() && channel != null
                        && channel.isActive()) {
                    http2ClientChannels.add(http2ClientChannel);
                    signalChannelAvailable();
                }
            } finally {
                lock.unlock();
            }
        }

        void releaseWaitingRequests() {
            lock.lock();
            try {
                signalChannelAvailable();
            } finally {
                lock.unlock();
            }
        }

        void removeChannel(Http2ClientChannel http2ClientChannel) {
            lock.lock();
            try {
                if (http2ClientChannels.remove(http2ClientChannel)) {
                    awaitNewChannelIfEmpty();
                }
            } finally {
                lock.unlock();
            }
        }

        private void signalChannelAvailable() {
            newChannelInitialized = true;
            channelAvailable.signalAll();
        }
    }
}
