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

package io.ballerina.stdlib.http.transport.http2;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DecoderException;
import io.netty.handler.codec.DecoderResult;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http.LastHttpContent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SERVER_PORT;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;

/**
 * Tests that a request body which fails part-way is reset on the HTTP/2 stream instead of being ended as complete.
 */
public class Http2AbortedRequestBodyTest {
    private static final Logger LOG = LoggerFactory.getLogger(Http2AbortedRequestBodyTest.class);

    private HttpClientConnector httpClientConnector;
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;
    private final BlockingQueue<Object> requestBodyOutcomes = new LinkedBlockingQueue<>();

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        serverConnector = connectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new BodyReadingListener(requestBodyOutcomes));
        future.sync();

        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = HttpConnectorUtil.getSenderConfiguration(transportsConfiguration,
                Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(true);
        httpClientConnector = connectorFactory.createHttpClientConnector(HttpConnectorUtil.getTransportProperties(
                transportsConfiguration), senderConfiguration,
                new ConnectionManager(senderConfiguration.getPoolConfiguration()));
    }

    @Test(description = "A body that fails after some data has been sent resets the stream")
    public void testAbortedBodyAfterDataResetsTheStream() throws InterruptedException {
        HttpCarbonMessage request = createRequest();
        request.addHttpContent(new DefaultHttpContent(
                Unpooled.copiedBuffer("partial body", StandardCharsets.UTF_8)));
        request.addHttpContent(abortedLastContent());

        assertRequestWasReset(request);
    }

    @Test(description = "A body that fails before any data has been sent does not end the stream with the headers")
    public void testAbortedBodyWithoutDataResetsTheStream() throws InterruptedException {
        HttpCarbonMessage request = createRequest();
        request.addHttpContent(abortedLastContent());

        assertRequestWasReset(request);
    }

    private void assertRequestWasReset(HttpCarbonMessage request) throws InterruptedException {
        Throwable clientError = new MessageSender(httpClientConnector).sendMessageAndExpectError(request);
        assertNotNull(clientError, "The client received a response to a request it never finished sending");

        Object outcome = requestBodyOutcomes.poll(10, TimeUnit.SECONDS);
        assertTrue(outcome instanceof Exception, "The server read the truncated request as complete: " + outcome);
        assertEquals(((Exception) outcome).getMessage(),
                     Constants.REMOTE_CLIENT_CLOSED_WHILE_READING_INBOUND_REQUEST_BODY);
    }

    private static HttpCarbonMessage createRequest() {
        String uri = String.format("http://%s:%d", TestUtil.TEST_HOST, HTTP_SERVER_PORT);
        HttpCarbonMessage request = new HttpCarbonRequest(new DefaultHttpRequest(HttpVersion.HTTP_1_1,
                                                                                 HttpMethod.POST, uri));
        request.setHttpMethod(HttpMethod.POST.toString());
        request.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
        request.setProperty(Constants.HTTP_PORT, HTTP_SERVER_PORT);
        request.setHeader(TestUtil.HOST, TestUtil.TEST_HOST + ":" + HTTP_SERVER_PORT);
        return request;
    }

    private static LastHttpContent abortedLastContent() {
        LastHttpContent lastHttpContent = new DefaultLastHttpContent();
        lastHttpContent.setDecoderResult(DecoderResult.failure(new DecoderException("client went away")));
        return lastHttpContent;
    }

    @AfterClass
    public void cleanUp() {
        httpClientConnector.close();
        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }

    /**
     * Reads each request body to the end and records either its length or the failure that ended it.
     */
    private static class BodyReadingListener implements HttpConnectorListener {
        private final BlockingQueue<Object> outcomes;

        BodyReadingListener(BlockingQueue<Object> outcomes) {
            this.outcomes = outcomes;
        }

        @Override
        public void onMessage(HttpCarbonMessage request) {
            Thread.startVirtualThread(() -> {
                try (InputStream body = new HttpMessageDataStreamer(request).getInputStream()) {
                    outcomes.add(body.readAllBytes().length);
                } catch (IOException | RuntimeException e) {
                    outcomes.add(e);
                }
            });
        }

        @Override
        public void onError(Throwable throwable) {
        }
    }
}
