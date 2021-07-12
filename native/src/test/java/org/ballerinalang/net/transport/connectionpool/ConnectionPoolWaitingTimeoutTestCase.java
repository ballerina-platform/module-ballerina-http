package org.ballerinalang.net.transport.connectionpool;

import org.ballerinalang.net.transport.contract.Constants;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.message.HttpMessageDataStreamer;
import org.ballerinalang.net.transport.util.DefaultHttpConnectorListener;
import org.ballerinalang.net.transport.util.TestUtil;
import org.ballerinalang.net.transport.util.server.HttpServer;
import org.ballerinalang.net.transport.util.server.initializers.SendChannelIDServerInitializer;
import org.testng.Assert;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.NoSuchElementException;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * Tests the timeout for waiting for idle connection in connection pool.
 */
public class ConnectionPoolWaitingTimeoutTestCase {

    private HttpServer httpServer;
    private HttpClientConnector httpClientConnector;
    private HttpWsConnectorFactory connectorFactory;
    private static final int MAX_ACTIVE_CONNECTIONS = 2;
    private static final int MAX_WAIT_TIME_FOR_CONNECTION_POOL = 1000;

    @BeforeClass
    public void setup() {
        httpServer = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT, new SendChannelIDServerInitializer(5000));

        connectorFactory = new DefaultHttpWsConnectorFactory();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.getPoolConfiguration().setMaxActivePerPool(MAX_ACTIVE_CONNECTIONS);
        senderConfiguration.getPoolConfiguration().setMaxWaitTime(MAX_WAIT_TIME_FOR_CONNECTION_POOL);
        httpClientConnector = connectorFactory.createHttpClientConnector(new HashMap<>(), senderConfiguration);
    }

    @Test
    public void testWaitingForConnectionTimeout() {
        try {
            int noOfRequests = 3;

            CountDownLatch[] countDownLatches = new CountDownLatch[noOfRequests];
            for (int i = 0; i < noOfRequests; i++) {
                countDownLatches[i] = new CountDownLatch(1);
            }

            DefaultHttpConnectorListener[] responseListeners = new DefaultHttpConnectorListener[noOfRequests];
            for (int i = 0; i < countDownLatches.length; i++) {
                responseListeners[i] = TestUtil.sendRequestAsync(countDownLatches[i], httpClientConnector);
            }

            // Wait for the responses
            for (CountDownLatch countDownLatch : countDownLatches) {
                countDownLatch.await(10, TimeUnit.SECONDS);
            }

            // Check the responses.
            Throwable throwable = null;
            HashSet<String> channelIds = new HashSet<>();
            for (DefaultHttpConnectorListener responseListener : responseListeners) {
                if (responseListener.getHttpErrorMessage() != null) {
                    if (throwable != null) {
                        Assert.fail("Cannot have more than one error");
                    }
                    throwable = responseListener.getHttpErrorMessage();
                } else {
                    String channelId = new BufferedReader(new InputStreamReader(
                            new HttpMessageDataStreamer(responseListener.getHttpResponseMessage()).getInputStream()))
                            .lines().collect(Collectors.joining("\n"));
                    channelIds.add(channelId);
                }
            }

            Assert.assertTrue(channelIds.size() <= MAX_ACTIVE_CONNECTIONS);
            Assert.assertTrue(throwable instanceof NoSuchElementException);
            Assert.assertEquals(throwable.getMessage(), Constants.MAXIMUM_WAIT_TIME_EXCEED);
        } catch (Exception e) {
            TestUtil.handleException("IOException occurred while running testMaxActiveConnectionsPerPool", e);
        }
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException, InterruptedException {
        TestUtil.cleanUp(new ArrayList<>(), httpServer);
        connectorFactory.shutdown();
    }

}
