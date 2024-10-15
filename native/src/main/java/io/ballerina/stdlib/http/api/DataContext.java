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

package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.util.concurrent.CompletableFuture;

/**
 * {@code DataContext} is the wrapper to hold {@code Context} and {@code Callback}.
 */
public class DataContext {
    private Environment environment;
    private HttpClientConnector clientConnector;
    private BObject requestObj;
    private CompletableFuture<Object> balFuture;
    private HttpCarbonMessage correlatedMessage;

    public DataContext(Environment environment, HttpClientConnector clientConnector,
                       BObject requestObj, HttpCarbonMessage outboundRequestMsg) {
        this.environment = environment;
        this.balFuture = new CompletableFuture<>();
        this.clientConnector = clientConnector;
        this.requestObj = requestObj;
        this.correlatedMessage = outboundRequestMsg;
    }

    public DataContext(Environment environment, HttpCarbonMessage inboundRequestMsg) {
        this.environment = environment;
        this.balFuture = new CompletableFuture<>();
        this.clientConnector = null;
        this.requestObj = null;
        this.correlatedMessage = inboundRequestMsg;
    }

    public void notifyInboundResponseStatus(BObject inboundResponse, BError httpConnectorError) {
        //Make the request associate with this response consumable again so that it can be reused.
        if (inboundResponse != null) {
            getFuture().complete(inboundResponse);
        } else if (httpConnectorError != null) {
            getFuture().complete(httpConnectorError);
        } else {
            BError err = HttpUtil.createHttpError("inbound response retrieval error", HttpErrorType.CLIENT_ERROR);
            getFuture().complete(err);
        }
    }

    public void notifyOutboundResponseStatus(BError httpConnectorError) {
        getFuture().complete(httpConnectorError);
    }

    public HttpCarbonMessage getOutboundRequest() {
        return correlatedMessage;
    }

    public HttpClientConnector getClientConnector() {
        return clientConnector;
    }

    public BObject getRequestObj() {
        return requestObj;
    }

    public Environment getEnvironment() {
        return environment;
    }

    public CompletableFuture<Object> getFuture() {
        return balFuture;
    }
}
