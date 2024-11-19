/*
 * Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.api.client.actions;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.PredefinedTypes;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.observability.ObservabilityConstants;
import io.ballerina.runtime.observability.ObserveUtils;
import io.ballerina.runtime.observability.ObserverContext;
import io.ballerina.runtime.transactions.TransactionConstants;
import io.ballerina.runtime.transactions.TransactionLocalContext;
import io.ballerina.runtime.transactions.TransactionResourceManager;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;
import io.ballerina.stdlib.http.api.CompressionConfigState;
import io.ballerina.stdlib.http.api.DataContext;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ClientConnectorException;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.ballerina.stdlib.http.transport.message.PooledDataStreamerFactory;
import io.ballerina.stdlib.http.transport.message.ResponseHandle;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;
import io.ballerina.stdlib.mime.util.HeaderUtil;
import io.ballerina.stdlib.mime.util.MultipartDataSource;
import io.netty.handler.codec.EncoderException;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaders;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.OutputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Objects;

import static io.ballerina.runtime.api.constants.RuntimeConstants.BALLERINA_VERSION;
import static io.ballerina.stdlib.http.api.HttpConstants.ANN_CONFIG_ATTR_COMPRESSION;
import static io.ballerina.stdlib.http.api.HttpConstants.SET_HOST_HEADER;
import static io.ballerina.stdlib.http.api.HttpUtil.extractEntity;
import static io.ballerina.stdlib.http.api.HttpUtil.getCompressionState;
import static io.ballerina.stdlib.http.transport.contract.Constants.ENCODING_DEFLATE;
import static io.ballerina.stdlib.http.transport.contract.Constants.ENCODING_GZIP;
import static io.netty.handler.codec.http.HttpHeaderNames.ACCEPT_ENCODING;

/**
 * {@code AbstractHTTPAction} is the base class for all HTTP Connector Actions.
 */
public abstract class AbstractHTTPAction {

    private static final Logger logger = LoggerFactory.getLogger(AbstractHTTPAction.class);

    private static final String CACHE_BALLERINA_VERSION;
    private static final String WHITESPACE = " ";
    static {
        CACHE_BALLERINA_VERSION = System.getProperty(BALLERINA_VERSION);
    }

    protected static HttpCarbonMessage createOutboundRequestMsg(String serviceUri, BMap config, String path,
                                                                BObject request) {
        HttpCarbonMessage requestMsg = HttpUtil.getCarbonMsg(request, HttpUtil.createHttpCarbonMessage(true));
        HttpUtil.checkEntityAvailability(request);
        HttpUtil.enrichOutboundMessage(requestMsg, request);
        prepareOutboundRequest(serviceUri, path, requestMsg, isNoEntityBodyRequest(request), isHostHeaderSet(request));
        handleAcceptEncodingHeader(requestMsg, getCompressionConfigFromEndpointConfig(config));
        return requestMsg;
    }

    static String getCompressionConfigFromEndpointConfig(BMap clientEndpointConfig) {
        return clientEndpointConfig.get(ANN_CONFIG_ATTR_COMPRESSION).toString();
    }

    static void handleAcceptEncodingHeader(HttpCarbonMessage outboundRequest, String compressionConfigValue) {
        CompressionConfigState compressionState = getCompressionState(compressionConfigValue);

        if (compressionState == CompressionConfigState.ALWAYS && (outboundRequest.getHeader(
                ACCEPT_ENCODING.toString()) == null)) {
            outboundRequest.setHeader(ACCEPT_ENCODING.toString(), ENCODING_DEFLATE + ", " + ENCODING_GZIP);
        } else if (compressionState == CompressionConfigState.NEVER && (outboundRequest.getHeader(
                ACCEPT_ENCODING.toString()) != null)) {
            outboundRequest.removeHeader(ACCEPT_ENCODING.toString());
        }
    }

    static void prepareOutboundRequest(String serviceUri, String path, HttpCarbonMessage outboundRequest,
                                       Boolean nonEntityBodyReq, Boolean isHostHeaderSet) {
        TransactionResourceManager trxResourceManager = TransactionResourceManager.getInstance();
        if (trxResourceManager.isInTransaction()) {
            TransactionLocalContext transactionLocalContext = trxResourceManager.getCurrentTransactionContext();
            outboundRequest.setHeader(HttpConstants.HEADER_X_XID, transactionLocalContext.getGlobalTransactionId());
            outboundRequest.setHeader(HttpConstants.HEADER_X_REGISTER_AT_URL, transactionLocalContext.getURL());
            outboundRequest.setHeader(HttpConstants.HEADER_X_INFO_RECORD,
                    getTrxInfoRecordJson(transactionLocalContext.getInfoRecord()));
        }
        try {
            String uri = getServiceUri(serviceUri) + path;
            URL url = new URL(encodeWhitespacesInUri(uri));

            int port = getOutboundReqPort(url);
            String host = url.getHost();

            setOutboundReqProperties(outboundRequest, url, port, host, nonEntityBodyReq);
            setOutboundReqHeaders(outboundRequest, port, host, isHostHeaderSet);

        } catch (MalformedURLException e) {
            throw HttpUtil.createHttpError("malformed URL specified. " + e.getMessage(),
                                           HttpErrorType.GENERIC_CLIENT_ERROR);
        } catch (Exception e) {
            throw HttpUtil.createHttpError("failed to prepare request. " + e.getMessage(),
                                           HttpErrorType.GENERIC_CLIENT_ERROR);
        }
    }

    private static String getServiceUri(String serviceUri) {
        if (serviceUri.isEmpty()) {
            throw HttpUtil.createHttpError("service URI is not defined correctly.", HttpErrorType.GENERIC_CLIENT_ERROR);
        }
        return serviceUri;
    }

    private static String encodeWhitespacesInUri(String uri) {
        if (!uri.contains(WHITESPACE)) {
            return uri;
        }
        // Uses Percent-Encoding as defined in spec(https://tools.ietf.org/html/rfc3986#section-2.1)
        return uri.trim().replaceAll(WHITESPACE, "%20");
    }

    private static void setOutboundReqHeaders(HttpCarbonMessage outboundRequest, int port, String host,
                                              Boolean isHostHeaderSet) {
        HttpHeaders headers = outboundRequest.getHeaders();
        setHostHeader(host, port, headers, isHostHeaderSet);
        setOutboundUserAgent(headers);
        removeConnectionHeader(headers);
    }

    private static void setOutboundReqProperties(HttpCarbonMessage outboundRequest, URL url, int port, String host,
                                                 Boolean nonEntityBodyReq) {
        outboundRequest.setProperty(Constants.HTTP_HOST, host);
        outboundRequest.setProperty(Constants.HTTP_PORT, port);

        String outboundReqPath = getOutboundReqPath(url);
        outboundRequest.setProperty(HttpConstants.TO, outboundReqPath);

        outboundRequest.setProperty(HttpConstants.PROTOCOL, url.getProtocol());
        outboundRequest.setProperty(HttpConstants.NO_ENTITY_BODY, nonEntityBodyReq);
    }

    private static String getTrxInfoRecordJson(Object infoRecord) {
        if (infoRecord != null) {
            ArrayType mapArrType = TypeCreator.createArrayType(PredefinedTypes.TYPE_MAP);
            BArray mapArr = ValueCreator.createArrayValue(mapArrType);
            return populateTrxInfoJson((BMap<String, Object>) infoRecord, mapArr, 0);
        }
        return "";
    }

    private static String populateTrxInfoJson(BMap<String, Object> infoMap, BArray jsonArray, int i) {
        BMap<BString, Object> subMap = ValueCreator.createMapValue();
        byte[] globalTransactionId = ((BArray) infoMap.get(TransactionConstants.GLOBAL_TRX_ID)).getByteArray();
        int retryNumber = ((Number) infoMap.get(TransactionConstants.RETRY_NUMBER)).intValue();
        int startTime = getStartTime((BObject) infoMap.get(TransactionConstants.START_TIME));
        subMap.put(TransactionConstants.GLOBAL_TRX_ID, StringUtils
                .fromString(new String(globalTransactionId, StandardCharsets.UTF_8)));
        subMap.put(TransactionConstants.RETRY_NUMBER, StringUtils.fromString(String.valueOf(retryNumber)));
        subMap.put(TransactionConstants.START_TIME, StringUtils.fromString(String.valueOf(startTime)));
        jsonArray.add(i++, subMap);
        if (retryNumber > 0) {
            Object prevInfoRecord = infoMap.get(TransactionConstants.PREVIOUS_ATTEMPT);
            if (prevInfoRecord != null) {
                populateTrxInfoJson((BMap<String, Object>) prevInfoRecord, jsonArray, i);
            }
        }
        return StringUtils.getJsonString(jsonArray);
    }

    private static int getStartTime(BObject timestamp) {
        if (timestamp != null) {
            return ((Number) timestamp.getNativeData(TransactionConstants.TIMESTAMP_OBJECT_VALUE_FIELD)).intValue();
        }
        return 0;
    }

    private static void setHostHeader(String host, int port, HttpHeaders headers, Boolean isHostHeaderSet) {
        if (isHostHeaderSet && headers.contains(HttpHeaderNames.HOST)) {
            return;
        }
        if (port == 80 || port == 443) {
            headers.set(HttpHeaderNames.HOST, host);
        } else {
            headers.set(HttpHeaderNames.HOST, host + ":" + port);
        }
    }

    private static void removeConnectionHeader(HttpHeaders headers) {
        // Remove existing Connection header
        if (headers.contains(HttpHeaderNames.CONNECTION)) {
            headers.remove(HttpHeaderNames.CONNECTION);
        }
    }

    private static void setOutboundUserAgent(HttpHeaders headers) {
        String userAgent;
        if (CACHE_BALLERINA_VERSION != null) {
            userAgent = "ballerina/" + CACHE_BALLERINA_VERSION;
        } else {
            userAgent = "ballerina";
        }

        if (!headers.contains(HttpHeaderNames.USER_AGENT)) { // If User-Agent is not already set from program
            headers.set(HttpHeaderNames.USER_AGENT, userAgent);
        }
    }

    private static String getOutboundReqPath(URL url) {
        String toPath = url.getPath();
        String query = url.getQuery();
        if (query != null) {
            toPath = toPath + "?" + query;
        }
        return toPath;
    }

    private static int getOutboundReqPort(URL url) {
        int port = 80;
        if (url.getPort() != -1) {
            port = url.getPort();
        } else if (url.getProtocol().equalsIgnoreCase(HttpConstants.PROTOCOL_HTTPS)) {
            port = 443;
        }
        return port;
    }

    protected static void executeNonBlockingAction(DataContext dataContext, boolean async) {
        HttpCarbonMessage outboundRequestMsg = dataContext.getOutboundRequest();

        //Make the request associate with this response consumable again so that it can be reused.
        checkDirtiness(dataContext, outboundRequestMsg);

        Object sourceHandler = outboundRequestMsg.getProperty(HttpConstants.SRC_HANDLER);
        if (sourceHandler == null) {

            outboundRequestMsg.setProperty(HttpConstants.SRC_HANDLER,
                    dataContext.getEnvironment().getStrandLocal(HttpConstants.SRC_HANDLER));
        }

        Object poolableByteBufferFactory = outboundRequestMsg.getProperty(HttpConstants.POOLED_BYTE_BUFFER_FACTORY);
        if (poolableByteBufferFactory == null) {
            outboundRequestMsg.setProperty(HttpConstants.POOLED_BYTE_BUFFER_FACTORY,
                    dataContext.getEnvironment().getStrandLocal(HttpConstants.POOLED_BYTE_BUFFER_FACTORY));
        }
        Object remoteAddress = outboundRequestMsg.getProperty(HttpConstants.REMOTE_ADDRESS);
        if (remoteAddress == null) {
            outboundRequestMsg.setProperty(HttpConstants.REMOTE_ADDRESS,
                    dataContext.getEnvironment().getStrandLocal(HttpConstants.REMOTE_ADDRESS));
        }
        outboundRequestMsg.setProperty(HttpConstants.ORIGIN_HOST,
                dataContext.getEnvironment().getStrandLocal(HttpConstants.ORIGIN_HOST));
        outboundRequestMsg.setProperty(HttpConstants.INBOUND_MESSAGE,
                dataContext.getEnvironment().getStrandLocal(HttpConstants.INBOUND_MESSAGE));
        sendOutboundRequest(dataContext, outboundRequestMsg, async);
    }

    private static void checkDirtiness(DataContext dataContext, HttpCarbonMessage outboundRequestMsg) {
        BObject requestObj = dataContext.getRequestObj();
        String contentType = HttpUtil.getContentTypeFromTransportMessage(outboundRequestMsg);
        outboundRequestMsg.setIoException(null);
        if (requestObj != null) {
            if (dirty(requestObj)) {
                cleanOutboundReq(outboundRequestMsg, requestObj, contentType);
            } else {
                requestObj.set(HttpConstants.REQUEST_REUSE_STATUS_FIELD, HttpConstants.DIRTY_REQUEST);
            }
        }
    }

    private static void cleanOutboundReq(HttpCarbonMessage outboundRequestMsg, BObject request,
                                         String contentType) {
        BObject entity = extractEntity(request);
        if (entity != null) {
            Object messageDataSource = EntityBodyHandler.getMessageDataSource(entity);
            if (messageDataSource == null && EntityBodyHandler.getByteChannel(entity) == null
                    && !HeaderUtil.isMultipart(contentType)) {
                outboundRequestMsg.addHttpContent(new DefaultLastHttpContent());
            } else {
                outboundRequestMsg.waitAndReleaseAllEntities();
            }
        } else {
            outboundRequestMsg.addHttpContent(new DefaultLastHttpContent());
        }
    }

    static boolean isNoEntityBodyRequest(BObject request) {
        return (Boolean) request.get(HttpConstants.REQUEST_NO_ENTITY_BODY_FIELD);
    }

    static boolean isHostHeaderSet(BObject request) {
        return Objects.nonNull(request.getNativeData(SET_HOST_HEADER));
    }

    private static boolean dirty(BObject request) {
        return (Boolean) request.get(HttpConstants.REQUEST_REUSE_STATUS_FIELD);
    }

    private static void sendOutboundRequest(DataContext dataContext, HttpCarbonMessage outboundRequestMsg,
                                            boolean async) {
        try {
            send(dataContext, outboundRequestMsg, async);
        } catch (BallerinaConnectorException e) {
            dataContext.notifyInboundResponseStatus(null, HttpUtil.createHttpError(e.getMessage()));
        } catch (Exception e) {
            BallerinaConnectorException exception =
                    new BallerinaConnectorException("Failed to send outboundRequestMsg to the backend", e);
            dataContext.notifyInboundResponseStatus(null, HttpUtil.getError(exception));
        }
    }

    /**
     * Send outbound request through the client connector. If the Content-Type is multipart, check whether the boundary
     * exist. If not get a new boundary string and add it as a parameter to Content-Type, just before sending header
     * info through wire. If a boundary string exist at this point, serialize multipart entity body, else serialize
     * entity body which can either be a message data source or a byte channel.
     *
     * @param dataContext        holds the ballerina context and callback
     * @param outboundRequestMsg Outbound request that needs to be sent across the wire
     * @param async              whether a handle should be return
     */
    private static void send(DataContext dataContext, HttpCarbonMessage outboundRequestMsg, boolean async) {
        HttpClientConnector clientConnector = dataContext.getClientConnector();
        String contentType = HttpUtil.getContentTypeFromTransportMessage(outboundRequestMsg);
        String boundaryString = null;

        if (HeaderUtil.isMultipart(contentType)) {
            boundaryString = HttpUtil.addBoundaryIfNotExist(outboundRequestMsg, contentType);
        }

        HttpUtil.checkAndObserveHttpRequest(dataContext.getEnvironment(), outboundRequestMsg);

        final HTTPClientConnectorListener httpClientConnectorLister = ObserveUtils.isObservabilityEnabled() ?
                new ObservableHttpClientConnectorListener(dataContext) :
                new HTTPClientConnectorListener(dataContext);

        final HttpMessageDataStreamer outboundMsgDataStreamer = getHttpMessageDataStreamer(outboundRequestMsg);
        final OutputStream messageOutputStream = outboundMsgDataStreamer.getOutputStream();
        BObject requestObj = dataContext.getRequestObj();
        BObject entityObj = null;
        if (requestObj != null) {
            entityObj = extractEntity(requestObj);
            if (entityObj == null) {
                //This is reached when it is a passthrough scenario(the body has not been built) or when the
                // entity body is empty/null. It is not possible to differentiate the two scenarios in Ballerina,
                // hence the value for passthrough is set to be true for both cases because transport side will
                // interpret this value only when there is an unbuilt body in carbon message.
                outboundRequestMsg.setPassthrough(true);
            }
        }

        HttpResponseFuture future = clientConnector.send(outboundRequestMsg);
        if (async) {
            future.setResponseHandleListener(httpClientConnectorLister);
        } else {
            future.setHttpConnectorListener(httpClientConnectorLister);
        }
        try {
            if (entityObj != null) {
                if (boundaryString != null) {
                    serializeMultiparts(dataContext.getEnvironment(), entityObj, messageOutputStream, boundaryString);
                } else {
                    serializeDataSource(dataContext.getEnvironment(), entityObj, messageOutputStream);
                }
            }
        } catch (IOException | EncoderException serializerException) {
            // We don't have to do anything here as the client connector will notify the error though the listener
            logger.warn("couldn't serialize the message", serializerException);
        } catch (RuntimeException exception) {
            if (exception.getMessage() != null &&
                    exception.getMessage().contains(Constants.INBOUND_RESPONSE_ALREADY_RECEIVED)) {
                logger.warn("Response already received before completing the outbound request", exception);
            } else {
                throw HttpUtil.createHttpError(exception.getMessage(), HttpErrorType.GENERIC_CLIENT_ERROR);
            }
        }
    }

    private static HttpMessageDataStreamer getHttpMessageDataStreamer(HttpCarbonMessage outboundRequestMsg) {
        final HttpMessageDataStreamer outboundMsgDataStreamer;
        final PooledDataStreamerFactory pooledDataStreamerFactory = (PooledDataStreamerFactory)
                outboundRequestMsg.getProperty(HttpConstants.POOLED_BYTE_BUFFER_FACTORY);
        if (pooledDataStreamerFactory != null) {
            outboundMsgDataStreamer = pooledDataStreamerFactory.createHttpDataStreamer(outboundRequestMsg);
        } else {
            outboundMsgDataStreamer = new HttpMessageDataStreamer(outboundRequestMsg);
        }
        return outboundMsgDataStreamer;
    }

    /**
     * Serialize multipart entity body. If an array of body parts exist, encode body parts else serialize body content
     * if it exist as a byte channel/stream.
     *
     * @param env                 Represents the runtime environment
     * @param entityObj           Represents the entity that holds the actual body
     * @param messageOutputStream Output stream to which the payload is written
     * @param boundaryString      Boundary string that should be used in encoding body parts
     */
    private static void serializeMultiparts(Environment env, BObject entityObj, OutputStream messageOutputStream,
                                            String boundaryString) throws IOException {
        BArray bodyParts = EntityBodyHandler.getBodyPartArray(entityObj);
        if (bodyParts != null && bodyParts.size() > 0) {
            serializeMultipartDataSource(env, messageOutputStream, boundaryString, entityObj);
        } else {
            serializeDataSource(env, entityObj, messageOutputStream);
        }
    }

    /**
     * Encode body parts with the given boundary and send it across the wire.
     *
     * @param env                 Represents the runtime environment
     * @param boundaryString      Boundary string of multipart entity
     * @param entityObj           Represent ballerina entity struct
     * @param messageOutputStream Output stream to which the payload is written
     */
    private static void serializeMultipartDataSource(Environment env, OutputStream messageOutputStream,
                                                     String boundaryString, BObject entityObj) {
        MultipartDataSource multipartDataSource = new MultipartDataSource(env, entityObj, boundaryString);
        multipartDataSource.serialize(messageOutputStream);
        HttpUtil.closeMessageOutputStream(messageOutputStream);
    }

    private static void serializeDataSource(Environment env, BObject entityObj, OutputStream messageOutputStream)
            throws IOException {
        Object messageDataSource = EntityBodyHandler.getMessageDataSource(entityObj);
        if (messageDataSource != null) {
            HttpUtil.serializeDataSource(messageDataSource, entityObj, messageOutputStream);
            HttpUtil.closeMessageOutputStream(messageOutputStream);
        } else if (EntityBodyHandler.getByteStream(entityObj) != null) {
            //When the entity body is a byte stream and when it is not null
            EntityBodyHandler.writeByteStreamToOutputStream(env, entityObj, messageOutputStream);
            HttpUtil.closeMessageOutputStream(messageOutputStream);
        } else if (EntityBodyHandler.getByteChannel(entityObj) != null) {
            //When the entity body is a byte channel and when it is not null
            EntityBodyHandler.writeByteChannelToOutputStream(entityObj, messageOutputStream);
            HttpUtil.closeMessageOutputStream(messageOutputStream);
        } else {
            logger.debug("Entity does not have a serializable payload");
        }
    }

    private static class HTTPClientConnectorListener implements HttpClientConnectorListener {

        private DataContext dataContext;

        private HTTPClientConnectorListener(DataContext dataContext) {
            this.dataContext = dataContext;
        }

        @Override
        public void onMessage(HttpCarbonMessage inboundResponseMessage) {
            this.dataContext.notifyInboundResponseStatus
                    (HttpUtil.createResponseStruct(inboundResponseMessage), null);
        }

        @Override
        public void onResponseHandle(ResponseHandle responseHandle) {
            BObject httpFuture = ValueCreator.createObjectValue(ModuleUtils.getHttpPackage(),
                                                                HttpConstants.HTTP_FUTURE);
            httpFuture.addNativeData(HttpConstants.TRANSPORT_HANDLE, responseHandle);
            this.dataContext.notifyInboundResponseStatus(httpFuture, null);
        }

        @Override
        public void onError(Throwable throwable) {
            BError httpConnectorError;
            if (throwable instanceof ClientConnectorException) {
                httpConnectorError = HttpUtil.createHttpError(throwable);
            } else if (throwable instanceof IOException) {
                this.dataContext.getOutboundRequest().setIoException((IOException) throwable);
                httpConnectorError = HttpUtil.createHttpError(throwable);
            } else {
                this.dataContext.getOutboundRequest()
                        .setIoException(new IOException(throwable.getMessage(), throwable));
                httpConnectorError = HttpUtil.createHttpError(throwable);
            }
            this.dataContext.notifyInboundResponseStatus(null, httpConnectorError);
        }
    }

    /**
     * Observe {@link HTTPClientConnectorListener} and add HTTP status code as a tag to {@link ObserverContext}.
     */
    private static class ObservableHttpClientConnectorListener extends HTTPClientConnectorListener {

        private final DataContext context;

        private ObservableHttpClientConnectorListener(DataContext dataContext) {
            super(dataContext);
            this.context = dataContext;
        }

        @Override
        public void onMessage(HttpCarbonMessage httpCarbonMessage) {
            int statusCode = httpCarbonMessage.getHttpStatusCode();
            addHttpStatusCode(statusCode);
            super.onMessage(httpCarbonMessage);
        }

        @Override
        public void onError(Throwable throwable) {
            if (throwable instanceof ClientConnectorException) {
                ClientConnectorException clientConnectorException = (ClientConnectorException) throwable;
                addHttpStatusCode(clientConnectorException.getHttpStatusCode());
                ObserverContext observerContext =
                        ObserveUtils.getObserverContextOfCurrentFrame(context.getEnvironment());
                if (observerContext != null) {
                    observerContext.addTag(ObservabilityConstants.TAG_KEY_ERROR, ObservabilityConstants.TAG_TRUE_VALUE);
                }
            }
            super.onError(throwable);
        }

        private void addHttpStatusCode(int statusCode) {
            ObserverContext observerContext = ObserveUtils.getObserverContextOfCurrentFrame(context.getEnvironment());
            if (observerContext != null) {
                observerContext.addProperty(ObservabilityConstants.PROPERTY_KEY_HTTP_STATUS_CODE, statusCode);
            }
        }
    }
}
