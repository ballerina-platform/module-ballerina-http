/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DecoderException;
import io.netty.handler.codec.DecoderResult;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http.LastHttpContent;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;

/**
 * Tests that the HTTP/1.1 client does not send a request whose body failed part-way as a complete request.
 */
public class ClientAbortedRequestBodyTestCase {

    private static final String CHUNKED_BODY_END = "0\r\n\r\n";

    // What each connection to the backend received before it was closed.
    private final BlockingQueue<String> receivedRequests = new LinkedBlockingQueue<>();
    private ServerSocket backend;
    private HttpWsConnectorFactory connectorFactory;
    private HttpClientConnector httpClientConnector;

    @BeforeClass
    public void setup() throws IOException {
        backend = new ServerSocket(0);
        Thread acceptor = new Thread(this::acceptConnections);
        acceptor.setDaemon(true);
        acceptor.start();

        connectorFactory = new DefaultHttpWsConnectorFactory();
        httpClientConnector = connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(new TransportsConfiguration()), new SenderConfiguration());
    }

    @Test
    public void testBodyFailingAfterItStartedClosesTheConnection() throws Exception {
        HttpCarbonMessage request = newPost();
        CountDownLatch done = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = send(request, done);
        request.addHttpContent(new DefaultHttpContent(Unpooled.copiedBuffer("partial", StandardCharsets.UTF_8)));
        request.addHttpContent(failedBodyEnd());

        assertFailed(listener, done);
        String received = receivedRequests.poll(10, TimeUnit.SECONDS);
        assertNotNull(received, "The backend connection was not closed");
        assertTrue(received.contains("partial") && !received.endsWith(CHUNKED_BODY_END),
                   "The backend received the partial body as a complete request: " + received);
    }

    @Test
    public void testBodyFailingBeforeAnythingWasSentSendsNothing() throws Exception {
        HttpCarbonMessage request = newPost();
        CountDownLatch done = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = send(request, done);
        request.addHttpContent(failedBodyEnd());

        assertFailed(listener, done);
        String received = receivedRequests.poll(10, TimeUnit.SECONDS);
        assertNotNull(received, "The backend connection was not closed");
        assertEquals(received, "", "The backend received a request for a body that never existed");
    }

    private static LastHttpContent failedBodyEnd() {
        LastHttpContent lastHttpContent = new DefaultLastHttpContent();
        lastHttpContent.setDecoderResult(DecoderResult.failure(new DecoderException("client went away")));
        return lastHttpContent;
    }

    private static void assertFailed(DefaultHttpConnectorListener listener, CountDownLatch done)
            throws InterruptedException {
        assertTrue(done.await(10, TimeUnit.SECONDS), "The request neither failed nor got a response");
        assertNotNull(listener.getHttpErrorMessage(), "The request got a response instead of failing");
        assertEquals(listener.getHttpErrorMessage().getMessage(),
                     Constants.CONNECTION_CLOSED_INCOMPLETE_OUTBOUND_REQUEST_BODY);
    }

    private HttpCarbonMessage newPost() {
        HttpCarbonMessage request = new HttpCarbonMessage(
                new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, "/upload"));
        request.setProperty(Constants.HTTP_PORT, backend.getLocalPort());
        request.setProperty(Constants.PROTOCOL, Constants.HTTP_SCHEME);
        request.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
        request.setHttpMethod(Constants.HTTP_POST_METHOD);
        return request;
    }

    private DefaultHttpConnectorListener send(HttpCarbonMessage request, CountDownLatch done) {
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(done);
        httpClientConnector.send(request).setHttpConnectorListener(listener);
        return listener;
    }

    private void acceptConnections() {
        while (!backend.isClosed()) {
            try {
                Socket socket = backend.accept();
                Thread reader = new Thread(() -> readUntilClosed(socket));
                reader.setDaemon(true);
                reader.start();
            } catch (IOException e) {
                return;
            }
        }
    }

    // Answers a complete chunked request, so that a request sent as complete is seen as such and not left waiting.
    private void readUntilClosed(Socket socket) {
        StringBuilder received = new StringBuilder();
        try (socket; InputStream in = socket.getInputStream(); OutputStream out = socket.getOutputStream()) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = in.read(buffer)) >= 0) {
                received.append(new String(buffer, 0, read, StandardCharsets.ISO_8859_1));
                if (received.toString().endsWith(CHUNKED_BODY_END)) {
                    out.write("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n".getBytes(StandardCharsets.US_ASCII));
                    out.flush();
                    break;
                }
            }
        } catch (IOException ignored) {
            // The client reset the connection.
        }
        receivedRequests.add(received.toString());
    }

    @AfterClass
    public void cleanUp() throws Exception {
        backend.close();
        connectorFactory.shutdown();
    }
}
