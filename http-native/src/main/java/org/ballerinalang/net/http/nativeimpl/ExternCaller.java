/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.http.nativeimpl;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.values.BObject;
import org.ballerinalang.net.http.HttpConstants;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;

/**
 * Extern functions related to HTTP caller.
 *
 * @since 2.0.0
 */
public class ExternCaller {

    public static BObject getCaller(Environment env) {
        HttpCarbonMessage inboundMessage = (HttpCarbonMessage) env.getStrandLocal(HttpConstants.INBOUND_MESSAGE);
        return (BObject) inboundMessage.getProperty(HttpConstants.CALLER);
    }

    private ExternCaller() {}
}
