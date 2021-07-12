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

import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.api.DataContext;
import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;

import java.io.OutputStream;

/**
 * {@code {@link ConnectionAction}} represents a Abstract implementation of Native Ballerina Connection Function.
 *
 * @since 0.96
 */
public abstract class ConnectionAction {

    static void sendOutboundResponseRobust(DataContext dataContext, HttpCarbonMessage requestMessage,
                                    BObject outboundResponseObj, HttpCarbonMessage responseMessage) {
        ResponseWriter.sendResponseRobust(dataContext, requestMessage, outboundResponseObj, responseMessage);
    }

    static void setResponseConnectorListener(DataContext dataContext, HttpResponseFuture outResponseStatusFuture) {
        HttpConnectorListener outboundResStatusConnectorListener =
                new ResponseWriter.HttpResponseConnectorListener(dataContext);
        outResponseStatusFuture.setHttpConnectorListener(outboundResStatusConnectorListener);
    }

    static void serializeMsgDataSource(DataContext dataContext, Object outboundMessageSource, BObject entityStruct,
                                       OutputStream messageOutputStream) {
        ResponseWriter.serializeDataSource(dataContext.getEnvironment(), outboundMessageSource, entityStruct,
                                           messageOutputStream);
    }

    static HttpMessageDataStreamer getMessageDataStreamer(HttpCarbonMessage outboundResponse) {
        return ResponseWriter.getResponseDataStreamer(outboundResponse);
    }
}
