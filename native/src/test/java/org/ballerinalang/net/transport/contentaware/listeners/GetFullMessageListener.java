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
 */

package org.ballerinalang.net.transport.contentaware.listeners;

import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.handler.codec.http.LastHttpContent;
import org.ballerinalang.net.transport.contract.Constants;
import org.ballerinalang.net.transport.contract.HttpConnectorListener;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.message.FullHttpMessageListener;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.transport.message.HttpCarbonResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * This class implements GetFullMessageListener. GetFullMessageListener is responsible for echoing back the
 * request payload using getFullHttpCarbonMessage API.
 */
public class GetFullMessageListener implements HttpConnectorListener {
    private static final Logger LOG = LoggerFactory.getLogger(GetFullMessageListener.class);

    private ExecutorService executor = Executors.newSingleThreadExecutor();

    @Override
    public void onMessage(HttpCarbonMessage httpRequest) {
        executor.execute(() -> httpRequest.getFullHttpCarbonMessage().addListener(new FullHttpMessageListener() {
            @Override
            public void onComplete(HttpCarbonMessage httpCarbonMessage) {
                HttpCarbonMessage httpResponse =
                        new HttpCarbonResponse(new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK));
                httpResponse.setHeader(HttpHeaderNames.CONNECTION.toString(), HttpHeaderValues.KEEP_ALIVE.toString());
                httpResponse.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), Constants.TEXT_PLAIN);
                httpResponse.setHttpStatusCode(HttpResponseStatus.OK.code());

                do {
                    HttpContent httpContent = httpRequest.getHttpContent();
                    httpResponse.addHttpContent(httpContent);
                    if (httpContent instanceof LastHttpContent) {
                        break;
                    }
                } while (true);

                try {
                    httpRequest.respond(httpResponse);
                } catch (ServerConnectorException e) {
                    LOG.error("Error occurred during message notification: " + e.getMessage());
                }
            }

            @Override
            public void onError(Exception error) {

            }
        }));
    }

    @Override
    public void onError(Throwable throwable) {

    }
}
