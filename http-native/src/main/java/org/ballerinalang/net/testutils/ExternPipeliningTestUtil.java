/*
 *  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package org.ballerinalang.net.testutils;

import io.netty.handler.codec.http.FullHttpResponse;
import io.netty.handler.codec.http.HttpResponseStatus;
import org.ballerinalang.net.testutils.client.HttpClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.Assert;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.util.LinkedList;

import static org.ballerinalang.net.testutils.Utils.getEntityBodyFrom;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertTrue;

/**
 * Contains utility functions used for HTTP 1.1 pipelining tests.
 *
 * @since 0.982.0
 */
public class ExternPipeliningTestUtil {

    private static final Logger log = LoggerFactory.getLogger(ExternPipeliningTestUtil.class);

    private static final int BUFFER_SIZE = 1024;
    private static final String HOST = "localhost";
    private static final String CONNECTION_RESET = "Connection reset by peer";
    private static final String CHANNEL_INACTIVE = "Channel is inactive";
    private static final String WINDOWS_CONNECTION_ERROR =
            "An existing connection was forcibly closed by the remote host";

    // Test whether the response order matches the request order when HTTP pipelining is used
    public static boolean externTestPipelinedResponseOrder(int servicePort) {

        HttpClient httpClient = new HttpClient(HOST, servicePort);
        LinkedList<FullHttpResponse> fullHttpResponses = httpClient.sendPipeLinedRequests(
                "/pipeliningTest/responseOrder");

        //Verify response order and their body content
        verifyResponse(fullHttpResponses.pop(), "response-one", "Hello1");
        verifyResponse(fullHttpResponses.pop(), "response-two", "Hello2");
        verifyResponse(fullHttpResponses.pop(), "response-three", "Hello3");

        assertFalse(httpClient.waitForChannelClose());
        return true;
    }

    // Test pipelining with timeout. If the first request's response didn't arrive before the server timeout, client
    // shouldn't receive the responses for the subsequent requests
    public static boolean externTestPipeliningWithTimeout(int servicePort) {
        try {
            SocketChannel clientSocket = connectToRemoteEndpoint(servicePort);
            String pipelinedRequests = "GET /pipelining/testTimeout HTTP/1.1\r\n" +
                    "host: localhost\r\n" +
                    "connection: keep-alive\r\n" +
                    "accept-encoding: gzip\r\n" +
                    "message-id: request-one\r\n\r\n" +
                    "GET /pipelining/testTimeout HTTP/1.1\r\n" +
                    "host: localhost\r\n" +
                    "connection: keep-alive\r\n" +
                    "accept-encoding: gzip\r\n" +
                    "message-id: request-two\r\n\r\n" +
                    "GET /pipelining/testTimeout HTTP/1.1\r\n" +
                    "host: localhost\r\n" +
                    "connection: keep-alive\r\n" +
                    "accept-encoding: gzip\r\n" +
                    "message-id: request-three\r\n\r\n";

            writePipelinedRequests(clientSocket, pipelinedRequests);
            String expected = "HTTP/1.1 408 Request Timeout";
            readAndAssertResponse(clientSocket, expected);
        } catch (IOException e) {
            log.error("Error in processing request" + e.getMessage());
            return false;
        }
        return true;
    }

    // Once the pipelining limit is reached, connection should be closed from the server side")
    public static boolean externTestPipeliningLimit(int servicePort) {
        HttpClient httpClient = new HttpClient(HOST, servicePort);
        String connectionCloseMsg = httpClient.sendMultiplePipelinedRequests("/pipeliningLimit/testMaxRequestLimit");
        assertTrue(CHANNEL_INACTIVE.equals(connectionCloseMsg) || WINDOWS_CONNECTION_ERROR.equals(connectionCloseMsg) ||
                CONNECTION_RESET.equals(connectionCloseMsg), "When the channel is closed from the server " +
                "side, client should either receive a channel inactive message or if another pipeline request is " +
                "being written to the closed connection, a connection reset message. Actual value received is : " +
                connectionCloseMsg);
        return true;
    }

    private static void verifyResponse(FullHttpResponse response, String expectedId, String expectedBody) {
        assertEquals(response.status(), HttpResponseStatus.OK);
        assertEquals(response.headers().get("message-id"), expectedId);
        assertEquals(getEntityBodyFrom(response), expectedBody);
    }

    /**
     * Connects to the remote endpoint.
     *
     * @return the channel created from the connection.
     * @throws IOException if there's an error when connecting to remote endpoint.
     */
    private static SocketChannel connectToRemoteEndpoint(int port) throws IOException {
        InetSocketAddress remoteAddress = new InetSocketAddress("localhost", port);

        SocketChannel clientSocket = SocketChannel.open();
        clientSocket.configureBlocking(true);
        clientSocket.socket().setReceiveBufferSize(BUFFER_SIZE);
        clientSocket.socket().setSendBufferSize(BUFFER_SIZE);
        clientSocket.connect(remoteAddress);

        if (!clientSocket.finishConnect()) {
            throw new Error("Cannot connect to server");
        }
        return clientSocket;
    }

    /**
     * Send piplined requests to the server.
     *
     * @param socketChannel     Represents socket channel
     * @param pipelinedRequests Represent pipelined requests
     * @throws IOException when IO error occurs
     */
    private static void writePipelinedRequests(SocketChannel socketChannel, String pipelinedRequests) throws IOException {
        int i = 0;
        ByteBuffer buf = ByteBuffer.allocate(BUFFER_SIZE);
        byte[] data = pipelinedRequests.getBytes();
        while (i != data.length) {
            buf.clear();
            for (; data.length > i; i++) {
                if (buf.hasRemaining()) {
                    buf.put(data[i]);
                } else {
                    break;
                }
            }
            buf.flip();
            while (buf.hasRemaining()) {
                socketChannel.write(buf);
            }
        }
    }

    /**
     * Read and assert response.
     *
     * @param socketChannel Represent the client socket channel
     * @param expected      Expected value from the response
     * @throws IOException when an IO error occurs
     */
    private static void readAndAssertResponse(SocketChannel socketChannel, String expected)
            throws IOException {
        int count;
        ByteBuffer buffer = ByteBuffer.allocateDirect(BUFFER_SIZE);
        StringBuilder inboundContent = new StringBuilder();

        count = socketChannel.read(buffer);
        Assert.assertTrue(count > 0);
        // Loop while data is available; channel is non-blocking
        while (count > 0) {
            buffer.flip();
            while (buffer.hasRemaining()) {
                inboundContent.append((char) buffer.get());
            }
            buffer.clear();
            try {
                count = socketChannel.read(buffer);
            } catch (IOException e) {
                //Ignores this exception because the read cannot succeed if the connection is closed in the middle.
                log.warn("Cannot read more data when connection is closed", e);
            }
        }

        if (count < 0) {
            socketChannel.close();
        }

        String response = inboundContent.toString().trim();
        String[] responseLines = response.split("\r\n");
        Assert.assertEquals(responseLines[0], expected.trim(), "Server should timeout without sending any responses");
    }
}
