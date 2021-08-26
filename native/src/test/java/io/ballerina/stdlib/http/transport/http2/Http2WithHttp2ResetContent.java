package io.ballerina.stdlib.http.transport.http2;

import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoMessageListener;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.common.HttpRoute;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http2.Http2ClientChannel;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.netty.handler.codec.http.HttpMethod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.ballerina.stdlib.http.transport.contract.Constants.LOCALHOST;
import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SERVER_PORT;
import static org.testng.Assert.assertEquals;

/**
 * This contains test case for sending a Http2ResetContent content to initiate a stream reset.
 */
public class Http2WithHttp2ResetContent {
    private static final Logger LOG = LoggerFactory.getLogger(TestExhaustedStreamIdForClient.class);

    private HttpClientConnector httpClientConnector;
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;
    private ConnectionManager connectionManager;

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
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();

        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = HttpConnectorUtil.getSenderConfiguration(transportsConfiguration,
                Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(true);       // Force to use HTTP/2 without an upgrade
        connectionManager = new ConnectionManager(senderConfiguration.getPoolConfiguration());
        httpClientConnector = connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration, connectionManager);
    }

    @Test(description = "Sends a request with reset content such that the stream will be reset")
    public void testHttp2ResetContent() {
        HttpCarbonMessage requestMessage = MessageGenerator.getHttp2CarbonMessageWithResetContent(HttpMethod.POST);
        HttpCarbonMessage response = new MessageSender(httpClientConnector).sendMessage(requestMessage);

        Http2ClientChannel http2ClientChannel = connectionManager.getHttp2ConnectionManager()
                .borrowChannel(null, new HttpRoute(Constants.HTTP_SCHEME, LOCALHOST,
                        HTTP_SERVER_PORT, 0));

        int activeStreamsAfterReset = http2ClientChannel.getConnection().local().numActiveStreams();
        assertEquals(activeStreamsAfterReset, 0);
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
}
