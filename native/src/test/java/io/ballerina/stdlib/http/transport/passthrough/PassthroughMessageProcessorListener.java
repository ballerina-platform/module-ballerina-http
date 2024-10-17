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

package io.ballerina.stdlib.http.transport.passthrough;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ClientConnectorException;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonResponse;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;

/**
 * A Message Processor class to be used for test pass through scenarios.
 */
public class PassthroughMessageProcessorListener implements HttpConnectorListener {

    private static final Logger LOG = LoggerFactory.getLogger(PassthroughMessageProcessorListener.class);
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
        Thread.startVirtualThread(() -> {
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
                        Thread.startVirtualThread(() -> {
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
