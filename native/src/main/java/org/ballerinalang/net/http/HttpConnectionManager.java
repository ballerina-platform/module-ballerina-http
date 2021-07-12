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
 */
package org.ballerinalang.net.http;

import org.ballerinalang.net.transport.contract.HttpWsConnectorFactory;
import org.ballerinalang.net.transport.contract.ServerConnector;
import org.ballerinalang.net.transport.contract.config.ListenerConfiguration;
import org.ballerinalang.net.transport.contract.config.SenderConfiguration;
import org.ballerinalang.net.transport.contract.config.ServerBootstrapConfiguration;
import org.ballerinalang.net.transport.contract.config.TransportProperty;
import org.ballerinalang.net.transport.contract.config.TransportsConfiguration;
import org.ballerinalang.net.transport.message.HttpConnectorUtil;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import static org.ballerinalang.net.http.HttpConstants.HTTP_ACCESS_LOG_ENABLED;
import static org.ballerinalang.net.http.HttpConstants.HTTP_TRACE_LOG_ENABLED;

/**
 * {@code HttpConnectionManager} is responsible for managing all the server connectors with ballerina runtime.
 *
 * @since 0.94
 */
public class HttpConnectionManager {

    private static final HttpConnectionManager instance = new HttpConnectionManager();
    private final Map<String, ServerConnector> startupDelayedHTTPServerConnectors = new HashMap<>();
    private final Map<String, HttpServerConnectorContext> serverConnectorPool = new HashMap<>();
    private ServerBootstrapConfiguration serverBootstrapConfiguration;
    private final TransportsConfiguration trpConfig;
    private final HttpWsConnectorFactory httpConnectorFactory = HttpUtil.createHttpWsConnectionFactory();

    private HttpConnectionManager() {
        trpConfig = buildDefaultTransportConfig();
        serverBootstrapConfiguration = HttpConnectorUtil
                .getServerBootstrapConfiguration(trpConfig.getTransportProperties());
    }

    public static HttpConnectionManager getInstance() {
        return instance;
    }

    public ServerConnector createHttpServerConnector(ListenerConfiguration listenerConfig) throws Exception {
        String listenerInterface = listenerConfig.getHost() + ":" + listenerConfig.getPort();
        HttpServerConnectorContext httpServerConnectorContext = serverConnectorPool.get(listenerInterface);
        if (httpServerConnectorContext != null) {
            if (checkForConflicts(listenerConfig, httpServerConnectorContext)) {
                throw new Exception("Conflicting configuration detected for listener " +
                        "configuration id " + listenerConfig.getId());
            }
            httpServerConnectorContext.incrementReferenceCount();
            return httpServerConnectorContext.getServerConnector();
        }

        if (isHTTPTraceLoggerEnabled()) {
            listenerConfig.setHttpTraceLogEnabled(true);
        }

        if (isHTTPAccessLoggerEnabled()) {
            listenerConfig.setHttpAccessLogEnabled(true);
        }

        serverBootstrapConfiguration = HttpConnectorUtil
                .getServerBootstrapConfiguration(trpConfig.getTransportProperties());
        ServerConnector serverConnector =
                httpConnectorFactory.createServerConnector(serverBootstrapConfiguration, listenerConfig);

        httpServerConnectorContext = new HttpServerConnectorContext(serverConnector, listenerConfig);
        serverConnectorPool.put(serverConnector.getConnectorID(), httpServerConnectorContext);
        httpServerConnectorContext.incrementReferenceCount();
        addStartupDelayedHTTPServerConnector(listenerInterface, serverConnector);
        return serverConnector;
    }

    /**
     * Add a HTTP ServerConnector which startup is delayed at the service deployment time.
     *
     * @param id connector identifier
     * @param serverConnector ServerConnector
     */
    public void addStartupDelayedHTTPServerConnector(String id, ServerConnector serverConnector) {
        startupDelayedHTTPServerConnectors.put(id, serverConnector);
    }

    private static class HttpServerConnectorContext {
        private final ServerConnector serverConnector;
        private final ListenerConfiguration listenerConfiguration;
        private int referenceCount = 0;

        HttpServerConnectorContext(ServerConnector serverConnector, ListenerConfiguration listenerConfiguration) {
            this.serverConnector = serverConnector;
            this.listenerConfiguration = listenerConfiguration;
        }

        void incrementReferenceCount() {
            this.referenceCount++;
        }

        void decrementReferenceCount() {
            this.referenceCount--;
        }

        ServerConnector getServerConnector() {
            return this.serverConnector;
        }

        ListenerConfiguration getListenerConfiguration() {
            return this.listenerConfiguration;
        }

        int getReferenceCount() {
            return this.referenceCount;
        }
    }

    private boolean checkForConflicts(ListenerConfiguration listenerConfiguration, HttpServerConnectorContext context) {
        if (context == null) {
            return false;
        }
        if (!listenerConfiguration.getScheme().equalsIgnoreCase("https")) {
            return false;
        }
        ListenerConfiguration config = context.getListenerConfiguration();
        return !listenerConfiguration.getKeyStoreFile().equals(config.getKeyStoreFile())
                || !listenerConfiguration.getKeyStorePass().equals(config.getKeyStorePass());
    }

    public TransportsConfiguration getTransportConfig() {
        return trpConfig;
    }

    public boolean isHTTPTraceLoggerEnabled() {
        return Boolean.parseBoolean(System.getProperty(HTTP_TRACE_LOG_ENABLED));
    }

    private boolean isHTTPAccessLoggerEnabled() {
        return Boolean.parseBoolean(System.getProperty(HTTP_ACCESS_LOG_ENABLED));
    }

    private TransportsConfiguration buildDefaultTransportConfig() {
        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration httpSender = new SenderConfiguration("http-sender");

        SenderConfiguration httpsSender = new SenderConfiguration("https-sender");
        httpsSender.setScheme("https");

        TransportProperty latencyMetrics = new TransportProperty();
        latencyMetrics.setName("latency.metrics.enabled");
        latencyMetrics.setValue(true);

        TransportProperty serverSocketTimeout = new TransportProperty();
        serverSocketTimeout.setName("server.bootstrap.socket.timeout");
        serverSocketTimeout.setValue(60);

        TransportProperty clientSocketTimeout = new TransportProperty();
        clientSocketTimeout.setName("client.bootstrap.socket.timeout");
        clientSocketTimeout.setValue(60);

        Set<SenderConfiguration> senderConfigurationSet = new HashSet<>();
        senderConfigurationSet.add(httpSender);
        senderConfigurationSet.add(httpsSender);
        transportsConfiguration.setSenderConfigurations(senderConfigurationSet);

        Set<TransportProperty> transportPropertySet = new HashSet<>();
        transportPropertySet.add(latencyMetrics);
        transportPropertySet.add(serverSocketTimeout);
        transportPropertySet.add(clientSocketTimeout);
        transportsConfiguration.setTransportProperties(transportPropertySet);

        return transportsConfiguration;
    }
}
