/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.transport.http2.trailer;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.trailer.TrailerHeaderTestTemplate;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.ballerina.stdlib.http.transport.util.server.HttpServer;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http2.DefaultHttp2Headers;
import io.netty.handler.codec.http2.Http2Headers;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.netty.handler.codec.http.HttpResponseStatus.OK;
import static org.testng.Assert.assertNotNull;
import static org.testng.AssertJUnit.assertEquals;
import static org.testng.AssertJUnit.assertTrue;

/**
 * Test case for H2 inbound response which contains only the header frame without any data frame.
 */
public class H2ListenerTrailersInInitialHeaderFrameTestCase extends TrailerHeaderTestTemplate {
    private static final Logger LOG = LoggerFactory.getLogger(H2ListenerTrailersInInitialHeaderFrameTestCase.class);

    private HttpServer http2Server;
    private HttpClientConnector httpClientConnector;
    private HttpWsConnectorFactory connectorFactory;
    private SendHeadersWithoutDataFrameInitializer initializer;

    @BeforeClass
    public void setup() {
        initializer = new SendHeadersWithoutDataFrameInitializer();
        http2Server = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT, initializer);

        connectorFactory = new DefaultHttpWsConnectorFactory();
        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = HttpConnectorUtil.getSenderConfiguration(
                transportsConfiguration, Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        httpClientConnector = connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration);
    }

    @Test()
    public void testNoDataFrameResponse() {
        Http2Headers inputHeaders = new DefaultHttp2Headers().status(OK.codeAsText());
        inputHeaders.add("x-abc", "abc");
        inputHeaders.add("content-length", "0");
        inputHeaders.add("content-type", "text/plain");
        initializer.setHeaders(inputHeaders);

        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateRequest(HttpMethod.GET, "Test");
        HttpCarbonMessage response = new MessageSender(httpClientConnector).sendMessage(httpCarbonMessage);
        assertNotNull(response, "Expected response not received");
        assertEquals(response.getHeaders().get("x-abc"), "abc");
        assertEquals(response.getHeaders().get("content-length"), "0");
        assertEquals(response.getHeaders().get("content-type"), "text/plain");
    }


    @Test(dependsOnMethods = "testNoDataFrameResponse")
    public void testNoDataFrameButWithTrailersInsideHeaderFrame() {
        Http2Headers inputHeaders = new DefaultHttp2Headers().status(OK.codeAsText());
        inputHeaders.add("x-abc", "abc");
        inputHeaders.add("trailer", "abc , hello");
        inputHeaders.add("content-length", "0");
        inputHeaders.add("content-type", "text/plain");
        inputHeaders.add("abc", "abc");
        initializer.setHeaders(inputHeaders);

        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateRequest(HttpMethod.GET, "Test");
        HttpCarbonMessage response = new MessageSender(httpClientConnector).sendMessage(httpCarbonMessage);
        assertNotNull(response, "Expected response not received");
        assertEquals(response.getHeaders().get("x-abc"), "abc");
        assertEquals(response.getHeaders().get("content-length"), "0");
        assertEquals(response.getHeaders().get("content-type"), "text/plain");
        assertEquals(response.getHeaders().get("trailer"), "abc , hello");
        assertEquals(response.getHeaders().get("abc"), "abc");
        assertEquals(response.getTrailerHeaders().get("abc"), "abc");
    }

    @Test(dependsOnMethods = "testNoDataFrameButWithTrailersInsideHeaderFrame")
    public void testNoDataFrameButWithTrailerHeaderAndNoRespectiveTrailers() {
        Http2Headers inputHeaders = new DefaultHttp2Headers().status(OK.codeAsText());
        inputHeaders.add("x-abc", "abc");
        inputHeaders.add("trailer", "abc,cool");
        inputHeaders.add("content-length", "0");
        inputHeaders.add("content-type", "text/plain");
        initializer.setHeaders(inputHeaders);

        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateRequest(HttpMethod.GET, "Test");
        HttpCarbonMessage response = new MessageSender(httpClientConnector).sendMessage(httpCarbonMessage);
        assertNotNull(response, "Expected response not received");
        assertEquals(response.getHeaders().get("x-abc"), "abc");
        assertEquals(response.getHeaders().get("content-length"), "0");
        assertEquals(response.getHeaders().get("content-type"), "text/plain");
        assertEquals(response.getHeaders().get("trailer"), "abc,cool");
        assertTrue(response.getTrailerHeaders().isEmpty());
    }

    @AfterClass
    public void cleanUp() throws ServerConnectorException {
        try {
            http2Server.shutdown();
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.error("Interrupted while waiting for HttpWsFactory to shutdown", e);
        }
    }
}
