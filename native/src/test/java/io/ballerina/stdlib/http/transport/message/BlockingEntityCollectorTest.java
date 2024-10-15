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
import io.netty.handler.codec.http.LastHttpContent;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.nio.ByteBuffer;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * A unit test class for Transport module BlockingEntityCollector class functions.
 */
public class BlockingEntityCollectorTest {

    @Test
    public void testAddHttpContentWithNullHttpContent() {
        BlockingEntityCollector blockingEntityCollector = new BlockingEntityCollector(5);
        blockingEntityCollector.addHttpContent(null);
    }

    @Test
    public void testAddMessageBody() {
        BlockingEntityCollector blockingEntityCollector = new BlockingEntityCollector(5);
        ByteBuffer msgBody = ByteBuffer.allocate(16);
        blockingEntityCollector.addMessageBody(msgBody);
    }

    @Test
    public void testGetMessageBodyWithNullObject() {
        BlockingEntityCollector blockingEntityCollector = new BlockingEntityCollector(5);
        ByteBuf returnVal = blockingEntityCollector.getMessageBody();
        Assert.assertNull(returnVal);
    }

    @Test
    public void testGetMessageBody() {
        BlockingEntityCollector blockingEntityCollector = new BlockingEntityCollector(5);
        ByteBuffer msgBody = ByteBuffer.allocate(16);
        blockingEntityCollector.addMessageBody(msgBody);
        ByteBuf returnVal = blockingEntityCollector.getMessageBody();
        Assert.assertNotNull(returnVal);
    }

    @Test
    public void testGetFullMessageLengthWithNullObject() {
        BlockingEntityCollector blockingEntityCollector = new BlockingEntityCollector(5);
        long returnVal = blockingEntityCollector.getFullMessageLength();
        Assert.assertEquals(returnVal, 0);
    }

    @Test
    public void testGetFullMessageLengthWithLastHttpContent() {
        BlockingEntityCollector blockingEntityCollector = new BlockingEntityCollector(5);
        LastHttpContent httpContent = mock(LastHttpContent.class);
        ByteBuf value = mock(ByteBuf.class);
        when(value.readableBytes()).thenReturn(5);
        when(httpContent.content()).thenReturn(value);
        blockingEntityCollector.addHttpContent(httpContent);
        long returnVal = blockingEntityCollector.getFullMessageLength();
        Assert.assertEquals(returnVal, 5);
    }

    @Test
    public void testGetFullMessageLength() {
        BlockingEntityCollector blockingEntityCollector = new BlockingEntityCollector(5);
        ByteBuffer msgBody = ByteBuffer.allocate(0);
        blockingEntityCollector.addMessageBody(msgBody);
        long returnVal = blockingEntityCollector.getFullMessageLength();
        Assert.assertEquals(returnVal, 0);
    }

    @Test
    public void testWaitAndReleaseAllEntitiesWithNullObject() {
        BlockingEntityCollector blockingEntityCollector = new BlockingEntityCollector(5);
        ByteBuffer msgBody = ByteBuffer.allocate(16);
        blockingEntityCollector.addMessageBody(msgBody);
        blockingEntityCollector.waitAndReleaseAllEntities();
    }

}
