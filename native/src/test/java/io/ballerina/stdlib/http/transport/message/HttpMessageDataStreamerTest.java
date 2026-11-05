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

import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.netty.buffer.AbstractByteBufAllocator;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.ByteBufAllocator;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DecoderException;
import io.netty.handler.codec.DecoderResult;
import io.netty.handler.codec.EncoderException;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http.LastHttpContent;
import org.junit.Assert;
import org.testng.annotations.Test;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.zip.GZIPOutputStream;
import java.util.zip.InflaterInputStream;

import static io.netty.handler.codec.http.HttpResponseStatus.OK;
import static org.mockito.Mockito.mock;
import static org.testng.Assert.assertThrows;
import static org.testng.Assert.expectThrows;

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

    @Test(timeOut = 10000)
    public void testReadReturnsTheBytesAlreadyReceived() throws Exception {
        HttpCarbonMessage message = newResponse(60000);
        message.addHttpContent(chunk("data: 1\n\n"));
        InputStream inputStream = new HttpMessageDataStreamer(message).getInputStream();

        CompletableFuture<String> firstRead = CompletableFuture.supplyAsync(() -> readOnce(inputStream, 8192));
        Assert.assertEquals("data: 1\n\n", firstRead.get(2, TimeUnit.SECONDS));

        CompletableFuture<String> secondRead = CompletableFuture.supplyAsync(() -> readOnce(inputStream, 8192));
        // Still waiting: no further content has arrived yet.
        assertThrows(TimeoutException.class, () -> secondRead.get(200, TimeUnit.MILLISECONDS));
        message.addHttpContent(new DefaultLastHttpContent(text("data: 2\n\n")));
        Assert.assertEquals("data: 2\n\n", secondRead.get(2, TimeUnit.SECONDS));
        Assert.assertEquals(-1, inputStream.read(new byte[8192], 0, 8192));
    }

    @Test
    public void testReadDrainsQueuedChunksAcrossBoundaries() throws IOException {
        HttpCarbonMessage message = newResponse(60000);
        ByteBuf first = text("abc");
        ByteBuf second = text("defg");
        message.addHttpContent(new DefaultHttpContent(first));
        message.addHttpContent(new DefaultHttpContent(second));
        message.addHttpContent(new DefaultLastHttpContent(text("hi")));
        InputStream inputStream = new HttpMessageDataStreamer(message).getInputStream();

        Assert.assertEquals("abcde", readOnce(inputStream, 5));
        Assert.assertEquals(2, inputStream.available());
        Assert.assertEquals("fghi", readOnce(inputStream, 8192));
        Assert.assertEquals(0, inputStream.available());
        Assert.assertEquals(-1, inputStream.read());
        Assert.assertEquals(0, first.refCnt());
        Assert.assertEquals(0, second.refCnt());
    }

    @Test
    public void testEmptyChunksDoNotEndTheBody() throws IOException {
        HttpCarbonMessage message = newResponse(60000);
        message.addHttpContent(chunk(""));
        message.addHttpContent(chunk("x"));
        message.addHttpContent(chunk(""));
        message.addHttpContent(chunk("y"));
        message.addHttpContent(new DefaultLastHttpContent());
        InputStream inputStream = new HttpMessageDataStreamer(message).getInputStream();

        Assert.assertEquals('x', inputStream.read());
        Assert.assertEquals("y", readOnce(inputStream, 8192));
        Assert.assertEquals(null, readOnce(inputStream, 8192));
    }

    @Test
    public void testReadReportsAFailedBodyAfterTheBytesBeforeIt() {
        HttpCarbonMessage message = newResponse(60000);
        message.addHttpContent(chunk("partial"));
        LastHttpContent failed = new DefaultLastHttpContent();
        failed.setDecoderResult(DecoderResult.failure(new DecoderException("body failed")));
        message.addHttpContent(failed);
        InputStream inputStream = new HttpMessageDataStreamer(message).getInputStream();

        Assert.assertEquals("partial", readOnce(inputStream, 8192));
        DecoderException failure = expectThrows(DecoderException.class,
                                                () -> inputStream.read(new byte[8192], 0, 8192));
        Assert.assertEquals("body failed", failure.getMessage());
        expectThrows(DecoderException.class, inputStream::read);
    }

    @Test
    public void testAFailedFirstChunkIsReportedOnEveryRead() {
        HttpCarbonMessage message = newResponse(60000);
        LastHttpContent failed = new DefaultLastHttpContent();
        failed.setDecoderResult(DecoderResult.failure(new DecoderException("body failed")));
        message.addHttpContent(failed);
        InputStream inputStream = new HttpMessageDataStreamer(message).getInputStream();

        expectThrows(DecoderException.class, inputStream::read);
        expectThrows(DecoderException.class, inputStream::read);
        expectThrows(DecoderException.class, () -> inputStream.read(new byte[8192], 0, 8192));
    }

    @Test(expectedExceptions = DecoderException.class,
          expectedExceptionsMessageRegExp = "No entity was added to the queue before the timeout")
    public void testReadTimesOutWithoutContent() throws IOException {
        InputStream inputStream = new HttpMessageDataStreamer(newResponse(100)).getInputStream();
        inputStream.read(new byte[8192], 0, 8192);
    }

    @Test(timeOut = 10000)
    public void testReadRetriedAfterATimeoutReleasesEachChunkOnce() throws IOException {
        HttpCarbonMessage message = newResponse(100);
        message.addHttpContent(chunk("a"));
        InputStream inputStream = new HttpMessageDataStreamer(message).getInputStream();
        Assert.assertEquals('a', inputStream.read());
        expectThrows(DecoderException.class, inputStream::read);

        message.addHttpContent(chunk("b"));
        message.addHttpContent(new DefaultLastHttpContent());
        Assert.assertEquals('b', inputStream.read());
        Assert.assertEquals(-1, inputStream.read());
    }

    @Test(timeOut = 10000)
    public void testCompressedBodyReadReturnsTheBytesAlreadyReceived() throws Exception {
        ByteArrayOutputStream compressed = new ByteArrayOutputStream();
        GZIPOutputStream gzip = new GZIPOutputStream(compressed, true);
        gzip.write("first".getBytes(StandardCharsets.UTF_8));
        gzip.flush();
        byte[] firstPart = compressed.toByteArray();
        compressed.reset();
        gzip.write("second".getBytes(StandardCharsets.UTF_8));
        gzip.close();
        byte[] secondPart = compressed.toByteArray();

        HttpCarbonMessage message = newResponse(60000);
        message.setHeader(HttpHeaderNames.CONTENT_ENCODING.toString(), "gzip");
        message.addHttpContent(new DefaultHttpContent(Unpooled.wrappedBuffer(firstPart)));
        ReadableByteChannel channel = Channels.newChannel(new HttpMessageDataStreamer(message).getInputStream());

        ByteBuffer buffer = ByteBuffer.allocate(8192);
        CompletableFuture<Integer> firstRead = CompletableFuture.supplyAsync(() -> {
            try {
                return channel.read(buffer);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        });
        Assert.assertEquals("first".length(), firstRead.get(2, TimeUnit.SECONDS).intValue());
        Assert.assertEquals("first", new String(buffer.array(), 0, buffer.position(), StandardCharsets.UTF_8));

        message.addHttpContent(new DefaultLastHttpContent(Unpooled.wrappedBuffer(secondPart)));
        buffer.clear();
        Assert.assertEquals("second".length(), channel.read(buffer));
        Assert.assertEquals("second", new String(buffer.array(), 0, buffer.position(), StandardCharsets.UTF_8));
    }

    @Test
    public void testAbortingTheOutputStreamEndsTheBodyAsFailed() throws IOException {
        HttpCarbonMessage message = newResponse(1000);
        OutputStream outputStream = new HttpMessageDataStreamer(message).getOutputStream();
        outputStream.write("unsent".getBytes(StandardCharsets.UTF_8));
        IOException cause = new IOException("disk failure");

        Assert.assertTrue("The abort did not end the body", HttpUtil.abortMessageOutputStream(outputStream, cause));
        outputStream.close();

        HttpContent end = message.getBlockingEntityCollector().getHttpContent();
        Assert.assertTrue(end instanceof LastHttpContent);
        Assert.assertSame(cause, end.decoderResult().cause());
        Assert.assertEquals(0, end.content().readableBytes());
        Assert.assertNull("Closing after the abort ended the body again",
                          message.getBlockingEntityCollector().getHttpContent());
    }

    @Test
    public void testAbortingTheOutputStreamOfAFailedMessageReportsNothingEnded() {
        HttpCarbonMessage message = newResponse(1000);
        message.setIoException(new IOException("client closed the connection"));
        OutputStream outputStream = new HttpMessageDataStreamer(message).getOutputStream();

        Assert.assertFalse("The abort ended a body that had already failed",
                           HttpUtil.abortMessageOutputStream(outputStream, new IOException("disk failure")));
    }

    @Test
    public void testEventStreamKeepsWritingIntoAFreshBufferAfterARejectedEvent() throws IOException {
        HttpCarbonMessage message = newResponse(1000);
        message.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), "text/event-stream");
        message.setIoException(new IOException("client closed the connection"));
        OutputStream outputStream = new HttpMessageDataStreamer(message).getOutputStream();

        outputStream.write("data: a\n".getBytes(StandardCharsets.UTF_8));
        assertThrows(EncoderException.class, () -> outputStream.write('\n'));
        outputStream.write('d');
    }

    @Test
    public void testClosingAnEventStreamSendsItsLastBytesAndReleasesItsBuffers() throws IOException {
        List<ByteBuf> buffers = new ArrayList<>();
        ByteBufAllocator allocator = new AbstractByteBufAllocator() {
            @Override
            protected ByteBuf newHeapBuffer(int initialCapacity, int maxCapacity) {
                return Unpooled.buffer(initialCapacity, maxCapacity);
            }

            @Override
            protected ByteBuf newDirectBuffer(int initialCapacity, int maxCapacity) {
                ByteBuf buffer = Unpooled.directBuffer(initialCapacity, maxCapacity);
                buffers.add(buffer);
                return buffer;
            }

            @Override
            public boolean isDirectBufferPooled() {
                return false;
            }
        };
        HttpCarbonMessage message = newResponse(1000);
        message.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), "text/event-stream");
        OutputStream outputStream = new HttpMessageDataStreamer(message, allocator).getOutputStream();

        outputStream.write("data: a\n\ndata: b".getBytes(StandardCharsets.UTF_8));
        outputStream.close();

        EntityCollector entityCollector = message.getBlockingEntityCollector();
        HttpContent event = entityCollector.getHttpContent();
        Assert.assertEquals("data: a\n\n", event.content().toString(StandardCharsets.UTF_8));
        event.release();
        HttpContent last = entityCollector.getHttpContent();
        Assert.assertTrue(last instanceof LastHttpContent);
        Assert.assertEquals("data: b", last.content().toString(StandardCharsets.UTF_8));
        last.release();
        for (ByteBuf buffer : buffers) {
            Assert.assertEquals(0, buffer.refCnt());
        }
    }

    private static HttpCarbonMessage newResponse(int maxWaitTimeMillis) {
        return new HttpCarbonMessage(new DefaultHttpResponse(HttpVersion.HTTP_1_1, OK), maxWaitTimeMillis,
                                     mock(Listener.class));
    }

    private static HttpContent chunk(String value) {
        return new DefaultHttpContent(text(value));
    }

    private static ByteBuf text(String value) {
        return Unpooled.copiedBuffer(value, StandardCharsets.UTF_8);
    }

    private static String readOnce(InputStream inputStream, int length) {
        byte[] buffer = new byte[length];
        try {
            int read = inputStream.read(buffer, 0, length);
            return read < 0 ? null : new String(buffer, 0, read, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
