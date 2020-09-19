/*
 * Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.ballerinalang.net.http.actions.websocketconnector;

import io.netty.channel.ChannelFuture;
import org.ballerinalang.jvm.api.BalEnv;
import org.ballerinalang.jvm.api.BalFuture;
import org.ballerinalang.jvm.api.values.BObject;
import org.ballerinalang.jvm.api.values.BString;
import org.ballerinalang.jvm.scheduling.Scheduler;
import org.ballerinalang.jvm.scheduling.Strand;
import org.ballerinalang.net.http.websocket.WebSocketConstants;
import org.ballerinalang.net.http.websocket.WebSocketException;
import org.ballerinalang.net.http.websocket.WebSocketUtil;
import org.ballerinalang.net.http.websocket.observability.WebSocketObservabilityConstants;
import org.ballerinalang.net.http.websocket.observability.WebSocketObservabilityUtil;
import org.ballerinalang.net.http.websocket.server.WebSocketConnectionInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.wso2.transport.http.netty.contract.websocket.WebSocketConnection;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.ballerinalang.net.http.websocket.WebSocketConstants.ErrorCode;

/**
 * {@code Get} is the GET action implementation of the HTTP Connector.
 */
public class Close {
    private static final Logger log = LoggerFactory.getLogger(Close.class);

    public static Object externClose(BalEnv env, BObject wsConnection, long statusCode, BString reason, long timeoutInSecs) {
        Strand strand = Scheduler.getStrand();
        BalFuture balFuture = env.markAsync();
        WebSocketConnectionInfo connectionInfo = (WebSocketConnectionInfo) wsConnection
                .getNativeData(WebSocketConstants.NATIVE_DATA_WEBSOCKET_CONNECTION_INFO);
        WebSocketObservabilityUtil.observeResourceInvocation(strand, connectionInfo,
                                                             WebSocketConstants.RESOURCE_NAME_CLOSE);
        try {
            CountDownLatch countDownLatch = new CountDownLatch(1);
            List<WebSocketException> errors = new ArrayList<>(1);
            ChannelFuture closeFuture = initiateConnectionClosure(errors, (int) statusCode, reason.getValue(),
                                                                  connectionInfo, countDownLatch);
            waitForTimeout(errors, (int) timeoutInSecs, countDownLatch, connectionInfo);
            closeFuture.channel().close().addListener(future -> {
                WebSocketUtil.setListenerOpenField(connectionInfo);
                if (errors.isEmpty()) {
                    balFuture.complete(null);
                } else {
                    balFuture.complete(errors.get(errors.size() - 1));
                }
            });
            WebSocketObservabilityUtil.observeSend(WebSocketObservabilityConstants.MESSAGE_TYPE_CLOSE,
                                                   connectionInfo);
        } catch (Exception e) {
            log.error("Error occurred when closing the connection", e);
            WebSocketObservabilityUtil.observeError(WebSocketObservabilityUtil.getConnectionInfo(wsConnection),
                                                    WebSocketObservabilityConstants.ERROR_TYPE_MESSAGE_SENT,
                                                    WebSocketObservabilityConstants.MESSAGE_TYPE_CLOSE,
                                                    e.getMessage());
            balFuture.complete(WebSocketUtil.createErrorByType(e));
        }
        return null;
    }

    private static ChannelFuture initiateConnectionClosure(List<WebSocketException> errors, int statusCode, String reason,
                                                           WebSocketConnectionInfo connectionInfo,
                                                           CountDownLatch latch) throws IllegalAccessException {
        WebSocketConnection webSocketConnection = connectionInfo.getWebSocketConnection();
        ChannelFuture closeFuture;
        if (statusCode < 0) {
            closeFuture = webSocketConnection.initiateConnectionClosure();
        } else {
            closeFuture = webSocketConnection.initiateConnectionClosure(statusCode, reason);
        }
        return closeFuture.addListener(future -> {
            Throwable cause = future.cause();
            if (!future.isSuccess() && cause != null) {
                addError(cause.getMessage(), errors);
                WebSocketObservabilityUtil.observeError(connectionInfo,
                                                        WebSocketObservabilityConstants.ERROR_TYPE_CLOSE,
                                                        cause.getMessage());
            }
            latch.countDown();
        });
    }

    private static void waitForTimeout(List<WebSocketException> errors, int timeoutInSecs,
                                       CountDownLatch latch, WebSocketConnectionInfo connectionInfo) {
        try {
            if (timeoutInSecs < 0) {
                latch.await();
            } else {
                boolean countDownReached = latch.await(timeoutInSecs, TimeUnit.SECONDS);
                if (!countDownReached) {
                    String errMsg = String.format(
                            "Could not receive a WebSocket close frame from remote endpoint within %d seconds",
                            timeoutInSecs);
                    addError(errMsg, errors);
                    WebSocketObservabilityUtil.observeError(connectionInfo,
                                                            WebSocketObservabilityConstants.ERROR_TYPE_CLOSE, errMsg);
                }
            }
        } catch (InterruptedException err) {
            String errMsg = "Connection interrupted while closing the connection";
            addError(errMsg, errors);
            WebSocketObservabilityUtil.observeError(connectionInfo,
                                                    WebSocketObservabilityConstants.ERROR_TYPE_CLOSE, errMsg);
            Thread.currentThread().interrupt();
        }
    }

    private static void addError(String errMsg, List<WebSocketException> errors) {
        errors.add(WebSocketUtil.getWebSocketException(errMsg, null,
                ErrorCode.WsConnectionClosureError.errorCode(), null));
    }

    private Close() {
    }
}
