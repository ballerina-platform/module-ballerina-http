/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 *
 */

package io.ballerina.stdlib.http.transport.contractimpl.sender.http2;

import io.ballerina.stdlib.http.transport.message.DefaultBackPressureListener;
import io.ballerina.stdlib.http.transport.message.DefaultListener;
import io.ballerina.stdlib.http.transport.message.Http2InboundContentListener;
import io.ballerina.stdlib.http.transport.message.Http2PassthroughBackPressureListener;
import io.ballerina.stdlib.http.transport.message.Http2Reset;
import io.ballerina.stdlib.http.transport.message.Listener;
import io.ballerina.stdlib.http.transport.message.PassthroughBackPressureListener;
import io.netty.buffer.ByteBufAllocator;
import io.netty.buffer.EmptyByteBuf;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http2.Http2Error;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Starts writing HTTP/2 request content.
 */
public class RequestWriteStarter {
    private static final Logger LOG = LoggerFactory.getLogger(RequestWriteStarter.class);

    private final OutboundMsgHolder outboundMsgHolder;
    private final Http2ClientChannel http2ClientChannel;

    public RequestWriteStarter(OutboundMsgHolder outboundMsgHolder, Http2ClientChannel http2ClientChannel) {
        this.outboundMsgHolder = outboundMsgHolder;
        this.http2ClientChannel = http2ClientChannel;
    }

    public void startWritingContent() {
        setBackPressureListener();
        outboundMsgHolder.setFirstContentWritten(false);
        outboundMsgHolder.getRequest().getHttpContentAsync().setMessageListener(httpContent -> {
            checkStreamUnwritability();
            http2ClientChannel.getChannel().eventLoop().execute(() -> {
                if (httpContent instanceof Http2ResetContent) {
                    if (http2ClientChannel.getConnection().numActiveStreams() == 0) {
                        Http2ResetContent resetContent = (Http2ResetContent) httpContent;
                        Http2Content emptyHttp2Content = new Http2Content(new DefaultLastHttpContent(
                                resetContent.content()), outboundMsgHolder);
                        http2ClientChannel.getChannel().write(emptyHttp2Content);
                    }
                    int streamId = http2ClientChannel.getConnection().local().lastStreamCreated();
                    Http2Reset http2Reset = new Http2Reset(streamId, Http2Error.CANCEL);
                    http2Reset.setEndOfStream(true);
                    http2ClientChannel.getChannel().write(http2Reset);
                } else {
                    Http2Content http2Content = new Http2Content(httpContent, outboundMsgHolder);
                    http2ClientChannel.getChannel().write(http2Content);
                }
            });
        });
    }

    private void setBackPressureListener() {
        if (outboundMsgHolder.getRequest().isPassthrough()) {
            setPassthroughBackOffListener();
        } else {
            outboundMsgHolder.getBackPressureObservable().setListener(new DefaultBackPressureListener());
        }
    }

    /**
     * Backoff scenarios involved here are (request HTTP/2-HTTP/2) and (request HTTP/1.1-HTTP/2).
     */
    private void setPassthroughBackOffListener() {
        Listener inboundListener = outboundMsgHolder.getRequest().getListener();
        if (inboundListener instanceof Http2InboundContentListener) {
            outboundMsgHolder.getBackPressureObservable().setListener(
                new Http2PassthroughBackPressureListener((Http2InboundContentListener) inboundListener));
        } else if (inboundListener instanceof DefaultListener) {
            outboundMsgHolder.getBackPressureObservable().setListener(
                new PassthroughBackPressureListener(outboundMsgHolder.getRequest().getSourceContext()));
        }
    }

    private void checkStreamUnwritability() {
        if (!outboundMsgHolder.isStreamWritable()) {
            if (LOG.isDebugEnabled()) {
                LOG.debug("In thread {}. Stream is not writable.", Thread.currentThread().getName());
            }
            outboundMsgHolder.getBackPressureObservable().notifyUnWritable();
        }
    }
}
