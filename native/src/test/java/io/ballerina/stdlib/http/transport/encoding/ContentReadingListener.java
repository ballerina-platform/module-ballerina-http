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

package io.ballerina.stdlib.http.transport.encoding;

import com.google.common.io.ByteStreams;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.Charset;

/**
 * HTTP connector Listener for Content reading.
 */
public class ContentReadingListener implements HttpConnectorListener {

    private static final Logger LOG = LoggerFactory.getLogger(ContentReadingListener.class);

    @Override
    public void onMessage(HttpCarbonMessage httpMessage) {
        Thread.startVirtualThread(() -> {
            try {
                InputStream inputStream = new HttpMessageDataStreamer(httpMessage).getInputStream();
                String response = new String(ByteStreams.toByteArray(inputStream), Charset.defaultCharset());
                String alteredContent = "Altered " + response + " content";

                HttpCarbonMessage newMsg = httpMessage.cloneCarbonMessageWithOutData();
                newMsg.addHttpContent(new DefaultLastHttpContent(
                        Unpooled.wrappedBuffer(alteredContent.getBytes(Charset.defaultCharset()))));
                newMsg.completeMessage();

                httpMessage.respond(newMsg);
            } catch (IOException | ServerConnectorException e) {
                LOG.error("Error occurred during message processing ", e);
            }

        });
    }

    @Override
    public void onError(Throwable throwable) {

    }
}
