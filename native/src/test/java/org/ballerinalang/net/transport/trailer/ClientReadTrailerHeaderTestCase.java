/*
 *  Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 *
 */

package org.ballerinalang.net.transport.trailer;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpHeaders;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import org.ballerinalang.net.transport.contentaware.listeners.TrailerHeaderListener;
import org.ballerinalang.net.transport.contract.Constants;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.config.ChunkConfig;
import org.ballerinalang.net.transport.contract.config.ListenerConfiguration;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.contractimpl.common.states.StateUtil;
import org.ballerinalang.net.transport.message.FullHttpMessageListener;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.transport.util.DefaultHttpConnectorListener;
import org.ballerinalang.net.transport.util.TestUtil;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.util.HashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;

/**
 * Test case for HTTP/1.1 trailer headers read come along with inbound response.
 *
 * @since 6.3.1
 */
public class ClientReadTrailerHeaderTestCase extends TrailerHeaderTestTemplate {
    private HttpClientConnector clientConnector;

    @BeforeClass
    public void setup() {
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.SERVER_CONNECTOR_PORT);
        listenerConfiguration.setChunkConfig(ChunkConfig.ALWAYS);

        HttpHeaders trailers = new DefaultLastHttpContent().trailingHeaders();
        trailers.add("foo", "xyz");
        trailers.add("bar", "ballerina");
        trailers.add("Max-forwards", "five");
        super.setup(listenerConfiguration, trailers, TrailerHeaderListener.MessageType.RESPONSE);

        HttpWsConnectorFactory httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();
        clientConnector = httpWsConnectorFactory.createHttpClientConnector(new HashMap<>(), new SenderConfiguration());
    }

    @Test
    public void testSmallPayload() throws InterruptedException {
        testReadTrailers(TestUtil.smallEntity);
    }

    @Test
    public void testLargePayload() throws InterruptedException {
        testReadTrailers(TestUtil.largeEntity);
    }

    private void testReadTrailers(String payload) throws InterruptedException {

        HttpCarbonMessage requestMsg = new HttpCarbonMessage(new DefaultHttpRequest(HttpVersion.HTTP_1_1,
                                                                                    HttpMethod.POST, ""));
        requestMsg.setProperty(Constants.HTTP_PORT, TestUtil.SERVER_CONNECTOR_PORT);
        requestMsg.setProperty(Constants.PROTOCOL, Constants.HTTP_SCHEME);
        requestMsg.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
        requestMsg.setHttpMethod(Constants.HTTP_POST_METHOD);

        ByteBuffer byteBuffer = ByteBuffer.wrap(payload.getBytes(Charset.forName("UTF-8")));
        requestMsg.addHttpContent(new DefaultLastHttpContent(Unpooled.wrappedBuffer(byteBuffer)));
        requestMsg.completeMessage();

        CountDownLatch latch = new CountDownLatch(1);
        DefaultHttpConnectorListener listener = new DefaultHttpConnectorListener(latch);
        clientConnector.send(requestMsg).setHttpConnectorListener(listener);

        latch.await(30, TimeUnit.SECONDS);

        HttpCarbonMessage response = listener.getHttpResponseMessage();
        Semaphore executionWaitSem = new Semaphore(0);

        response.getFullHttpCarbonMessage().addListener(new FullHttpMessageListener() {
            @Override
            public void onComplete(HttpCarbonMessage httpCarbonMessage) {
                executionWaitSem.release();
            }

            @Override
            public void onError(Exception error) {
                executionWaitSem.release();
            }
        });
        executionWaitSem.tryAcquire(120, TimeUnit.SECONDS);

        assertEquals(response.getHeader("Trailer"), "foo, bar, Max-forwards");
        assertEquals(response.getTrailerHeaders().get("foo"), "xyz");
        assertEquals(response.getTrailerHeaders().get("bar"), "ballerina");
        assertEquals(response.getTrailerHeaders().get("Max-forwards"), "five");
    }

    @Test(description = "Test populating inbound trailers to the message")
    public void testPopulateTrailersToMessage() {
        DefaultLastHttpContent lastHttpContent = new DefaultLastHttpContent();
        HttpHeaders trailers = lastHttpContent.trailingHeaders();
        trailers.add("foo", "xyz");
        trailers.add("bar", "ballerina");
        trailers.add("Max-forwards", "five");
        HttpCarbonMessage outboundResponseMsg = new HttpCarbonMessage(
                new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK));
        StateUtil.setInboundTrailersToNewMessage(trailers, outboundResponseMsg);

        assertEquals(lastHttpContent.trailingHeaders().size(), 0);
        assertEquals(outboundResponseMsg.getTrailerHeaders().get("foo"), "xyz");
        assertEquals(outboundResponseMsg.getTrailerHeaders().get("bar"), "ballerina");
        assertEquals(outboundResponseMsg.getTrailerHeaders().get("Max-forwards"), "five");
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        super.cleanUp();
    }
}
