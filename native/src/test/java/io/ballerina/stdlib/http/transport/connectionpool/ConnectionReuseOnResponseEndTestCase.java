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

package io.ballerina.stdlib.http.transport.connectionpool;

import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
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
import io.ballerina.stdlib.http.transport.util.server.initializers.SendChannelIDServerInitializer;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;

/**
 * Verifies that an HTTP/1.1 client connection is back in the pool by the time its response is seen to end, so a
 * request sent as soon as the previous response is read reuses it.
 */
public class ConnectionReuseOnResponseEndTestCase {

    private HttpServer httpServer;
    private HttpClientConnector httpClientConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() {
        httpServer = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT, new SendChannelIDServerInitializer(0));
        connectorFactory = new DefaultHttpWsConnectorFactory();
        httpClientConnector = connectorFactory.createHttpClientConnector(new HashMap<>(), new SenderConfiguration());
    }

    @Test(timeOut = 30000,
          description = "A request sent the moment the previous response ends must reuse its pooled connection")
    public void testRequestSentWhenTheResponseEndsReusesTheConnection() throws Exception {
        CompletableFuture<String> firstChannelId = new CompletableFuture<>();
        CountDownLatch secondResponseLatch = new CountDownLatch(1);
        DefaultHttpConnectorListener secondListener = new DefaultHttpConnectorListener(secondResponseLatch);
        httpClientConnector.send(newRequest()).setHttpConnectorListener(new HttpConnectorListener() {
            @Override
            public void onMessage(HttpCarbonMessage response) {
                // Registered when the headers arrive, so it runs on the I/O thread as the body ends
                response.getFullHttpCarbonMessage().addListener(new FullHttpMessageListener() {
                    @Override
                    public void onComplete(HttpCarbonMessage httpCarbonMessage) {
                        firstChannelId.complete(TestUtil.getStringFromInputStream(
                                new HttpMessageDataStreamer(httpCarbonMessage).getInputStream()));
                        httpClientConnector.send(newRequest()).setHttpConnectorListener(secondListener);
                    }

                    @Override
                    public void onError(Exception error) {
                        firstChannelId.completeExceptionally(error);
                    }
                });
            }

            @Override
            public void onError(Throwable throwable) {
                firstChannelId.completeExceptionally(throwable);
            }
        });

        String channelIdOne = firstChannelId.get(10, TimeUnit.SECONDS);
        String channelIdTwo = TestUtil.waitAndGetStringEntity(secondResponseLatch, secondListener);
        assertEquals(channelIdTwo, channelIdOne, "The second request opened another connection");
    }

    private static HttpCarbonMessage newRequest() {
        return TestUtil.createHttpsPostReq(TestUtil.HTTP_SERVER_PORT, "hello", "/");
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        TestUtil.cleanUp(new ArrayList<>(), httpServer, connectorFactory);
    }
}
