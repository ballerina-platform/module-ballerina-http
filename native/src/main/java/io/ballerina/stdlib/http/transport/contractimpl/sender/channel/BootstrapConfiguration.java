/*
 * Copyright (c) 2015, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and limitations under the License.
 */

package io.ballerina.stdlib.http.transport.contractimpl.sender.channel;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * A class represents client bootstrap configurations.
 */
public class BootstrapConfiguration {

    private static final Logger LOG = LoggerFactory.getLogger(BootstrapConfiguration.class);

    private final boolean tcpNoDelay;
    private final boolean keepAlive;
    private final boolean socketReuse;
    private final int connectTimeOut;
    private final int receiveBufferSize;
    private final int sendBufferSize;
    private final int socketTimeout;

    public BootstrapConfiguration(SenderConfiguration senderConfiguration) {
        this.connectTimeOut = senderConfiguration.getConnectTimeOut();
        this.receiveBufferSize = senderConfiguration.getReceiveBufferSize();
        this.sendBufferSize = senderConfiguration.getSendBufferSize();
        this.tcpNoDelay = senderConfiguration.isTcpNoDelay();
        this.socketReuse = senderConfiguration.isSocketReuse();
        this.keepAlive = senderConfiguration.isSocketKeepAlive();
        this.socketTimeout = senderConfiguration.getSocketTimeout();

        String logValue = "{}:{}";
        LOG.debug(logValue, Constants.CLIENT_BOOTSTRAP_TCP_NO_DELY , tcpNoDelay);
        LOG.debug(logValue, Constants.CLIENT_BOOTSTRAP_CONNECT_TIME_OUT, connectTimeOut);
        LOG.debug(logValue, Constants.CLIENT_BOOTSTRAP_RECEIVE_BUFFER_SIZE, receiveBufferSize);
        LOG.debug(logValue, Constants.CLIENT_BOOTSTRAP_SEND_BUFFER_SIZE, sendBufferSize);
        LOG.debug(logValue, Constants.CLIENT_BOOTSTRAP_SO_TIMEOUT, socketTimeout);
        LOG.debug(logValue, Constants.CLIENT_BOOTSTRAP_KEEPALIVE, keepAlive);
        LOG.debug(logValue, Constants.CLIENT_BOOTSTRAP_SO_REUSE, socketReuse);
    }

    public boolean isTcpNoDelay() {
        return tcpNoDelay;
    }

    public int getConnectTimeOut() {
        return connectTimeOut;
    }

    public int getReceiveBufferSize() {
        return receiveBufferSize;
    }

    public int getSendBufferSize() {
        return sendBufferSize;
    }

    public boolean isKeepAlive() {
        return keepAlive;
    }

    public boolean isSocketReuse() {
        return socketReuse;
    }

    public int getSocketTimeout() {
        return socketTimeout;
    }
}
