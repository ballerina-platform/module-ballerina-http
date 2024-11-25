/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.http.transport.connectionpool;

import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.ServerBootstrapConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.passthrough.PassthroughMessageProcessorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.server.HttpServer;
import io.ballerina.stdlib.http.transport.util.server.initializers.SendChannelIDServerInitializer;
import io.netty.handler.codec.http.HttpMethod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URI;
import java.util.HashMap;
import java.util.concurrent.Callable;
import java.util.concurrent.CompletableFuture;

import static org.junit.Assert.assertNotEquals;
import static org.testng.AssertJUnit.assertNotNull;

/**
 * Test that when two different clients have the same route with their own pools that they do not share one another's
 * pool among them.
 *
 * @since 6.0.260
 */
public class PerClientPoolTestCase {
    private static final Logger LOG = LoggerFactory.getLogger(PerClientPoolTestCase.class);

    private HttpWsConnectorFactory httpWsConnectorFactory;
    private ServerConnector serverConnector;
    private HttpServer httpServer;

    @BeforeClass
    public void setup() {
        httpServer = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT, new SendChannelIDServerInitializer(5000));

        httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.SERVER_CONNECTOR_PORT);
        serverConnector = httpWsConnectorFactory
            .createServerConnector(new ServerBootstrapConfiguration(new HashMap<>()), listenerConfiguration);
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        serverConnectorFuture
            .setHttpConnectorListener(new PassthroughMessageProcessorListener(new SenderConfiguration(), false));
        try {
            serverConnectorFuture.sync();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for server connector to start");
        }
    }

    @Test
    public void testPerClientConnectionPool() {
        try {
            final CompletableFuture<String> requestOneResponse = new CompletableFuture<>();
            final CompletableFuture<String> requestTwoResponse = new CompletableFuture<>();

            ClientWorker clientWorkerOne = new ClientWorker();
            ClientWorker clientWorkerTwo = new ClientWorker();

            Thread.startVirtualThread(() -> {
                requestOneResponse.complete(clientWorkerOne.call());
            });
            assertNotNull(requestOneResponse.get());
            Thread.startVirtualThread(() -> {
                requestTwoResponse.complete(clientWorkerTwo.call());
            });
            assertNotNull(requestTwoResponse.get());

            assertNotEquals(requestOneResponse.get(), requestTwoResponse.get());
        } catch (Exception e) {
            TestUtil.handleException("IOException occurred while running testPerClientConnectionPool", e);
        }
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            serverConnector.stop();
            httpServer.shutdown();
            httpWsConnectorFactory.shutdown();
        } catch (Exception e) {
            LOG.warn("Interrupted while waiting for response two", e);
        }
    }

    private class ClientWorker implements Callable<String> {

        private String response;

        @Override
        public String call() {
            try {
                URI baseURI = URI.create(String.format("http://%s:%d", "localhost", TestUtil.SERVER_CONNECTOR_PORT));
                HttpURLConnection urlConn = TestUtil.request(baseURI, "/", HttpMethod.POST.name(), true);
                urlConn.getOutputStream().write(TestUtil.smallEntity.getBytes());
                response = TestUtil.getContent(urlConn);
            } catch (IOException e) {
                LOG.error("Couldn't get the response", e);
            }

            return response;
        }
    }
}
