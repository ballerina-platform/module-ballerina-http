/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.transport.passthrough;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import org.ballerinalang.net.transport.contract.Constants;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.contract.HttpConnectorListener;
import org.ballerinalang.net.transport.contract.HttpResponseFuture;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.exceptions.ClientConnectorException;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contractimpl.DefaultHttpWsConnectorFactory;
import org.ballerinalang.net.transport.contractimpl.sender.channel.pool.ConnectionManager;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.transport.message.HttpCarbonResponse;
import org.ballerinalang.net.transport.util.TestUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * A Message Processor class to be used for test pass through scenarios.
 */
public class PassthroughMessageProcessorListener implements HttpConnectorListener {

    private static final Logger LOG = LoggerFactory.getLogger(PassthroughMessageProcessorListener.class);
    private ExecutorService executor = Executors.newSingleThreadExecutor();
    private HttpClientConnector clientConnector;
    private HttpWsConnectorFactory httpWsConnectorFactory;
    private SenderConfiguration senderConfiguration;
    private ConnectionManager connectionManager;
    private boolean shareConnectionPool;

    public PassthroughMessageProcessorListener(SenderConfiguration senderConfiguration) {
        this.httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();
        this.senderConfiguration = senderConfiguration;
    }

    public PassthroughMessageProcessorListener(SenderConfiguration senderConfiguration, boolean shareConnectionPool) {
        this.httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();
        this.senderConfiguration = senderConfiguration;
        this.shareConnectionPool = shareConnectionPool;
        if (shareConnectionPool) {
            connectionManager = new ConnectionManager(senderConfiguration.getPoolConfiguration());
        }
    }

    @Override
    public void onMessage(HttpCarbonMessage httpRequestMessage) {
        executor.execute(() -> {
            httpRequestMessage.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
            httpRequestMessage.setProperty(Constants.HTTP_PORT, TestUtil.HTTP_SERVER_PORT);
            httpRequestMessage
                    .setProperty(Constants.SRC_HANDLER, httpRequestMessage.getProperty(Constants.SRC_HANDLER));
            try {
                if (shareConnectionPool && connectionManager != null) {
                    clientConnector = httpWsConnectorFactory
                        .createHttpClientConnector(new HashMap<>(), senderConfiguration, connectionManager);
                } else {
                    clientConnector = httpWsConnectorFactory
                        .createHttpClientConnector(new HashMap<>(), senderConfiguration);
                }
                HttpResponseFuture future = clientConnector.send(httpRequestMessage);
                future.setHttpConnectorListener(new HttpConnectorListener() {
                    @Override
                    public void onMessage(HttpCarbonMessage httpResponse) {
                        executor.execute(() -> {
                            try {
                                httpRequestMessage.respond(httpResponse);
                            } catch (ServerConnectorException e) {
                                LOG.error("Error occurred during message notification: " + e.getMessage());
                            }
                        });
                    }

                    @Override
                    public void onError(Throwable throwable) {
                        if (throwable instanceof ClientConnectorException) {
                            ClientConnectorException connectorException = (ClientConnectorException) throwable;
                            if (connectorException.getOutboundChannelID() != null) {
                                // Send TimeoutResponse
                                sendErrorResponse(connectorException.getOutboundChannelID(),
                                                  HttpResponseStatus.GATEWAY_TIMEOUT);
                            }
                        } else {
                            sendErrorResponse(throwable.getMessage(), HttpResponseStatus.INTERNAL_SERVER_ERROR);
                        }
                    }

                    private void sendErrorResponse(String payload, HttpResponseStatus status) {
                        HttpCarbonResponse outboundResponse = new HttpCarbonResponse(
                                new DefaultHttpResponse(HttpVersion.HTTP_1_1, status));
                        outboundResponse.addHttpContent(new DefaultLastHttpContent(Unpooled.wrappedBuffer(
                                payload.getBytes())));
                        try {
                            httpRequestMessage.respond(outboundResponse);
                        } catch (ServerConnectorException e) {
                            LOG.error("Error occurred while sending error-message", e);
                        }
                    }
                });
            } catch (Exception e) {
                LOG.error("Error occurred during message processing: ", e);
            }
        });
    }

    @Override
    public void onError(Throwable throwable) {

    }
}
