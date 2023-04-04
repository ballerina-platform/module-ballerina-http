/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.http2;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.ballerina.stdlib.http.transport.util.server.HttpServer;
import io.ballerina.stdlib.http.transport.util.server.HttpsServer;
import io.ballerina.stdlib.http.transport.util.server.initializers.http2.Http2PseudoHeaderServerInitializer;
import io.netty.handler.codec.http.HttpMethod;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP2_VERSION;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTPS_SCHEME;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_SCHEME;
import static io.ballerina.stdlib.http.transport.contract.Constants.PROTOCOL;
import static io.ballerina.stdlib.http.transport.util.Http2Util.getSenderConfigs;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

/**
 * Test cases to test the http/https scheme pseudo header.
 */
public class Http2PseudoHeadersTest {

    private HttpServer http2HttpServer;
    private HttpsServer http2HttpsServer;
    private HttpClientConnector httpClientConnector;
    private HttpClientConnector httpsClientConnector;
    private HttpWsConnectorFactory connectorFactory;

    @BeforeClass
    public void setup() {
        http2HttpServer = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT,
                new Http2PseudoHeaderServerInitializer(HTTP_SCHEME));
        http2HttpsServer = TestUtil.startHttpsServer(TestUtil.HTTPS_SERVER_PORT,
                new Http2PseudoHeaderServerInitializer(HTTPS_SCHEME),
                1, 2, HTTP2_VERSION);
        connectorFactory = new DefaultHttpWsConnectorFactory();

        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration httpSenderConfiguration = HttpConnectorUtil.getSenderConfiguration(transportsConfiguration,
                Constants.HTTP_SCHEME);
        httpSenderConfiguration.setHttpVersion(Constants.HTTP_2_0);

        httpClientConnector = connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), httpSenderConfiguration);
        httpsClientConnector = connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration),
                getSenderConfigs(Constants.HTTP_2_0));
    }

    @Test
    public void testHttpSchemeHeader() {
        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateRequest(HttpMethod.GET, null,
                TestUtil.HTTP_SERVER_PORT, "http://");
        HttpCarbonMessage response = new MessageSender(httpClientConnector).sendMessage(httpCarbonMessage);
        assertNotNull(response, "Expected response not received");
        String result = TestUtil.getStringFromInputStream(new HttpMessageDataStreamer(response).getInputStream());
        assertEquals(result, "http - via HTTP/2", "Expected response not received");
    }

    @Test
    public void testHttpsSchemeHeader() {
        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateRequest(HttpMethod.GET, null,
                TestUtil.HTTPS_SERVER_PORT, "https://");
        httpCarbonMessage.setProperty(PROTOCOL, HTTPS_SCHEME);
        HttpCarbonMessage response = new MessageSender(httpsClientConnector).sendMessage(httpCarbonMessage);
        assertNotNull(response, "Expected response not received");
        String result = TestUtil.getStringFromInputStream(new HttpMessageDataStreamer(response).getInputStream());
        assertEquals(result, "https - via HTTP/2", "Expected response not received");
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            http2HttpServer.shutdown();
            http2HttpsServer.shutdown();
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            TestUtil.handleException("Failed to shutdown the test server", e);
        }
    }

}
