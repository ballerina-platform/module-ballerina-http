/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.transport.http2.goaway;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;

public class GoAwayTestUtils {

    public static HttpClientConnector setupHttp2PriorKnowledgeClient() {
        HttpWsConnectorFactory connectorFactory = new DefaultHttpWsConnectorFactory();
        TransportsConfiguration transportsConfiguration = new TransportsConfiguration();
        SenderConfiguration senderConfiguration = new SenderConfiguration();
        senderConfiguration.setScheme(Constants.HTTP_SCHEME);
        senderConfiguration.setHttpVersion(Constants.HTTP_2_0);
        senderConfiguration.setForceHttp2(true);
        return connectorFactory.createHttpClientConnector(
                HttpConnectorUtil.getTransportProperties(transportsConfiguration), senderConfiguration);
    }
}
