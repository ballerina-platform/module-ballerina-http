/*
 *  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.http2.listeners;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

/**
 * {@code Http2ServerConnectorListener} is a HttpConnectorListener which receives messages and respond back with
 * different types of HTTP/2 messages depending on the request.
 */
public class Http2ServerConnectorListener implements HttpConnectorListener {

    private static final Logger LOG = LoggerFactory.getLogger(Http2ServerConnectorListener.class);

    private String expectedResource;
    private String[] promisedResources;

    public void setPromisedResources(String... promisedResources) {
        this.promisedResources = promisedResources;
    }

    public Http2ServerConnectorListener setExpectedResource(String requestedResource) {
        this.expectedResource = requestedResource;
        return this;
    }

    @Override
    public void onMessage(HttpCarbonMessage httpRequest) {
        Thread.startVirtualThread(() -> {
            try {
                // Send Push Promise messages
                List<Http2PushPromise> promises = new ArrayList<>();
                if (promisedResources != null) {
                    for (String promisedResource : promisedResources) {
                        Http2PushPromise promise = new Http2PushPromise(Constants.HTTP_GET_METHOD, promisedResource);
                        HttpResponseFuture responseFuture = httpRequest.pushPromise(promise);
                        responseFuture.sync();
                        Throwable error = responseFuture.getStatus().getCause();
                        if (error != null) {
                            responseFuture.resetStatus();
                            LOG.error("Error occurred while sending push promises " + error.getMessage());
                        } else {
                            promises.add(promise);
                        }
                    }
                }

                // Send the intended response message
                HttpResponseFuture responseFuture =
                        httpRequest.respond(MessageGenerator.generateResponse(expectedResource));
                responseFuture.sync();
                Throwable error = responseFuture.getStatus().getCause();
                if (error != null) {
                    responseFuture.resetStatus();
                    LOG.error("Error occurred while sending the response " + error.getMessage());
                }

                // Send Promised response message
                for (Http2PushPromise promise : promises) {
                    responseFuture = httpRequest.pushResponse(
                            MessageGenerator.generateResponse("Resource for " + promise.getPath()), promise);
                    responseFuture.sync();
                    error = responseFuture.getStatus().getCause();
                    if (error != null) {
                        responseFuture.resetStatus();
                        LOG.error("Error occurred while sending promised response " + error.getMessage());
                    }
                }
            } catch (Exception e) {
                LOG.error("Error occurred while processing message: " + e.getMessage());
            }
        });
    }

    @Override
    public void onError(Throwable throwable) {
    }
}
