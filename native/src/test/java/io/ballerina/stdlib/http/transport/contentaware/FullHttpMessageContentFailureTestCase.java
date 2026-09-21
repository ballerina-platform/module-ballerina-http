/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.contentaware;

import io.ballerina.stdlib.http.transport.message.FullHttpMessageListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonResponse;
import io.netty.handler.codec.DecoderException;
import io.netty.handler.codec.DecoderResult;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http.LastHttpContent;
import org.testng.annotations.Test;

import java.util.concurrent.atomic.AtomicReference;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNull;
import static org.testng.Assert.assertSame;
import static org.testng.Assert.fail;

/**
 * Tests that a content failure reaches whoever asks for the full message, whether they ask before or after it, and
 * that a failed body is never mistaken for an empty one.
 */
public class FullHttpMessageContentFailureTestCase {

    @Test(description = "A failure that arrived before the full message was requested is still reported")
    public void testFailureBeforeListenerIsReplayed() {
        HttpCarbonResponse response = createResponse();
        DecoderException failure = new DecoderException("Failed to decode");
        response.notifyContentFailure(failure);

        RecordingListener listener = new RecordingListener();
        response.getFullHttpCarbonMessage().addListener(listener);

        assertSame(listener.error.get(), failure);
    }

    @Test(description = "A recorded failure wins over the message also being marked complete, in either order")
    public void testFailureWinsOverCompletion() {
        DecoderException failure = new DecoderException("Failed to decode");

        HttpCarbonResponse failedThenCompleted = createResponse();
        failedThenCompleted.notifyContentFailure(failure);
        failedThenCompleted.setLastHttpContentArrived();
        RecordingListener firstListener = new RecordingListener();
        failedThenCompleted.getFullHttpCarbonMessage().addListener(firstListener);
        assertSame(firstListener.error.get(), failure);

        HttpCarbonResponse completedThenFailed = createResponse();
        completedThenFailed.setLastHttpContentArrived();
        completedThenFailed.notifyContentFailure(failure);
        RecordingListener secondListener = new RecordingListener();
        completedThenFailed.getFullHttpCarbonMessage().addListener(secondListener);
        assertSame(secondListener.error.get(), failure);
    }

    @Test(description = "A failure that arrives after the listener was added is reported as before")
    public void testFailureAfterListenerIsReported() {
        HttpCarbonResponse response = createResponse();
        RecordingListener listener = new RecordingListener();
        response.getFullHttpCarbonMessage().addListener(listener);
        DecoderException failure = new DecoderException("Failed to decode");
        response.notifyContentFailure(failure);

        assertSame(listener.error.get(), failure);
    }

    @Test(description = "A message without a failure does not report one")
    public void testNoFailureIsNotReported() {
        HttpCarbonResponse response = createResponse();
        RecordingListener listener = new RecordingListener();
        response.getFullHttpCarbonMessage().addListener(listener);

        assertNull(listener.error.get());
    }

    @Test(description = "A body that failed before any content arrived must not be counted as an empty body")
    public void testFailedBodyDoesNotLookEmpty() {
        HttpCarbonResponse response = createResponse();
        LastHttpContent failedContent = new DefaultLastHttpContent();
        failedContent.setDecoderResult(DecoderResult.failure(new DecoderException("Failed to decode")));
        response.addHttpContent(failedContent);

        assertEquals(response.countMessageLengthTill(1), 1);
    }

    @Test(description = "A body that completed without any content is still counted as empty")
    public void testCompletedEmptyBodyStillLooksEmpty() {
        HttpCarbonResponse response = createResponse();
        response.addHttpContent(new DefaultLastHttpContent());

        assertEquals(response.countMessageLengthTill(1), 0);
    }

    private HttpCarbonResponse createResponse() {
        return new HttpCarbonResponse(new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK));
    }

    private static final class RecordingListener implements FullHttpMessageListener {

        private final AtomicReference<Exception> error = new AtomicReference<>();

        @Override
        public void onComplete(HttpCarbonMessage httpCarbonMessage) {
            fail("The message never completed");
        }

        @Override
        public void onError(Exception error) {
            this.error.set(error);
        }
    }
}
