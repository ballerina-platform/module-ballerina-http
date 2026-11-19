/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport;

import io.ballerina.stdlib.http.transport.contract.CallDeadline;
import io.ballerina.stdlib.http.transport.contract.CallExchange;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.CallCancelledException;
import io.ballerina.stdlib.http.transport.contract.exceptions.CallTimeoutException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.message.ResponseHandle;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertNull;
import static org.testng.Assert.assertTrue;

/**
 * Tests that the total timeout of an HTTP/1.1 call, and a cancel by the caller, abort the exchange by closing its
 * connection, and that they do so only while the connection still belongs to the call.
 * <p>
 * The backend is a plain socket, so the tests see exactly when the client closes the connection.
 */
public class CallDeadlineTestCase {

    // Long enough that the idle timeout never fires first, so any failure within a test is from the deadline
    private static final int IDLE_TIMEOUT_MILLIS = 60000;
    private static final long DEADLINE_MILLIS = 1000;
    private static final int PORT = TestUtil.HTTP_SERVER_PORT;

    private Backend backend;
    private HttpWsConnectorFactory connectorFactory;

    @AfterMethod(alwaysRun = true)
    public void cleanUp() throws InterruptedException {
        if (backend != null) {
            backend.close();
        }
        if (connectorFactory != null) {
            connectorFactory.shutdown();
        }
    }

    @Test(timeOut = 60000)
    public void testDeadlineClosesTheConnectionWhileWaitingForTheResponse() throws Exception {
        backend = new Backend(PORT, Backend::swallowRequestAndStay);
        HttpClientConnector client = createClient(new SenderConfiguration());

        long start = System.nanoTime();
        DefaultHttpConnectorListener listener = send(client, withDeadline(newRequest(), DEADLINE_MILLIS));
        assertNotNull(listener.getHttpErrorMessage(), "The call did not fail");
        long elapsedMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start);

        assertTrue(listener.getHttpErrorMessage() instanceof CallTimeoutException,
                   "Expected a CallTimeoutException but got " + listener.getHttpErrorMessage());
        assertTrue(listener.getHttpErrorMessage().getMessage().startsWith(Constants.CALL_TIMEOUT_EXCEEDED));
        assertTrue(elapsedMillis >= DEADLINE_MILLIS - 100 && elapsedMillis < DEADLINE_MILLIS + 4000,
                   "The call failed after " + elapsedMillis + " ms");
        assertTrue(backend.connectionClosedByClient.get(0).await(10, TimeUnit.SECONDS),
                   "The client did not close the connection");
    }

    @Test(timeOut = 60000)
    public void testDeadlineCoversTheBodyReadAfterTheResponseIsReturned() throws Exception {
        backend = new Backend(PORT, Backend::sendHeadersAndPartOfTheBodyThenStay);
        HttpClientConnector client = createClient(new SenderConfiguration());

        DefaultHttpConnectorListener listener = send(client, withDeadline(newRequest(), DEADLINE_MILLIS));
        HttpCarbonMessage response = listener.getHttpResponseMessage();
        assertNotNull(response, "The response did not arrive: " + listener.getHttpErrorMessage());

        long start = System.nanoTime();
        Throwable failure = readBodyFailure(response);
        long elapsedMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start);

        assertNotNull(failure, "The body ended without failing");
        assertTrue(messageOf(failure).startsWith(Constants.CALL_TIMEOUT_EXCEEDED),
                   "The body failed with: " + messageOf(failure));
        assertTrue(elapsedMillis < 10000, "The body read ended after " + elapsedMillis + " ms");
        assertTrue(backend.connectionClosedByClient.get(0).await(10, TimeUnit.SECONDS),
                   "The client did not close the connection");
    }

    @Test(timeOut = 60000)
    public void testConnectionReusedAfterCallEndedIsNotClosedByItsDeadline() throws Exception {
        // The first call responds at once and ends well before its deadline, and the second call, on the connection the
        // first one has given back, takes longer than that deadline
        backend = new Backend(PORT, (backend, socket, connection) -> {
            backend.readRequest(socket, connection);
            Backend.respond(socket, "first");
            backend.readRequest(socket, connection);
            Thread.sleep(2 * DEADLINE_MILLIS + 500);
            Backend.respond(socket, "second");
            Backend.awaitEof(socket);
        });
        HttpClientConnector client = createClient(new SenderConfiguration());

        DefaultHttpConnectorListener first = send(client, withDeadline(newRequest(), DEADLINE_MILLIS));
        assertEquals(bodyOf(first.getHttpResponseMessage()), "first");

        DefaultHttpConnectorListener second = send(client, newRequest());
        assertNull(second.getHttpErrorMessage(), "The second call was failed by the first call's deadline: "
                + second.getHttpErrorMessage());
        assertEquals(bodyOf(second.getHttpResponseMessage()), "second");
        assertEquals(backend.accepted.get(), 1, "The second call did not reuse the connection");
    }

    @Test(timeOut = 60000)
    public void testCancelClosesTheConnection() throws Exception {
        backend = new Backend(PORT, Backend::swallowRequestAndStay);
        HttpClientConnector client = createClient(new SenderConfiguration());
        HttpCarbonMessage request = newRequest();
        request.setProperty(Constants.CALL_CANCELLABLE, true);

        CompletableFuture<ResponseHandle> handle = new CompletableFuture<>();
        HttpResponseFuture future = client.send(request);
        future.setResponseHandleListener(new HttpClientConnectorListener() {
            @Override
            public void onResponseHandle(ResponseHandle responseHandle) {
                handle.complete(responseHandle);
            }

            @Override
            public void onError(Throwable throwable) {
                handle.completeExceptionally(throwable);
            }
        });
        ResponseHandle responseHandle = handle.get(10, TimeUnit.SECONDS);
        assertTrue(backend.requestReceived.get(0).await(10, TimeUnit.SECONDS), "The request did not arrive");

        CountDownLatch done = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(done);
        client.getResponse(responseHandle).setHttpConnectorListener(listener);
        CallExchange.of(responseHandle.getOutboundMsgHolder().getRequest())
                .abort(new CallCancelledException(Constants.CALL_CANCELLED, -1));

        assertTrue(done.await(10, TimeUnit.SECONDS), "The cancelled call did not complete");
        assertTrue(listener.getHttpErrorMessage() instanceof CallCancelledException,
                   "Expected a CallCancelledException but got " + listener.getHttpErrorMessage());
        assertTrue(backend.connectionClosedByClient.get(0).await(10, TimeUnit.SECONDS),
                   "The client did not close the connection");
    }

    @Test(timeOut = 60000)
    public void testDeadlineBoundsTheWaitForAConnectionFromTheExhaustedPool() throws Exception {
        // The one connection of the pool is held by a call that is never answered, until the backend lets it go
        CompletableFuture<Void> releaseFirstConnection = new CompletableFuture<>();
        AtomicInteger connections = new AtomicInteger();
        backend = new Backend(PORT, (backend, socket, connection) -> {
            if (connections.incrementAndGet() == 1) {
                backend.readRequest(socket, connection);
                releaseFirstConnection.get();
                socket.close();
            } else {
                backend.readRequest(socket, connection);
                Backend.respond(socket, "served");
                Backend.awaitEof(socket);
            }
        });
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.getPoolConfiguration().setMaxActivePerPool(1);
        senderConfiguration.getPoolConfiguration().setMaxWaitTime(30000);
        HttpClientConnector client = createClient(senderConfiguration);

        CountDownLatch holderSent = new CountDownLatch(1);
        DefaultHttpConnectorListener holder = new DefaultHttpConnectorListener(holderSent);
        client.send(newRequest()).setHttpConnectorListener(holder);
        assertTrue(backend.requestReceived.get(0).await(10, TimeUnit.SECONDS), "The request did not arrive");

        long start = System.nanoTime();
        DefaultHttpConnectorListener waiting = send(client, withDeadline(newRequest(), DEADLINE_MILLIS));
        long elapsedMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start);
        assertTrue(waiting.getHttpErrorMessage() instanceof CallTimeoutException,
                   "Expected a CallTimeoutException but got " + waiting.getHttpErrorMessage());
        assertTrue(elapsedMillis < 10000, "The wait for the connection ended after " + elapsedMillis
                + " ms, instead of with the deadline");

        // The slot the abandoned wait asked for was given back, so a later call gets a connection
        releaseFirstConnection.complete(null);
        assertTrue(holderSent.await(10, TimeUnit.SECONDS), "The held call did not end when its connection closed");
        DefaultHttpConnectorListener later = send(client, newRequest());
        assertNull(later.getHttpErrorMessage(), "A later call failed: " + later.getHttpErrorMessage());
        assertEquals(bodyOf(later.getHttpResponseMessage()), "served");
    }

    @Test(timeOut = 60000)
    public void testCallWhoseDeadlineHasRunOutIsNotSent() throws Exception {
        backend = new Backend(PORT, Backend::swallowRequestAndStay);
        HttpClientConnector client = createClient(new SenderConfiguration());
        HttpCarbonMessage request = newRequest();
        CallDeadline deadline = CallDeadline.startingNow(TimeUnit.MILLISECONDS.toNanos(1));
        Thread.sleep(20);
        request.setProperty(Constants.CALL_DEADLINE, deadline);

        DefaultHttpConnectorListener listener = send(client, request);

        assertTrue(listener.getHttpErrorMessage() instanceof CallTimeoutException,
                   "Expected a CallTimeoutException but got " + listener.getHttpErrorMessage());
        assertEquals(backend.accepted.get(), 0, "A call whose time had run out opened a connection");
    }

    @Test
    public void testExchangeThatEndedCannotBeAborted() {
        CountDownLatch done = new CountDownLatch(1);
        HttpCarbonMessage request = newRequest();
        request.setProperty(Constants.CALL_DEADLINE, CallDeadline.startingNow(TimeUnit.SECONDS.toNanos(60)));
        HttpResponseFuture future = new io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpResponseFuture();
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(done);
        future.setHttpConnectorListener(listener);
        CallExchange exchange = CallExchange.begin(request, future);
        AtomicReference<Throwable> aborted = new AtomicReference<>();
        assertTrue(exchange.bind(aborted::set));

        exchange.end();
        exchange.abort(new CallCancelledException(Constants.CALL_CANCELLED, -1));

        assertNull(aborted.get(), "An exchange that had ended aborted the connection that is no longer its own");
        assertFalse(exchange.isAborted());
        assertEquals(done.getCount(), 1L, "An exchange that had ended failed the call");
        assertFalse(exchange.bind(failure -> { }), "An ended exchange accepted a connection");
    }

    @Test
    public void testExchangeThatWasAbortedAbortsItsConnectionOnceAndRefusesAnother() {
        CountDownLatch done = new CountDownLatch(1);
        HttpCarbonMessage request = newRequest();
        request.setProperty(Constants.CALL_CANCELLABLE, true);
        HttpResponseFuture future = new io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpResponseFuture();
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(done);
        future.setHttpConnectorListener(listener);
        CallExchange exchange = CallExchange.begin(request, future);
        AtomicInteger aborts = new AtomicInteger();
        assertTrue(exchange.bind(failure -> aborts.incrementAndGet()));

        CallCancelledException first = new CallCancelledException(Constants.CALL_CANCELLED, -1);
        exchange.abort(first);
        exchange.abort(new CallCancelledException("later", -1));

        assertEquals(aborts.get(), 1);
        assertTrue(exchange.isAborted());
        assertEquals(exchange.getFailure(), first);
        assertEquals(listener.getHttpErrorMessage(), first);
        assertFalse(exchange.bind(failure -> { }), "An aborted exchange accepted a connection");
    }

    private HttpClientConnector createClient(SenderConfiguration senderConfiguration) {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        senderConfiguration.setSocketIdleTimeout(IDLE_TIMEOUT_MILLIS);
        return connectorFactory.createHttpClientConnector(new HashMap<>(), senderConfiguration);
    }

    private static HttpCarbonMessage newRequest() {
        return TestUtil.createHttpPostReq(PORT, "hello", "/");
    }

    private static HttpCarbonMessage withDeadline(HttpCarbonMessage request, long millis) {
        request.setProperty(Constants.CALL_DEADLINE, CallDeadline.startingNow(TimeUnit.MILLISECONDS.toNanos(millis)));
        return request;
    }

    private static DefaultHttpConnectorListener send(HttpClientConnector client, HttpCarbonMessage request)
            throws InterruptedException {
        CountDownLatch latch = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
        client.send(request).setHttpConnectorListener(listener);
        assertTrue(latch.await(30, TimeUnit.SECONDS), "The call neither responded nor failed");
        return listener;
    }

    private static String bodyOf(HttpCarbonMessage response) {
        assertNotNull(response, "No response");
        return TestUtil.getStringFromInputStream(new HttpMessageDataStreamer(response).getInputStream());
    }

    private static Throwable readBodyFailure(HttpCarbonMessage response) {
        try (InputStream in = new HttpMessageDataStreamer(response).getInputStream()) {
            while (in.read() != -1) {
                // Reading on until the body ends or fails
            }
            return null;
        } catch (IOException | RuntimeException e) {
            return e;
        }
    }

    private static String messageOf(Throwable failure) {
        for (Throwable t = failure; t != null; t = t.getCause()) {
            if (t.getMessage() != null && t.getMessage().startsWith(Constants.CALL_TIMEOUT_EXCEEDED)) {
                return t.getMessage();
            }
        }
        return String.valueOf(failure.getMessage());
    }

    /**
     * A backend that handles each connection with a script and records what the test needs to see of them.
     */
    private static final class Backend implements AutoCloseable {

        interface Script {
            void run(Backend backend, Socket socket, int connection) throws Exception;
        }

        final AtomicInteger accepted = new AtomicInteger();
        final CopyOnWriteArrayList<CountDownLatch> requestReceived = new CopyOnWriteArrayList<>();
        final CopyOnWriteArrayList<CountDownLatch> connectionClosedByClient = new CopyOnWriteArrayList<>();
        private final ServerSocket serverSocket;
        private final Script script;
        private final Thread acceptor;
        private final CopyOnWriteArrayList<Socket> sockets = new CopyOnWriteArrayList<>();

        Backend(int port, Script script) throws IOException {
            this.script = script;
            this.serverSocket = new ServerSocket(port);
            for (int i = 0; i < 4; i++) {
                requestReceived.add(new CountDownLatch(1));
                connectionClosedByClient.add(new CountDownLatch(1));
            }
            this.acceptor = new Thread(this::acceptConnections, "call-deadline-backend");
            this.acceptor.setDaemon(true);
            this.acceptor.start();
        }

        private void acceptConnections() {
            while (!serverSocket.isClosed()) {
                try {
                    Socket socket = serverSocket.accept();
                    sockets.add(socket);
                    int connection = accepted.getAndIncrement();
                    Thread handler = new Thread(() -> handle(socket, connection), "call-deadline-connection");
                    handler.setDaemon(true);
                    handler.start();
                } catch (IOException e) {
                    return;
                }
            }
        }

        private void handle(Socket socket, int connection) {
            try {
                script.run(this, socket, connection);
            } catch (Exception e) {
                // The test checks what it needs to of what happened
            }
        }

        void readRequest(Socket socket, int connection) throws IOException {
            InputStream in = socket.getInputStream();
            ByteArrayOutputStream head = new ByteArrayOutputStream();
            int matched = 0;
            int b;
            while (matched < 4 && (b = in.read()) != -1) {
                head.write(b);
                matched = (b == (matched % 2 == 0 ? '\r' : '\n')) ? matched + 1 : (b == '\r' ? 1 : 0);
            }
            String headers = head.toString(StandardCharsets.US_ASCII).toLowerCase();
            int index = headers.indexOf("content-length:");
            if (index >= 0) {
                int end = headers.indexOf("\r\n", index);
                int length = Integer.parseInt(headers.substring(index + "content-length:".length(), end).trim());
                in.readNBytes(length);
            }
            requestReceived.get(connection).countDown();
        }

        static void respond(Socket socket, String body) throws IOException {
            OutputStream out = socket.getOutputStream();
            out.write(("HTTP/1.1 200 OK\r\nContent-Length: " + body.length() + "\r\n\r\n" + body)
                              .getBytes(StandardCharsets.US_ASCII));
            out.flush();
        }

        /** Returns when the client closes its end of the connection. */
        static void awaitEof(Socket socket) throws IOException {
            socket.setSoTimeout(30000);
            try {
                while (socket.getInputStream().read() != -1) {
                    // Discarding whatever else arrives
                }
            } catch (SocketTimeoutException e) {
                // Never closed, which the check of the test's latch reports
                return;
            }
        }

        static void swallowRequestAndStay(Backend backend, Socket socket, int connection) throws Exception {
            backend.readRequest(socket, connection);
            backend.awaitEofAndSignal(socket, connection);
        }

        static void sendHeadersAndPartOfTheBodyThenStay(Backend backend, Socket socket, int connection)
                throws Exception {
            backend.readRequest(socket, connection);
            socket.getOutputStream().write("HTTP/1.1 200 OK\r\nContent-Length: 100\r\n\r\npartial"
                                                   .getBytes(StandardCharsets.US_ASCII));
            socket.getOutputStream().flush();
            backend.awaitEofAndSignal(socket, connection);
        }

        private void awaitEofAndSignal(Socket socket, int connection) throws IOException {
            awaitEof(socket);
            connectionClosedByClient.get(connection).countDown();
        }

        @Override
        public void close() {
            try {
                serverSocket.close();
            } catch (IOException e) {
                // Closing anyway
            }
            for (Socket socket : sockets) {
                try {
                    socket.close();
                } catch (IOException e) {
                    // Closing anyway
                }
            }
        }
    }
}
