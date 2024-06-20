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
 */

package io.ballerina.stdlib.http.api.client.endpoint;

import io.ballerina.runtime.api.values.BDecimal;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpConnectionManager;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.Map;

import static io.ballerina.stdlib.http.api.HttpConstants.CLIENT_EP_HTTP2_INITIAL_WINDOW_SIZE;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP2_PRIOR_KNOWLEDGE;
import static io.ballerina.stdlib.http.api.HttpConstants.SOCKET_CONFIG_CONNECT_TIMEOUT;
import static io.ballerina.stdlib.http.api.HttpConstants.SOCKET_CONFIG_KEEP_ALIVE;
import static io.ballerina.stdlib.http.api.HttpConstants.SOCKET_CONFIG_RECEIVE_BUFFER_SIZE;
import static io.ballerina.stdlib.http.api.HttpConstants.SOCKET_CONFIG_SEND_BUFFER_SIZE;
import static io.ballerina.stdlib.http.api.HttpConstants.SOCKET_CONFIG_SOCKET_REUSE;
import static io.ballerina.stdlib.http.api.HttpConstants.SOCKET_CONFIG_TCP_NO_DELAY;
import static io.ballerina.stdlib.http.api.HttpUtil.getConnectionManager;
import static io.ballerina.stdlib.http.api.HttpUtil.populateSenderConfigurations;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_2_0_VERSION;
import static java.lang.System.err;

/**
 * Initialization of client endpoint.
 *
 * @since 0.966
 */
public class CreateSimpleHttpClient {
    @SuppressWarnings("unchecked")
    public static Object createSimpleHttpClient(BObject httpClient, BMap globalPoolConfig, BString clientUrl,
                                                BMap<BString, Object> clientEndpointConfig, BString optionsString) {
        try {
            HttpConnectionManager connectionManager = HttpConnectionManager.getInstance();
            String scheme;
            String urlString = clientUrl.getValue();
            if (!urlString.strip().isEmpty()) {
                String[] urlStrings = urlString.split(HttpConstants.SCHEME_SEPARATOR, 2);
                if (urlStrings.length == 1) {
                    urlStrings = isClientSecurityConfigured(clientEndpointConfig) ?
                            new String[]{HttpConstants.HTTPS_SCHEME, urlStrings[0]} :
                            new String[]{HttpConstants.HTTP_SCHEME, urlStrings[0]};
                } else {
                    if (urlStrings[0].equals(HttpConstants.HTTP_SCHEME) &&
                            isClientSecurityConfigured(clientEndpointConfig)) {
                        err.println(HttpConstants.HTTP_RUNTIME_WARNING_PREFIX +
                                HttpConstants.HTTPS_RECOMMENDATION_ERROR);
                    }
                }
                urlStrings[1] = urlStrings[1].replaceAll(HttpConstants.DOUBLE_SLASH, HttpConstants.SINGLE_SLASH);
                urlString = urlStrings[0] + HttpConstants.SCHEME_SEPARATOR + urlStrings[1];
            }
            URL url;
            try {
                url = new URL(urlString);
            } catch (MalformedURLException e) {
                return HttpUtil.createHttpError("malformed URL: " + urlString, HttpErrorType.GENERIC_CLIENT_ERROR);
            }
            scheme = url.getProtocol();
            Map<String, Object> properties =
                    HttpConnectorUtil.getTransportProperties(connectionManager.getTransportConfig());
            properties.put(HttpConstants.CLIENT_CONFIG_HASH_CODE, optionsString.hashCode());
            SenderConfiguration senderConfiguration = new SenderConfiguration();
            senderConfiguration.setScheme(scheme);

            if (connectionManager.isHTTPTraceLoggerEnabled()) {
                senderConfiguration.setHttpTraceLogEnabled(true);
            }
            if (connectionManager.isHTTPAccessLoggerEnabled()) {
                senderConfiguration.setHttpAccessLogEnabled(true);
            }
            senderConfiguration.setTLSStoreType(HttpConstants.PKCS_STORE_TYPE);

            String httpVersion = clientEndpointConfig.getStringValue(HttpConstants.CLIENT_EP_HTTP_VERSION).getValue();
            if (HTTP_2_0_VERSION.equals(httpVersion)) {
                BMap<BString, Object> http2Settings = (BMap<BString, Object>) clientEndpointConfig.
                        get(HttpConstants.HTTP2_SETTINGS);
                boolean http2PriorKnowledge = (boolean) http2Settings.get(HTTP2_PRIOR_KNOWLEDGE);
                senderConfiguration.setForceHttp2(http2PriorKnowledge);
                if (!http2PriorKnowledge) {
                    BMap<BString, Object> http1Settings = (BMap<BString, Object>) clientEndpointConfig.get(
                            HttpConstants.HTTP1_SETTINGS);
                    senderConfiguration.setKeepAliveConfig(HttpUtil.getKeepAliveConfig(http1Settings
                            .getStringValue(HttpConstants.CLIENT_EP_IS_KEEP_ALIVE).getValue()));
                }
                senderConfiguration.setHttp2InitialWindowSize(http2Settings
                        .getIntValue(CLIENT_EP_HTTP2_INITIAL_WINDOW_SIZE).intValue());
            } else {
                BMap<BString, Object> http1Settings = (BMap<BString, Object>) clientEndpointConfig.get(
                        HttpConstants.HTTP1_SETTINGS);
                String chunking = http1Settings.getStringValue(HttpConstants.CLIENT_EP_CHUNKING).getValue();
                senderConfiguration.setChunkingConfig(HttpUtil.getChunkConfig(chunking));
                String keepAliveConfig = http1Settings.getStringValue(HttpConstants.CLIENT_EP_IS_KEEP_ALIVE).getValue();
                senderConfiguration.setKeepAliveConfig(HttpUtil.getKeepAliveConfig(keepAliveConfig));
            }

            // Set Response validation limits.
            BMap<BString, Object> responseLimits = (BMap<BString, Object>) clientEndpointConfig.get(
                    HttpConstants.RESPONSE_LIMITS);
            HttpUtil.setInboundMgsSizeValidationConfig(responseLimits.getIntValue(HttpConstants.MAX_STATUS_LINE_LENGTH),
                                                       responseLimits.getIntValue(HttpConstants.MAX_HEADER_SIZE),
                                                       responseLimits.getIntValue(HttpConstants.MAX_ENTITY_BODY_SIZE),
                                                       senderConfiguration.getMsgSizeValidationConfig());
            try {
                populateSenderConfigurations(senderConfiguration, clientEndpointConfig, scheme);
            } catch (RuntimeException e) {
                return HttpUtil.createHttpError(e.getMessage(), HttpErrorType.GENERIC_CLIENT_ERROR);
            }
            ConnectionManager poolManager;
            BMap userDefinedPoolConfig = (BMap) clientEndpointConfig.get(
                    HttpConstants.USER_DEFINED_POOL_CONFIG);

            if (userDefinedPoolConfig == null) {
                poolManager = getConnectionManager(globalPoolConfig);
            } else {
                poolManager = getConnectionManager(userDefinedPoolConfig);
            }

            BMap<BString, Object> clientSocketConfig =
                    (BMap<BString, Object>) clientEndpointConfig.getMapValue(HttpConstants.SOCKET_CONFIG);
            if (clientSocketConfig != null) {
                setClientSocketConfig(clientSocketConfig, senderConfiguration);
            }

            HttpClientConnector httpClientConnector = HttpUtil.createHttpWsConnectionFactory()
                    .createHttpClientConnector(properties, senderConfiguration, poolManager);
            httpClient.addNativeData(HttpConstants.CLIENT, httpClientConnector);
            httpClient.addNativeData(HttpConstants.CLIENT_ENDPOINT_SERVICE_URI, urlString);
            httpClient.addNativeData(HttpConstants.CLIENT_ENDPOINT_CONFIG, clientEndpointConfig);
            return null;
        } catch (Exception ex) {
            return HttpUtil.createHttpError(ex.getMessage(), HttpErrorType.GENERIC_CLIENT_ERROR);
        }
    }

    private static boolean isClientSecurityConfigured(BMap<BString, Object> clientEndpointConfig) {
        return clientEndpointConfig.get(HttpConstants.ENDPOINT_CONFIG_SECURESOCKET) != null ||
                clientEndpointConfig.get(HttpConstants.CLIENT_EP_AUTH) != null;
    }

    private static void setClientSocketConfig(BMap<BString, Object> clientSocketConfig,
                                              SenderConfiguration senderConfig) {
        double connectTimeOut = ((BDecimal) clientSocketConfig.get(SOCKET_CONFIG_CONNECT_TIMEOUT)).floatValue();
        senderConfig.setConnectTimeOut(connectTimeOut);
        int receiveBufferSize = clientSocketConfig.getIntValue(SOCKET_CONFIG_RECEIVE_BUFFER_SIZE).intValue();
        senderConfig.setReceiveBufferSize(receiveBufferSize);
        int sendBufferSize = clientSocketConfig.getIntValue(SOCKET_CONFIG_SEND_BUFFER_SIZE).intValue();
        senderConfig.setSendBufferSize(sendBufferSize);
        boolean tcpNoDelay = clientSocketConfig.getBooleanValue(SOCKET_CONFIG_TCP_NO_DELAY);
        senderConfig.setTcpNoDelay(tcpNoDelay);
        boolean socketReuse = clientSocketConfig.getBooleanValue(SOCKET_CONFIG_SOCKET_REUSE);
        senderConfig.setSocketReuse(socketReuse);
        boolean keepAlive = clientSocketConfig.getBooleanValue(SOCKET_CONFIG_KEEP_ALIVE);
        senderConfig.setSocketKeepAlive(keepAlive);
    }

    private CreateSimpleHttpClient() {
    }
}
