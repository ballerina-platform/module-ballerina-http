/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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

import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoMessageListener;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.InboundMsgSizeValidationConfig;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.util.Http2Util;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SCHEME;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

/**
 * Tests that a request whose headers exceed the maximum header list size of the HTTP/2 server is failed with the
 * reason reported by the HTTP/2 codec, rather than with the generic message of the stream closure which follows it.
 */
public class Http2ClientHeaderSizeExceededTestCase {

    private static final int MAX_HEADER_SIZE = 600;
    private static final String EXPECTED_FAILURE = "Header size exceeded max allowed size (" + MAX_HEADER_SIZE + ")";

    private HttpWsConnectorFactory connectorFactory;
    private ServerConnector serverConnector;
    private HttpClientConnector clientConnector;

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        InboundMsgSizeValidationConfig sizeValidationConfig = new InboundMsgSizeValidationConfig();
        sizeValidationConfig.setMaxHeaderSize(MAX_HEADER_SIZE);
        listenerConfiguration.setMsgSizeValidationConfig(sizeValidationConfig);

        serverConnector = connectorFactory.createServerConnector(TestUtil.getDefaultServerBootstrapConfig(),
                listenerConfiguration);
        ServerConnectorFuture serverConnectorFuture = serverConnector.start();
        serverConnectorFuture.setHttpConnectorListener(new EchoMessageListener());
        serverConnectorFuture.sync();

        clientConnector = Http2Util.getTestHttp2Client(connectorFactory, true);
    }

    @Test(description = "The cause reported by the codec must reach the caller when the request headers exceed the "
            + "header size limit of the server")
    public void testHeaderSizeExceededReportsCodecCause() {
        MessageSender messageSender = new MessageSender(clientConnector);
        // The first request establishes the connection and receives the SETTINGS frame of the server, which carries
        // the header size limit that the next request is validated against.
        HttpCarbonMessage warmUpResponse = messageSender.sendMessage(createRequest("small"));
        assertNotNull(warmUpResponse, "Expected response not received");

        Throwable error = messageSender.sendMessageAndExpectError(createRequest(largeHeaderValue()));
        assertNotNull(error, "Expected the request to fail as its headers exceed the limit");
        assertEquals(error.getMessage(), EXPECTED_FAILURE);
    }

    private HttpCarbonMessage createRequest(String headerValue) {
        String path = "/";
        String uri = HTTP_SCHEME + TestUtil.TEST_HOST + ":" + TestUtil.HTTP_SERVER_PORT + path;
        HttpCarbonMessage request = new HttpCarbonRequest(
                new DefaultHttpRequest(new HttpVersion(Constants.DEFAULT_VERSION_HTTP_1_1, true),
                        HttpMethod.GET, uri));
        request.setHttpMethod(HttpMethod.GET.name());
        request.setProperty(Constants.TO, path);
        request.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
        request.setProperty(Constants.HTTP_PORT, TestUtil.HTTP_SERVER_PORT);
        request.setHeader(TestUtil.HOST, TestUtil.TEST_HOST + ":" + TestUtil.HTTP_SERVER_PORT);
        request.setHeader("X-Test", headerValue);
        request.addHttpContent(new DefaultLastHttpContent());
        return request;
    }

    private static String largeHeaderValue() {
        return "0123456789".repeat(MAX_HEADER_SIZE / 5);
    }

    @AfterClass
    public void cleanUp() throws Exception {
        clientConnector.close();
        serverConnector.stop();
        connectorFactory.shutdown();
    }
}
