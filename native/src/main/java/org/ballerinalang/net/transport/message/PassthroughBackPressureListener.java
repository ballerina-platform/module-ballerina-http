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

package org.ballerinalang.net.transport.message;

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

    /**
     * Sets the incoming and outgoing message channels.
     *
     * @param inContext  This will be used to block and resume read interest of the incoming channel.
     */
    public PassthroughBackPressureListener(ChannelHandlerContext inContext) {
        inChannel = inContext.channel();
    }

    @Override
    public void onUnWritable() {
        if (LOG.isDebugEnabled()) {
            LOG.debug("Read disabled for inChannel {}", inChannel.id());
        }
        inChannel.config().setAutoRead(false);
    }

    @Override
    public void onWritable() {
        if (LOG.isDebugEnabled()) {
            LOG.debug("Read enabled for inChannel {}", inChannel.id());
        }
        inChannel.config().setAutoRead(true);
    }
}
