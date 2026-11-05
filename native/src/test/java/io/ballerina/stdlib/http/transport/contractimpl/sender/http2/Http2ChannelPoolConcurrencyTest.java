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

import io.ballerina.stdlib.http.transport.contract.exceptions.ClientConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.common.HttpRoute;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http2StateUtil;
import io.ballerina.stdlib.http.transport.contractimpl.sender.TargetHandler;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.TargetChannel;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.PoolConfiguration;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.netty.buffer.Unpooled;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http2.DefaultHttp2Connection;
import io.netty.handler.codec.http2.Http2Connection;
import io.netty.handler.codec.http2.Http2Error;
import io.netty.handler.codec.http2.Http2Exception;
import io.netty.handler.codec.http2.Http2NoMoreStreamIdsException;
import io.netty.handler.codec.http2.Http2Stream;
import org.testng.annotations.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertNull;
import static org.testng.Assert.assertSame;
import static org.testng.Assert.assertTrue;
import static org.testng.Assert.expectThrows;
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
    public void testWaitForNewConnectionIsBounded() throws ClientConnectorException {
        Http2ConnectionManager connectionManager = newConnectionManager(100, 200);
        assertNull(fetch(connectionManager), "The first request should open the connection");

        long start = System.nanoTime();
        assertNull(fetch(connectionManager), "The waiting request should open its own connection");
        long waitedMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start);
        assertTrue(waitedMillis >= 150 && waitedMillis < 5000, "Waited " + waitedMillis + "ms");
    }

    @Test(description = "A non-positive wait time must wait for the new connection instead of skipping the wait")
    public void testNonPositiveWaitTimeWaitsWithoutALimit() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(100, -1);
        NewConnectionAttempt opener = claimNewConnection(connectionManager);

        ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            Future<Http2ClientChannel> waitingRequest = executor.submit(() -> fetch(connectionManager));
            assertStillWaiting(waitingRequest);

            Http2ClientChannel http2ClientChannel = newHttp2ClientChannel(connectionManager);
            connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel, opener);
            assertSame(waitingRequest.get(5, TimeUnit.SECONDS), http2ClientChannel);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test(description = "Losing the last channel must let one request open a connection while the rest wait for it")
    public void testRemovingTheLastChannelRearmsThePool() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(100, 60000);
        NewConnectionAttempt opener = claimNewConnection(connectionManager);
        Http2ClientChannel lostChannel = newHttp2ClientChannel(connectionManager);
        connectionManager.addHttp2ClientChannel(ROUTE, lostChannel, opener);
        connectionManager.removeClientChannel(ROUTE, lostChannel);

        NewConnectionAttempt replacementOpener = claimNewConnection(connectionManager);
        ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            Future<Http2ClientChannel> waitingRequest = executor.submit(() -> fetch(connectionManager));
            assertStillWaiting(waitingRequest);

            Http2ClientChannel replacement = newHttp2ClientChannel(connectionManager);
            connectionManager.addHttp2ClientChannel(ROUTE, replacement, replacementOpener);
            assertSame(waitingRequest.get(5, TimeUnit.SECONDS), replacement);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test(description = "A channel exhausted again while a new connection is opening must not start another one")
    public void testReExhaustedChannelWaitsForTheConnectionBeingOpened() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(2, 60000);
        NewConnectionAttempt opener = claimNewConnection(connectionManager);
        Http2ClientChannel firstChannel = newHttp2ClientChannel(connectionManager);
        connectionManager.addHttp2ClientChannel(ROUTE, firstChannel, opener);
        Http2Stream firstStream = openStream(firstChannel);
        assertSame(fetch(connectionManager), firstChannel, "The channel should take one more");
        openStream(firstChannel);

        NewConnectionAttempt secondOpener = claimNewConnection(connectionManager);
        firstStream.close();
        assertSame(fetch(connectionManager), firstChannel, "The released stream should be reused");

        ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            Future<Http2ClientChannel> waitingRequest = executor.submit(() -> fetch(connectionManager));
            assertStillWaiting(waitingRequest);

            Http2ClientChannel secondChannel = newHttp2ClientChannel(connectionManager);
            connectionManager.addHttp2ClientChannel(ROUTE, secondChannel, secondOpener);
            assertSame(waitingRequest.get(5, TimeUnit.SECONDS), secondChannel);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test(timeOut = 30000,
          description = "A request that stops waiting for an attempt that never reports back must take it over")
    public void testRequestThatStoppedWaitingTakesOverTheOpenerAttempt() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(100, 2000);
        NewConnectionAttempt stalled = claimNewConnection(connectionManager);
        NewConnectionAttempt impatient = new NewConnectionAttempt();
        assertNull(connectionManager.fetchChannel(ROUTE, impatient), "The request should open its own after waiting");
        assertTrue(impatient.isOpener(), "The request should take over opening the connection");

        ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            Future<Http2ClientChannel> waitingRequest = executor.submit(() -> fetch(connectionManager));
            assertStillWaiting(waitingRequest);

            connectionManager.failWaitingRequests(ROUTE, stalled, new ClientConnectorException(null, "Refused"));
            assertStillWaiting(waitingRequest);

            Http2ClientChannel http2ClientChannel = newHttp2ClientChannel(connectionManager);
            connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel, impatient);
            assertSame(waitingRequest.get(5, TimeUnit.SECONDS), http2ClientChannel);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test(description = "An exhausted channel that is closed must not return to the pool when its streams close")
    public void testClosedExhaustedChannelIsNotReturnedToThePool() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(2, 60000);
        NewConnectionAttempt opener = claimNewConnection(connectionManager);
        Http2ClientChannel http2ClientChannel = newHttp2ClientChannel(connectionManager);
        connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel, opener);
        Http2Stream firstStream = openStream(http2ClientChannel);

        assertSame(fetch(connectionManager), http2ClientChannel, "The channel should take one more");
        openStream(http2ClientChannel);

        http2ClientChannel.getChannel().close().sync();
        firstStream.close();

        assertNull(fetch(connectionManager), "A closed channel must not be handed out");
    }

    @Test(description = "Only the failure of the attempt opening the connection releases the requests waiting for it")
    public void testUnrelatedFailureDoesNotReleaseWaitingRequests() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(2, -1);
        NewConnectionAttempt opener = new NewConnectionAttempt();
        assertNull(connectionManager.fetchChannel(ROUTE, opener), "The first request should open the connection");
        assertTrue(opener.isOpener());

        ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            NewConnectionAttempt waiter = new NewConnectionAttempt();
            Future<Http2ClientChannel> waitingRequest = executor.submit(() -> connectionManager.fetchChannel(ROUTE,
                                                                                                            waiter));
            assertStillWaiting(waitingRequest);

            connectionManager.releaseWaitingRequests(ROUTE, new NewConnectionAttempt());
            assertStillWaiting(waitingRequest);

            connectionManager.releaseWaitingRequests(ROUTE, opener);
            assertNull(waitingRequest.get(5, TimeUnit.SECONDS), "The released request should open its own connection");
            assertFalse(waiter.isOpener());
        } finally {
            executor.shutdownNow();
        }
    }

    @Test(timeOut = 30000,
          description = "Requests waiting for a connection attempt fail with its error as soon as it fails")
    public void testWaitingRequestsFailWithTheFailedAttemptsError() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(100, -1);
        NewConnectionAttempt opener = new NewConnectionAttempt();
        assertNull(connectionManager.fetchChannel(ROUTE, opener), "The first request should open the connection");

        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            List<Future<Http2ClientChannel>> waitingRequests = new ArrayList<>();
            for (int i = 0; i < 2; i++) {
                waitingRequests.add(executor.submit(() -> connectionManager.fetchChannel(ROUTE,
                                                                                         new NewConnectionAttempt())));
            }
            for (Future<Http2ClientChannel> waitingRequest : waitingRequests) {
                assertStillWaiting(waitingRequest);
            }

            ClientConnectorException failure = new ClientConnectorException(null, "Connection refused");
            connectionManager.failWaitingRequests(ROUTE, opener, failure);
            for (Future<Http2ClientChannel> waitingRequest : waitingRequests) {
                ExecutionException failed = expectThrows(ExecutionException.class,
                                                          () -> waitingRequest.get(5, TimeUnit.SECONDS));
                assertSame(failed.getCause(), failure);
            }

            NewConnectionAttempt nextAttempt = new NewConnectionAttempt();
            assertNull(connectionManager.fetchChannel(ROUTE, nextAttempt), "The next request should open again");
            assertTrue(nextAttempt.isOpener());
        } finally {
            executor.shutdownNow();
        }
    }

    @Test(timeOut = 30000,
          description = "An unexpected user event on the connection being opened must not fail the requests waiting")
    public void testUnexpectedUserEventDoesNotFailWaitingRequests() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(100, -1);
        NewConnectionAttempt opener = new NewConnectionAttempt();
        assertNull(connectionManager.fetchChannel(ROUTE, opener), "The first request should open the connection");
        TargetChannel targetChannel = new TargetChannel(null, null, ROUTE, null);
        targetChannel.setNewConnectionAttempt(opener, connectionManager);
        TargetHandler targetHandler = new TargetHandler();
        targetHandler.setTargetChannel(targetChannel);
        EmbeddedChannel connection = new EmbeddedChannel(targetHandler);
        targetChannel.setChannel(connection);

        ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            Future<Http2ClientChannel> waitingRequest = executor.submit(() -> fetch(connectionManager));
            assertStillWaiting(waitingRequest);

            connection.pipeline().fireUserEventTriggered("unexpected");
            assertStillWaiting(waitingRequest);

            Http2ClientChannel http2ClientChannel = newHttp2ClientChannel(connectionManager);
            connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel, opener);
            assertSame(waitingRequest.get(5, TimeUnit.SECONDS), http2ClientChannel);
        } finally {
            executor.shutdownNow();
        }
    }

    private static Http2ClientChannel fetch(Http2ConnectionManager connectionManager)
            throws ClientConnectorException {
        return connectionManager.fetchChannel(ROUTE, new NewConnectionAttempt());
    }

    private static NewConnectionAttempt claimNewConnection(Http2ConnectionManager connectionManager)
            throws ClientConnectorException {
        NewConnectionAttempt attempt = new NewConnectionAttempt();
        assertNull(connectionManager.fetchChannel(ROUTE, attempt), "The request should open a new connection");
        assertTrue(attempt.isOpener(), "The request should be the one opening the connection");
        return attempt;
    }

    @Test(description = "A closed server-pushed stream must not free a slot it never reserved")
    public void testClosedPushStreamDoesNotFreeASlot() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(2, 60000);
        NewConnectionAttempt opener = claimNewConnection(connectionManager);
        Http2ClientChannel http2ClientChannel = newHttp2ClientChannel(connectionManager);
        connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel, opener);
        Http2Stream openerStream = openStream(http2ClientChannel);

        Http2Connection connection = http2ClientChannel.getConnection();
        Http2Stream pushStream =
                connection.remote().reservePushStream(connection.remote().incrementAndGetNextStreamId(), openerStream);
        pushStream.open(false).close();

        assertSame(fetch(connectionManager), http2ClientChannel, "The channel should take one more");
        assertNull(fetch(connectionManager), "The channel was full, but handed out a third stream");
    }

    @Test(description = "A stream refused by GOAWAY must release its slot once, when Netty closes it")
    public void testStreamRefusedByGoAwayIsReleasedOnce() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(100, 60000);
        NewConnectionAttempt opener = claimNewConnection(connectionManager);
        Http2ClientChannel http2ClientChannel = newHttp2ClientChannel(connectionManager);
        connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel, opener);
        Http2Stream acceptedStream = openStream(http2ClientChannel);
        http2ClientChannel.putInFlightMessage(acceptedStream.id(), newOutboundMsgHolder());
        assertSame(fetch(connectionManager), http2ClientChannel, "The channel should take one more");
        Http2Stream refusedStream = openStream(http2ClientChannel);
        http2ClientChannel.putInFlightMessage(refusedStream.id(), newOutboundMsgHolder());

        http2ClientChannel.getConnection().goAwayReceived(acceptedStream.id(), Http2Error.NO_ERROR.code(),
                                                          Unpooled.EMPTY_BUFFER);

        assertEquals(http2ClientChannel.incrementActiveStreamCount() - 1, 1,
                     "Only the stream the server accepted should still hold a slot");
    }

    @Test(description = "A stream the connection refuses to open must not keep its slot")
    public void testStreamThatCannotBeOpenedReleasesItsSlot() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(2, 60000);
        NewConnectionAttempt opener = claimNewConnection(connectionManager);
        Http2ClientChannel http2ClientChannel = newHttp2ClientChannel(connectionManager);
        connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel, opener);
        openStream(http2ClientChannel);
        // The server allows fewer concurrent streams than the pool expects
        http2ClientChannel.getConnection().local().maxActiveStreams(1);

        assertSame(fetch(connectionManager), http2ClientChannel, "The channel should take one more");
        expectThrows(Http2Exception.class, () -> Http2StateUtil.initiateStream(null,
                http2ClientChannel.getConnection(), http2ClientChannel, newOutboundMsgHolder()));

        assertSame(fetch(connectionManager), http2ClientChannel, "The refused stream still holds its slot");
    }

    @Test(description = "The rest of a request whose stream was refused must not release the slot again")
    public void testLaterChunksOfARefusedRequestDoNotReleaseTheSlotAgain() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(2, 60000);
        NewConnectionAttempt opener = claimNewConnection(connectionManager);
        Http2ClientChannel http2ClientChannel = newHttp2ClientChannel(connectionManager);
        connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel, opener);
        openStream(http2ClientChannel);
        http2ClientChannel.getConnection().local().maxActiveStreams(1);
        assertSame(fetch(connectionManager), http2ClientChannel, "The channel should take one more");

        Http2TargetHandler targetHandler = new Http2TargetHandler(http2ClientChannel.getConnection(), null);
        targetHandler.setHttp2ClientChannel(http2ClientChannel);
        Http2TargetHandler.Http2RequestWriter requestWriter =
                targetHandler.new Http2RequestWriter(newOutboundMsgHolder());
        List<HttpContent> body = List.of(new DefaultHttpContent(Unpooled.wrappedBuffer(new byte[16])),
                                         new DefaultHttpContent(Unpooled.wrappedBuffer(new byte[16])),
                                         new DefaultLastHttpContent(Unpooled.wrappedBuffer(new byte[16])));
        expectThrows(Http2Exception.class, () -> requestWriter.writeContent(null, body.get(0)));
        requestWriter.writeContent(null, body.get(1));
        requestWriter.writeContent(null, body.get(2));

        for (HttpContent content : body) {
            assertEquals(content.refCnt(), 0, "A chunk of the refused request was not released");
        }
        assertSame(fetch(connectionManager), http2ClientChannel, "The released slot should be reused");
        assertNull(fetch(connectionManager), "The channel was full, but handed out a third stream");
    }

    @Test(description = "A channel out of stream ids must not return to the pool when its reserved slot is released")
    public void testChannelOutOfStreamIdsIsNotHandedOutAgain() throws Exception {
        Http2ConnectionManager connectionManager = newConnectionManager(100, 60000);
        NewConnectionAttempt opener = claimNewConnection(connectionManager);
        Http2ClientChannel http2ClientChannel = newHttp2ClientChannel(connectionManager);
        connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel, opener);
        http2ClientChannel.getConnection().local().createStream(Integer.MAX_VALUE, false);
        assertSame(fetch(connectionManager), http2ClientChannel, "The channel should take one more");

        expectThrows(Http2NoMoreStreamIdsException.class, () -> Http2StateUtil.initiateStream(null,
                http2ClientChannel.getConnection(), http2ClientChannel, newOutboundMsgHolder()));

        assertTrue(http2ClientChannel.isStale());
        assertNull(fetch(connectionManager), "A channel out of stream ids was handed out again");
    }

    private static OutboundMsgHolder newOutboundMsgHolder() {
        return new OutboundMsgHolder(
                new HttpCarbonRequest(new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.GET, "/")));
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
            throws Http2Exception, ClientConnectorException {
        NewConnectionAttempt attempt = new NewConnectionAttempt();
        Http2ClientChannel http2ClientChannel = connectionManager.fetchChannel(ROUTE, attempt);
        if (http2ClientChannel == null) {
            connectionsOpened.incrementAndGet();
            http2ClientChannel = newHttp2ClientChannel(connectionManager);
            connectionManager.addHttp2ClientChannel(ROUTE, http2ClientChannel, attempt);
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
