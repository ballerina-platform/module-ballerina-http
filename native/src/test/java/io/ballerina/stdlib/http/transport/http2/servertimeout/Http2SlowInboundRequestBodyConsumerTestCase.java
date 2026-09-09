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

package io.ballerina.stdlib.http.transport.http2.servertimeout;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.http2.listeners.Http2SlowRequestBodyConsumerListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpResponseStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

/**
 * Verifies that an HTTP/2 service which consumes a large inbound request body slowly is not timed out - the
 * request-side counterpart of
 * {@link io.ballerina.stdlib.http.transport.http2.clienttimeout.Http2SlowInboundResponseBodyConsumerTestCase}.
 */
public class Http2SlowInboundRequestBodyConsumerTestCase {

    private static final Logger LOG = LoggerFactory.getLogger(Http2SlowInboundRequestBodyConsumerTestCase.class);

    // Comfortably larger than the default 64KB inbound flow control window.
    private static final int REQUEST_SIZE = 1024 * 1024;
    private static final int CHUNK_SIZE = 8192;
    private static final int SERVER_IDLE_TIMEOUT = 2000;
    private static final int READ_SLICE = 16 * 1024;
    private static final int CONSUMER_PAUSE = SERVER_IDLE_TIMEOUT + SERVER_IDLE_TIMEOUT / 2;
    private static final int PAUSED_READS = 2;
    // A regression here shows up as a stalled transfer rather than a quick error, so the test methods and the
    // tear down are bounded to keep a failure a red test instead of a hung build.
    private static final int TEST_TIME_OUT = 60000;
    private static final int CLEAN_UP_TIME_OUT = 30000;

    private HttpClientConnector h2ClientWithPriorKnowledge;
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        listenerConfiguration.setSocketIdleTimeout(SERVER_IDLE_TIMEOUT);
        serverConnector = connectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(
                new Http2SlowRequestBodyConsumerListener(READ_SLICE, CONSUMER_PAUSE, PAUSED_READS));
        future.sync();

        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setScheme(Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(true);
        // Keep the client well out of the way, the server side timing is what is under test.
        senderConfiguration.setSocketIdleTimeout(500000);
        h2ClientWithPriorKnowledge = connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration);
    }

    @Test(timeOut = TEST_TIME_OUT,
          description = "A request body consumed more slowly than the server socket idle timeout must still "
                  + "arrive in full, because the idleness is caused by the service rather than by the client.")
    public void testSlowlyConsumedLargeRequestIsNotTruncated() {
        HttpCarbonMessage request = MessageGenerator.generateDelayedRequest(HttpMethod.POST);

        byte[] payload = new byte[REQUEST_SIZE];
        for (int i = 0; i < REQUEST_SIZE; i++) {
            payload[i] = (byte) ('A' + (i % 26));
        }
        for (int offset = 0; offset < REQUEST_SIZE; offset += CHUNK_SIZE) {
            int length = Math.min(CHUNK_SIZE, REQUEST_SIZE - offset);
            request.addHttpContent(new DefaultHttpContent(Unpooled.copiedBuffer(payload, offset, length)));
        }
        request.addHttpContent(new DefaultLastHttpContent());

        HttpCarbonMessage response = new MessageSender(h2ClientWithPriorKnowledge).sendMessage(request);
        assertNotNull(response, "Did not receive a response");
        assertEquals(response.getHttpStatusCode().intValue(), HttpResponseStatus.OK.code(),
                     "Expected the request to be served rather than timed out");

        String receivedByteCount =
                TestUtil.getStringFromInputStream(new HttpMessageDataStreamer(response).getInputStream());
        assertEquals(receivedByteCount, Integer.toString(REQUEST_SIZE),
                     "The service did not read the complete request body");
    }

    @AfterClass(timeOut = CLEAN_UP_TIME_OUT)
    public void cleanUp() {
        h2ClientWithPriorKnowledge.close();
        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }
}
