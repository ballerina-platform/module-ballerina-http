/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
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

package io.ballerina.stdlib.http.transport.contractimpl.listener.http3;

import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

/**
 * Message holder for inbound request and push response. Keeps track of the last read or write execution time.
 */
public class InboundMessageHolder {
    private HttpCarbonMessage inboundMsg;

    public InboundMessageHolder(HttpCarbonMessage inboundMsgOrPushResponse) {
        this.inboundMsg = inboundMsgOrPushResponse;
    }

    public HttpCarbonMessage getInboundMsg() {
        return inboundMsg;
    }

}
