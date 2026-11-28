/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.FullHttpMessageListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.server.HttpServer;
import io.ballerina.stdlib.http.transport.util.server.initializers.HalfResponseCloseServerInitializer;
import io.netty.handler.codec.DecoderException;
import io.netty.handler.codec.http.HttpContent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;

/**
 * Tests that the body chunks already received for a client response are released when the response fails part-way.
 * The chunks are pooled buffers, so if they were left queued and the message was then dropped (for example when the
 * application never reads the failed response) the pooled memory would never be returned.
 */
public class ClientResponseBufferReleaseOnFailureTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(ClientResponseBufferReleaseOnFailureTestCase.class);

    private HttpServer httpServer;
    private HttpClientConnector httpClientConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() {
        // Sends part of the body and then closes the connection, so the response fails while its body is read.
        httpServer = TestUtil.startHTTPServer(TestUtil.HTTPS_SERVER_PORT, new HalfResponseCloseServerInitializer());

        connectorFactory = new DefaultHttpWsConnectorFactory();
        httpClientConnector = connectorFactory.createHttpClientConnector(new HashMap<>(), new SenderConfiguration());
    }

    @Test(description = "Content queued before the failure is released, and the failure is still reported")
    public void testQueuedContentReleasedWhenResponseBodyFails() throws Exception {
        HttpCarbonMessage response = sendAndGetResponse();

        // Waiting for the failure through the full-message future does not consume anything from the queue.
        AtomicReference<Exception> failure = new AtomicReference<>();
        CountDownLatch failed = new CountDownLatch(1);
        response.getFullHttpCarbonMessage().addListener(new FullHttpMessageListener() {
            @Override
            public void onComplete(HttpCarbonMessage httpCarbonMessage) {
                failed.countDown();
            }

            @Override
            public void onError(Exception error) {
                failure.set(error);
                failed.countDown();
            }
        });
        assertTrue(failed.await(6, TimeUnit.SECONDS), "The response should have failed");
        assertNotNull(failure.get(), "The response should have failed, not completed");
        assertEquals(failure.get().getMessage(), Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY);

        // The 10 bytes that arrived before the connection closed were queued. They must have been released and
        // dropped, so the first thing left to read is the failure marker, which carries no data.
        HttpContent first = response.getHttpContent();
        assertNotNull(first);
        assertTrue(first.decoderResult().isFailure(), "The queued body chunk should have been released");
        assertEquals(first.content().readableBytes(), 0);

        // Releasing must not be reported to the application as "content already released".
        assertFalse(response.isContentReleased());
    }

    @Test(description = "A read after the failure still reports the original error")
    public void testReadAfterFailureReportsOriginalError() throws Exception {
        HttpCarbonMessage response = sendAndGetResponse();

        String message = "";
        try {
            TestUtil.getStringFromInputStream(new HttpMessageDataStreamer(response).getInputStream());
        } catch (DecoderException e) {
            message = e.getMessage();
        }
        assertEquals(message, Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY);
    }

    private HttpCarbonMessage sendAndGetResponse() throws InterruptedException {
        HttpCarbonMessage msg = TestUtil.createHttpsPostReq(TestUtil.HTTPS_SERVER_PORT, "Test request body", "");

        CountDownLatch latch = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
        HttpResponseFuture responseFuture = httpClientConnector.send(msg);
        responseFuture.setHttpConnectorListener(listener);
        assertTrue(latch.await(6, TimeUnit.SECONDS), "No response received");

        HttpCarbonMessage response = listener.getHttpResponseMessage();
        assertNotNull(response);
        return response;
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            httpServer.shutdown();
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.error("Failed to shutdown the test server");
        }
    }
}
