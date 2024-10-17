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

import io.netty.buffer.ByteBuf;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpMessage;
import io.netty.handler.codec.http.HttpRequest;
import io.netty.handler.codec.http.HttpResponse;
import org.junit.Assert;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.ByteBuffer;

import static org.mockito.Mockito.mock;

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
    public void testNotifyContentFailure() {
        HttpMessage httpResponse = mock(HttpResponse.class);
        Listener contentListener = mock(Listener.class);
        HttpCarbonMessage httpCarbonMessage = new HttpCarbonMessage(httpResponse, 100, contentListener);
        httpCarbonMessage.getFullHttpCarbonMessage();
        httpCarbonMessage.notifyContentFailure(new Exception());
    }

}
