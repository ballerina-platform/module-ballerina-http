/*
 * Copyright (c) 2026, WSO2 LLC. (https://www.wso2.com).
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

package io.ballerina.stdlib.http.transport.contractimpl.sender;

import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.embedded.EmbeddedChannel;
import io.netty.handler.ssl.SslHandshakeCompletionEvent;
import org.mockito.Mockito;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.ArrayList;
import java.util.List;

import javax.net.ssl.SSLEngine;
import javax.net.ssl.SSLPeerUnverifiedException;
import javax.net.ssl.SSLSession;

/**
 * Tests that {@link CertificateValidationHandler} does not drop a client that sent no certificate.
 */
public class CertificateValidationHandlerTest {

    @Test
    public void testClientWithoutCertificateIsNotDropped() throws Exception {
        SSLEngine engine = Mockito.mock(SSLEngine.class);
        SSLSession session = Mockito.mock(SSLSession.class);
        Mockito.when(engine.getSession()).thenReturn(session);
        Mockito.when(session.getPeerCertificates()).thenThrow(new SSLPeerUnverifiedException("peer not verified"));

        List<Object> events = new ArrayList<>();
        EmbeddedChannel channel = new EmbeddedChannel(new CertificateValidationHandler(engine, 10, 10),
                new ChannelInboundHandlerAdapter() {
                    @Override
                    public void userEventTriggered(io.netty.channel.ChannelHandlerContext ctx, Object evt) {
                        events.add(evt);
                    }
                });
        channel.pipeline().fireUserEventTriggered(SslHandshakeCompletionEvent.SUCCESS);

        Assert.assertTrue(channel.isActive(), "The channel must stay open for a client without a certificate");
        Assert.assertEquals(events.size(), 1);
        Assert.assertSame(events.get(0), SslHandshakeCompletionEvent.SUCCESS);
        channel.finishAndReleaseAll();
    }
}
