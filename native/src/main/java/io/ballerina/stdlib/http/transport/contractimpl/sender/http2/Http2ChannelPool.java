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

import io.ballerina.stdlib.http.transport.internal.ResourceLock;
import io.netty.channel.Channel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.LinkedBlockingQueue;

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

        private final BlockingQueue<Http2ClientChannel> http2ClientChannels = new LinkedBlockingQueue<>();
        // Maximum number of allowed active streams
        private final int maxActiveStreams;
        private CountDownLatch newChannelInitializerLatch = new CountDownLatch(1);
        private final ResourceLock lock = new ResourceLock(); // Use ResourceLock here
        private boolean newChannelInitializer = true;

        PerRouteConnectionPool(int maxActiveStreams) {
            this.maxActiveStreams = maxActiveStreams;
        }

        /**
         * Fetches an active {@code TargetChannel} from the pool. The first thread will add the channel to the pool. It
         * is handled using a CountDownLatch. Subsequent threads will reuse the channel. Once the maxActiveStreams
         * reaches in the channel, a new channel will be added to handle the excess requests. At that point also new
         * channel addition happens through a synchronized manner to avoid multiple channels getting added to the pool.
         *
         * @return active TargetChannel
         */
        Http2ClientChannel fetchTargetChannel() {
            waitTillNewChannelInitialized();
            if (!http2ClientChannels.isEmpty()) {
                Http2ClientChannel http2ClientChannel = http2ClientChannels.peek();
                if (http2ClientChannel == null) {  // if channel is not active, forget it and fetch next one
                    return fetchTargetChannel();
                }
                Channel channel = http2ClientChannel.getChannel();
                if (channel == null) {  // if channel is not active, forget it and fetch next one
                    removeChannel(http2ClientChannel);
                    return fetchTargetChannel();
                }
                // increment and get active stream count
                int activeStreamCount = http2ClientChannel.incrementActiveStreamCount();

                if (activeStreamCount < maxActiveStreams) {  // safe to fetch the Target Channel
                    return http2ClientChannel;
                } else if (activeStreamCount == maxActiveStreams) {  // no more streams except this one can be opened
                    http2ClientChannel.markAsExhausted();
                    removeChannel(http2ClientChannel);
                    // When the stream count reaches maxActiveStreams, a new channel will be added only if the
                    // channel queue is empty. This process is synchronized as transport thread can return channels
                    // after being reset. If such channel is returned before the new CountDownLatch, the subsequent
                    // ballerina thread will not take http1.1 thread as the channels queue is not empty. In such cases,
                    // threads wait on the countdown latch cannot be released until another thread is returned. Hence
                    // synchronized on a lock
                    try (ResourceLock ignored = lock.obtain()) {
                        if (http2ClientChannels.isEmpty()) {
                            newChannelInitializer = true;
                            newChannelInitializerLatch = new CountDownLatch(1);
                        }
                    }
                    return http2ClientChannel;
                } else {
                    removeChannel(http2ClientChannel);
                    return fetchTargetChannel();    // fetch the next one from the queue
                }
            }
            return null;
        }

        void addChannel(Http2ClientChannel http2ClientChannel) {
            http2ClientChannels.add(http2ClientChannel);
            releaseCountdown();
        }

        void releaseCountdown() {
            try (ResourceLock ignored = lock.obtain()) {
                newChannelInitializerLatch.countDown();
            }
        }

        void removeChannel(Http2ClientChannel http2ClientChannel) {
            http2ClientChannels.remove(http2ClientChannel);
        }

        private void waitTillNewChannelInitialized() {
            try {
                if (newChannelInitializer) {
                    newChannelInitializer = false;
                } else {
                    newChannelInitializerLatch.await();
                }
            } catch (InterruptedException e) {
                LOG.warn("Interrupted before adding the target channel");
            }
        }
    }
}
