/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.transport.http2.frameleveltests.server;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.http2.frameleveltests.FrameLevelTestUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonResponse;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.buffer.ByteBuf;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http.LastHttpContent;
import io.netty.util.CharsetUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;

import static org.testng.Assert.assertEquals;

/**
 * This contains a test case where the tcp connection is closed by the timer task after the stream gets completed.
 */
public class Http2SuccessfulResponseBeforeConnectionEvictionAfterTcpClientGoAwayScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(
            Http2SuccessfulResponseBeforeConnectionEvictionAfterTcpClientGoAwayScenarioTest.class);
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;
    private Semaphore semaphore = new Semaphore(1);
    private String serverError = "";
    String requestData = "";

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        listenerConfiguration.setTimeBetweenStaleEviction(500);
        listenerConfiguration.setMinIdleTimeInStaleState(6000);
        serverConnector = connectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new GoAwayMessageListener());
        future.sync();
    }

    @Test
    private void testSuccessfulConnectionBeforeConnectionEvictionAfterClientGoAway() throws IOException,
            InterruptedException {
        Socket socket = new Socket("localhost", TestUtil.HTTP_SERVER_PORT);
        semaphore.acquire();
        OutputStream outputStream = socket.getOutputStream();
        sendGoAwayAfterSendingHeaders(outputStream);
        Thread.sleep(2000);
        assertEquals(requestData, FrameLevelTestUtils.DATA_VALUE_HELLO_WORLD_03);
        semaphore.acquire();
        assertEquals(serverError, Constants.REMOTE_CLIENT_SENT_GOAWAY_WHILE_READING_INBOUND_REQUEST_BODY);
    }

    public static void sendGoAwayAfterSendingHeaders(OutputStream outputStream) throws IOException,
            InterruptedException {
        outputStream.write(FrameLevelTestUtils.PREFACE_FRAME);
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.SETTINGS_FRAME_WITH_ACK);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.SERVER_HEADER_FRAME_STREAM_03);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.SERVER_HEADER_FRAME_STREAM_05);
        Thread.sleep(FrameLevelTestUtils.SLEEP_TIME);
        outputStream.write(FrameLevelTestUtils.GO_AWAY_FRAME_MAX_STREAM_03);
        Thread.sleep(4000);
        // Sending data for stream 03 after 4 seconds but not waiting more than the stale timeout
        outputStream.write(FrameLevelTestUtils.DATA_FRAME_STREAM_03);
        Thread.sleep(8000);
    }

    @AfterClass
    public void cleanUp() {
        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOGGER.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }

    class GoAwayMessageListener implements HttpConnectorListener {
        private ExecutorService executor = Executors.newSingleThreadExecutor();

        @Override
        public void onMessage(HttpCarbonMessage httpRequest) {
            executor.execute(() -> {
                try {
                    HttpContent httpContent = httpRequest.getHttpContent();
                    if (httpContent.decoderResult().isFailure()) {
                        serverError = httpContent.decoderResult().cause().getMessage();
                        semaphore.release();
                        return;
                    }
                    HttpCarbonMessage httpResponse = new HttpCarbonResponse(
                            new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK));
                    httpResponse.setHeader(HttpHeaderNames.CONNECTION.toString(),
                            HttpHeaderValues.KEEP_ALIVE.toString());
                    httpResponse.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), Constants.TEXT_PLAIN);
                    httpResponse.setHttpStatusCode(HttpResponseStatus.OK.code());
                    do {
                        httpResponse.addHttpContent(httpContent);
                        ByteBuf byteBuf = httpContent.content();
                        requestData += byteBuf.toString(CharsetUtil.UTF_8);
                        if (httpContent instanceof LastHttpContent) {
                            break;
                        }
                    } while (true);
                    httpRequest.respond(httpResponse);
                } catch (ServerConnectorException e) {
                }
            });
        }

        @Override
        public void onError(Throwable throwable) {
            semaphore.release();
        }
    }
}
