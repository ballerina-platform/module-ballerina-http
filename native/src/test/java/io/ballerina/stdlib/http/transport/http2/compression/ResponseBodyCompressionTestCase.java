/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.http2.compression;

import io.ballerina.stdlib.http.transport.contentaware.listeners.EchoMessageListener;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.nettyclient.Http2NettyClient;
import io.ballerina.stdlib.http.transport.util.client.http2.nettyclient.HttpResponseHandler;
import io.netty.handler.codec.http.FullHttpResponse;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static org.testng.AssertJUnit.assertEquals;
import static org.testng.AssertJUnit.assertNotNull;
import static org.testng.AssertJUnit.assertNull;

/**
 * Test HTTP/2 response body compression.
 */
public class ResponseBodyCompressionTestCase {
    private static final Logger LOG = LoggerFactory.getLogger(ResponseBodyCompressionTestCase.class);
    private ServerConnector serverConnector;
    private HttpWsConnectorFactory connectorFactory;
    private Http2NettyClient h2ClientWithoutDecompressor;
    private static final String PAYLOAD = "Test Http2 Message";

    @BeforeClass
    public void setup() throws InterruptedException {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        listenerConfiguration.setPort(TestUtil.HTTP_SERVER_PORT);
        listenerConfiguration.setScheme(Constants.HTTP_SCHEME);
        listenerConfiguration.setVersion(Constants.HTTP_2_0);
        serverConnector = connectorFactory
                .createServerConnector(TestUtil.getDefaultServerBootstrapConfig(), listenerConfiguration);
        ServerConnectorFuture future = serverConnector.start();
        future.setHttpConnectorListener(new EchoMessageListener());
        future.sync();
        h2ClientWithoutDecompressor = new Http2NettyClient();
    }

    @Test
    public void testResponseBodyCompression() throws Exception {

        h2ClientWithoutDecompressor.startClient(TestUtil.HTTP_SERVER_PORT, false);
        HttpResponseHandler responseHandler;

        int streamId = 3;
        responseHandler = h2ClientWithoutDecompressor.sendPostRequest(PAYLOAD, streamId,
                                                                      HttpHeaderValues.GZIP.toString());
        assertCompressedResults(Constants.ENCODING_GZIP, responseHandler.getFullResponse(streamId),
                                responseHandler.getResponsePayload(streamId));

        streamId = streamId + 2;
        responseHandler = h2ClientWithoutDecompressor.sendPostRequest(PAYLOAD, streamId,
                                                                      HttpHeaderValues.DEFLATE.toString());
        assertCompressedResults(Constants.ENCODING_DEFLATE, responseHandler.getFullResponse(streamId),
                                responseHandler.getResponsePayload(streamId));

        streamId = streamId + 2;
        responseHandler = h2ClientWithoutDecompressor.sendPostRequest(PAYLOAD, streamId, "deflate;q=1.0, gzip;q=0.8");
        assertCompressedResults(Constants.ENCODING_DEFLATE, responseHandler.getFullResponse(streamId),
                                responseHandler.getResponsePayload(streamId));

        streamId = streamId + 2;
        responseHandler = h2ClientWithoutDecompressor.sendPostRequest(PAYLOAD, streamId, "br");
        assertCompressedResults(Constants.ENCODING_BR, responseHandler.getFullResponse(streamId),
                responseHandler.getResponsePayload(streamId));

        streamId = streamId + 2;
        responseHandler = h2ClientWithoutDecompressor.sendPostRequest(PAYLOAD, streamId, "br, deflate");
        assertCompressedResults(Constants.ENCODING_BR, responseHandler.getFullResponse(streamId),
                responseHandler.getResponsePayload(streamId));

        streamId = streamId + 2;
        responseHandler = h2ClientWithoutDecompressor.sendPostRequest(PAYLOAD, streamId, null);
        assertPlainResults(responseHandler.getFullResponse(streamId), responseHandler.getResponsePayload(streamId));

        streamId = streamId + 2;
        responseHandler = h2ClientWithoutDecompressor
                .sendPostRequest(PAYLOAD, streamId, HttpHeaderValues.IDENTITY.toString());
        assertPlainResults(responseHandler.getFullResponse(streamId), responseHandler.getResponsePayload(streamId));

        streamId = streamId + 2;
        responseHandler = h2ClientWithoutDecompressor.sendPostRequest(PAYLOAD, streamId, "sdch, snappy");
        assertPlainResults(responseHandler.getFullResponse(streamId), responseHandler.getResponsePayload(streamId));

        streamId = streamId + 2;
        responseHandler = h2ClientWithoutDecompressor.sendPostRequest(PAYLOAD, streamId, "sdch, snappy, deflate");
        assertCompressedResults("deflate", responseHandler.getFullResponse(streamId),
                responseHandler.getResponsePayload(streamId));
    }

    private void assertCompressedResults(String expectedEncoding, FullHttpResponse response, String responsePayload) {
        assertEquals(expectedEncoding, response.headers().get(HttpHeaderNames.CONTENT_ENCODING));
        assertNotNull(responsePayload);
    }

    private void assertPlainResults(FullHttpResponse response, String responsePayload) {
        assertNull(response.headers().get(HttpHeaderNames.CONTENT_ENCODING));
        assertNotNull(responsePayload);
        assertEquals(PAYLOAD, responsePayload);
    }

    @AfterClass
    public void cleanUp() {
        h2ClientWithoutDecompressor.closeChannel();
        serverConnector.stop();
        try {
            connectorFactory.shutdown();
        } catch (InterruptedException e) {
            LOG.warn("Interrupted while waiting for HttpWsFactory to close");
        }
    }
}
