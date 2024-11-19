/*
 *  Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.FullHttpMessageListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.mime.nativeimpl.MimeDataSourceBuilder;
import io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody;
import io.ballerina.stdlib.mime.util.EntityBodyChannel;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;
import io.ballerina.stdlib.mime.util.EntityWrapper;
import io.ballerina.stdlib.mime.util.MimeUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.util.Locale;
import java.util.Objects;
import java.util.concurrent.CompletableFuture;

import static io.ballerina.stdlib.http.api.nativeimpl.ExternUtils.getResult;
import static io.ballerina.stdlib.mime.util.EntityBodyHandler.constructBlobDataSource;
import static io.ballerina.stdlib.mime.util.EntityBodyHandler.constructJsonDataSource;
import static io.ballerina.stdlib.mime.util.EntityBodyHandler.constructStringDataSource;
import static io.ballerina.stdlib.mime.util.EntityBodyHandler.constructXmlDataSource;
import static io.ballerina.stdlib.mime.util.EntityBodyHandler.isStreamingRequired;
import static io.ballerina.stdlib.mime.util.MimeConstants.ENTITY_BYTE_CHANNEL;
import static io.ballerina.stdlib.mime.util.MimeConstants.MESSAGE_DATA_SOURCE;
import static io.ballerina.stdlib.mime.util.MimeConstants.NO_CONTENT_ERROR;
import static io.ballerina.stdlib.mime.util.MimeConstants.PARSER_ERROR;
import static io.ballerina.stdlib.mime.util.MimeConstants.TRANSPORT_MESSAGE;

/**
 * A wrapper class to handle http protocol related functionality before the data source build.
 *
 * @since slp3
 */
public class ExternHttpDataSourceBuilder extends MimeDataSourceBuilder {

    private static final Logger log = LoggerFactory.getLogger(ExternHttpDataSourceBuilder.class);

    public static Object getNonBlockingByteArray(Environment env, BObject entityObj) {
        Object transportMessage = entityObj.getNativeData(TRANSPORT_MESSAGE);
        if (isStreamingRequired(entityObj) || transportMessage == null) {
            return getByteArray(entityObj);
        }
        try {
            Object messageDataSource = EntityBodyHandler.getMessageDataSource(entityObj);
            if (messageDataSource != null) {
                return getAlreadyBuiltByteArray(entityObj, messageDataSource);
            }
        } catch (Exception exception) {
            return createError(exception, "blob");
        }
        // access payload in non-blocking manner
        return env.yieldAndRun(() -> {
            try {
                CompletableFuture<Object> balFuture = new CompletableFuture<>();
                constructNonBlockingDataSource(balFuture, entityObj, SourceType.BLOB);
                return getResult(balFuture);
            } catch (Exception exception) {
                return createError(exception, "blob");
            }
        });
    }

    public static Object getNonBlockingJson(Environment env, BObject entityObj) {
        if (isStreamingRequired(entityObj)) {
            return getJson(entityObj);
        }
        try {
            Object dataSource = EntityBodyHandler.getMessageDataSource(entityObj);
            if (dataSource != null) {
                return getAlreadyBuiltJson(dataSource);
            }
        } catch (Exception exception) {
            return createError(exception, "json");
        }
        // access payload in non-blocking manner
        return env.yieldAndRun(() -> {
            try {
                CompletableFuture<Object> balFuture = new CompletableFuture<>();
                constructNonBlockingDataSource(balFuture, entityObj, SourceType.JSON);
                return getResult(balFuture);
            } catch (Exception exception) {
                return createError(exception, "json");
            }
        });
    }

    public static Object getNonBlockingText(Environment env, BObject entityObj) {
        if (isStreamingRequired(entityObj)) {
            return getText(entityObj);
        }
        try {
            Object dataSource = EntityBodyHandler.getMessageDataSource(entityObj);
            if (dataSource != null) {
                return io.ballerina.runtime.api.utils.StringUtils.fromString(MimeUtil.getMessageAsString(dataSource));
            }
        } catch (Exception exception) {
            return createError(exception, "text");
        }
        // access payload in non-blocking manner
        return env.yieldAndRun(() -> {
            try {
                CompletableFuture<Object> balFuture = new CompletableFuture<>();
                constructNonBlockingDataSource(balFuture, entityObj, SourceType.TEXT);
                return getResult(balFuture);
            } catch (Exception exception) {
                return createError(exception, "text");
            }
        });
    }

    public static Object getNonBlockingXml(Environment env, BObject entityObj) {
        if (isStreamingRequired(entityObj)) {
            return getXml(entityObj);
        }
        try {
            Object dataSource = EntityBodyHandler.getMessageDataSource(entityObj);
            if (dataSource != null) {
                return getAlreadyBuiltXml(dataSource);
            }
        } catch (Exception exception) {
            return createError(exception, "text");
        }
        // access payload in non-blocking manner
        return env.yieldAndRun(() -> {
            try {
                CompletableFuture<Object> balFuture = new CompletableFuture<>();
                constructNonBlockingDataSource(balFuture, entityObj, SourceType.XML);
                return getResult(balFuture);
            } catch (Exception exception) {
                return createError(exception, "text");
            }
        });
    }

    public static Object getByteChannel(BObject entityObj) {
        populateInputStream(entityObj);
        return MimeEntityBody.getByteChannel(entityObj);
    }

    public static void populateInputStream(BObject entityObj) {
        Object dataSource = entityObj.getNativeData(MESSAGE_DATA_SOURCE);
        if (Objects.nonNull(dataSource)) {
            return;
        }
        HttpCarbonMessage httpCarbonMessage = (HttpCarbonMessage) entityObj.getNativeData(TRANSPORT_MESSAGE);
        if (Objects.nonNull(httpCarbonMessage)) {
            HttpMessageDataStreamer httpMessageDataStreamer = new HttpMessageDataStreamer(httpCarbonMessage);

            long contentLength = HttpUtil.extractContentLength(httpCarbonMessage);
            if (contentLength > 0) {
                entityObj.addNativeData(ENTITY_BYTE_CHANNEL, new EntityWrapper(
                        new EntityBodyChannel(httpMessageDataStreamer.getInputStream())));
            }
        }
    }

    public static void constructNonBlockingDataSource(CompletableFuture<Object> balFuture, BObject entity,
                                                      SourceType sourceType) {
        HttpCarbonMessage inboundMessage = extractTransportMessageFromEntity(entity);
        if (inboundMessage.isContentReleased()) {
            createErrorAndNotify(balFuture, "Entity body content is already released");
            return;
        }
        inboundMessage.getFullHttpCarbonMessage().addListener(new FullHttpMessageListener() {
            @Override
            public void onComplete(HttpCarbonMessage inboundMessage) {
                Object dataSource = null;
                HttpMessageDataStreamer dataStreamer = new HttpMessageDataStreamer(inboundMessage);
                InputStream inputStream = dataStreamer.getInputStream();
                try {
                    switch (sourceType) {
                        case JSON:
                            dataSource = constructJsonDataSource(entity, inputStream);
                            updateJsonDataSourceAndNotify(balFuture, entity, dataSource);
                            return;
                        case TEXT:
                            dataSource = constructStringDataSource(entity, inputStream);
                            break;
                        case XML:
                            dataSource = constructXmlDataSource(entity, inputStream);
                            break;
                        case BLOB:
                            dataSource = constructBlobDataSource(inputStream);
                            break;
                    }
                    updateDataSourceAndNotify(balFuture, entity, dataSource);
                } catch (Exception e) {
                    createErrorAndNotify(balFuture, "Error occurred while extracting " +
                            sourceType.toString().toLowerCase(Locale.ENGLISH) + " data from entity: " + getErrorMsg(e));
                } finally {
                    try {
                        inputStream.close();
                    } catch (IOException exception) {
                        log.error("Error occurred while closing the inbound data stream", exception);
                    }
                }
            }

            @Override
            public void onError(Exception ex) {
                createErrorAndNotify(balFuture, "Error occurred while extracting content from message : " +
                        ex.getMessage());
            }
        });
    }

    private static Object notifyError(Exception exception, String type) {
        return createError(exception, type);
    }

    private static Object notifyError(CompletableFuture<Object> balFuture, Exception exception, String type) {
        BError error = (BError) createError(exception, type);
        if (balFuture != null) {
            setReturnValuesAndNotify(balFuture, error);
            return null;
        }
        return error;
    }

    private static void createErrorAndNotify(CompletableFuture<Object> balFuture, String errMsg) {
        BError error = MimeUtil.createError(PARSER_ERROR, errMsg);
        setReturnValuesAndNotify(balFuture, error);
    }

    private static void setReturnValuesAndNotify(CompletableFuture<Object> balFuture, Object result) {
        balFuture.complete(result);
    }

    private static void updateDataSourceAndNotify(CompletableFuture<Object> balFuture, BObject entityObj,
                                                  Object result) {
        updateDataSource(entityObj, result);
        setReturnValuesAndNotify(balFuture, result);
    }

    private static void updateJsonDataSourceAndNotify(CompletableFuture<Object> balFuture, BObject entityObj,
                                                      Object result) {
        updateJsonDataSource(entityObj, result);
        setReturnValuesAndNotify(balFuture, result);
    }

    private static HttpCarbonMessage extractTransportMessageFromEntity(BObject entityObj) {
        HttpCarbonMessage message = (HttpCarbonMessage) entityObj.getNativeData(TRANSPORT_MESSAGE);
        if (message != null) {
            return message;
        }
        throw MimeUtil.createError(NO_CONTENT_ERROR, "Empty content");
    }

    /**
     * Type of content to construct the data source.
     */
    public enum SourceType {
        JSON,
        XML,
        TEXT,
        BLOB
    }

    private ExternHttpDataSourceBuilder() {}
}
