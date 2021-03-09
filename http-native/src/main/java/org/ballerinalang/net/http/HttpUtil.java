/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.http;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BDecimal;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BRefValue;
import io.ballerina.runtime.api.values.BStreamingJson;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BXmlItem;
import io.ballerina.runtime.api.values.BXmlSequence;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import io.ballerina.runtime.transactions.TransactionConstants;
import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;
import io.netty.handler.codec.http.HttpHeaders;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.util.CharsetUtil;
import org.ballerinalang.config.ConfigRegistry;
import org.ballerinalang.mime.util.EntityBodyChannel;
import org.ballerinalang.mime.util.EntityBodyHandler;
import org.ballerinalang.mime.util.EntityHeaderHandler;
import org.ballerinalang.mime.util.EntityWrapper;
import org.ballerinalang.mime.util.HeaderUtil;
import org.ballerinalang.mime.util.MimeUtil;
import org.ballerinalang.mime.util.MultipartDataSource;
import org.ballerinalang.mime.util.MultipartDecoder;
import org.ballerinalang.net.http.caching.RequestCacheControlObj;
import org.ballerinalang.net.http.caching.ResponseCacheControlObj;
import org.ballerinalang.net.http.websocket.WebSocketConstants;
import org.ballerinalang.net.transport.contract.HttpResponseFuture;
import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.config.ChunkConfig;
import org.ballerinalang.net.transport.contract.config.ForwardedExtensionConfig;
import org.ballerinalang.net.transport.contract.config.InboundMsgSizeValidationConfig;
import org.ballerinalang.net.transport.contract.config.KeepAliveConfig;
import org.ballerinalang.net.transport.contract.config.ListenerConfiguration;
import org.ballerinalang.net.transport.contract.config.Parameter;
import org.ballerinalang.net.transport.contract.config.ProxyServerConfiguration;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.config.SslConfiguration;
import org.ballerinalang.net.transport.contract.exceptions.ClientConnectorException;
import org.ballerinalang.net.transport.contract.exceptions.ConnectionTimedOutException;
import org.ballerinalang.net.transport.contract.exceptions.EndpointTimeOutException;
import org.ballerinalang.net.transport.contract.exceptions.PromiseRejectedException;
import org.ballerinalang.net.transport.contract.exceptions.ServerConnectorException;
import org.ballerinalang.net.transport.contract.exceptions.SslException;
import org.ballerinalang.net.transport.contractimpl.sender.channel.pool.ConnectionManager;
import org.ballerinalang.net.transport.contractimpl.sender.channel.pool.PoolConfiguration;
import org.ballerinalang.net.transport.message.Http2PushPromise;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.transport.message.HttpMessageDataStreamer;
import org.ballerinalang.stdlib.io.utils.IOConstants;
import org.ballerinalang.stdlib.io.utils.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.net.InetSocketAddress;
import java.net.URLEncoder;
import java.net.UnknownHostException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;

import static io.ballerina.runtime.api.constants.RuntimeConstants.BALLERINA_VERSION;
import static io.ballerina.runtime.api.utils.StringUtils.fromString;
import static io.ballerina.runtime.api.utils.StringUtils.fromStringArray;
import static io.ballerina.runtime.api.utils.StringUtils.fromStringSet;
import static io.ballerina.runtime.observability.ObservabilityConstants.PROPERTY_HTTP_HOST;
import static io.ballerina.runtime.observability.ObservabilityConstants.PROPERTY_HTTP_PORT;
import static io.ballerina.runtime.observability.ObservabilityConstants.PROPERTY_KEY_HTTP_STATUS_CODE;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_HTTP_METHOD;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_HTTP_URL;
import static io.ballerina.runtime.observability.ObservabilityConstants.TAG_KEY_PEER_ADDRESS;
import static io.netty.handler.codec.http.HttpHeaderNames.CACHE_CONTROL;
import static org.ballerinalang.mime.util.EntityBodyHandler.checkEntityBodyAvailability;
import static org.ballerinalang.mime.util.MimeConstants.BOUNDARY;
import static org.ballerinalang.mime.util.MimeConstants.ENTITY_BYTE_CHANNEL;
import static org.ballerinalang.mime.util.MimeConstants.HEADERS_MAP_FIELD;
import static org.ballerinalang.mime.util.MimeConstants.HEADER_NAMES_ARRAY_FIELD;
import static org.ballerinalang.mime.util.MimeConstants.INVALID_CONTENT_LENGTH_ERROR;
import static org.ballerinalang.mime.util.MimeConstants.IS_BODY_BYTE_CHANNEL_ALREADY_SET;
import static org.ballerinalang.mime.util.MimeConstants.MULTIPART_AS_PRIMARY_TYPE;
import static org.ballerinalang.mime.util.MimeConstants.OCTET_STREAM;
import static org.ballerinalang.mime.util.MimeConstants.REQUEST_ENTITY_FIELD;
import static org.ballerinalang.mime.util.MimeConstants.RESPONSE_ENTITY_FIELD;
import static org.ballerinalang.net.http.HttpConstants.ALWAYS;
import static org.ballerinalang.net.http.HttpConstants.ANN_CONFIG_ATTR_COMPRESSION_CONTENT_TYPES;
import static org.ballerinalang.net.http.HttpConstants.ANN_CONFIG_ATTR_COMPRESSION_ENABLE;
import static org.ballerinalang.net.http.HttpConstants.ANN_CONFIG_ATTR_SSL_ENABLED_PROTOCOLS;
import static org.ballerinalang.net.http.HttpConstants.AUTO;
import static org.ballerinalang.net.http.HttpConstants.CONNECTION_MANAGER;
import static org.ballerinalang.net.http.HttpConstants.CONNECTION_POOLING_MAX_ACTIVE_STREAMS_PER_CONNECTION;
import static org.ballerinalang.net.http.HttpConstants.DOUBLE_SLASH;
import static org.ballerinalang.net.http.HttpConstants.HTTP_ERROR_MESSAGE;
import static org.ballerinalang.net.http.HttpConstants.HTTP_ERROR_STATUS_CODE;
import static org.ballerinalang.net.http.HttpConstants.HTTP_HEADERS;
import static org.ballerinalang.net.http.HttpConstants.HTTP_TRAILER_HEADERS;
import static org.ballerinalang.net.http.HttpConstants.LISTENER_CONFIGURATION;
import static org.ballerinalang.net.http.HttpConstants.MUTUAL_SSL_CERTIFICATE;
import static org.ballerinalang.net.http.HttpConstants.MUTUAL_SSL_HANDSHAKE_RECORD;
import static org.ballerinalang.net.http.HttpConstants.NEVER;
import static org.ballerinalang.net.http.HttpConstants.NO_CONTENT_LENGTH_FOUND;
import static org.ballerinalang.net.http.HttpConstants.ONE_BYTE;
import static org.ballerinalang.net.http.HttpConstants.PKCS_STORE_TYPE;
import static org.ballerinalang.net.http.HttpConstants.PROTOCOL_HTTPS;
import static org.ballerinalang.net.http.HttpConstants.REQUEST;
import static org.ballerinalang.net.http.HttpConstants.REQUEST_CACHE_CONTROL_FIELD;
import static org.ballerinalang.net.http.HttpConstants.REQUEST_MUTUAL_SSL_HANDSHAKE_FIELD;
import static org.ballerinalang.net.http.HttpConstants.REQUEST_MUTUAL_SSL_HANDSHAKE_STATUS;
import static org.ballerinalang.net.http.HttpConstants.RESOLVED_REQUESTED_URI;
import static org.ballerinalang.net.http.HttpConstants.RESOLVED_REQUESTED_URI_FIELD;
import static org.ballerinalang.net.http.HttpConstants.RESPONSE_CACHE_CONTROL;
import static org.ballerinalang.net.http.HttpConstants.RESPONSE_CACHE_CONTROL_FIELD;
import static org.ballerinalang.net.http.HttpConstants.RESPONSE_REASON_PHRASE_FIELD;
import static org.ballerinalang.net.http.HttpConstants.RESPONSE_STATUS_CODE_FIELD;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_CERT;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_CERTKEY_CERT_FILE;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_CERTKEY_KEY_FILE;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_CERTKEY_KEY_PASSWORD;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_CERT_VALIDATION;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_CERT_VALIDATION_CACHE_SIZE;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_CERT_VALIDATION_CACHE_VALIDITY_PERIOD;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_CERT_VALIDATION_TYPE;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_CERT_VALIDATION_TYPE_OCSP_STAPLING;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_CIPHERS;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_DISABLE_SSL;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_HANDSHAKE_TIMEOUT;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_HOST_NAME_VERIFICATION_ENABLED;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_KEY;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_KEYSTORE_FILE_PATH;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_KEYSTORE_PASSWORD;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_MUTUAL_SSL;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_PROTOCOL;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_PROTOCOL_NAME;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_PROTOCOL_VERSIONS;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_SESSION_TIMEOUT;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_SHARE_SESSION;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_TRUSTSTORE_FILE_PATH;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_TRUSTSTORE_PASSWORD;
import static org.ballerinalang.net.http.HttpConstants.SECURESOCKET_CONFIG_VERIFY_CLIENT;
import static org.ballerinalang.net.http.HttpConstants.SERVER_NAME;
import static org.ballerinalang.net.http.HttpConstants.TRANSPORT_MESSAGE;
import static org.ballerinalang.net.http.nativeimpl.ModuleUtils.getHttpPackage;
import static org.ballerinalang.net.http.nativeimpl.pipelining.PipeliningHandler.sendPipelinedResponse;
import static org.ballerinalang.net.transport.contract.Constants.ENCODING_GZIP;
import static org.ballerinalang.net.transport.contract.Constants.HTTP_1_1_VERSION;
import static org.ballerinalang.net.transport.contract.Constants.HTTP_2_0_VERSION;
import static org.ballerinalang.net.transport.contract.Constants.HTTP_TRANSFER_ENCODING_IDENTITY;
import static org.ballerinalang.net.transport.contract.Constants.PROMISED_STREAM_REJECTED_ERROR;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_100_CONTINUE_RESPONSE;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_INBOUND_REQUEST;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_OUTBOUND_RESPONSE;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_CLIENT_CLOSED_WHILE_READING_INBOUND_REQUEST_BODY;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_CLIENT_CLOSED_WHILE_READING_INBOUND_REQUEST_HEADERS;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_CLIENT_CLOSED_WHILE_WRITING_100_CONTINUE_RESPONSE;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_CLIENT_CLOSED_WHILE_WRITING_OUTBOUND_RESPONSE_BODY;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_CLIENT_CLOSED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_SERVER_CLOSED_BEFORE_INITIATING_INBOUND_RESPONSE;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_SERVER_CLOSED_BEFORE_INITIATING_OUTBOUND_REQUEST;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_HEADERS;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_SERVER_CLOSED_WHILE_WRITING_OUTBOUND_REQUEST_BODY;
import static org.ballerinalang.net.transport.contract.Constants.REMOTE_SERVER_CLOSED_WHILE_WRITING_OUTBOUND_REQUEST_HEADERS;

/**
 * Utility class providing utility methods.
 */
public class HttpUtil {

    public static final boolean TRUE = true;
    public static final boolean FALSE = false;

    private static final Logger log = LoggerFactory.getLogger(HttpUtil.class);

    private static final String METHOD_ACCESSED = "isMethodAccessed";
    private static final String IO_EXCEPTION_OCCURRED = "I/O exception occurred";
    private static final String CHUNKING_CONFIG = "chunking_config";
    private static final String ILLEGAL_FUNCTION_INVOKED = "illegal function invocation";

    /**
     * Set new entity to in/out request/response struct.
     *
     * @param httpMessageStruct request/response struct.
     * @return created entity.
     */
    public static BObject createNewEntity(BObject httpMessageStruct) {
        BObject entity = ValueCreatorUtils.createEntityObject();
        HttpCarbonMessage httpCarbonMessage = HttpUtil.getCarbonMsg(httpMessageStruct,
                HttpUtil.createHttpCarbonMessage(isRequest(httpMessageStruct)));
        entity.addNativeData(ENTITY_BYTE_CHANNEL, null);

        httpMessageStruct.addNativeData(HTTP_HEADERS, httpCarbonMessage.getHeaders());
        httpMessageStruct.addNativeData(HTTP_TRAILER_HEADERS, httpCarbonMessage.getTrailerHeaders());
        httpMessageStruct.set(isRequest(httpMessageStruct) ? REQUEST_ENTITY_FIELD : RESPONSE_ENTITY_FIELD , entity);
        httpMessageStruct.addNativeData(IS_BODY_BYTE_CHANNEL_ALREADY_SET, false);
        return entity;
    }

    /**
     * Set the given entity to request or response message.
     *
     * @param messageObj Represent ballerina request/response
     * @param entityObj  Represent an entity
     * @param isRequest  boolean representing whether the message is a request or a response
     * @param updateAllHeaders  boolean representing whether the headers need to be updated in the transport message
     */
    public static void setEntity(BObject messageObj, BObject entityObj, boolean isRequest,
                                 boolean updateAllHeaders) {
        HttpCarbonMessage httpCarbonMessage = HttpUtil.getCarbonMsg(messageObj,
                HttpUtil.createHttpCarbonMessage(isRequest));
        String contentType = MimeUtil.getContentTypeWithParameters(entityObj);
        if (checkEntityBodyAvailability(entityObj)) {
            httpCarbonMessage.waitAndReleaseAllEntities();
            if (contentType == null) {
                contentType = OCTET_STREAM;
            }
            ((HttpHeaders) messageObj.getNativeData(HTTP_HEADERS)).set(HttpHeaderNames.CONTENT_TYPE.toString(),
                                                                       contentType);
        }
        messageObj.set(isRequest ? REQUEST_ENTITY_FIELD : RESPONSE_ENTITY_FIELD, entityObj);
        messageObj.addNativeData(IS_BODY_BYTE_CHANNEL_ALREADY_SET, checkEntityBodyAvailability(entityObj));
        if (updateAllHeaders) {
            HttpUtil.setEntityHeaderToTransportHeader(entityObj, (HttpHeaders) messageObj.getNativeData(HTTP_HEADERS));
        }
    }

    /**
     * Get the entity from request or response.
     *
     * @param messageObj         Ballerina context
     * @param isRequest          boolean representing whether the message is a request or a response
     * @param entityBodyRequired boolean representing whether the entity body is required
     * @param entityHeadersRequired boolean representing whether the entity headers are required
     * @return Entity of the request or response
     */
    public static BObject getEntity(BObject messageObj, boolean isRequest, boolean entityBodyRequired,
                                        boolean entityHeadersRequired) {
        BObject entity = (BObject) messageObj.get(isRequest ? REQUEST_ENTITY_FIELD : RESPONSE_ENTITY_FIELD);
        boolean byteChannelAlreadySet = false;

        if (messageObj.getNativeData(IS_BODY_BYTE_CHANNEL_ALREADY_SET) != null) {
            byteChannelAlreadySet = (Boolean) messageObj.getNativeData(IS_BODY_BYTE_CHANNEL_ALREADY_SET);
        }
        if (entityBodyRequired && !byteChannelAlreadySet) {
            populateEntityBody(messageObj, entity, isRequest, entityHeadersRequired);
        }
        if (entityHeadersRequired) {
            populateEntityHeaders(messageObj, entity);
        }
        return entity;
    }

    /**
     * Populate entity with the relevant body content.
     *
     * @param messageObj Represent ballerina request/response
     * @param entityObj     Represent an entity
     * @param request    boolean representing whether the message is a request or a response
     * @param streaming  boolean representing whether the entity requires byte channel or message as native data
     */
    public static void populateEntityBody(BObject messageObj, BObject entityObj, boolean request,
                                          boolean streaming) {
        HttpCarbonMessage httpCarbonMessage = HttpUtil
                .getCarbonMsg(messageObj, HttpUtil.createHttpCarbonMessage(request));
        String contentType = httpCarbonMessage.getHeader(HttpHeaderNames.CONTENT_TYPE.toString());
        //TODO check following condition related to streaming
        if (MimeUtil.isNotNullAndEmpty(contentType) && contentType.startsWith(MULTIPART_AS_PRIMARY_TYPE)
                && !streaming) {
            MultipartDecoder.parseBody(entityObj, contentType,
                                       new HttpMessageDataStreamer(httpCarbonMessage).getInputStream());
        } else {
            long contentLength = HttpUtil.extractContentLength(httpCarbonMessage);
            if (contentLength > 0) {
                if (streaming) {
                    entityObj.addNativeData(ENTITY_BYTE_CHANNEL, new EntityWrapper(
                            new EntityBodyChannel(new HttpMessageDataStreamer(httpCarbonMessage).getInputStream())));
                } else {
                    entityObj.addNativeData(TRANSPORT_MESSAGE, httpCarbonMessage);
                }
            } else {
                if (HttpHeaderValues.CHUNKED.toString().equals(
                        httpCarbonMessage.getHeader(HttpHeaderNames.TRANSFER_ENCODING.toString()))) {
                    entityObj.addNativeData(TRANSPORT_MESSAGE, httpCarbonMessage);
                }
            }
        }
        messageObj.set(request ? REQUEST_ENTITY_FIELD : RESPONSE_ENTITY_FIELD, entityObj);
        messageObj.addNativeData(IS_BODY_BYTE_CHANNEL_ALREADY_SET, true);
    }

    private static void populateEntityHeaders(BObject messageObj, BObject entity) {
        HttpCarbonMessage httpCarbonMessage = (HttpCarbonMessage) messageObj.getNativeData(TRANSPORT_MESSAGE);
        if (httpCarbonMessage == null) {
            return;
        }

        BMap<BString, Object> headers = EntityHeaderHandler.getNewHeaderMap();
        HttpHeaders httpHeaders = httpCarbonMessage.getHeaders();
        for (String key : httpHeaders.names()) {
            String[] values = httpHeaders.getAll(key).toArray(new String[0]);
            headers.put(fromString(key.toLowerCase(Locale.getDefault())), fromStringArray(values));
        }
        entity.set(HEADERS_MAP_FIELD, headers);

        Set<String> distinctNames = new TreeSet<>(String.CASE_INSENSITIVE_ORDER);
        distinctNames.addAll(httpHeaders.names());
        entity.set(HEADER_NAMES_ARRAY_FIELD, fromStringSet(distinctNames));
    }

    /**
     * Given a {@link HttpCarbonMessage}, returns the content length extracting from headers.
     *
     * @param httpCarbonMessage Represent the message
     * @return length of the content
     */
    public static long extractContentLength(HttpCarbonMessage httpCarbonMessage) {
        long contentLength = NO_CONTENT_LENGTH_FOUND;
        String lengthStr = httpCarbonMessage.getHeader(HttpHeaderNames.CONTENT_LENGTH.toString());
        try {
            contentLength = lengthStr != null ? Long.parseLong(lengthStr) : contentLength;
            if (contentLength == NO_CONTENT_LENGTH_FOUND) {
                //Read one byte to make sure the incoming stream has data
                contentLength = httpCarbonMessage.countMessageLengthTill(ONE_BYTE);
            }
        } catch (NumberFormatException e) {
            throw MimeUtil.createError(INVALID_CONTENT_LENGTH_ERROR, "Invalid content length");
        }
        return contentLength;
    }

    public static BObject extractEntity(BObject request) {
        Object isEntityBodyAvailable = request.getNativeData(IS_BODY_BYTE_CHANNEL_ALREADY_SET);
        if (isEntityBodyAvailable == null || !((Boolean) isEntityBodyAvailable)) {
            return null;
        }
        return (BObject) request.get(isRequest(request) ? REQUEST_ENTITY_FIELD : RESPONSE_ENTITY_FIELD);
    }

    public static void closeMessageOutputStream(OutputStream messageOutputStream) {
        try {
            if (messageOutputStream != null) {
                messageOutputStream.close();
            }
        } catch (IOException e) {
            log.error("Couldn't close message output stream", e);
        }
    }

    public static void prepareOutboundResponse(BObject connectionObj, HttpCarbonMessage inboundRequestMsg,
                                               HttpCarbonMessage outboundResponseMsg,
                                               BObject outboundResponseObj) {
        HttpUtil.checkEntityAvailability(outboundResponseObj);
        HttpUtil.addCorsHeaders(inboundRequestMsg, outboundResponseMsg);
        HttpUtil.enrichOutboundMessage(outboundResponseMsg, outboundResponseObj);
        HttpService httpService = (HttpService) connectionObj.getNativeData(HttpConstants.HTTP_SERVICE);
        HttpUtil.setCompressionHeaders(httpService.getCompressionConfig(), inboundRequestMsg, outboundResponseMsg);
        HttpUtil.setChunkingHeader(httpService.getChunkingConfig(), outboundResponseMsg);
    }

    private static void addCorsHeaders(HttpCarbonMessage requestMsg, HttpCarbonMessage responseMsg) {
        if (requestMsg.getHeader(HttpHeaderNames.ORIGIN.toString()) != null) {
            CorsHeaderGenerator.process(requestMsg, responseMsg, true);
        }
    }

    /**
     * This method should never be called directly to send out responses for ballerina HTTP 1.1. Use
     * PipeliningHandler's sendPipelinedResponse() method instead.
     *
     * @param requestMsg  Represent the request message
     * @param responseMsg Represent the corresponding response
     * @return HttpResponseFuture that represent the future results
     */
    public static HttpResponseFuture sendOutboundResponse(HttpCarbonMessage requestMsg,
                                                          HttpCarbonMessage responseMsg) {
        HttpResponseFuture responseFuture;
        try {
            responseFuture = requestMsg.respond(responseMsg);
        } catch (ServerConnectorException e) {
            throw new BallerinaConnectorException("Error occurred during response", e);
        }
        return responseFuture;
    }

    /**
     * Sends an HTTP/2 Server Push message back to the client.
     *
     * @param requestMsg   the request message associated to the server push response
     * @param pushResponse the server push message
     * @param pushPromise  the push promise associated with the server push
     * @return the future to get notifications of the operation asynchronously
     */
    public static HttpResponseFuture pushResponse(HttpCarbonMessage requestMsg, HttpCarbonMessage pushResponse,
                                                  Http2PushPromise pushPromise) {
        HttpResponseFuture responseFuture;
        try {
            responseFuture = requestMsg.pushResponse(pushResponse, pushPromise);
        } catch (ServerConnectorException e) {
            throw new BallerinaConnectorException("Error occurred while sending a server push message", e);
        }
        return responseFuture;
    }

    /**
     * Sends an HTTP/2 Push Promise message back to the client.
     *
     * @param requestMsg  the request message associated to the push promise
     * @param pushPromise the push promise message
     * @return the future to get notifications of the operation asynchronously
     */
    public static HttpResponseFuture pushPromise(HttpCarbonMessage requestMsg, Http2PushPromise pushPromise) {
        HttpResponseFuture responseFuture;
        try {
            responseFuture = requestMsg.pushPromise(pushPromise);
        } catch (ServerConnectorException e) {
            throw new BallerinaConnectorException("Error occurred during response", e);
        }
        return responseFuture;
    }

    public static void handleFailure(HttpCarbonMessage requestMessage, String errorMsg) {
        int statusCode = getStatusCode(requestMessage, errorMsg);
        sendPipelinedResponse(requestMessage, createErrorMessage(errorMsg, statusCode));
    }

    static void handleFailure(HttpCarbonMessage requestMessage, BError error) {
        String typeName = error.getType().getName();
        if (HttpConstants.HTTP_CLIENT_REQUEST_ERROR.equals(typeName) ||
                HttpConstants.HTTP_REMOTE_SERVER_ERROR.equals(typeName)) {
            Object statusCode = ((BMap) error.getDetails()).get(HTTP_ERROR_STATUS_CODE);
            if (statusCode != null) {
                requestMessage.setHttpStatusCode(((Long) statusCode).intValue());
            }
        }
        String errorMsg = getErrorMessage(error);
        int statusCode = getStatusCode(requestMessage, errorMsg);
        error.printStackTrace();
        sendPipelinedResponse(requestMessage, createErrorMessage(errorMsg, statusCode));
    }

    private static String getErrorMessage(BError error) {
        BMap errorDetails = (BMap) error.getDetails();
        if (errorDetails.get(HTTP_ERROR_MESSAGE) != null) {
            return errorDetails.get(HTTP_ERROR_MESSAGE).toString();
        }
        return error.getErrorMessage().getValue();
    }

    private static int getStatusCode(HttpCarbonMessage requestMessage, String errorMsg) {
        Integer carbonStatusCode = requestMessage.getHttpStatusCode();
        if (carbonStatusCode == null) {
            //log only the internal server errors
            log.error(errorMsg);
            return HttpResponseStatus.INTERNAL_SERVER_ERROR.code();
        }
        return carbonStatusCode;
    }

    public static HttpCarbonMessage createErrorMessage(String payload, int statusCode) {
        HttpCarbonMessage response = HttpUtil.createHttpCarbonMessage(false);
        response.waitAndReleaseAllEntities();
        if (payload != null) {
            response.addHttpContent(
                    new DefaultLastHttpContent(Unpooled.wrappedBuffer(payload.getBytes(CharsetUtil.UTF_8))));
        } else {
            response.addHttpContent(new DefaultLastHttpContent());
        }
        setHttpStatusCodes(statusCode, response);

        return response;
    }

    private static void setHttpStatusCodes(int statusCode, HttpCarbonMessage response) {
        HttpHeaders httpHeaders = response.getHeaders();
        httpHeaders.set(HttpHeaderNames.CONTENT_TYPE, org.ballerinalang.net.transport.contract.Constants.TEXT_PLAIN);

        response.setHttpStatusCode(statusCode);
    }

    /**
     * Get error value from throwable.
     *
     * @param throwable Throwable representing the error.
     * @return Error struct
     */
    public static BError getError(Throwable throwable) {
        if (throwable.getCause() instanceof ClientConnectorException) {
            return createHttpError(throwable);
        }
        if (throwable.getMessage() == null) {
            return createHttpError(IO_EXCEPTION_OCCURRED);
        } else {
            return createHttpError(throwable.getMessage());
        }
    }

    public static BError createHttpError(String errorMessage) {
        HttpErrorType errorType = getErrorType(errorMessage);
        return createHttpError(errorMessage, errorType);
    }

    public static BError createHttpError(Throwable throwable) {
        BError cause;
        if (throwable instanceof EndpointTimeOutException) {
            return createHttpError(throwable.getMessage(), HttpErrorType.IDLE_TIMEOUT_TRIGGERED);
        } else if (throwable instanceof SslException) {
            return createHttpError(throwable.getMessage(), HttpErrorType.SSL_ERROR);
        } else if (throwable instanceof PromiseRejectedException) {
            return createHttpError(throwable.getMessage(), HttpErrorType.HTTP2_CLIENT_ERROR);
        } else if (throwable instanceof ConnectionTimedOutException) {
            cause = createErrorCause(throwable.getMessage(), IOConstants.ErrorCode.ConnectionTimedOut.errorCode(),
                                     IOUtils.getIOPackage());
            return createHttpError("Something wrong with the connection", HttpErrorType.GENERIC_CLIENT_ERROR, cause);
        } else if (throwable instanceof ClientConnectorException) {
            cause = createErrorCause(throwable.getMessage(), IOConstants.ErrorCode.GenericError.errorCode(),
                                     IOUtils.getIOPackage());
            return createHttpError("Something wrong with the connection", HttpErrorType.GENERIC_CLIENT_ERROR, cause);
        } else {
            return createHttpError(throwable.getMessage(), HttpErrorType.GENERIC_CLIENT_ERROR);
        }
    }

    public static BError createHttpError(String message, HttpErrorType errorType) {
        return ErrorCreator.createDistinctError(errorType.getErrorName(), getHttpPackage(),
                                                fromString(message));
    }

    public static BError createHttpError(String message, HttpErrorType errorType, BError cause) {
        return ErrorCreator.createDistinctError(errorType.getErrorName(), getHttpPackage(),
                                                fromString(message), cause);
    }

    // TODO: Find a better way to get the error type than String matching.
    private static HttpErrorType getErrorType(String errorMessage) {
        // Every Idle Timeout triggered error is mapped to IdleTimeoutError
        if (errorMessage.contains("Idle timeout triggered")) {
            return HttpErrorType.IDLE_TIMEOUT_TRIGGERED;
        }

        switch (errorMessage) {
            case REMOTE_SERVER_CLOSED_BEFORE_INITIATING_INBOUND_RESPONSE:
                return HttpErrorType.INIT_INBOUND_RESPONSE_FAILED;
            case REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_HEADERS:
                return HttpErrorType.READING_INBOUND_RESPONSE_HEADERS_FAILED;
            case REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY:
                return HttpErrorType.READING_INBOUND_RESPONSE_BODY_FAILED;
            case REMOTE_SERVER_CLOSED_BEFORE_INITIATING_OUTBOUND_REQUEST:
                return HttpErrorType.INIT_OUTBOUND_REQUEST_FAILED;
            case REMOTE_SERVER_CLOSED_WHILE_WRITING_OUTBOUND_REQUEST_HEADERS:
                return HttpErrorType.WRITING_OUTBOUND_REQUEST_HEADER_FAILED;
            case REMOTE_SERVER_CLOSED_WHILE_WRITING_OUTBOUND_REQUEST_BODY:
                return HttpErrorType.WRITING_OUTBOUND_REQUEST_BODY_FAILED;
            case REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_INBOUND_REQUEST:
                return HttpErrorType.INIT_INBOUND_REQUEST_FAILED;
            case REMOTE_CLIENT_CLOSED_WHILE_READING_INBOUND_REQUEST_HEADERS:
                return HttpErrorType.READING_INBOUND_REQUEST_HEADER_FAILED;
            case REMOTE_CLIENT_CLOSED_WHILE_READING_INBOUND_REQUEST_BODY:
                return HttpErrorType.READING_INBOUND_REQUEST_BODY_FAILED;
            case REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_OUTBOUND_RESPONSE:
                return HttpErrorType.INIT_OUTBOUND_RESPONSE_FAILED;
            case REMOTE_CLIENT_CLOSED_WHILE_WRITING_OUTBOUND_RESPONSE_HEADERS:
                return HttpErrorType.WRITING_OUTBOUND_RESPONSE_HEADERS_FAILED;
            case REMOTE_CLIENT_CLOSED_WHILE_WRITING_OUTBOUND_RESPONSE_BODY:
                return HttpErrorType.WRITING_OUTBOUND_RESPONSE_BODY_FAILED;
            case REMOTE_CLIENT_CLOSED_BEFORE_INITIATING_100_CONTINUE_RESPONSE:
                return HttpErrorType.INIT_100_CONTINUE_RESPONSE_FAILED;
            case REMOTE_CLIENT_CLOSED_WHILE_WRITING_100_CONTINUE_RESPONSE:
                return HttpErrorType.WRITING_100_CONTINUE_RESPONSE_FAILED;
            case PROMISED_STREAM_REJECTED_ERROR:
                return HttpErrorType.HTTP2_CLIENT_ERROR;
            default:
                return HttpErrorType.GENERIC_CLIENT_ERROR;
        }
    }

    private static BError createErrorCause(String message, String errorTypeId, Module packageName) {
        return ErrorCreator.createDistinctError(errorTypeId, packageName,
                                                fromString(message));
    }

    public static HttpCarbonMessage getCarbonMsg(BObject objectValue, HttpCarbonMessage defaultMsg) {
        HttpCarbonMessage httpCarbonMessage = (HttpCarbonMessage) objectValue.getNativeData(TRANSPORT_MESSAGE);
        if (httpCarbonMessage != null) {
            return httpCarbonMessage;
        }
        addCarbonMsg(objectValue, defaultMsg);
        return defaultMsg;
    }

    /**
     * Gets the {@code Http2PushPromise} represented by the PushPromise object.
     *
     * @param pushPromiseObj  the push promise object
     * @param defaultPushPromise the Http2PushPromise to use if the object does not have native data of a push promise
     * @return the {@code Http2PushPromise} represented by the PushPromise object
     */
    public static Http2PushPromise getPushPromise(BObject pushPromiseObj, Http2PushPromise defaultPushPromise) {
        Http2PushPromise pushPromise =
                (Http2PushPromise) pushPromiseObj.getNativeData(HttpConstants.TRANSPORT_PUSH_PROMISE);
        if (pushPromise != null) {
            return pushPromise;
        }
        pushPromiseObj.addNativeData(HttpConstants.TRANSPORT_PUSH_PROMISE, defaultPushPromise);
        return defaultPushPromise;
    }

    /**
     * Populates the push promise object from native {@code Http2PushPromise}.
     *  @param pushPromiseObj the push promise object
     * @param pushPromise the native Http2PushPromise
     */
    public static void populatePushPromiseStruct(BObject pushPromiseObj,
                                                 Http2PushPromise pushPromise) {
        pushPromiseObj.addNativeData(HttpConstants.TRANSPORT_PUSH_PROMISE, pushPromise);
        pushPromiseObj.set(HttpConstants.PUSH_PROMISE_PATH_FIELD, fromString(pushPromise.getPath()));
        pushPromiseObj.set(HttpConstants.PUSH_PROMISE_METHOD_FIELD, fromString(pushPromise.getMethod()));
    }

    /**
     * Creates native {@code Http2PushPromise} from PushPromise object.
     *
     * @param pushPromiseObj the PushPromise object
     * @return the populated the native {@code Http2PushPromise}
     */
    public static Http2PushPromise createHttpPushPromise(BObject pushPromiseObj) {
        String method = pushPromiseObj.get(HttpConstants.PUSH_PROMISE_METHOD_FIELD).toString();
        if (method == null || method.isEmpty()) {
            method = HttpConstants.HTTP_METHOD_GET;
        }

        String path = pushPromiseObj.get(HttpConstants.PUSH_PROMISE_PATH_FIELD).toString();
        if (path == null || path.isEmpty()) {
            path = HttpConstants.DEFAULT_BASE_PATH;
        }
        return new Http2PushPromise(method, path);
    }

    public static void addCarbonMsg(BObject struct, HttpCarbonMessage httpCarbonMessage) {
        struct.addNativeData(TRANSPORT_MESSAGE, httpCarbonMessage);
    }

    public static void populateInboundRequest(BObject inboundRequest, BObject entity,
                                              HttpCarbonMessage inboundRequestMsg) {
        inboundRequest.addNativeData(TRANSPORT_MESSAGE, inboundRequestMsg);
        inboundRequest.addNativeData(REQUEST, true);

        BMap<BString, Object> mutualSslRecord = ValueCreatorUtils.createHTTPRecordValue(
                MUTUAL_SSL_HANDSHAKE_RECORD);
        mutualSslRecord.put(REQUEST_MUTUAL_SSL_HANDSHAKE_STATUS,
                            fromString((String) inboundRequestMsg.getProperty(HttpConstants.MUTUAL_SSL_RESULT)));
        mutualSslRecord.put(MUTUAL_SSL_CERTIFICATE,
                            fromString((String) inboundRequestMsg.getProperty(HttpConstants.BASE_64_ENCODED_CERT)));
        inboundRequest.set(REQUEST_MUTUAL_SSL_HANDSHAKE_FIELD, mutualSslRecord);

        enrichWithInboundRequestInfo(inboundRequest, inboundRequestMsg);
        enrichWithInboundRequestHeaders(inboundRequest, inboundRequestMsg);

        populateEntity(inboundRequest, entity, inboundRequestMsg);
        inboundRequest.set(REQUEST_ENTITY_FIELD, entity);
        inboundRequest.addNativeData(IS_BODY_BYTE_CHANNEL_ALREADY_SET, false);

        String cacheControlHeader = inboundRequestMsg.getHeader(CACHE_CONTROL.toString());
        if (cacheControlHeader != null) {
            BObject cacheControlObj = ValueCreatorUtils.createRequestCacheControlObject();
            RequestCacheControlObj requestCacheControl = new RequestCacheControlObj(cacheControlObj);
            requestCacheControl.populateStruct(cacheControlHeader);
            inboundRequest.set(REQUEST_CACHE_CONTROL_FIELD, requestCacheControl.getObj());
        }
    }

    private static void enrichWithInboundRequestHeaders(BObject inboundRequestObj,
                                                        HttpCarbonMessage inboundRequestMsg) {
        if (inboundRequestMsg.getHeader(HttpHeaderNames.USER_AGENT.toString()) != null) {
            BString agent = fromString(
                    inboundRequestMsg.getHeader(HttpHeaderNames.USER_AGENT.toString()));
            inboundRequestObj.set(HttpConstants.REQUEST_USER_AGENT_FIELD, agent);
            inboundRequestMsg.removeHeader(HttpHeaderNames.USER_AGENT.toString());
        }
    }

    private static void enrichWithInboundRequestInfo(BObject inboundRequestObj,
                                                     HttpCarbonMessage inboundRequestMsg) {
        inboundRequestObj.set(HttpConstants.REQUEST_RAW_PATH_FIELD,
                              fromString(inboundRequestMsg.getRequestUrl()));
        inboundRequestObj.set(HttpConstants.REQUEST_METHOD_FIELD,
                              fromString(inboundRequestMsg.getHttpMethod()));
        inboundRequestObj.set(HttpConstants.REQUEST_VERSION_FIELD,
                              fromString(inboundRequestMsg.getHttpVersion()));
        HttpResourceArguments resourceArgValues = (HttpResourceArguments) inboundRequestMsg.getProperty(
                HttpConstants.RESOURCE_ARGS);
        if (resourceArgValues != null && resourceArgValues.getMap().get(HttpConstants.EXTRA_PATH_INFO) != null) {
            inboundRequestObj.set(
                    HttpConstants.REQUEST_EXTRA_PATH_INFO_FIELD, fromString(
                            resourceArgValues.getMap().get(HttpConstants.EXTRA_PATH_INFO)));
        }
    }

    /**
     * Populates the HTTP caller with native data.
     *
     * @param caller     Represents the HTTP caller
     * @param inboundMsg Represents carbon message
     * @param config     Represents service endpoint configuration
     */
    public static void enrichHttpCallerWithNativeData(BObject caller, HttpCarbonMessage inboundMsg,
                                                      BMap config) {
        caller.addNativeData(HttpConstants.TRANSPORT_MESSAGE, inboundMsg);
        caller.set(HttpConstants.HTTP_CONNECTOR_CONFIG_FIELD, config);
    }

    /**
     * Populates the HTTP caller with connection information.
     * @param httpCaller   Represents the HTTP caller
     * @param inboundMsg   Represents the carbon message
     * @param httpResource Represents the Http Resource
     * @param config       Represents the service endpoint configuration
     */
    public static void enrichHttpCallerWithConnectionInfo(BObject httpCaller, HttpCarbonMessage inboundMsg,
                                                          HttpResource httpResource, BMap config) {
        BMap<BString, Object> remote = ValueCreatorUtils.createHTTPRecordValue(HttpConstants.REMOTE);
        BMap<BString, Object> local = ValueCreatorUtils.createHTTPRecordValue(HttpConstants.LOCAL);

        Object remoteSocketAddress = inboundMsg.getProperty(HttpConstants.REMOTE_ADDRESS);
        if (remoteSocketAddress instanceof InetSocketAddress) {
            InetSocketAddress inetSocketAddress = (InetSocketAddress) remoteSocketAddress;
            BString remoteHost = fromString(inetSocketAddress.getHostString());
            long remotePort = inetSocketAddress.getPort();
            remote.put(HttpConstants.REMOTE_HOST_FIELD, remoteHost);
            remote.put(HttpConstants.REMOTE_PORT_FIELD, remotePort);
        }
        httpCaller.set(HttpConstants.REMOTE_STRUCT_FIELD, remote);

        Object localSocketAddress = inboundMsg.getProperty(HttpConstants.LOCAL_ADDRESS);
        if (localSocketAddress instanceof InetSocketAddress) {
            InetSocketAddress inetSocketAddress = (InetSocketAddress) localSocketAddress;
            String localHost = inetSocketAddress.getHostName();
            long localPort = inetSocketAddress.getPort();
            local.put(HttpConstants.LOCAL_HOST_FIELD, fromString(localHost));
            local.put(HttpConstants.LOCAL_PORT_FIELD, localPort);
        }
        httpCaller.set(HttpConstants.LOCAL_STRUCT_INDEX, local);
        httpCaller.set(HttpConstants.SERVICE_ENDPOINT_PROTOCOL_FIELD,
                       fromString((String) inboundMsg.getProperty(HttpConstants.PROTOCOL)));
        httpCaller.set(HttpConstants.SERVICE_ENDPOINT_CONFIG_FIELD, config);
        httpCaller.addNativeData(HttpConstants.HTTP_SERVICE, httpResource.getParentService());
        httpCaller.addNativeData(HttpConstants.REMOTE_SOCKET_ADDRESS, remoteSocketAddress);
    }

    /**
     * Populate inbound response with headers and entity.
     * @param inboundResponse  Ballerina struct to represent response
     * @param entity    Entity of the response
     * @param inboundResponseMsg      Represent carbon message.
     */
    public static void populateInboundResponse(BObject inboundResponse, BObject entity,
                                               HttpCarbonMessage inboundResponseMsg) {
        inboundResponse.addNativeData(TRANSPORT_MESSAGE, inboundResponseMsg);
        int statusCode = inboundResponseMsg.getHttpStatusCode();
        inboundResponse.set(RESPONSE_STATUS_CODE_FIELD, (long) statusCode);
        String reasonPhrase = inboundResponseMsg.getReasonPhrase();
        inboundResponse.set(RESPONSE_REASON_PHRASE_FIELD, fromString(reasonPhrase));

        if (inboundResponseMsg.getHeader(HttpHeaderNames.SERVER.toString()) != null) {
            inboundResponse.set(HttpConstants.RESPONSE_SERVER_FIELD,
                                fromString(inboundResponseMsg.getHeader(HttpHeaderNames.SERVER.toString())));
            inboundResponseMsg.removeHeader(HttpHeaderNames.SERVER.toString());
        }

        if (inboundResponseMsg.getProperty(RESOLVED_REQUESTED_URI) != null) {
            inboundResponse.set(RESOLVED_REQUESTED_URI_FIELD,
                                fromString(inboundResponseMsg.getProperty(RESOLVED_REQUESTED_URI).toString()));
        }

        String cacheControlHeader = inboundResponseMsg.getHeader(CACHE_CONTROL.toString());
        if (cacheControlHeader != null) {
            ResponseCacheControlObj responseCacheControl = new ResponseCacheControlObj(getHttpPackage(),
                                                                                       RESPONSE_CACHE_CONTROL);
            responseCacheControl.populateStruct(cacheControlHeader);
            inboundResponse.set(RESPONSE_CACHE_CONTROL_FIELD, responseCacheControl.getObj());
        }

        populateEntity(inboundResponse, entity, inboundResponseMsg);
        inboundResponse.set(RESPONSE_ENTITY_FIELD, entity);
        inboundResponse.addNativeData(IS_BODY_BYTE_CHANNEL_ALREADY_SET, false);
    }

    /**
     * Populate entity with headers and content-length.
     *
     * @param requestObj Represent an inbound request
     * @param entity Represent an entity struct
     * @param cMsg   Represent a carbon message
     */
    private static void populateEntity(BObject requestObj, BObject entity, HttpCarbonMessage cMsg) {
        long contentLength = -1;
        String lengthStr = cMsg.getHeader(HttpHeaderNames.CONTENT_LENGTH.toString());
        try {
            contentLength = lengthStr != null ? Long.parseLong(lengthStr) : contentLength;
            MimeUtil.setContentLength(entity, contentLength);
        } catch (NumberFormatException e) {
            throw createHttpError("Invalid content length", HttpErrorType.INVALID_CONTENT_LENGTH);
        }
        requestObj.addNativeData(HTTP_HEADERS, cMsg.getHeaders());
        requestObj.addNativeData(HTTP_TRAILER_HEADERS, cMsg.getTrailerHeaders());
    }

    /**
     * Set headers and properties of request/response object to the outbound transport message.
     *
     * @param outboundMsg    transport Http carbon message.
     * @param outboundMsgObj req/resp object.
     */
    public static void enrichOutboundMessage(HttpCarbonMessage outboundMsg, BObject outboundMsgObj) {
        setHeadersToTransportMessage(outboundMsg, outboundMsgObj);
        setPropertiesToTransportMessage(outboundMsg, outboundMsgObj);
    }

    private static void setHeadersToTransportMessage(HttpCarbonMessage outboundMsg, BObject messageObj) {
        boolean request = isRequest(messageObj);
        HttpHeaders transportHeaders = outboundMsg.getHeaders();
        if (request || isResponse(messageObj)) {
            addRemovedPropertiesBackToHeadersMap(messageObj, transportHeaders);
            // Since now the InRequest & OutRequest are merged to a single Request and InResponse & OutResponse
            // are merged to a single Response, without returning need to populate all headers from the struct
            // to the HttpCarbonMessage.
            // TODO: refactor this logic properly.
            // return;
        }
        HttpHeaders httpHeaders = (HttpHeaders) messageObj.getNativeData(HTTP_HEADERS);
        if (httpHeaders != transportHeaders) {
            //This is done only when the entity map and transport message do not refer to the same header map
            if (httpHeaders != null) {
                transportHeaders.add(httpHeaders);
            }
        }
        if (!request) {
            HttpHeaders transportTrailingHeaders = outboundMsg.getTrailerHeaders();
            HttpHeaders trailingHeaders = (HttpHeaders) messageObj.getNativeData(HTTP_TRAILER_HEADERS);
            if (trailingHeaders != null && trailingHeaders != transportTrailingHeaders) {
                transportTrailingHeaders.add(trailingHeaders);
            }
        }
    }

    private static void setEntityHeaderToTransportHeader(BObject entityObj, HttpHeaders httpHeaders) {
        BMap<BString, Object> entityHeaders = EntityHeaderHandler.getEntityHeaderMap(entityObj);

        for (BString entryKey : entityHeaders.getKeys()) {
            BArray entryValues = (BArray) entityHeaders.get(entryKey);
            if (entryValues.size() > 1) {
                Iterator<String> valueIterator = Arrays.stream(entryValues.getStringArray()).map(String::valueOf)
                        .iterator();
                httpHeaders.add(entryKey.getValue(), valueIterator);
            } else if (entryValues.size() == 1) {
                httpHeaders.set(entryKey.getValue(), entryValues.getBString(0).getValue());
            }
        }
    }

    private static boolean isRequest(BObject value) {
        return value.getType().getName().equals(REQUEST);
    }

    private static boolean isResponse(BObject value) {
        return value.getType().getName().equals(HttpConstants.RESPONSE);
    }

    private static void addRemovedPropertiesBackToHeadersMap(BObject messageObj, HttpHeaders transportHeaders) {
        if (isRequest(messageObj)) {
            Object userAgent = messageObj.get(HttpConstants.REQUEST_USER_AGENT_FIELD);
            if (userAgent != null && !userAgent.toString().isEmpty()) {
                transportHeaders.set(HttpHeaderNames.USER_AGENT.toString(), userAgent.toString());
            }
        } else {
            Object server = messageObj.get(HttpConstants.RESPONSE_SERVER_FIELD);
            if (server != null && !server.toString().isEmpty()) {
                transportHeaders.set(HttpHeaderNames.SERVER.toString(), server.toString());
            }
        }
    }

    private static void setPropertiesToTransportMessage(HttpCarbonMessage outboundResponseMsg, BObject messageObj) {
        if (isResponse(messageObj)) {
            //TODO fix following logic
            long statusCode = (Long) messageObj.get(RESPONSE_STATUS_CODE_FIELD);
            if (statusCode != 0) {
                outboundResponseMsg.setHttpStatusCode(getIntValue(statusCode));
            }
            Object respPhrase = messageObj.get(RESPONSE_REASON_PHRASE_FIELD);
            if (respPhrase != null && !respPhrase.toString().isEmpty()) {
                outboundResponseMsg.setProperty(HttpConstants.HTTP_REASON_PHRASE, respPhrase.toString());
            }
        }
    }

    /**
     * Check the existence of entity. Set new entity of not present.
     *
     * @param value  request/response struct.
     */
    public static void checkEntityAvailability(BObject value) {
        BObject entity = (BObject) value.get(isRequest(value) ? REQUEST_ENTITY_FIELD : RESPONSE_ENTITY_FIELD);
        if (entity == null) {
            createNewEntity(value);
        }
    }

    /**
     * Check the existence of content-length and transfer-encoding headers.
     *
     * @param message transport message
     * @return true if the headers are available else false.
     */
    public static Boolean checkRequestBodySizeHeadersAvailability(HttpCarbonMessage message) {
        String contentLength = message.getHeader(HttpHeaderNames.CONTENT_LENGTH.toString());
        String transferEncoding = message.getHeader(HttpHeaderNames.TRANSFER_ENCODING.toString());
        return contentLength != null || transferEncoding != null;
    }

    /**
     * Check the existence of the message entity data source.
     *
     * @param value  request/response object.
     * @return true if the message entity data source is available else false.
     */
    public static boolean isEntityDataSourceAvailable(BObject value) {
        BObject entityObj = (BObject) value
                .get(isRequest(value) ? REQUEST_ENTITY_FIELD : RESPONSE_ENTITY_FIELD);
        return (entityObj != null && EntityBodyHandler.getMessageDataSource(entityObj) != null);
    }

    private static void setCompressionHeaders(BMap<BString, Object> compressionConfig, HttpCarbonMessage requestMsg,
                                              HttpCarbonMessage outboundResponseMsg) {
        if (!checkConfigAnnotationAvailability(compressionConfig)) {
            return;
        }
        String contentEncoding = outboundResponseMsg.getHeaders().get(HttpHeaderNames.CONTENT_ENCODING);
        if (contentEncoding != null) {
            return;
        }
        CompressionConfigState compressionState = getCompressionState(
                compressionConfig.getStringValue(ANN_CONFIG_ATTR_COMPRESSION_ENABLE).getValue());
        if (compressionState == CompressionConfigState.NEVER) {
            outboundResponseMsg.getHeaders().set(HttpHeaderNames.CONTENT_ENCODING, HTTP_TRANSFER_ENCODING_IDENTITY);
            return;
        }

        String acceptEncodingValue = requestMsg.getHeaders().get(HttpHeaderNames.ACCEPT_ENCODING);
        List<String> contentTypesAnnotationValues = getAsStringList(
                compressionConfig.getArrayValue(ANN_CONFIG_ATTR_COMPRESSION_CONTENT_TYPES).getStringArray());
        String contentType = outboundResponseMsg.getHeader(HttpHeaderNames.CONTENT_TYPE.toString());

        if (contentTypesAnnotationValues.isEmpty() || isContentTypeMatched(contentTypesAnnotationValues, contentType)) {
            if (compressionState == CompressionConfigState.ALWAYS &&
                    (acceptEncodingValue == null || HTTP_TRANSFER_ENCODING_IDENTITY.equals(acceptEncodingValue))) {
                outboundResponseMsg.getHeaders().set(HttpHeaderNames.CONTENT_ENCODING, ENCODING_GZIP);
            }
        } else {
            outboundResponseMsg.getHeaders().set(HttpHeaderNames.CONTENT_ENCODING, HTTP_TRANSFER_ENCODING_IDENTITY);
        }
    }

    public static CompressionConfigState getCompressionState(String compressionState) {
        switch (compressionState) {
            case AUTO:
                return CompressionConfigState.AUTO;
            case ALWAYS:
                return CompressionConfigState.ALWAYS;
            case NEVER:
                return CompressionConfigState.NEVER;
            default:
                return null;
        }
    }

    private static boolean isContentTypeMatched(List<String> contentTypes, String contentType) {
        return contentType != null && contentTypes.stream().anyMatch(
                contentType.toLowerCase(Locale.getDefault())::contains);
    }

    private static List<String> getAsStringList(Object[] values) {
        List<String> valuesList = new ArrayList<>();
        if (values == null) {
            return valuesList;
        }
        for (Object val : values) {
            valuesList.add(val.toString().trim().toLowerCase(Locale.getDefault()));
        }
        return valuesList;
    }

    public static String getListenerInterface(String host, int port) {
        host = host != null ? host : "0.0.0.0";
        return host + ":" + port;
    }

    public static ChunkConfig getChunkConfig(String chunkConfig) {
        switch (chunkConfig) {
            case HttpConstants.AUTO:
                return ChunkConfig.AUTO;
            case HttpConstants.ALWAYS:
                return ChunkConfig.ALWAYS;
            case NEVER:
                return ChunkConfig.NEVER;
            default:
                throw new BallerinaConnectorException(
                        "Invalid configuration found for Transfer-Encoding: " + chunkConfig);
        }
    }

    public static KeepAliveConfig getKeepAliveConfig(String keepAliveConfig) {
        switch (keepAliveConfig) {
            case HttpConstants.AUTO:
                return KeepAliveConfig.AUTO;
            case HttpConstants.ALWAYS:
                return KeepAliveConfig.ALWAYS;
            case NEVER:
                return KeepAliveConfig.NEVER;
            default:
                throw new BallerinaConnectorException(
                        "Invalid configuration found for Keep-Alive: " + keepAliveConfig);
        }
    }

    public static ForwardedExtensionConfig getForwardedExtensionConfig(String forwarded) {
        ForwardedExtensionConfig forwardedConfig;
        if (HttpConstants.FORWARDED_ENABLE.equalsIgnoreCase(forwarded)) {
            forwardedConfig = ForwardedExtensionConfig.ENABLE;
        } else if (HttpConstants.FORWARDED_TRANSITION.equalsIgnoreCase(forwarded)) {
            forwardedConfig = ForwardedExtensionConfig.TRANSITION;
        } else if (HttpConstants.FORWARDED_DISABLE.equalsIgnoreCase(forwarded)) {
            forwardedConfig = ForwardedExtensionConfig.DISABLE;
        } else {
            throw new BallerinaConnectorException("Invalid configuration found for Forwarded : " + forwarded);
        }
        return forwardedConfig;
    }

    public static HttpCarbonMessage createHttpCarbonMessage(boolean isRequest) {
        HttpCarbonMessage httpCarbonMessage;
        if (isRequest) {
            httpCarbonMessage = new HttpCarbonMessage(
                    new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.GET, ""));
        } else {
            httpCarbonMessage = new HttpCarbonMessage(
                    new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK));
        }
        httpCarbonMessage.completeMessage();
        return httpCarbonMessage;
    }

    public static void checkFunctionValidity(BObject connectionObj, HttpCarbonMessage reqMsg,
                                             HttpCarbonMessage outboundResponseMsg) {
        serverConnectionStructCheck(reqMsg);
        int statusCode = outboundResponseMsg.getHttpStatusCode();
        methodInvocationCheck(reqMsg, statusCode, ILLEGAL_FUNCTION_INVOKED);
    }

    static void methodInvocationCheck(HttpCarbonMessage reqMsg, int statusCode, String errMsg) {
        if (reqMsg == null || reqMsg.getProperty(METHOD_ACCESSED) != null) {
            throw createHttpError(errMsg, HttpErrorType.GENERIC_CLIENT_ERROR);
        }

        if (is100ContinueRequest(reqMsg, statusCode) || statusCode == HttpConstants.INVALID_STATUS_CODE) {
            return;
        }
        reqMsg.setProperty(METHOD_ACCESSED, true);
    }

    public static void serverConnectionStructCheck(HttpCarbonMessage reqMsg) {
        if (reqMsg == null) {
            throw createHttpError("operation not allowed:invalid Connection variable",
                    HttpErrorType.GENERIC_LISTENER_ERROR);
        }
    }

    private static boolean is100ContinueRequest(HttpCarbonMessage reqMsg, int statusCode) {
        return HttpConstants.HEADER_VAL_100_CONTINUE.equalsIgnoreCase(
                reqMsg.getHeader(HttpHeaderNames.EXPECT.toString())) || statusCode == 100;
    }

    public static BMap getTransactionConfigAnnotation(MethodType resource, String transactionPackagePath) {
        return (BMap) resource.getAnnotation(StringUtils.fromString(
                transactionPackagePath + ":" + TransactionConstants.ANN_NAME_TRX_PARTICIPANT_CONFIG));
    }

    private static int getIntValue(long val) {
        int intVal = (int) val;

        if (intVal != val) {
            throw new IllegalArgumentException("invalid argument: " + val);
        }

        return intVal;
    }

    public static String getContentTypeFromTransportMessage(HttpCarbonMessage transportMessage) {
        return transportMessage.getHeader(HttpHeaderNames.CONTENT_TYPE.toString());
    }

    /**
     * If the given Content-Type header value doesn't have a boundary parameter value, get a new boundary string and
     * append it to Content-Type and set it to transport message.
     *
     * @param transportMessage Represent transport message
     * @param contentType      Represent the Content-Type header value
     * @return The boundary string that was extracted from header or the newly generated one
     */
    public static String addBoundaryIfNotExist(HttpCarbonMessage transportMessage, String contentType) {
        String boundaryString;
        String boundaryValue = HeaderUtil.extractBoundaryParameter(contentType);
        boundaryString = boundaryValue != null ? boundaryValue : HttpUtil.addBoundaryParameter(transportMessage,
                                                                                               contentType);
        return boundaryString;
    }

    /**
     * Generate a new boundary string and append it Content-Type and set that to transport message.
     *
     * @param transportMessage Represent transport message
     * @param contentType      Represent the Content-Type header value
     * @return The newly generated boundary string
     */
    private static String addBoundaryParameter(HttpCarbonMessage transportMessage, String contentType) {
        String boundaryString = null;
        if (contentType != null && contentType.startsWith(MULTIPART_AS_PRIMARY_TYPE)) {
            boundaryString = MimeUtil.getNewMultipartDelimiter();
            transportMessage.setHeader(HttpHeaderNames.CONTENT_TYPE.toString(), contentType + "; " + BOUNDARY + "=" +
                    boundaryString);
        }
        return boundaryString;
    }

    public static HttpWsConnectorFactory createHttpWsConnectionFactory() {
        return DefaultHttpWsConnectorFactoryHolder.getHttpConnectorFactory();
    }

    public static void checkAndObserveHttpRequest(Environment environment, HttpCarbonMessage message) {
        ObserverContext observerContext = ObserveUtils.getObserverContextOfCurrentFrame(environment);

        if (observerContext != null) {
            HttpUtil.injectHeaders(message, ObserveUtils.getContextProperties(observerContext));
            observerContext.addTag(TAG_KEY_HTTP_METHOD, message.getHttpMethod());
            observerContext.addTag(TAG_KEY_HTTP_URL, String.valueOf(message.getProperty(HttpConstants.TO)));
            observerContext.addTag(TAG_KEY_PEER_ADDRESS,
                       message.getProperty(PROPERTY_HTTP_HOST) + ":" + message.getProperty(PROPERTY_HTTP_PORT));
            // Add HTTP Status Code tag. The HTTP status code will be set using the response message.
            // Sometimes the HTTP status code will not be set due to errors etc. Therefore, it's very important to set
            // some value to HTTP Status Code to make sure that tags will not change depending on various
            // circumstances.
            // HTTP Status code must be a number.
            observerContext.addProperty(PROPERTY_KEY_HTTP_STATUS_CODE, 0);
        }
    }

    public static void injectHeaders(HttpCarbonMessage msg, Map<String, String> headers) {
        if (headers != null) {
            headers.forEach((key, value) -> msg.setHeader(key, String.valueOf(value)));
        }
    }

    private static void setChunkingHeader(String transferValue, HttpCarbonMessage outboundResponseMsg) {
        if (transferValue == null) { //TODO check this logic - chamil
            return;
        }
        outboundResponseMsg.setProperty(CHUNKING_CONFIG, getChunkConfig(transferValue));
    }

    /**
     * Creates InResponse using the native {@code HttpCarbonMessage}.
     *
     * @param httpCarbonMessage the HttpCarbonMessage
     * @return the Response struct
     */
    public static BObject createResponseStruct(HttpCarbonMessage httpCarbonMessage) {
        BObject responseObj = ValueCreatorUtils.createResponseObject();
        BObject entity = ValueCreatorUtils.createEntityObject();

        HttpUtil.populateInboundResponse(responseObj, entity, httpCarbonMessage);
        return responseObj;
    }

    public static void populateSenderConfigurations(SenderConfiguration senderConfiguration,
            BMap<BString, Object> clientEndpointConfig, String scheme) {
        ProxyServerConfiguration proxyServerConfiguration;
        BMap<BString, Object> secureSocket = (BMap<BString, Object>) clientEndpointConfig
                .getMapValue(HttpConstants.ENDPOINT_CONFIG_SECURESOCKET);
        String httpVersion = clientEndpointConfig.getStringValue(HttpConstants.CLIENT_EP_HTTP_VERSION).getValue();
        if (secureSocket != null) {
            HttpUtil.populateSSLConfiguration(senderConfiguration, secureSocket);
        } else if (scheme.equals(PROTOCOL_HTTPS)) {
            if (httpVersion.equals(HTTP_2_0_VERSION)) {
                throw createHttpError("To enable https you need to configure secureSocket record",
                        HttpErrorType.SSL_ERROR);
            } else {
                senderConfiguration.useJavaDefaults();
            }
        }
        if (HTTP_1_1_VERSION.equals(httpVersion)) {
            BMap<BString, Object> http1Settings = (BMap<BString, Object>) clientEndpointConfig
                    .get(HttpConstants.HTTP1_SETTINGS);
            BMap proxy = http1Settings.getMapValue(HttpConstants.PROXY_STRUCT_REFERENCE);
            if (proxy != null) {
                String proxyHost = proxy.getStringValue(HttpConstants.PROXY_HOST).getValue();
                int proxyPort = proxy.getIntValue(HttpConstants.PROXY_PORT).intValue();
                String proxyUserName = proxy.getStringValue(HttpConstants.PROXY_USERNAME).getValue();
                String proxyPassword = proxy.getStringValue(HttpConstants.PROXY_PASSWORD).getValue();
                try {
                    proxyServerConfiguration = new ProxyServerConfiguration(proxyHost, proxyPort);
                } catch (UnknownHostException e) {
                    throw new BallerinaConnectorException("Failed to resolve host" + proxyHost, e);
                }
                if (!proxyUserName.isEmpty()) {
                    proxyServerConfiguration.setProxyUsername(proxyUserName);
                }
                if (!proxyPassword.isEmpty()) {
                    proxyServerConfiguration.setProxyPassword(proxyPassword);
                }
                senderConfiguration.setProxyServerConfiguration(proxyServerConfiguration);
            }
        }
        long timeoutMillis = clientEndpointConfig.getIntValue(HttpConstants.CLIENT_EP_ENDPOINT_TIMEOUT);
        if (timeoutMillis < 0) {
            senderConfiguration.setSocketIdleTimeout(0);
        } else {
            senderConfiguration.setSocketIdleTimeout(
                    validateConfig(timeoutMillis, HttpConstants.CLIENT_EP_ENDPOINT_TIMEOUT.getValue()));
        }
        if (httpVersion != null) {
            senderConfiguration.setHttpVersion(httpVersion);
        }
        String forwardedExtension = clientEndpointConfig.getStringValue(HttpConstants.CLIENT_EP_FORWARDED).getValue();
        senderConfiguration.setForwardedExtensionConfig(HttpUtil.getForwardedExtensionConfig(forwardedExtension));
    }

    public static ConnectionManager getConnectionManager(BMap<BString, Long> poolStruct) {
        ConnectionManager poolManager = (ConnectionManager) poolStruct.getNativeData(CONNECTION_MANAGER);
        if (poolManager == null) {
            synchronized (poolStruct) {
                if (poolStruct.getNativeData(CONNECTION_MANAGER) == null) {
                    PoolConfiguration userDefinedPool = new PoolConfiguration();
                    populatePoolingConfig(poolStruct, userDefinedPool);
                    poolManager = new ConnectionManager(userDefinedPool);
                    poolStruct.addNativeData(CONNECTION_MANAGER, poolManager);
                }
            }
        }
        return poolManager;
    }

    public static void populatePoolingConfig(BMap<BString, Long> poolRecord, PoolConfiguration poolConfiguration) {
        long maxActiveConnections = poolRecord.get(HttpConstants.CONNECTION_POOLING_MAX_ACTIVE_CONNECTIONS);
        poolConfiguration.setMaxActivePerPool(
                validateConfig(maxActiveConnections,
                               HttpConstants.CONNECTION_POOLING_MAX_ACTIVE_CONNECTIONS.getValue()));

        long maxIdleConnections = poolRecord.get(HttpConstants.CONNECTION_POOLING_MAX_IDLE_CONNECTIONS);
        poolConfiguration.setMaxIdlePerPool(
                validateConfig(maxIdleConnections, HttpConstants.CONNECTION_POOLING_MAX_IDLE_CONNECTIONS.getValue()));

        long waitTime = poolRecord.get(HttpConstants.CONNECTION_POOLING_WAIT_TIME);
        poolConfiguration.setMaxWaitTime(waitTime);

        long maxActiveStreamsPerConnection = poolRecord.get(CONNECTION_POOLING_MAX_ACTIVE_STREAMS_PER_CONNECTION);
        poolConfiguration.setHttp2MaxActiveStreamsPerConnection(
                maxActiveStreamsPerConnection == -1 ? Integer.MAX_VALUE : validateConfig(
                        maxActiveStreamsPerConnection,
                        CONNECTION_POOLING_MAX_ACTIVE_STREAMS_PER_CONNECTION.getValue()));
    }

    private static int validateConfig(long value, String configName) {
        try {
            return Math.toIntExact(value);
        } catch (ArithmeticException e) {
            log.warn("The value set for the configuration needs to be less than {}. The " + configName +
                             "value is set to {}", Integer.MAX_VALUE);
            return Integer.MAX_VALUE;
        }
    }

    /**
     * Populates SSL configuration instance with secure socket configuration.
     *
     * @param senderConfiguration SSL configuration instance.
     * @param secureSocket        Secure socket configuration.
     */
    public static void populateSSLConfiguration(SslConfiguration senderConfiguration,
                                                BMap<BString, Object> secureSocket) {
        List<Parameter> clientParamList = new ArrayList<>();
        boolean enable = secureSocket.getBooleanValue(SECURESOCKET_CONFIG_DISABLE_SSL);
        if (!enable) {
            senderConfiguration.disableSsl();
            return;
        }
        Object cert = secureSocket.get(SECURESOCKET_CONFIG_CERT);
        if (cert == null) {
            throw createHttpError("Need to configure 'crypto:TrustStore' or 'cert' with client SSL certificates file.",
                                  HttpErrorType.SSL_ERROR);
        }
        evaluateCertField(cert, senderConfiguration);
        BMap<BString, Object> key = getBMapValueIfPresent(secureSocket, SECURESOCKET_CONFIG_KEY);
        if (key != null) {
            evaluateKeyField(key, senderConfiguration);
        }
        BMap<BString, Object> protocol = getBMapValueIfPresent(secureSocket, SECURESOCKET_CONFIG_PROTOCOL);
        if (protocol != null) {
            evaluateProtocolField(protocol, senderConfiguration, clientParamList);
        }
        BMap<BString, Object> certValidation = getBMapValueIfPresent(secureSocket, SECURESOCKET_CONFIG_CERT_VALIDATION);
        if (certValidation != null) {
            evaluateCertValidationField(certValidation, senderConfiguration);
        }
        BArray ciphers = secureSocket.containsKey(SECURESOCKET_CONFIG_CIPHERS) ?
                secureSocket.getArrayValue(SECURESOCKET_CONFIG_CIPHERS) : null;
        if (ciphers != null) {
            evaluateCiphersField(ciphers, clientParamList);
        }
        evaluateCommonFields(secureSocket, senderConfiguration, clientParamList);

        if (!clientParamList.isEmpty()) {
            senderConfiguration.setParameters(clientParamList);
        }
    }

    public static String sanitizeBasePath(String basePath) {
        basePath = basePath.trim().replace(DOUBLE_SLASH, HttpConstants.SINGLE_SLASH);

        if (!basePath.startsWith(HttpConstants.DEFAULT_BASE_PATH)) {
            basePath = HttpConstants.DEFAULT_BASE_PATH.concat(basePath);
        }

        if ((basePath.endsWith(HttpConstants.DEFAULT_BASE_PATH) && basePath.length() != 1)) {
            basePath = basePath.substring(0, basePath.length() - 1);
        }

        if (basePath.endsWith("*")) {
            basePath = basePath.substring(0, basePath.length() - 1);
        }

        return basePath;
    }

    /**
     * Serialize outbound message.
     *
     * @param outboundMessageSource Represent the outbound message datasource
     * @param entity                Represent the entity of the outbound message
     * @param messageOutputStream   Represent the output stream
     * @throws IOException In case an error occurs while writing to output stream
     */
    public static void serializeDataSource(Object outboundMessageSource, BObject entity,
                                           OutputStream messageOutputStream) throws IOException {
        if (MimeUtil.generateAsJSON(outboundMessageSource, entity)) {
            JsonUtils.serialize(outboundMessageSource, messageOutputStream);
        } else {
            serialize(outboundMessageSource, messageOutputStream);
        }
    }

    public static void serialize(Object value, OutputStream outputStream) throws IOException {
        //TODO check the possibility of value being null
        if (value == null) {
            throw createHttpError("error occurred while serializing null data");
        } else if (value instanceof BArray) {
            if (value instanceof BStreamingJson) {
                ((BStreamingJson) value).serialize(outputStream);
            } else {
                ((BArray) value).serialize(outputStream);
            }
        } else if (value instanceof MultipartDataSource) {
            ((MultipartDataSource) value).serialize(outputStream);
        } else if (value instanceof BXmlItem) {
            ((BXmlItem) value).serialize(outputStream);
        } else if (value instanceof BXmlSequence) {
            ((BXmlSequence) value).serialize(outputStream);
        } else if (value instanceof Long || value instanceof String || value instanceof BDecimal ||
                value instanceof Double || value instanceof Integer || value instanceof Boolean) {
            outputStream.write(value.toString().getBytes(Charset.defaultCharset()));
        } else if (value instanceof BString) {
            outputStream.write(((BString) value).getValue().getBytes(Charset.defaultCharset()));
        } else {
            ((BRefValue) value).serialize(outputStream);
        }
    }

    /**
     * Check the availability of an annotation.
     *
     * @param configAnnotation      Represent the annotation
     * @return True if the annotation and the annotation value are available
     */
    public static boolean checkConfigAnnotationAvailability(BMap configAnnotation) {
        return configAnnotation != null;
    }

    /**
     * Returns Listener configuration instance populated with endpoint config.
     *
     * @param port              listener port.
     * @param endpointConfig    listener endpoint configuration.
     * @return                  transport listener configuration instance.
     */
    public static ListenerConfiguration getListenerConfig(long port, BMap endpointConfig) {
        String host = endpointConfig.getStringValue(HttpConstants.ENDPOINT_CONFIG_HOST).getValue();
        BMap<BString, Object> sslConfig = endpointConfig.getMapValue(HttpConstants.ENDPOINT_CONFIG_SECURESOCKET);
        String httpVersion = endpointConfig.getStringValue(HttpConstants.ENDPOINT_CONFIG_VERSION).getValue();
        long idleTimeout = endpointConfig.getIntValue(HttpConstants.ENDPOINT_CONFIG_TIMEOUT);

        ListenerConfiguration listenerConfiguration = new ListenerConfiguration();
        if (HTTP_1_1_VERSION.equals(httpVersion)) {
            BMap<BString, Object> http1Settings =
                    (BMap<BString, Object>) endpointConfig.get(HttpConstants.HTTP1_SETTINGS);
            listenerConfiguration.setPipeliningLimit(http1Settings.getIntValue(HttpConstants.PIPELINING_REQUEST_LIMIT));
            String keepAlive = http1Settings.getStringValue(HttpConstants.ENDPOINT_CONFIG_KEEP_ALIVE).getValue();
            listenerConfiguration.setKeepAliveConfig(HttpUtil.getKeepAliveConfig(keepAlive));
        }

        // Set Request validation limits.
        BMap<BString, Object> requestLimits =
                (BMap<BString, Object>) endpointConfig.getMapValue(HttpConstants.REQUEST_LIMITS);
        setInboundMgsSizeValidationConfig(requestLimits.getIntValue(HttpConstants.MAX_URI_LENGTH),
                                          requestLimits.getIntValue(HttpConstants.MAX_HEADER_SIZE),
                                          requestLimits.getIntValue(HttpConstants.MAX_ENTITY_BODY_SIZE),
                                          listenerConfiguration.getMsgSizeValidationConfig());

        if (host == null || host.trim().isEmpty()) {
            listenerConfiguration.setHost(ConfigRegistry.getInstance().getConfigOrDefault("b7a.http.host",
                    HttpConstants.HTTP_DEFAULT_HOST));
        } else {
            listenerConfiguration.setHost(host);
        }

        if (port == 0) {
            throw new BallerinaConnectorException("Listener port is not defined!");
        }
        listenerConfiguration.setPort(Math.toIntExact(port));

        if (idleTimeout < 0) {
            throw new BallerinaConnectorException("Idle timeout cannot be negative. If you want to disable the " +
                    "timeout please use value 0");
        }
        listenerConfiguration.setSocketIdleTimeout(Math.toIntExact(idleTimeout));

        // Set HTTP version
        if (httpVersion != null) {
            listenerConfiguration.setVersion(httpVersion);
        }

        if (endpointConfig.getType().getName().equalsIgnoreCase(LISTENER_CONFIGURATION)) {
            BString serverName = endpointConfig.getStringValue(SERVER_NAME);
            listenerConfiguration.setServerHeader(serverName != null ? serverName.getValue() : getServerName());
        } else {
            listenerConfiguration.setServerHeader(getServerName());
        }

        if (sslConfig != null) {
            return setSslConfig(sslConfig, listenerConfiguration);
        }

        listenerConfiguration.setPipeliningEnabled(true); //Pipelining is enabled all the time
        Object webSocketCompressionEnabled = endpointConfig.get(WebSocketConstants.COMPRESSION_ENABLED_CONFIG);
        if (webSocketCompressionEnabled != null) {
            listenerConfiguration.setWebSocketCompressionEnabled((Boolean) webSocketCompressionEnabled);
        }

        return listenerConfiguration;
    }

    public static void setInboundMgsSizeValidationConfig(long maxInitialLineLength, long maxHeaderSize,
                                                         long maxEntityBodySize,
                                                         InboundMsgSizeValidationConfig sizeValidationConfig) {
        if (maxInitialLineLength >= 0) {
            sizeValidationConfig.setMaxInitialLineLength(Math.toIntExact(maxInitialLineLength));
        } else {
            throw new BallerinaConnectorException(
                    "Invalid configuration found for max initial line length : " + maxInitialLineLength);
        }

        if (maxHeaderSize >= 0) {
            sizeValidationConfig.setMaxHeaderSize(Math.toIntExact(maxHeaderSize));
        } else {
            throw new BallerinaConnectorException("Invalid configuration found for maxHeaderSize : " + maxHeaderSize);
        }

        if (maxEntityBodySize != -1) {
            if (maxEntityBodySize >= 0) {
                sizeValidationConfig.setMaxEntityBodySize(maxEntityBodySize);
            } else {
                throw new BallerinaConnectorException(
                        "Invalid configuration found for maxEntityBodySize : " + maxEntityBodySize);
            }
        }
    }

    private static String getServerName() {
        String userAgent;
        String version = System.getProperty(BALLERINA_VERSION);
        if (version != null) {
            userAgent = "ballerina/" + version;
        } else {
            userAgent = "ballerina";
        }
        return userAgent;
    }

    private static ListenerConfiguration setSslConfig(BMap<BString, Object> secureSocket,
                                                      ListenerConfiguration listenerConfiguration) {
        List<Parameter> serverParamList = new ArrayList<>();
        listenerConfiguration.setScheme(PROTOCOL_HTTPS);
        BMap<BString, Object> key = getBMapValueIfPresent(secureSocket, SECURESOCKET_CONFIG_KEY);
        assert key != null; // This validation happens at Ballerina level
        evaluateKeyField(key, listenerConfiguration);
        BMap<BString, Object> mutualSsl = getBMapValueIfPresent(secureSocket, SECURESOCKET_CONFIG_MUTUAL_SSL);
        if (mutualSsl != null) {
            String verifyClient = mutualSsl.getStringValue(SECURESOCKET_CONFIG_VERIFY_CLIENT).getValue();
            listenerConfiguration.setVerifyClient(verifyClient);
            Object cert = mutualSsl.get(SECURESOCKET_CONFIG_CERT);
            evaluateCertField(cert, listenerConfiguration);
        }
        BMap<BString, Object> protocol = getBMapValueIfPresent(secureSocket, SECURESOCKET_CONFIG_PROTOCOL);
        if (protocol != null) {
            evaluateProtocolField(protocol, listenerConfiguration, serverParamList);
        }
        BMap<BString, Object> certValidation = getBMapValueIfPresent(secureSocket, SECURESOCKET_CONFIG_CERT_VALIDATION);
        if (certValidation != null) {
            evaluateCertValidationField(certValidation, listenerConfiguration);
        }
        BArray ciphers = secureSocket.containsKey(SECURESOCKET_CONFIG_CIPHERS) ?
                secureSocket.getArrayValue(SECURESOCKET_CONFIG_CIPHERS) : null;
        if (ciphers != null) {
            evaluateCiphersField(ciphers, serverParamList);
        }
        evaluateCommonFields(secureSocket, listenerConfiguration, serverParamList);

        listenerConfiguration.setTLSStoreType(PKCS_STORE_TYPE);
        if (!serverParamList.isEmpty()) {
            listenerConfiguration.setParameters(serverParamList);
        }
        listenerConfiguration.setId(HttpUtil.getListenerInterface(listenerConfiguration.getHost(),
                                                                  listenerConfiguration.getPort()));
        return listenerConfiguration;
    }

    private static void evaluateKeyField(BMap<BString, Object> key, SslConfiguration sslConfiguration) {
        if (key.containsKey(SECURESOCKET_CONFIG_KEYSTORE_FILE_PATH)) {
            String keyStoreFile = key.getStringValue(SECURESOCKET_CONFIG_KEYSTORE_FILE_PATH).getValue();
            if (keyStoreFile.isBlank()) {
                throw createHttpError("KeyStore file location must be provided for secure connection.",
                                      HttpErrorType.SSL_ERROR);
            }
            String keyStorePassword = key.getStringValue(SECURESOCKET_CONFIG_KEYSTORE_PASSWORD).getValue();
            if (keyStorePassword.isBlank()) {
                throw createHttpError("KeyStore password must be provided for secure connection.",
                                      HttpErrorType.SSL_ERROR);
            }
            sslConfiguration.setKeyStoreFile(keyStoreFile);
            sslConfiguration.setKeyStorePass(keyStorePassword);
        } else {
            String certFile = key.getStringValue(SECURESOCKET_CONFIG_CERTKEY_CERT_FILE).getValue();
            String keyFile = key.getStringValue(SECURESOCKET_CONFIG_CERTKEY_KEY_FILE).getValue();
            BString keyPassword = key.containsKey(SECURESOCKET_CONFIG_CERTKEY_KEY_PASSWORD) ?
                    key.getStringValue(SECURESOCKET_CONFIG_CERTKEY_KEY_PASSWORD) : null;
             if (certFile.isBlank()) {
                throw createHttpError("Certificate file location must be provided for secure connection.",
                                      HttpErrorType.SSL_ERROR);
            }
            if (keyFile.isBlank()) {
                throw createHttpError("Private key file location must be provided for secure connection.",
                                      HttpErrorType.SSL_ERROR);
            }
            if (sslConfiguration instanceof ListenerConfiguration) {
                sslConfiguration.setServerCertificates(certFile);
                sslConfiguration.setServerKeyFile(keyFile);
                if (keyPassword != null && !keyPassword.getValue().isBlank()) {
                    sslConfiguration.setServerKeyPassword(keyPassword.getValue());
                }
            } else {
                sslConfiguration.setClientCertificates(certFile);
                sslConfiguration.setClientKeyFile(keyFile);
                if (keyPassword != null && !keyPassword.getValue().isBlank()) {
                    sslConfiguration.setClientKeyPassword(keyPassword.getValue());
                }
            }
        }
    }

    private static void evaluateCertField(Object cert, SslConfiguration sslConfiguration) {
        if (cert instanceof BMap) {
            BMap<BString, BString> trustStore = (BMap<BString, BString>) cert;
            String trustStoreFile = trustStore.getStringValue(SECURESOCKET_CONFIG_TRUSTSTORE_FILE_PATH).getValue();
            String trustStorePassword = trustStore.getStringValue(SECURESOCKET_CONFIG_TRUSTSTORE_PASSWORD).getValue();
            if (trustStoreFile.isBlank()) {
                throw createHttpError("TrustStore file location must be provided for secure connection.",
                                      HttpErrorType.SSL_ERROR);
            }
            if (trustStorePassword.isBlank()) {
                throw createHttpError("TrustStore password must be provided for secure connection.",
                                      HttpErrorType.SSL_ERROR);
            }
            sslConfiguration.setTrustStoreFile(trustStoreFile);
            sslConfiguration.setTrustStorePass(trustStorePassword);
        } else {
            String certFile = ((BString) cert).getValue();
            if (certFile.isBlank()) {
                throw createHttpError("Certificate file location must be provided for secure connection.",
                                      HttpErrorType.SSL_ERROR);
            }
            if (sslConfiguration instanceof ListenerConfiguration) {
                sslConfiguration.setServerTrustCertificates(certFile);
            } else {
                sslConfiguration.setClientTrustCertificates(certFile);
            }
        }
    }

    private static void evaluateProtocolField(BMap<BString, Object> protocol,
                                              SslConfiguration sslConfiguration,
                                              List<Parameter> paramList) {
        List<String> sslEnabledProtocolsValueList = Arrays.asList(
                protocol.getArrayValue(SECURESOCKET_CONFIG_PROTOCOL_VERSIONS).getStringArray());
        if (!sslEnabledProtocolsValueList.isEmpty()) {
            String sslEnabledProtocols = sslEnabledProtocolsValueList.stream().collect(Collectors.joining(",", "", ""));
            Parameter serverProtocols = new Parameter(ANN_CONFIG_ATTR_SSL_ENABLED_PROTOCOLS, sslEnabledProtocols);
            paramList.add(serverProtocols);
        }
        String sslProtocol = protocol.getStringValue(SECURESOCKET_CONFIG_PROTOCOL_NAME).getValue();
        if (!sslProtocol.isBlank()) {
            sslConfiguration.setSSLProtocol(sslProtocol);
        }
    }

    private static void evaluateCertValidationField(BMap<BString, Object> certValidation,
                                                    SslConfiguration sslConfiguration) {
        String type = certValidation.getStringValue(SECURESOCKET_CONFIG_CERT_VALIDATION_TYPE).getValue();
        if (type.equals(SECURESOCKET_CONFIG_CERT_VALIDATION_TYPE_OCSP_STAPLING.getValue())) {
            sslConfiguration.setOcspStaplingEnabled(true);
        } else {
            sslConfiguration.setValidateCertEnabled(true);
        }
        long cacheSize = certValidation.getIntValue(SECURESOCKET_CONFIG_CERT_VALIDATION_CACHE_SIZE).intValue();
        long cacheValidityPeriod = ((BDecimal) certValidation.get(
                SECURESOCKET_CONFIG_CERT_VALIDATION_CACHE_VALIDITY_PERIOD)).intValue();
        if (cacheValidityPeriod != 0) {
            sslConfiguration.setCacheValidityPeriod(Math.toIntExact(cacheValidityPeriod));
        }
        if (cacheSize != 0) {
            sslConfiguration.setCacheSize(Math.toIntExact(cacheSize));
        }
    }

    private static void evaluateCiphersField(BArray ciphers, List<Parameter> paramList) {
        Object[] ciphersArray = ciphers.getStringArray();
        List<Object> ciphersList = Arrays.asList(ciphersArray);
        if (ciphersList.size() > 0) {
            String ciphersString = ciphersList.stream().map(Object::toString).collect(Collectors.joining(",", "", ""));
            Parameter serverParameters = new Parameter(HttpConstants.CIPHERS, ciphersString);
            paramList.add(serverParameters);
        }
    }

    private static void evaluateCommonFields(BMap<BString, Object> secureSocket, SslConfiguration sslConfiguration,
                                             List<Parameter> paramList) {
        if (!(sslConfiguration instanceof ListenerConfiguration)) {
            boolean hostNameVerificationEnabled = secureSocket.getBooleanValue(
                    SECURESOCKET_CONFIG_HOST_NAME_VERIFICATION_ENABLED);
            sslConfiguration.setHostNameVerificationEnabled(hostNameVerificationEnabled);
        }
        sslConfiguration.setSslSessionTimeOut((int) getLongValueOrDefault(secureSocket,
                                                                          SECURESOCKET_CONFIG_SESSION_TIMEOUT));
        sslConfiguration.setSslHandshakeTimeOut(getLongValueOrDefault(secureSocket,
                                                                      SECURESOCKET_CONFIG_HANDSHAKE_TIMEOUT));
        String enableSessionCreation = String.valueOf(secureSocket.getBooleanValue(SECURESOCKET_CONFIG_SHARE_SESSION));
        Parameter enableSessionCreationParam = new Parameter(SECURESOCKET_CONFIG_SHARE_SESSION.getValue(),
                                                             enableSessionCreation);
        paramList.add(enableSessionCreationParam);
    }

    private static BMap<BString, Object> getBMapValueIfPresent(BMap<BString, Object> map, BString key) {
        return map.containsKey(key) ? (BMap<BString, Object>) map.getMapValue(key) : null;
    }

    private static long getLongValueOrDefault(BMap<BString, Object> map, BString key) {
        return map.containsKey(key) ? ((BDecimal) map.get(key)).intValue() : 0L;
    }

    public static String getServiceName(BObject balService) {
        String serviceTypeName = balService.getType().getName();
        int serviceIndex = serviceTypeName.lastIndexOf("$$service$");
        return serviceTypeName.substring(0, serviceIndex);
    }

    /**
     * This method will remove the escape character "\" from a string and encode it. This is used for both basePath and
     * resource path sanitization. When the special chars are present in those paths, user can escape them in order to
     * get through the compilation phrase. Then listener sanitize and register paths in both basePath map and resource
     * syntax tree using encoded values as during the dispatching, the path matches with raw path.
     *
     * @param segment path segment
     * @return encoded value
     */
    public static String unescapeAndEncodeValue(String segment) {
        if (!segment.contains("\\")) {
            return segment;
        }
        return encodeString(segment.replace("\\", ""));
    }

    public static String encodeString(String value) {
        try {
            return URLEncoder.encode(value, StandardCharsets.UTF_8.name()).replaceAll("\\+", "%20");
        } catch (UnsupportedEncodingException e) {
            throw new BallerinaConnectorException("Error while encoding value: " + value, e);
        }
    }

    private HttpUtil() {
    }
}
