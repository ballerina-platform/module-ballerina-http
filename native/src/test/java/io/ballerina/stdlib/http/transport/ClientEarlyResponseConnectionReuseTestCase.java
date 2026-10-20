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
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;
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
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertNull;
import static org.testng.Assert.assertTrue;

/**
 * Tests that a connection is not reused after the backend responds before the request body was fully sent.
 */
public class ClientEarlyResponseConnectionReuseTestCase {

    private static final byte[] PAYLOAD_TOO_LARGE =
            "HTTP/1.1 413 Payload Too Large\r\nContent-Length: 0\r\n\r\n".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] UNAVAILABLE_HEAD =
            "HTTP/1.1 503 Service Unavailable\r\nContent-Length: 4\r\n\r\n".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] UNAVAILABLE_BODY = "busy".getBytes(StandardCharsets.US_ASCII);

    private final AtomicInteger acceptedConnections = new AtomicInteger();
    private final AtomicInteger closedConnections = new AtomicInteger();
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
    public void testNextRequestDoesNotReuseAConnectionLeftMidRequest() throws Exception {
        assertEarlyResponseClosesTheConnection(false);
    }

    @Test
    public void testNextRequestDoesNotReuseAConnectionLeftAwaiting100Continue() throws Exception {
        assertEarlyResponseClosesTheConnection(true);
    }

    @Test
    public void testConnectionLeftMidRequestIsClosedWhenTheRequestIsSentAgain() throws Exception {
        int closedBefore = closedConnections.get();
        HttpCarbonMessage unfinishedUpload = newPost(false, "/slow");
        Exchange first = send(unfinishedUpload);
        unfinishedUpload.addHttpContent(new DefaultHttpContent(Unpooled.wrappedBuffer(new byte[1024])));
        assertEquals(first.responseStatus(), 503);
        // Sending the request again, as a retry does, clears its I/O error while this response body still arrives.
        unfinishedUpload.setIoException(null);
        readToTheEnd(first.listener().getHttpResponseMessage());

        long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
        while (closedConnections.get() == closedBefore && System.nanoTime() < deadline) {
            Thread.sleep(10);
        }
        assertTrue(closedConnections.get() > closedBefore, "The connection left mid-request was kept for reuse");
    }

    private static void readToTheEnd(HttpCarbonMessage response) {
        while (true) {
            HttpContent content = response.getHttpContent();
            assertNotNull(content, "The response body did not end");
            content.release();
            if (content instanceof LastHttpContent) {
                return;
            }
        }
    }

    private void assertEarlyResponseClosesTheConnection(boolean expectContinue) throws Exception {
        int connectionsBefore = acceptedConnections.get();
        HttpCarbonMessage unfinishedUpload = newPost(expectContinue);
        Exchange first = send(unfinishedUpload);
        unfinishedUpload.addHttpContent(new DefaultHttpContent(Unpooled.wrappedBuffer(new byte[1024])));
        assertEquals(first.responseStatus(), 413);

        HttpCarbonMessage nextRequest = newPost(false);
        Exchange second = send(nextRequest);
        nextRequest.addHttpContent(new DefaultHttpContent(Unpooled.wrappedBuffer(new byte[1024])));
        assertEquals(second.responseStatus(), 413);
        assertEquals(acceptedConnections.get() - connectionsBefore, 2);
    }

    private HttpCarbonMessage newPost(boolean expectContinue) {
        return newPost(expectContinue, "/upload");
    }

    private HttpCarbonMessage newPost(boolean expectContinue, String path) {
        HttpCarbonMessage request = new HttpCarbonMessage(
                new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, path));
        request.setProperty(Constants.HTTP_PORT, backend.getLocalPort());
        request.setProperty(Constants.PROTOCOL, Constants.HTTP_SCHEME);
        request.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
        request.setProperty(Constants.TO, path);
        request.setHttpMethod(Constants.HTTP_POST_METHOD);
        if (expectContinue) {
            request.setHeader(HttpHeaderNames.EXPECT.toString(), HttpHeaderValues.CONTINUE.toString());
        }
        return request;
    }

    private Exchange send(HttpCarbonMessage request) {
        CountDownLatch done = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(done);
        httpClientConnector.send(request).setHttpConnectorListener(listener);
        return new Exchange(listener, done);
    }

    private record Exchange(DefaultHttpConnectorListener listener, CountDownLatch done) {
        int responseStatus() throws InterruptedException {
            assertTrue(done.await(10, TimeUnit.SECONDS), "No response within 10 seconds");
            assertNull(listener.getHttpErrorMessage(), "The request failed instead of getting the backend's response");
            HttpCarbonMessage response = listener.getHttpResponseMessage();
            assertNotNull(response);
            return response.getHttpStatusCode();
        }
    }

    private void acceptConnections() {
        while (!backend.isClosed()) {
            try {
                Socket socket = backend.accept();
                acceptedConnections.incrementAndGet();
                Thread handler = new Thread(() -> respondBeforeReadingTheBody(socket));
                handler.setDaemon(true);
                handler.start();
            } catch (IOException e) {
                return;
            }
        }
    }

    private void respondBeforeReadingTheBody(Socket socket) {
        try (socket; InputStream in = socket.getInputStream(); OutputStream out = socket.getOutputStream()) {
            byte[] buffer = new byte[8192];
            StringBuilder received = new StringBuilder();
            while (true) {
                while (!received.toString().contains("\r\n\r\n")) {
                    int read = in.read(buffer);
                    if (read < 0) {
                        closedConnections.incrementAndGet();
                        return;
                    }
                    received.append(new String(buffer, 0, read, StandardCharsets.ISO_8859_1));
                }
                if (received.toString().startsWith("POST /slow ")) {
                    out.write(UNAVAILABLE_HEAD);
                    out.flush();
                    Thread.sleep(500);
                    out.write(UNAVAILABLE_BODY);
                } else {
                    out.write(PAYLOAD_TOO_LARGE);
                }
                out.flush();
                received.delete(0, received.indexOf("\r\n\r\n") + 4);
            }
        } catch (IOException e) {
            // The client closed the connection.
            closedConnections.incrementAndGet();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    @AfterClass
    public void cleanUp() throws Exception {
        backend.close();
        connectorFactory.shutdown();
    }
}
