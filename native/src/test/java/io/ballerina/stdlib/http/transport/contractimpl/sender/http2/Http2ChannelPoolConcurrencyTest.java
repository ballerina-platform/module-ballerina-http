/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
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
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.codec.http2.DefaultHttp2Connection;
import io.netty.handler.codec.http2.Http2Connection;
import io.netty.handler.codec.http2.Http2Exception;
import io.netty.handler.codec.http2.Http2Stream;
import org.testng.annotations.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;

import static org.testng.Assert.assertNull;
import static org.testng.Assert.assertSame;
import static org.testng.Assert.assertTrue;
import static org.testng.Assert.fail;

/**
 * Verifies that the HTTP/2 per route pool never leaves a request waiting forever for a channel, whichever way a
 * stream closing on the event loop interleaves with requests exhausting and re-arming the pool.
 */
public class Http2ChannelPoolConcurrencyTest {

    private static final HttpRoute ROUTE = new HttpRoute("http", "localhost", 9090, 0);

    @Test(description = "Requests racing with stream closures at maxActiveStreamsPerConnection must all complete")
    public void testRequestsDoNotHangWhenStreamsCloseWhileThePoolIsExhausted() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(2, 60000);
        AtomicInteger connectionsOpened = new AtomicInteger();
        int workers = 16;
        int requestsPerWorker = 5000;

        ExecutorService executor = Executors.newFixedThreadPool(workers);
        try {
            List<Future<?>> results = new ArrayList<>();
            for (int i = 0; i < workers; i++) {
                results.add(executor.submit(() -> {
                    for (int j = 0; j < requestsPerWorker; j++) {
                        sendRequest(connectionManager, connectionsOpened);
                    }
                    return null;
                }));
            }
            for (Future<?> result : results) {
                try {
                    result.get(60, TimeUnit.SECONDS);
                } catch (TimeoutException e) {
                    fail("A request is stuck waiting for an HTTP/2 channel after " + connectionsOpened.get()
                            + " connections were opened");
                }
            }
        } finally {
            executor.shutdownNow();
        }
        assertTrue(connectionsOpened.get() <= workers,
                   "Opened " + connectionsOpened.get() + " connections for " + workers + " concurrent requests");
    }

    @Test(description = "A request must stop waiting for a connection attempt that never reports back")
    public void testWaitForNewConnectionIsBounded() {
        Http2ConnectionManager connectionManager = newConnectionManager(100, 200);
        assertNull(connectionManager.fetchChannel(ROUTE), "The first request should open the connection");

        long start = System.nanoTime();
        assertNull(connectionManager.fetchChannel(ROUTE), "The waiting request should open its own connection");
        long waitedMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start);
        assertTrue(waitedMillis >= 150 && waitedMillis < 5000, "Waited " + waitedMillis + "ms");
    }

    @Test(description = "A non-positive wait time must wait for the new connection instead of skipping the wait")
    public void testNonPositiveWaitTimeWaitsWithoutALimit() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(100, -1);
        assertNull(connectionManager.fetchChannel(ROUTE), "The first request should open the connection");

        ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            Future<Http2ClientChannel> waitingRequest = executor.submit(() -> connectionManager.fetchChannel(ROUTE));
            assertStillWaiting(waitingRequest);

            Http2ClientChannel http2ClientChannel = newHttp2ClientChannel(connectionManager);
            connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel);
            assertSame(waitingRequest.get(5, TimeUnit.SECONDS), http2ClientChannel);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test(description = "Losing the last channel must let one request open a connection while the rest wait for it")
    public void testRemovingTheLastChannelRearmsThePool() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(100, 60000);
        assertNull(connectionManager.fetchChannel(ROUTE), "The first request should open the connection");
        Http2ClientChannel lostChannel = newHttp2ClientChannel(connectionManager);
        connectionManager.addHttp2ClientChannel(ROUTE, lostChannel);
        connectionManager.removeClientChannel(ROUTE, lostChannel);

        assertNull(connectionManager.fetchChannel(ROUTE), "The next request should open the replacement connection");
        ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            Future<Http2ClientChannel> waitingRequest = executor.submit(() -> connectionManager.fetchChannel(ROUTE));
            assertStillWaiting(waitingRequest);

            Http2ClientChannel replacement = newHttp2ClientChannel(connectionManager);
            connectionManager.addHttp2ClientChannel(ROUTE, replacement);
            assertSame(waitingRequest.get(5, TimeUnit.SECONDS), replacement);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test(description = "An exhausted channel that is closed must not return to the pool when its streams close")
    public void testClosedExhaustedChannelIsNotReturnedToThePool() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(2, 60000);
        assertNull(connectionManager.fetchChannel(ROUTE), "The first request should open the connection");
        Http2ClientChannel http2ClientChannel = newHttp2ClientChannel(connectionManager);
        connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel);
        Http2Stream firstStream = openStream(http2ClientChannel);

        assertSame(connectionManager.fetchChannel(ROUTE), http2ClientChannel, "The channel should take one more");
        openStream(http2ClientChannel);

        http2ClientChannel.getChannel().close().sync();
        firstStream.close();

        assertNull(connectionManager.fetchChannel(ROUTE), "A closed channel must not be handed out");
    }

    private static void assertStillWaiting(Future<Http2ClientChannel> request) throws Exception {
        try {
            Http2ClientChannel http2ClientChannel = request.get(300, TimeUnit.MILLISECONDS);
            fail("The request did not wait for the new connection and got " + http2ClientChannel);
        } catch (TimeoutException expected) {
            // still waiting, as it should
        }
    }

    private static Http2ClientChannel newHttp2ClientChannel(Http2ConnectionManager connectionManager) {
        return new Http2ClientChannel(connectionManager, new DefaultHttp2Connection(false), ROUTE,
                                      new EmbeddedChannel(), null);
    }

    private static Http2Stream openStream(Http2ClientChannel http2ClientChannel) throws Http2Exception {
        Http2Connection connection = http2ClientChannel.getConnection();
        return connection.local().createStream(connection.local().incrementAndGetNextStreamId(), false);
    }

    private static void sendRequest(Http2ConnectionManager connectionManager, AtomicInteger connectionsOpened)
            throws Http2Exception {
        Http2ClientChannel http2ClientChannel = connectionManager.fetchChannel(ROUTE);
        if (http2ClientChannel == null) {
            connectionsOpened.incrementAndGet();
            http2ClientChannel = newHttp2ClientChannel(connectionManager);
            connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel);
        }
        Http2Connection connection = http2ClientChannel.getConnection();
        Http2Stream stream;
        synchronized (connection) {
            stream = connection.local().createStream(connection.local().incrementAndGetNextStreamId(), false);
        }
        Thread.yield();
        synchronized (connection) {
            stream.close();
        }
    }

    private static Http2ConnectionManager newConnectionManager(int maxActiveStreams, long maxWaitTimeMillis) {
        PoolConfiguration poolConfiguration = new PoolConfiguration();
        poolConfiguration.setHttp2MaxActiveStreamsPerConnection(maxActiveStreams);
        poolConfiguration.setMaxWaitTime(maxWaitTimeMillis);
        return new Http2ConnectionManager(poolConfiguration);
    }
}
