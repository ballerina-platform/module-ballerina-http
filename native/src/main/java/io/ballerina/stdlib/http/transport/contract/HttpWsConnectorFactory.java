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

package io.ballerina.stdlib.http.transport.contract;

import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.ServerBootstrapConfiguration;
import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketClientConnector;
import io.ballerina.stdlib.http.transport.contract.websocket.WebSocketClientConnectorConfig;
import io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool.ConnectionManager;

import java.util.Map;

/**
 * Allows you create server and client connectors.
 */
public interface HttpWsConnectorFactory {
    /**
     * This method can be used to get new server connectors.
     *
     * @param serverBootstrapConfiguration configTargetHandler socket related stuff.
     * @param listenerConfiguration contains SSL and socket bindings.
     * @return connector that represents the server socket and additional details.
     */
    ServerConnector createServerConnector(ServerBootstrapConfiguration serverBootstrapConfiguration,
                                          ListenerConfiguration listenerConfiguration);

    /**
     * This method can be used to get http client connectors.
     *
     * @param transportProperties configTargetHandler stuff like global timeout, number of outbound connections, etc.
     * @param senderConfiguration contains SSL configuration and endpoint details.
     * @return HttpClientConnector.
     */
    HttpClientConnector createHttpClientConnector(Map<String, Object> transportProperties,
                                                  SenderConfiguration senderConfiguration);

    /**
     * This method can be used to get http client connectors with SSL context initialized.
     *
     * @param transportProperties configTargetHandler stuff like global timeout, number of outbound connections, etc.
     * @param senderConfiguration contains SSL configuration and endpoint details.
     * @throws Exception if the connector creation fails.
     * @return HttpClientConnector.
     */
    HttpClientConnector createHttpsClientConnector(Map<String, Object> transportProperties,
                                                   SenderConfiguration senderConfiguration) throws Exception;

    /**
     * Creates a client connector with a given connection manager.
     *
     * @param transportProperties Represents the configurations related to HTTP client
     * @param senderConfiguration Represents the configurations related to client channel creation
     * @param connectionManager   Manages the client pool
     * @return the HttpClientConnector
     */
    HttpClientConnector createHttpClientConnector(Map<String, Object> transportProperties,
                                                  SenderConfiguration senderConfiguration,
                                                  ConnectionManager connectionManager);


    /**
     * Creates a client connector with a given connection manager and SSL context.
     *
     * @param transportProperties Represents the configurations related to HTTP client
     * @param senderConfiguration Represents the configurations related to client channel creation
     * @param connectionManager   Manages the client pool
     * @throws Exception if the connector creation fails.
     * @return the HttpClientConnector
     */
    HttpClientConnector createHttpsClientConnector(Map<String, Object> transportProperties,
                                                   SenderConfiguration senderConfiguration,
                                                   ConnectionManager connectionManager) throws Exception;

    /**
     * This method is used to get WebSocket client connector.
     *
     * @param clientConnectorConfig Properties to create a client connector.
     * @return WebSocketClientConnector.
     */
    WebSocketClientConnector createWsClientConnector(WebSocketClientConnectorConfig clientConnectorConfig);

    /**
     * This method is used to get WebSocket client connector with SSL context initialized.
     *
     * @param clientConnectorConfig Properties to create a client connector.
     * @throws Exception if the connector creation fails.
     * @return WebSocketClientConnector.
     */
    WebSocketClientConnector createWsClientConnectorWithSSL(WebSocketClientConnectorConfig clientConnectorConfig)
            throws Exception;

    /**
     * Shutdown all the server channels and the accepted channels. It also shutdown all the eventloop groups.
     * @throws InterruptedException when interrupted by some other event
     */
    void shutdown() throws InterruptedException;
}
