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

import io.ballerina.stdlib.http.transport.contract.exceptions.ClientConnectorException;
import io.netty.channel.Channel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
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
    // Written under the connection manager's lock but read without it, including from event loops
    private final Map<String, PerRouteConnectionPool> perRouteConnectionPools = new ConcurrentHashMap<>();

    PerRouteConnectionPool fetchPerRoutePool(String key) {
        return perRouteConnectionPools.get(key);
    }

    Map<String, PerRouteConnectionPool> getPerRouteConnectionPools() {
        return perRouteConnectionPools;
    }

    private enum NewChannelState {
        // The next caller opens a connection and the rest wait for it
        NEEDS_OPENER,
        // A caller is opening a connection that has not been added or failed yet, so the rest wait for it
        OPENING,
        // The last connection did not negotiate HTTP/2, so each caller opens its own
        OPEN_FREELY
    }

    /**
     * Entity which holds the pool of connections for a given http route.
     */
    static class PerRouteConnectionPool {

        // Guarded by lock, as is newChannelState
        private final Deque<Http2ClientChannel> http2ClientChannels = new ArrayDeque<>();
        // Maximum number of allowed active streams
        private final int maxActiveStreams;
        private final long maxWaitTimeNanos;
        // What a caller that finds no usable channel does
        private NewChannelState newChannelState = NewChannelState.NEEDS_OPENER;
        // The attempt the waiting callers wait for while OPENING; only its failure releases them
        private NewConnectionAttempt openingAttempt;
        private final ReentrantLock lock = new ReentrantLock();
        private final Condition channelAvailable = lock.newCondition();

        PerRouteConnectionPool(int maxActiveStreams, long maxWaitTimeMillis) {
            this.maxActiveStreams = maxActiveStreams;
            this.maxWaitTimeNanos = TimeUnit.MILLISECONDS.toNanos(maxWaitTimeMillis);
        }

        /**
         * Fetches an active {@code TargetChannel} from the pool and reserves a stream on it. When no channel can take
         * another stream, a single caller gets {@code null} and opens the new connection, while the rest wait until
         * it is added to the pool. If that connection attempt fails, the waiting callers fail with its error. A caller
         * that waits longer than a positive pool wait time gets {@code null} and opens its own connection, so a
         * connection attempt that never reports back cannot stall the route.
         *
         * @param attempt the caller's attempt, marked as the opener if the caller is to open the new connection
         * @return active TargetChannel, or {@code null} if the caller should open a new connection
         * @throws ClientConnectorException the failure of the connection attempt the caller waited for
         */
        Http2ClientChannel fetchTargetChannel(NewConnectionAttempt attempt) throws ClientConnectorException {
            lock.lock();
            try {
                long remainingNanos = maxWaitTimeNanos;
                NewConnectionAttempt awaited = null;
                while (true) {
                    Http2ClientChannel http2ClientChannel = reserveStream();
                    if (http2ClientChannel != null) {
                        return http2ClientChannel;
                    }
                    if (awaited != null && awaited.getFailure() != null) {
                        throw awaited.getFailure();
                    }
                    if (opensItsOwnConnection(attempt)) {
                        return null;
                    }
                    if (maxWaitTimeNanos > 0 && remainingNanos <= 0) {
                        LOG.warn("Timed out waiting for a new HTTP/2 connection, opening another connection");
                        abandonOpeningAttempt(awaited, attempt);
                        return null;
                    }
                    awaited = openingAttempt;
                    if (maxWaitTimeNanos <= 0) {  // a non-positive wait time means wait without a limit
                        channelAvailable.await();
                    } else {
                        remainingNanos = channelAvailable.awaitNanos(remainingNanos);
                    }
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                LOG.warn("Interrupted before adding the target channel");
                return null;
            } finally {
                lock.unlock();
            }
        }

        // Claims the opening of the route's new connection when none is being opened, so the caller does not wait
        private boolean opensItsOwnConnection(NewConnectionAttempt attempt) {
            if (newChannelState == NewChannelState.OPEN_FREELY) {
                return true;
            }
            if (newChannelState != NewChannelState.NEEDS_OPENER) {
                return false;
            }
            newChannelState = NewChannelState.OPENING;
            openingAttempt = attempt;
            attempt.markAsOpener();
            return true;
        }

        // An attempt that never reported back would keep every later caller waiting, so this caller replaces it
        private void abandonOpeningAttempt(NewConnectionAttempt awaited, NewConnectionAttempt attempt) {
            if (awaited != null && awaited == openingAttempt) {
                newChannelState = NewChannelState.NEEDS_OPENER;
                openingAttempt = null;
                opensItsOwnConnection(attempt);
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

        // With no channel left, the next caller opens a connection and the rest wait for it. When a connection is
        // already being opened, everyone waits for that one instead of opening another.
        private void awaitNewChannelIfEmpty() {
            if (http2ClientChannels.isEmpty() && newChannelState != NewChannelState.OPENING) {
                newChannelState = NewChannelState.NEEDS_OPENER;
            }
        }

        void addChannel(Http2ClientChannel http2ClientChannel, NewConnectionAttempt attempt) {
            lock.lock();
            try {
                http2ClientChannels.add(http2ClientChannel);
                // A channel opened by a caller that stopped waiting leaves the opener's attempt in progress
                if (newChannelState != NewChannelState.OPENING || attempt == openingAttempt) {
                    newChannelState = NewChannelState.NEEDS_OPENER;
                    openingAttempt = null;
                }
                channelAvailable.signalAll();
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
                    channelAvailable.signalAll();
                }
            } finally {
                lock.unlock();
            }
        }

        // The connection was made but did not negotiate HTTP/2, so each waiting caller opens its own
        void releaseWaitingRequests(NewConnectionAttempt attempt) {
            endOpeningAttempt(attempt, null);
        }

        // The waiting callers would most likely fail the same way, so they fail with this attempt's error
        void failWaitingRequests(NewConnectionAttempt attempt, ClientConnectorException failure) {
            endOpeningAttempt(attempt, failure);
        }

        private void endOpeningAttempt(NewConnectionAttempt attempt, ClientConnectorException failure) {
            lock.lock();
            try {
                if (attempt == null || attempt != openingAttempt) {
                    return;
                }
                openingAttempt = null;
                if (failure == null) {
                    newChannelState = NewChannelState.OPEN_FREELY;
                } else {
                    attempt.fail(failure);
                    newChannelState = NewChannelState.NEEDS_OPENER;
                }
                channelAvailable.signalAll();
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
    }
}
