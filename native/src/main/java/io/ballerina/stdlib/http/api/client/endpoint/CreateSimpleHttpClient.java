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

import static io.ballerina.stdlib.http.api.HttpConstants.HTTP2_PRIOR_KNOWLEDGE;
import static io.ballerina.stdlib.http.api.HttpUtil.getConnectionManager;
import static io.ballerina.stdlib.http.api.HttpUtil.populateSenderConfigurations;
import static io.ballerina.stdlib.http.transport.contract.Constants.HTTP_2_0_VERSION;

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
            if (!urlString.matches(HttpConstants.SCHEME_REGEX)) {
                urlString = HttpConstants.HTTP_SCHEME + urlString;
            }
            urlString = urlString.replaceAll(HttpConstants.REGEX, HttpConstants.SINGLE_SLASH);
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
            senderConfiguration.setTLSStoreType(HttpConstants.PKCS_STORE_TYPE);

            String httpVersion = clientEndpointConfig.getStringValue(HttpConstants.CLIENT_EP_HTTP_VERSION).getValue();
            if (HTTP_2_0_VERSION.equals(httpVersion)) {
                BMap<BString, Object> http2Settings = (BMap<BString, Object>) clientEndpointConfig.
                        get(HttpConstants.HTTP2_SETTINGS);
                boolean http2PriorKnowledge = (boolean) http2Settings.get(HTTP2_PRIOR_KNOWLEDGE);
                senderConfiguration.setForceHttp2(http2PriorKnowledge);
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

    private CreateSimpleHttpClient() {
    }
}
