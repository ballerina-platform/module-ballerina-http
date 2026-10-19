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

import io.ballerina.stdlib.http.transport.contractimpl.common.states.StateUtil;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.DecoderException;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpMessage;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponse;
import io.netty.handler.codec.http.LastHttpContent;
import org.junit.Assert;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

import static io.netty.buffer.Unpooled.EMPTY_BUFFER;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertTrue;
import static org.testng.Assert.expectThrows;

/**
 * A unit test class for Transport module HttpCarbonMessage class functions.
 */
public class HttpCarbonMessageTest {

    @Test
    public void testGetMessageBodyWithMockObjects() {
        HttpMessage httpMessage = mock(HttpMessage.class);
        Listener contentListener = mock(Listener.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpMessage, 100, contentListener);
        ByteBuf returnVal = httpCarbonMessage.getMessageBody();
        Assert.assertNull(returnVal);
    }

    @Test
    public void testGetFullMessageLengthWithMockObjects() {
        HttpMessage httpMessage = mock(HttpMessage.class);
        Listener contentListener = mock(Listener.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpMessage, 100, contentListener);
        long returnVal = httpCarbonMessage.getFullMessageLength();
        Assert.assertEquals(returnVal, 0);
    }

    @Test
    public void testAddMessageBodyWithMockObjects() {
        HttpMessage httpMessage = mock(HttpMessage.class);
        Listener contentListener = mock(Listener.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpMessage, 100, contentListener);
        ByteBuffer msgBody = ByteBuffer.allocate(16);
        httpCarbonMessage.addMessageBody(msgBody);
    }

    @Test
    public void testSetGetAndRemoveProperty() {
        HttpMessage httpMessage = mock(HttpMessage.class);
        Listener contentListener = mock(Listener.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpMessage, 100, contentListener);
        Object value = new Object();
        httpCarbonMessage.setProperty("property", value);
        Object returnVal = httpCarbonMessage.getProperty("property");
        Assert.assertEquals(returnVal, value);
        httpCarbonMessage.removeProperty("property");
        returnVal = httpCarbonMessage.getProperty("property");
        Assert.assertNull(returnVal);
    }

    @Test
    public void testGetReasonPhraseWithUnknownStatus() {
        HttpMessage httpMessage = mock(HttpMessage.class);
        Listener contentListener = mock(Listener.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpMessage, 100, contentListener);
        String returnVal = httpCarbonMessage.getReasonPhrase();
        Assert.assertEquals(returnVal, "Unknown Status");
    }

    @Test
    public void testGetNettyHttpRequest() {
        HttpMessage httpRequest = mock(HttpRequest.class);
        Listener contentListener = mock(Listener.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpRequest, 100, contentListener);
        HttpRequest returnVal = httpCarbonMessage.getNettyHttpRequest();
        Assert.assertEquals(returnVal, httpRequest);
    }

    @Test
    public void testGetNettyHttpResponse() {
        HttpMessage httpResponse = mock(HttpResponse.class);
        Listener contentListener = mock(Listener.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpResponse, 100, contentListener);
        HttpResponse returnVal = httpCarbonMessage.getNettyHttpResponse();
        Assert.assertEquals(returnVal, httpResponse);
    }

    @Test (expectedExceptions = RuntimeException.class)
    public void testAddHttpContentThrowsRunTimeException() {
        HttpMessage httpResponse = mock(HttpResponse.class);
        Listener contentListener = mock(Listener.class);
        HttpContent httpContent = mock(HttpContent.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpResponse, 100, contentListener);
        httpCarbonMessage.getHttpContentAsync();
        httpCarbonMessage.setIoException(new IOException());
        httpCarbonMessage.addHttpContent(httpContent);
    }

    @Test
    public void testContentRejectedAfterAnIoExceptionIsReleased() {
        HttpCarbonMessage listenedMessage = new HttpCarbonMessage(mock(HttpResponse.class), 100,
                                                                  mock(Listener.class));
        List<HttpContent> delivered = new ArrayList<>();
        listenedMessage.getHttpContentAsync().setMessageListener(delivered::add);
        assertReleasedOnRejection(listenedMessage);
        assertTrue(delivered.size() == 1 && delivered.get(0) instanceof LastHttpContent,
                   "The listener was not told that the body ended: " + delivered);

        assertReleasedOnRejection(new HttpCarbonMessage(mock(HttpResponse.class), 100, mock(Listener.class)));
    }

    @Test
    public void testQueuedContentIsKeptWhenContentIsRejectedBeforeAListenerIsSet() {
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(mock(HttpResponse.class), 100,
                                                                    mock(Listener.class));
        httpCarbonMessage.getHttpContentAsync();
        HttpContent queued = new DefaultHttpContent(Unpooled.copiedBuffer("queued", StandardCharsets.UTF_8));
        httpCarbonMessage.addHttpContent(queued);

        assertReleasedOnRejection(httpCarbonMessage);

        Assert.assertSame(queued, httpCarbonMessage.getHttpContent());
        assertTrue(httpCarbonMessage.getHttpContent() instanceof LastHttpContent);
        queued.release();
    }

    @Test
    public void testContentRejectedAfterAnIoExceptionIsReportedAsRemoved() {
        assertReportedAsRemovedOnRejection(true);
        assertReportedAsRemovedOnRejection(false);
    }

    private static void assertReportedAsRemovedOnRejection(boolean withMessageListener) {
        Listener contentListener = mock(Listener.class);
        List<Integer> removedBytes = new ArrayList<>();
        doAnswer(invocation -> removedBytes.add(invocation.<HttpContent>getArgument(0).content().readableBytes()))
                .when(contentListener).onRemove(any());
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(mock(HttpResponse.class), 100, contentListener);
        if (withMessageListener) {
            httpCarbonMessage.getHttpContentAsync().setMessageListener(content -> { });
        }

        assertReleasedOnRejection(httpCarbonMessage);

        Assert.assertEquals(List.of("rejected".length()), removedBytes);
    }

    private static void assertReleasedOnRejection(HttpCarbonMessage httpCarbonMessage) {
        httpCarbonMessage.setIoException(new IOException("client closed the connection"));
        HttpContent rejected = new DefaultHttpContent(Unpooled.copiedBuffer("rejected", StandardCharsets.UTF_8));
        expectThrows(UncheckedIOException.class, () -> httpCarbonMessage.addHttpContent(rejected));
        Assert.assertEquals(0, rejected.refCnt());
    }

    @Test
    public void testNotifyContentFailure() {
        HttpMessage httpResponse = mock(HttpResponse.class);
        Listener contentListener = mock(Listener.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpResponse, 100, contentListener);
        httpCarbonMessage.getFullHttpCarbonMessage();
        httpCarbonMessage.notifyContentFailure(new Exception());
    }


    // A content writer parked inside addHttpContent - the HTTP/2 outbound path blocks there when the peer's
    // flow control window is shut - used to hold the message monitor, so the event loop failing the queued
    // writes after an RST_STREAM deadlocked against it and the connection could never be closed.
    @Test(timeOut = 30000)
    public void testSetIoExceptionIsNotBlockedByAParkedContentWriter() throws Exception {
        HttpMessage httpMessage = mock(HttpMessage.class);
        Listener contentListener = mock(Listener.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpMessage, 100, contentListener);

        CountDownLatch writerParked = new CountDownLatch(1);
        CountDownLatch releaseWriter = new CountDownLatch(1);
        httpCarbonMessage.getHttpContentAsync().setMessageListener(httpContent -> {
            writerParked.countDown();
            try {
                releaseWriter.await();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        Thread writer = new Thread(() -> httpCarbonMessage.addHttpContent(mock(HttpContent.class)));
        Thread failer = new Thread(() -> httpCarbonMessage.setIoException(new IOException("write failed")));
        writer.start();
        try {
            assertTrue(writerParked.await(10, TimeUnit.SECONDS),
                       "Content writer never reached the message listener");
            failer.start();
            failer.join(TimeUnit.SECONDS.toMillis(10));
            assertFalse(failer.isAlive(),
                        "setIoException blocked behind a content writer parked inside addHttpContent");
        } finally {
            releaseWriter.countDown();
            writer.join(TimeUnit.SECONDS.toMillis(10));
            failer.join(TimeUnit.SECONDS.toMillis(10));
        }
    }

    @Test(timeOut = 30000)
    public void testReleaseIsNotBlockedByAParkedContentWriter() throws Exception {
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(mock(HttpMessage.class), 100,
                                                                    mock(Listener.class));
        CountDownLatch writerParked = new CountDownLatch(1);
        CountDownLatch releaseWriter = new CountDownLatch(1);
        httpCarbonMessage.getHttpContentAsync().setMessageListener(httpContent -> {
            writerParked.countDown();
            try {
                releaseWriter.await();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        Thread writer = new Thread(() -> httpCarbonMessage.addHttpContent(mock(HttpContent.class)));
        Thread releaser = new Thread(httpCarbonMessage::waitAndReleaseAllEntities);
        writer.start();
        try {
            assertTrue(writerParked.await(10, TimeUnit.SECONDS),
                       "Content writer never reached the message listener");
            httpCarbonMessage.setIoException(new IOException("write failed"));
            releaser.start();
            releaser.join(TimeUnit.SECONDS.toMillis(10));
            assertFalse(releaser.isAlive(),
                        "waitAndReleaseAllEntities blocked behind a content writer parked inside addHttpContent");
        } finally {
            releaseWriter.countDown();
            writer.join(TimeUnit.SECONDS.toMillis(10));
            releaser.join(TimeUnit.SECONDS.toMillis(10));
        }
    }

    // In passthrough the outbound writer takes each request chunk off the collector, so the response must only
    // wait for the request body to finish arriving, not for a LastHttpContent the collector will never hold.
    @Test(timeOut = 30000)
    public void testReleaseWaitsForABodyOwnedByAMessageListenerToArrive() throws Exception {
        assertReleaseWaitsUntil(message -> {
            message.addHttpContent(new DefaultLastHttpContent(EMPTY_BUFFER));
            message.setLastHttpContentArrived();
        });
    }

    // An outbound body is never marked as arrived, so its end is the LastHttpContent passing to the listener.
    @Test(timeOut = 30000)
    public void testReleaseOfABodyOwnedByAMessageListenerEndsWithItsLastContent() throws Exception {
        assertReleaseWaitsUntil(message -> message.addHttpContent(new DefaultLastHttpContent()));
    }

    @Test(timeOut = 30000)
    public void testReleaseOfABodyOwnedByAMessageListenerEndsOnContentFailure() throws Exception {
        assertReleaseWaitsUntil(message -> message.notifyContentFailure(new DecoderException("client closed")));
    }

    // An I/O error rejects any further content, for example after the backend reset a forwarded request, so the
    // body can no longer arrive and the release must not wait for it.
    @Test(timeOut = 30000)
    public void testReleaseOfABodyOwnedByAMessageListenerEndsOnIoException() throws Exception {
        assertReleaseWaitsUntil(message -> message.setIoException(new IOException("backend reset the stream")));
    }

    // The HTTP client clears the I/O error of every request it sends, including a forwarded inbound request whose
    // body is still arriving, so clearing it must not end the wait.
    @Test(timeOut = 30000)
    public void testReleaseStillWaitsAfterTheIoExceptionIsCleared() throws Exception {
        assertReleaseWaitsUntil(message -> message.setIoException(null), message -> {
            message.addHttpContent(new DefaultLastHttpContent(EMPTY_BUFFER));
            message.setLastHttpContentArrived();
        });
    }

    @Test
    public void testIncompleteInboundMessageIsRecordedAfterAnIoException() throws Exception {
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(mock(HttpRequest.class),
                                                                    (int) TimeUnit.MINUTES.toMillis(1),
                                                                    mock(Listener.class));
        httpCarbonMessage.setIoException(new IOException("backend reset the stream"));

        StateUtil.handleIncompleteInboundMessage(httpCarbonMessage, "client idle");

        CompletableFuture<Exception> failure = new CompletableFuture<>();
        httpCarbonMessage.getFullHttpCarbonMessage().addListener(new FullHttpMessageListener() {
            @Override
            public void onComplete(HttpCarbonMessage message) {
                failure.complete(null);
            }

            @Override
            public void onError(Exception error) {
                failure.complete(error);
            }
        });
        Exception recorded = failure.get(5, TimeUnit.SECONDS);
        assertTrue(recorded != null && "client idle".equals(recorded.getMessage()),
                   "The incomplete body was not recorded as a failure: " + recorded);
    }

    private static void assertReleaseWaitsUntil(Consumer<HttpCarbonMessage> endOfBody) throws Exception {
        assertReleaseWaitsUntil(message -> { }, endOfBody);
    }

    private static void assertReleaseWaitsUntil(Consumer<HttpCarbonMessage> beforeRelease,
                                                Consumer<HttpCarbonMessage> endOfBody) throws Exception {
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(mock(HttpRequest.class),
                                                                    (int) TimeUnit.MINUTES.toMillis(1),
                                                                    mock(Listener.class));
        httpCarbonMessage.getHttpContentAsync().setMessageListener(HttpContent::release);
        httpCarbonMessage.addHttpContent(new DefaultHttpContent(EMPTY_BUFFER));
        beforeRelease.accept(httpCarbonMessage);

        CountDownLatch released = new CountDownLatch(1);
        Thread releaser = new Thread(() -> {
            httpCarbonMessage.waitAndReleaseAllEntities();
            released.countDown();
        });
        releaser.start();
        assertFalse(released.await(500, TimeUnit.MILLISECONDS), "Released before the body finished arriving");

        endOfBody.accept(httpCarbonMessage);
        assertTrue(released.await(5, TimeUnit.SECONDS), "Still waiting after the body finished arriving");
        assertTrue(httpCarbonMessage.isContentReleased());
    }
}
