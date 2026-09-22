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

package io.ballerina.stdlib.http.transport.compression;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.message.ResponseHandle;
import io.ballerina.stdlib.http.transport.util.Http2Util;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageSender;
import io.ballerina.stdlib.http.transport.util.server.HttpServer;
import io.ballerina.stdlib.http.transport.util.server.initializers.GzipResponseServerInitializer;
import io.ballerina.stdlib.http.transport.util.server.initializers.http2.gzip.GzipPayloads;
import io.ballerina.stdlib.http.transport.util.server.initializers.http2.gzip.Http2GzipServerInitializer;
import io.netty.handler.codec.DecoderException;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpVersion;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import static io.ballerina.stdlib.http.transport.util.TestUtil.HTTP_SCHEME;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;
import static org.testng.Assert.expectThrows;

/**
 * Tests that a response body which cannot be decoded is reported to the caller rather than leaving the read
 * blocked, on both HTTP/1.1 and HTTP/2.
 */
public class ClientRespDecodingFailureTestCase {

    // Generous enough to absorb a slow CI machine, but far below the blocking entity collector's own wait, so a
    // read that is never terminated fails this test instead of passing late.
    private static final int READ_TIMEOUT_SECONDS = 15;

    // Both protocols must report the reason the decoder gave, rather than the stream error or the channel closure
    // each one wraps it in, so the same malformed body reads the same way whichever protocol carried it.
    private static final String EXPECTED_FAILURE =
            Constants.CONTENT_DECODING_FAILED + ": Input is not in the GZIP format";

    private HttpWsConnectorFactory connectorFactory;
    private HttpServer http2Server;
    private HttpServer http1Server;
    private HttpClientConnector http2ClientConnector;
    private HttpClientConnector http1ClientConnector;

    @BeforeClass
    public void setup() {
        connectorFactory = new DefaultHttpWsConnectorFactory();
        http2Server = TestUtil.startHTTPServer(TestUtil.HTTP_SERVER_PORT, new Http2GzipServerInitializer(), 1, 2);
        http1Server = TestUtil.startHTTPServer(TestUtil.SERVER_CONNECTOR_PORT, new GzipResponseServerInitializer(),
                1, 2);
        http2ClientConnector = Http2Util.getTestHttp2Client(connectorFactory, true);
        http1ClientConnector = Http2Util.getTestHttp1Client(connectorFactory);
    }

    @Test(description = "A malformed gzip body over HTTP/2 must surface as an error instead of blocking the read")
    public void testMalformedGzipOverHttp2() {
        assertReadFails(sendRequest(http2ClientConnector, TestUtil.HTTP_SERVER_PORT, GzipPayloads.PATH_MALFORMED_GZIP));
    }

    @Test(description = "A malformed gzip push response over HTTP/2 must surface as an error instead of blocking")
    public void testMalformedGzipPushResponseOverHttp2() {
        MessageSender messageSender = new MessageSender(http2ClientConnector);
        ResponseHandle handle = messageSender.submitMessage(
                createRequest(TestUtil.HTTP_SERVER_PORT, GzipPayloads.PATH_PUSH));
        assertNotNull(handle, "Response handle not found");
        assertTrue(messageSender.checkPromiseAvailability(handle), "Promise not available");
        Http2PushPromise promise = messageSender.getNextPromise(handle);
        assertNotNull(promise, "Promise not received");
        HttpCarbonMessage pushResponse = messageSender.getPushResponse(promise);
        assertNotNull(pushResponse, "Push response not received");
        assertReadFails(pushResponse);
    }

    @Test(description = "A valid gzip body over HTTP/2 is still decoded")
    public void testValidGzipOverHttp2() {
        HttpCarbonMessage response = sendRequest(http2ClientConnector, TestUtil.HTTP_SERVER_PORT, "/gzip");
        assertEquals(readBody(response), GzipPayloads.DECODED_CONTENT);
    }

    @Test(description = "A malformed gzip body over HTTP/1.1 keeps reporting an error")
    public void testMalformedGzipOverHttp1() {
        assertReadFails(sendRequest(http1ClientConnector, TestUtil.SERVER_CONNECTOR_PORT,
                GzipPayloads.PATH_MALFORMED_GZIP));
    }

    private void assertReadFails(HttpCarbonMessage response) {
        DecoderException error = expectThrows(DecoderException.class, () -> readBody(response));
        assertEquals(error.getMessage(), EXPECTED_FAILURE);
    }

    private HttpCarbonMessage sendRequest(HttpClientConnector clientConnector, int port, String path) {
        HttpCarbonMessage response = new MessageSender(clientConnector).sendMessage(createRequest(port, path));
        assertNotNull(response, "Expected response not received");
        return response;
    }

    private String readBody(HttpCarbonMessage response) {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        try (InputStream inputStream = new HttpMessageDataStreamer(response).getInputStream()) {
            Future<String> read = executor.submit(() -> TestUtil.getStringFromInputStream(inputStream));
            try {
                return read.get(READ_TIMEOUT_SECONDS, TimeUnit.SECONDS);
            } catch (TimeoutException e) {
                read.cancel(true);
                throw new AssertionError("Reading the response body did not return within " + READ_TIMEOUT_SECONDS
                        + " seconds", e);
            } catch (ExecutionException e) {
                Throwable cause = e.getCause();
                throw cause instanceof RuntimeException ? (RuntimeException) cause : new RuntimeException(cause);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new AssertionError(e);
            }
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        } finally {
            executor.shutdownNow();
        }
    }

    private HttpCarbonMessage createRequest(int port, String path) {
        String uri = HTTP_SCHEME + TestUtil.TEST_HOST + ":" + port + path;
        HttpCarbonMessage request = new HttpCarbonRequest(
                new DefaultHttpRequest(new HttpVersion(Constants.DEFAULT_VERSION_HTTP_1_1, true),
                        HttpMethod.GET, uri));
        request.setHttpMethod(HttpMethod.GET.name());
        request.setProperty(Constants.TO, path);
        request.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
        request.setProperty(Constants.HTTP_PORT, port);
        request.setHeader(TestUtil.HOST, TestUtil.TEST_HOST + ":" + port);
        request.addHttpContent(new DefaultLastHttpContent());
        return request;
    }

    @AfterClass
    public void cleanUp() throws Exception {
        http2ClientConnector.close();
        http1ClientConnector.close();
        http2Server.shutdown();
        http1Server.shutdown();
        connectorFactory.shutdown();
    }
}
