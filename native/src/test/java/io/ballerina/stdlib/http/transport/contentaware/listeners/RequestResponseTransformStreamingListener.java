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

package io.ballerina.stdlib.http.transport.contentaware.listeners;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashMap;

/**
 * Streaming processor which reads from same and write to same message.
 */
public class RequestResponseTransformStreamingListener implements HttpConnectorListener {

    private static final Logger LOG = LoggerFactory.getLogger(RequestResponseTransformStreamingListener.class);

    @Override
    public void onMessage(HttpCarbonMessage httpRequestMessage) {
        Thread.startVirtualThread(() -> {
            try {
                InputStream inputStream = new HttpMessageDataStreamer(httpRequestMessage).getInputStream();
                OutputStream outputStream = new HttpMessageDataStreamer(httpRequestMessage).getOutputStream();
                byte[] bytes = IOUtils.toByteArray(inputStream);
                outputStream.write(bytes);
                outputStream.close();
                httpRequestMessage.setProperty(Constants.HTTP_HOST, TestUtil.TEST_HOST);
                httpRequestMessage.setProperty(Constants.HTTP_PORT, TestUtil.HTTP_SERVER_PORT);

                HttpWsConnectorFactory httpWsConnectorFactory = new DefaultHttpWsConnectorFactory();
                HttpClientConnector clientConnector =
                        httpWsConnectorFactory.createHttpClientConnector(new HashMap<>(), new SenderConfiguration());
                HttpResponseFuture future = clientConnector.send(httpRequestMessage);
                future.setHttpConnectorListener(new HttpConnectorListener() {
                    @Override
                    public void onMessage(HttpCarbonMessage httpResponse) {
                        Thread.startVirtualThread(() -> {
                            InputStream inputS = new HttpMessageDataStreamer(httpResponse).getInputStream();
                            OutputStream outputS = new HttpMessageDataStreamer(httpResponse).getOutputStream();
                            try {
                                byte[] bytes = IOUtils.toByteArray(inputS);
                                outputS.write(bytes);
                                outputS.close();
                            } catch (IOException e) {
                                throw new RuntimeException("Cannot read Input Stream from Response", e);
                            }
                            try {
                                httpRequestMessage.respond(httpResponse);
                            } catch (ServerConnectorException e) {
                                LOG.error("Error occurred during message notification: " + e.getMessage());
                            }
                        });
                    }

                    @Override
                    public void onError(Throwable throwable) {

                    }
                });
            } catch (Exception e) {
                LOG.error("Error while reading stream", e);
            }
        });
    }

    @Override
    public void onError(Throwable throwable) {

    }
}
