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

    public static final int SLEEP_TIME = 100;

    public static final byte[] SETTINGS_FRAME = new byte[]{0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x64, 0x64};
    public static final byte[] SETTINGS_FRAME_WITH_ACK =
            new byte[]{0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00};
    public static final byte[] HEADER_FRAME_STREAM_03 = new byte[]{0x00, 0x00, 0x0a, 0x01, 0x04, 0x00, 0x00, 0x00, 0x03,
            (byte) 0x88, 0x5f, (byte) 0x87, 0x49, 0x7c, (byte) 0xa5, (byte) 0x8a, (byte) 0xe8, 0x19, (byte) 0xaa};
    public static final byte[] HEADER_FRAME_STREAM_05 = new byte[]{0x00, 0x00, 0x0a, 0x01, 0x04, 0x00, 0x00, 0x00, 0x05,
            (byte) 0x88, 0x5f, (byte) 0x87, 0x49, 0x7c, (byte) 0xa5, (byte) 0x8a, (byte) 0xe8, 0x19, (byte) 0xaa};
    public static final byte[] HEADER_FRAME_STREAM_07 = new byte[]{0x00, 0x00, 0x0a, 0x01, 0x04, 0x00, 0x00, 0x00, 0x07,
            (byte) 0x88, 0x5f, (byte) 0x87, 0x49, 0x7c, (byte) 0xa5, (byte) 0x8a, (byte) 0xe8, 0x19, (byte) 0xaa};
    public static final byte[] HEADER_FRAME_STREAM_09 = new byte[]{0x00, 0x00, 0x0a, 0x01, 0x04, 0x00, 0x00, 0x00, 0x09,
            (byte) 0x88, 0x5f, (byte) 0x87, 0x49, 0x7c, (byte) 0xa5, (byte) 0x8a, (byte) 0xe8, 0x19, (byte) 0xaa};
    public static final byte[] DATA_FRAME_STREAM_03 = new byte[]{0x00, 0x00, 0x0c, 0x00, 0x01, 0x00, 0x00, 0x00, 0x03,
            0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x33};
    public static final byte[] DATA_FRAME_STREAM_05 = new byte[]{0x00, 0x00, 0x0c, 0x00, 0x01, 0x00, 0x00, 0x00, 0x05,
            0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x35};
    public static final byte[] DATA_FRAME_STREAM_07 = new byte[]{0x00, 0x00, 0x0c, 0x00, 0x01, 0x00, 0x00, 0x00, 0x07,
            0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x37};
    public static final byte[] DATA_FRAME_STREAM_09 = new byte[]{0x00, 0x00, 0x0c, 0x00, 0x01, 0x00, 0x00, 0x00, 0x09,
            0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x39};
    public static final byte[] GO_AWAY_FRAME_STREAM_03 = new byte[]{0x00, 0x00, 0x08, 0x07, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x0b};
    public static final byte[] GO_AWAY_FRAME_MAX_STREAM_07 = new byte[]{0x00, 0x00, 0x08, 0x07, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00, 0x0b};

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
