/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.nativeimpl.connection;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.DataContext;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.message.PooledDataStreamerFactory;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;
import io.ballerina.stdlib.mime.util.HeaderUtil;
import io.ballerina.stdlib.mime.util.MultipartDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.OutputStream;

import static io.ballerina.stdlib.http.api.HttpUtil.extractEntity;
import static io.ballerina.stdlib.mime.util.MimeConstants.SERIALIZATION_ERROR;

/**
 * Response writer contains utility methods to serialize response data.
 *
 * @since 0.982.0
 */
public class ResponseWriter {

    private static final Logger log = LoggerFactory.getLogger(ResponseWriter.class);

    /**
     * Send outbound response to destination.
     *
     * @param dataContext      Represents data context which acts as the callback for response status
     * @param requestMessage   Represents the request that corresponds to the response
     * @param outboundResponse Represents ballerina response
     * @param responseMessage  Represents native response message
     */
    public static void sendResponseRobust(DataContext dataContext, HttpCarbonMessage requestMessage,
                                          BObject outboundResponse, HttpCarbonMessage responseMessage) {
        String contentType = HttpUtil.getContentTypeFromTransportMessage(responseMessage);
        String boundaryString = null;
        if (HeaderUtil.isMultipart(contentType)) {
            boundaryString = HttpUtil.addBoundaryIfNotExist(responseMessage, contentType);
        }
        HttpMessageDataStreamer outboundMsgDataStreamer = getResponseDataStreamer(responseMessage);
        BObject entityObj = extractEntity(outboundResponse);
        if (entityObj == null) {
            responseMessage.setPassthrough(true);
        }
        HttpResponseFuture outboundRespStatusFuture = HttpUtil.sendOutboundResponse(requestMessage, responseMessage);
        HttpConnectorListener outboundResStatusConnectorListener =
                new ResponseWriter.HttpResponseConnectorListener(dataContext, outboundMsgDataStreamer);
        outboundRespStatusFuture.setHttpConnectorListener(outboundResStatusConnectorListener);
        OutputStream messageOutputStream = outboundMsgDataStreamer.getOutputStream();
        if (entityObj != null) {
            if (boundaryString != null) {
                serializeMultiparts(dataContext.getEnvironment(), boundaryString, entityObj, messageOutputStream);
            } else {
                Object outboundMessageSource = EntityBodyHandler.getMessageDataSource(entityObj);
                serializeDataSource(dataContext.getEnvironment(), outboundMessageSource, entityObj,
                                    messageOutputStream);
            }
        }
    }

    /**
     * Serialize multipart entity body. If an array of body parts exist, encode body parts else serialize body content
     * if it exist as a byte channel/stream.
     *
     * @param env                 Represents the runtime environment
     * @param boundaryString      Boundary string that should be used in encoding body parts
     * @param entity              Represents the entity that holds the actual body
     * @param messageOutputStream Represents the output stream
     */
    private static void serializeMultiparts(Environment env, String boundaryString, BObject entity,
                                             OutputStream messageOutputStream) {
        BArray bodyParts = EntityBodyHandler.getBodyPartArray(entity);
        if (bodyParts != null && bodyParts.size() > 0) {
            MultipartDataSource multipartDataSource = new MultipartDataSource(env, entity, boundaryString);
            multipartDataSource.serialize(messageOutputStream);
            HttpUtil.closeMessageOutputStream(messageOutputStream);
        } else {
            serializeDataSource(env, EntityBodyHandler.getMessageDataSource(entity), entity,
                                messageOutputStream);
        }
    }

    /**
     * Serialize message datasource.
     *
     * @param env                   Represents the runtime environment
     * @param outboundMessageSource Outbound message datasource that needs to be serialized
     * @param entity                Represents the entity that holds headers and body content
     * @param messageOutputStream   Represents the output stream
     */
    static void serializeDataSource(Environment env, Object outboundMessageSource, BObject entity,
                                    OutputStream messageOutputStream) {
        try {
            if (outboundMessageSource != null) {
                HttpUtil.serializeDataSource(outboundMessageSource, entity, messageOutputStream);
                HttpUtil.closeMessageOutputStream(messageOutputStream);
            } else if (EntityBodyHandler.getEventStream(entity) != null) {
                //When the entity body is a byte stream of server sent events and it is not null
                EntityBodyHandler.writeEventStreamToOutputStream(env, entity, messageOutputStream);
            } else if (EntityBodyHandler.getByteStream(entity) != null) {
                //When the entity body is a byte stream and when it is not null
                EntityBodyHandler.writeByteStreamToOutputStream(env, entity, messageOutputStream);
                HttpUtil.closeMessageOutputStream(messageOutputStream);
            } else if (EntityBodyHandler.getByteChannel(entity) != null) {
                //When the entity body is a byte channel and when it is not null
                EntityBodyHandler.writeByteChannelToOutputStream(entity, messageOutputStream);
                HttpUtil.closeMessageOutputStream(messageOutputStream);
            }  else {
                log.debug("Entity does not have a serializable payload");
            }
        } catch (IOException ex) {
            throw ErrorCreator.createError(StringUtils.fromString(SERIALIZATION_ERROR), StringUtils.fromString(
                    "error occurred while serializing message data source : " + ex.getMessage()));
        }
    }

    /**
     * Get the response data streamer that should be used for serializing data.
     *
     * @param outboundResponse Represents native response
     * @return HttpMessageDataStreamer that should be used for serializing
     */
    static HttpMessageDataStreamer getResponseDataStreamer(HttpCarbonMessage outboundResponse) {
        final HttpMessageDataStreamer outboundMsgDataStreamer;
        final PooledDataStreamerFactory pooledDataStreamerFactory = (PooledDataStreamerFactory)
                outboundResponse.getProperty(HttpConstants.POOLED_BYTE_BUFFER_FACTORY);
        if (pooledDataStreamerFactory != null) {
            outboundMsgDataStreamer = pooledDataStreamerFactory.createHttpDataStreamer(outboundResponse);
        } else {
            outboundMsgDataStreamer = new HttpMessageDataStreamer(outboundResponse);
        }
        return outboundMsgDataStreamer;
    }

    /**
     * Response listener class receives notifications once a message has been sent out.
     */
    static class HttpResponseConnectorListener implements HttpConnectorListener {

        private final DataContext dataContext;
        private HttpMessageDataStreamer outboundMsgDataStreamer;

        HttpResponseConnectorListener(DataContext dataContext) {
            this.dataContext = dataContext;
        }

        HttpResponseConnectorListener(DataContext dataContext, HttpMessageDataStreamer outboundMsgDataStreamer) {
            this.dataContext = dataContext;
            this.outboundMsgDataStreamer = outboundMsgDataStreamer;
        }

        @Override
        public void onMessage(HttpCarbonMessage httpCarbonMessage) {
            this.dataContext.notifyOutboundResponseStatus(null);
        }

        @Override
        public void onError(Throwable throwable) {
            BError httpConnectorError = HttpUtil.createHttpError(throwable.getMessage(),
                                                                 HttpErrorType.GENERIC_LISTENER_ERROR);
            if (outboundMsgDataStreamer != null) {
                // Relevant transport state should set the IO Exception. Following code snippet is for other exceptions
                if (!(throwable instanceof IOException)) {
                    this.dataContext.getOutboundRequest()
                            .setIoException(new IOException(throwable.getMessage(), throwable));
                }
            }
            this.dataContext.notifyOutboundResponseStatus(httpConnectorError);
        }
    }

    private ResponseWriter() {}
}
