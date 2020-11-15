/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.ballerinalang.net.http.actions.httpclient;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import org.ballerinalang.net.http.DataContext;
import org.ballerinalang.net.http.HttpConstants;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;

import static org.ballerinalang.net.http.HttpConstants.CLIENT_ENDPOINT_CONFIG;
import static org.ballerinalang.net.http.HttpConstants.CLIENT_ENDPOINT_SERVICE_URI;

/**
 * {@code Submit} action can be used to invoke a http call with any httpVerb in asynchronous manner.
 */
public class Submit extends Execute {
    @SuppressWarnings("unchecked")
    public static Object submit(Environment env, BObject httpClient, BString httpVerb, BString path,
                                BObject requestObj) {
        String url = httpClient.getStringValue(CLIENT_ENDPOINT_SERVICE_URI).getValue();
        BMap<BString, Object> config = (BMap<BString, Object>) httpClient.get(CLIENT_ENDPOINT_CONFIG);
        HttpClientConnector clientConnector = (HttpClientConnector) httpClient.getNativeData(HttpConstants.CLIENT);
        HttpCarbonMessage outboundRequestMsg = createOutboundRequestMsg(url, config, path.getValue(), requestObj);
        outboundRequestMsg.setHttpMethod(httpVerb.getValue());
        DataContext dataContext = new DataContext(env, clientConnector, requestObj, outboundRequestMsg);
        executeNonBlockingAction(dataContext, true);
        return null;
    }
}
