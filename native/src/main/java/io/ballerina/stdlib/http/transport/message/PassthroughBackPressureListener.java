/*
 *  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.http.transport.message;

import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Implementation of the {@link BackPressureListener} for the passthrough scenario.
 */
public class PassthroughBackPressureListener implements BackPressureListener {
    private static final Logger LOG = LoggerFactory.getLogger(PassthroughBackPressureListener.class);

    private Channel inChannel;
    private final DefaultListener inboundListener;
    // Guarded by the observable that notifies this listener; read on the inbound event loop.
    private volatile boolean suspended;

    /**
     * Sets the incoming and outgoing message channels.
     *
     * @param inContext      This will be used to block and resume read interest of the incoming channel.
     * @param inboundListener the listener reading the incoming channel's content, told about the suspension so
     *                        the idle timeout on that channel does not mistake it for an unresponsive peer.
     */
    public PassthroughBackPressureListener(ChannelHandlerContext inContext, DefaultListener inboundListener) {
        inChannel = inContext.channel();
        this.inboundListener = inboundListener;
    }

    @Override
    public void onUnWritable() {
        if (LOG.isDebugEnabled()) {
            LOG.debug("Read disabled for inChannel {}", inChannel.id());
        }
        if (!suspended) {
            suspended = true;
            applyReadInterest();
        }
    }

    @Override
    public void onWritable() {
        if (LOG.isDebugEnabled()) {
            LOG.debug("Read enabled for inChannel {}", inChannel.id());
        }
        if (suspended) {
            suspended = false;
            applyReadInterest();
        }
    }

    // autoRead is only changed on the inbound event loop: setAutoRead(false) from another thread defers clearing the
    // read interest to a task, which can run after a resume and leave reads disarmed with autoRead still true. The
    // task applies the latest decision, so the order in which such tasks run does not matter.
    private void applyReadInterest() {
        if (inChannel.eventLoop().inEventLoop()) {
            applyReadInterestNow();
        } else {
            inChannel.eventLoop().execute(this::applyReadInterestNow);
        }
    }

    private void applyReadInterestNow() {
        boolean suspend = suspended;
        inChannel.config().setAutoRead(!suspend);
        if (suspend) {
            inboundListener.onDownstreamUnwritable();
        } else {
            inboundListener.onDownstreamWritable();
        }
    }
}
