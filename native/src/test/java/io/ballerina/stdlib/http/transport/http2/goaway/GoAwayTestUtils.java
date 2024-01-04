package io.ballerina.stdlib.http.transport.http2.goaway;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;

public class GoAwayTestUtils {

    public static HttpClientConnector setupHttp2PriorKnowledgeClient() {
        HttpWsConnectorFactory connectorFactory = new DefaultHttpWsConnectorFactory();
        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setScheme(Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(true);
        return connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration);
    }
}
