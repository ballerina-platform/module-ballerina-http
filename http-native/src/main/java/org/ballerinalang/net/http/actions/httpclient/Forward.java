/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.http.actions.httpclient;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import org.ballerinalang.net.http.BallerinaConnectorException;
import org.ballerinalang.net.http.DataContext;
import org.ballerinalang.net.http.HttpConstants;
import org.ballerinalang.net.http.HttpUtil;
import org.ballerinalang.net.transport.contract.HttpClientConnector;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;

import java.util.Locale;

import static org.ballerinalang.net.http.HttpConstants.CLIENT_ENDPOINT_SERVICE_URI;
import static org.ballerinalang.net.http.HttpUtil.checkRequestBodySizeHeadersAvailability;

/**
 * {@code Forward} action can be used to invoke an http call with incoming request httpVerb.
 */
public class Forward extends AbstractHTTPAction {
    @SuppressWarnings("unchecked")
    public static Object forward(Environment env, BObject httpClient, BString path, BObject requestObj) {
        String url = httpClient.getStringValue(CLIENT_ENDPOINT_SERVICE_URI).getValue();
        HttpCarbonMessage outboundRequestMsg = createOutboundRequestMsg(url, path.getValue(), requestObj);
        HttpClientConnector clientConnector = (HttpClientConnector) httpClient.getNativeData(HttpConstants.CLIENT);
        DataContext dataContext = new DataContext(env, clientConnector, requestObj, outboundRequestMsg);
        executeNonBlockingAction(dataContext, false);
        return null;
    }

    protected static HttpCarbonMessage createOutboundRequestMsg(String serviceUri, String path, BObject requestObj) {
        if (requestObj.getNativeData(HttpConstants.REQUEST) == null &&
                !HttpUtil.isEntityDataSourceAvailable(requestObj)) {
            throw new BallerinaConnectorException("invalid inbound request parameter");
        }
        HttpCarbonMessage outboundRequestMsg = HttpUtil
                .getCarbonMsg(requestObj, HttpUtil.createHttpCarbonMessage(true));

        if (HttpUtil.isEntityDataSourceAvailable(requestObj)) {
            HttpUtil.enrichOutboundMessage(outboundRequestMsg, requestObj);
            prepareOutboundRequest(serviceUri, path, outboundRequestMsg,
                                   !checkRequestBodySizeHeadersAvailability(outboundRequestMsg));
            outboundRequestMsg.setHttpMethod(requestObj.get(HttpConstants.HTTP_REQUEST_METHOD).toString());
        } else {
            prepareOutboundRequest(serviceUri, path, outboundRequestMsg,
                                   !checkRequestBodySizeHeadersAvailability(outboundRequestMsg));
            String httpVerb = outboundRequestMsg.getHttpMethod();
            outboundRequestMsg.setHttpMethod(httpVerb.trim().toUpperCase(Locale.getDefault()));
        }
        return outboundRequestMsg;
    }
}
