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

package io.ballerina.stdlib.http.transport.internal;

import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import org.testng.annotations.Test;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * A unit test class for Transport module HandlerExecutor class functions.
 */
public class HandlerExecutorTest {

    @Test
    public void testExecuteAtSourceConnectionInitiationWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtSourceConnectionInitiation(anyString());
        handlerExecutor.addHandler(messagingHandler);
        handlerExecutor.executeAtSourceConnectionInitiation("metadata");
    }

    @Test
    public void testExecuteAtSourceConnectionTerminationWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtSourceConnectionTermination(anyString());
        handlerExecutor.addHandler(messagingHandler);
        handlerExecutor.executeAtSourceConnectionTermination("metadata");
    }

    @Test
    public void testExecuteAtSourceRequestReceivingWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtSourceRequestReceiving(any());
        handlerExecutor.addHandler(messagingHandler);
        HttpCarbonMessage carbonMessage = mock(HttpCarbonMessage.class);
        handlerExecutor.executeAtSourceRequestReceiving(carbonMessage);
    }

    @Test
    public void testExecuteAtSourceRequestSendingWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtSourceRequestSending(any());
        handlerExecutor.addHandler(messagingHandler);
        HttpCarbonMessage carbonMessage = mock(HttpCarbonMessage.class);
        handlerExecutor.executeAtSourceRequestSending(carbonMessage);
    }

    @Test
    public void testExecuteAtTargetRequestReceivingWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtTargetRequestReceiving(any());
        handlerExecutor.addHandler(messagingHandler);
        HttpCarbonMessage carbonMessage = mock(HttpCarbonMessage.class);
        handlerExecutor.executeAtTargetRequestReceiving(carbonMessage);
    }

    @Test
    public void testExecuteAtTargetRequestSendingWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtTargetRequestSending(any());
        handlerExecutor.addHandler(messagingHandler);
        HttpCarbonMessage carbonMessage = mock(HttpCarbonMessage.class);
        handlerExecutor.executeAtTargetRequestSending(carbonMessage);
    }

    @Test
    public void testExecuteAtTargetResponseReceivingWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtTargetResponseReceiving(any());
        handlerExecutor.addHandler(messagingHandler);
        HttpCarbonMessage carbonMessage = mock(HttpCarbonMessage.class);
        handlerExecutor.executeAtTargetResponseReceiving(carbonMessage);
    }

    @Test
    public void testExecuteAtTargetResponseSending() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        handlerExecutor.addHandler(messagingHandler);
        HttpCarbonMessage carbonMessage = mock(HttpCarbonMessage.class);
        handlerExecutor.executeAtTargetResponseSending(carbonMessage);
    }

    @Test
    public void testExecuteAtTargetResponseSendingWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtTargetResponseSending(any());
        handlerExecutor.addHandler(messagingHandler);
        HttpCarbonMessage carbonMessage = mock(HttpCarbonMessage.class);
        handlerExecutor.executeAtTargetResponseSending(carbonMessage);
    }

    @Test
    public void testExecuteAtSourceResponseReceivingWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtSourceResponseReceiving(any());
        handlerExecutor.addHandler(messagingHandler);
        HttpCarbonMessage carbonMessage = mock(HttpCarbonMessage.class);
        handlerExecutor.executeAtSourceResponseReceiving(carbonMessage);
    }

    @Test
    public void testExecuteAtSourceResponseSendingWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtSourceResponseSending(any());
        handlerExecutor.addHandler(messagingHandler);
        HttpCarbonMessage carbonMessage = mock(HttpCarbonMessage.class);
        handlerExecutor.executeAtSourceResponseSending(carbonMessage);
    }

    @Test
    public void testExecuteAtTargetConnectionInitiationWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtTargetConnectionInitiation(anyString());
        handlerExecutor.addHandler(messagingHandler);
        handlerExecutor.executeAtTargetConnectionInitiation("metadata");
    }

    @Test
    public void testExecuteAtTargetConnectionTerminationWithRuntimeException() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        doThrow(new RuntimeException()).when(messagingHandler).invokeAtTargetConnectionTermination(anyString());
        handlerExecutor.addHandler(messagingHandler);
        handlerExecutor.executeAtTargetConnectionTermination("metadata");
    }

    @Test
    public void testAddAndRemoveHandler() {
        HandlerExecutor handlerExecutor = new HandlerExecutor();
        MessagingHandler messagingHandler = mock(MessagingHandler.class);
        when(messagingHandler.handlerName()).thenReturn("newHandler");
        handlerExecutor.addHandler(messagingHandler);
        handlerExecutor.removeHandler(messagingHandler);
    }

}
