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

package io.ballerina.stdlib.http.transport.message;

import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http.LastHttpContent;
import org.junit.Assert;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.zip.InflaterInputStream;

import static io.netty.handler.codec.http.HttpResponseStatus.OK;

/**
 * A unit test class for Transport module HttpMessageDataStreamer class functions.
 */
public class HttpMessageDataStreamerTest {

    @Test
    public void testGetInputStreamWithContentEncoding() {
        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateResponse("testResponse");
        httpCarbonMessage.setHeader(HttpHeaderNames.CONTENT_ENCODING.toString(), "gzip");
        HttpMessageDataStreamer httpMessageDataStreamer = new HttpMessageDataStreamer(httpCarbonMessage);
        Assert.assertNotNull(httpMessageDataStreamer.getInputStream());
        Assert.assertNull(httpCarbonMessage.getHeader(HttpHeaderNames.CONTENT_ENCODING.toString()));

        httpCarbonMessage.setHeader(HttpHeaderNames.CONTENT_ENCODING.toString(), "deflate");
        httpMessageDataStreamer = new HttpMessageDataStreamer(httpCarbonMessage);
        InputStream returnVal = httpMessageDataStreamer.getInputStream();
        Assert.assertTrue(returnVal instanceof InflaterInputStream);
        Assert.assertNull(httpCarbonMessage.getHeader(HttpHeaderNames.CONTENT_ENCODING.toString()));

        httpCarbonMessage.setHeader(HttpHeaderNames.CONTENT_ENCODING.toString(), "identity");
        httpMessageDataStreamer = new HttpMessageDataStreamer(httpCarbonMessage);
        Assert.assertNotNull(httpMessageDataStreamer.getInputStream());
        Assert.assertNull(httpCarbonMessage.getHeader(HttpHeaderNames.CONTENT_ENCODING.toString()));

        httpCarbonMessage.setHeader(HttpHeaderNames.CONTENT_ENCODING.toString(), "test");
        httpMessageDataStreamer = new HttpMessageDataStreamer(httpCarbonMessage);
        Assert.assertNotNull(httpMessageDataStreamer.getInputStream());
        Assert.assertNull(httpCarbonMessage.getHeader(HttpHeaderNames.CONTENT_ENCODING.toString()));
    }

    @Test
    public void testEventStreamChunking() throws IOException {
        HttpCarbonMessage httpResponse = new HttpCarbonResponse(new DefaultHttpResponse(HttpVersion.HTTP_1_1, OK));
        httpResponse.setHeader("Content-Type", "text/event-stream");
        HttpMessageDataStreamer httpMessageDataStreamer = new HttpMessageDataStreamer(httpResponse);
        OutputStream outputStream = httpMessageDataStreamer.getOutputStream();
        writeDummyEvent(outputStream);
        EntityCollector entityCollector = httpResponse.getBlockingEntityCollector();
        HttpContent content = entityCollector.getHttpContent();
        int currentChunkCount = 0;
        while (!(content instanceof LastHttpContent)) {
            currentChunkCount++;
            content = entityCollector.getHttpContent();
        }
        Assert.assertEquals(currentChunkCount, 4);
    }

    // This method writes a server-sent event payload to the output stream
    private static void writeDummyEvent(OutputStream outputStream) throws IOException {
        final int maxChunkSize = 8192;
        final int payloadSize = maxChunkSize * 4 - 10; // Reduced by few bytes to ensure chunking
                                                       // happens if two newlines are found
        final String dataPrefix = "data: ";
        final byte[] dataBytes = dataPrefix.getBytes();

        // Write the data prefix to the output stream
        outputStream.write(dataBytes);
        for (int i = dataBytes.length; i < payloadSize; i++) {
            outputStream.write('A');
        }

        // Write two newline characters to indicate the end of the event
        outputStream.write('\n');
        outputStream.write('\n');

        // Close the output stream
        outputStream.close();
    }
}
